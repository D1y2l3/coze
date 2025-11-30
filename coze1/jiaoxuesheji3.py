from flask import Flask, request, jsonify
from flask_cors import CORS
import json
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

# 初始化Flask应用
app = Flask(__name__)
CORS(app, resources=r"/*")  # 解决跨域问题

# Coze配置（请替换为你的实际API Token和工作流ID）
COZE_API_TOKEN = 'pat_ObtKbqWHYEimyO5jeQqxEfigFjAl8wXoqezh0FDtPOYDKjARpP9QKTqvXafTSJIN'
WORKFLOW_ID = '7553477857655291955'
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)


def handle_workflow_stream(stream: Stream[WorkflowEvent]):
    """处理Coze工作流的流式返回结果，保持与前端交互的格式一致性"""
    result = []
    for event in stream:
        # 打印每一条流式事件（可选，用于调试流式过程）
        # print(f"收到Coze事件: {event.event}, 内容: {event.message.content if event.message else None}")
        if event.event == WorkflowEventType.MESSAGE:
            if event.message and event.message.content:
                result.append(event.message.content)
        elif event.event == WorkflowEventType.ERROR:
            error_msg = f"工作流错误: {event.error}"
            print(f"[错误] {error_msg}")  # 打印工作流错误日志
            return {"success": False, "error": error_msg}
        elif event.event == WorkflowEventType.INTERRUPT:
            print(f"[中断] 工作流需要交互，尝试恢复...")  # 打印中断日志
            # 处理中断交互（保持递归调用逻辑）
            resume_result = handle_workflow_stream(
                coze.workflows.runs.resume(
                    workflow_id=WORKFLOW_ID,
                    event_id=event.interrupt.interrupt_data.event_id,
                    resume_data="请继续完成内容生成（基于用户需求：生成指定内容）",  # 可根据实际需求调整
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
    """接收前端传入的数据，调用Coze工作流处理，并打印结果到控制台"""
    try:
        # 解析前端请求（要求包含content字段）
        data = request.get_json()
        if not data or 'content' not in data:
            err_msg = "缺少content字段"
            print(f"[请求错误] {err_msg}")  # 打印请求参数错误日志
            return jsonify({
                'code': 400,
                'message': err_msg,
                'data': None
            }), 400

        # 提取并打印前端传入的内容
        input_content = data['content']
        print(f"\n===== 收到前端请求 =====")
        print(f"前端传入的数据: {input_content}")
        print(f"=======================\n")

        # 调用Coze工作流
        print(f"正在调用Coze工作流（ID: {WORKFLOW_ID}）...")
        stream = coze.workflows.runs.stream(
            workflow_id=WORKFLOW_ID,
            parameters={"input": input_content}  # 注意：需与Coze工作流的“输入参数名”一致
        )
        workflow_result = handle_workflow_stream(stream)

        # 打印工作流处理完成后的最终数据
        print(f"\n===== 工作流处理完成 =====")
        if workflow_result["success"]:
            print(f"处理结果: 成功")
            print(f"返回给前端的数据: \n{workflow_result['data']}")  # 核心：打印最终返回数据
        else:
            print(f"处理结果: 失败")
            print(f"错误信息: {workflow_result['error']}")
        print(f"=======================\n")

        # 统一返回格式给前端
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
        err_msg = "无效的JSON格式"
        print(f"[解析错误] {err_msg}")  # 打印JSON解析错误日志
        return jsonify({'code': 400, 'message': err_msg, 'data': None}), 400
    except Exception as e:
        err_msg = f"服务器错误: {str(e)}"
        print(f"[服务器错误] {err_msg}")  # 打印通用服务器错误日志
        return jsonify({'code': 500, 'message': err_msg, 'data': None}), 500


if __name__ == '__main__':
    # 保持与原服务相同的启动配置（host=0.0.0.0允许外部访问，port=5001为服务端口）
    print(f"Flask服务已启动，监听地址: http://0.0.0.0:5001")
    print(f"接口地址: POST http://0.0.0.0:5001/api/sheji")
    app.run(host='0.0.0.0', port=5001, debug=True)