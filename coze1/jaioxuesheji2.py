from flask import Flask, request, jsonify
from flask_cors import CORS
import json
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

# 初始化Flask应用
app = Flask(__name__)
CORS(app, resources=r"/*")  # 解决跨域问题

# Coze配置（替换为你的实际信息）
COZE_API_TOKEN = 'pat_ObtKbqWHYEimyO5jeQqxEfigFjAl8wXoqezh0FDtPOYDKjARpP9QKTqvXafTSJIN'
WORKFLOW_ID = '7553477857655291955'
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)


def handle_workflow_stream(stream: Stream[WorkflowEvent]):
    """处理Coze工作流的流式返回结果，保持与前端交互的格式一致性"""
    result = []
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            if event.message and event.message.content:
                result.append(event.message.content)
        elif event.event == WorkflowEventType.ERROR:
            return {"success": False, "error": f"工作流错误: {event.error}"}
        elif event.event == WorkflowEventType.INTERRUPT:
            # 处理中断交互（保持递归调用逻辑）
            resume_result = handle_workflow_stream(
                coze.workflows.runs.resume(
                    workflow_id=WORKFLOW_ID,
                    event_id=event.interrupt.interrupt_data.event_id,
                    resume_data="请继续完成内容生成",  # 可根据实际需求调整中断回复
                    interrupt_type=event.interrupt.interrupt_data.type,
                )
            )
            if not resume_result["success"]:
                return resume_result
            result.append(resume_result["data"])

    # 合并流式结果
    content = "".join(result)
    return {"success": True, "data": content}


@app.route('/api/sheji', methods=['POST'])
def receive_and_process():
    """接收前端传入的数据，格式与鸿蒙前端保持一致"""
    try:
        # 解析前端请求（要求包含content字段）
        data = request.get_json()
        if not data or 'content' not in data:
            return jsonify({
                'code': 400,
                'message': '缺少content字段',
                'data': None
            }), 400

        # 提取前端传入的内容
        input_content = data['content']
        print(f"前端传入的数据: {input_content}")

        # 调用Coze工作流
        stream = coze.workflows.runs.stream(
            workflow_id=WORKFLOW_ID,
            parameters={"input": input_content}  # 保持参数传递格式一致
        )
        workflow_result = handle_workflow_stream(stream)

        # 统一返回格式
        if workflow_result["success"]:
            return jsonify({
                'code': 200,
                'message': '处理成功',
                'data': workflow_result["data"]
            }), 200
        else:
            return jsonify({
                'code': 500,
                'message': workflow_result["error"],
                'data': None
            }), 500

    except json.JSONDecodeError:
        return jsonify({'code': 400, 'message': '无效的JSON格式', 'data': None}), 400
    except Exception as e:
        return jsonify({'code': 500, 'message': f'服务器错误: {str(e)}', 'data': None}), 500


if __name__ == '__main__':
    # 保持与原服务相同的启动配置
    app.run(host='0.0.0.0', port=5001, debug=True)