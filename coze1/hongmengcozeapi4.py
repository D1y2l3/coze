from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

app = Flask(__name__)
CORS(app, resources=r"/*")  # 解决跨域问题

# Coze 配置（建议将敏感信息放在环境变量中，此处为示例）
COZE_API_TOKEN = 'cztei_lN45HsGqVxVw0V6sc1jqqe6vEbuKF8V4iZF5Et4rvPX3WYqBVBgWitUwEd4Y1mY1A'  # 替换为你的令牌
WORKFLOW_ID = '7526153262711554084'  # 替换为你的工作流ID
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)


def handle_workflow_stream(stream: Stream[WorkflowEvent]):
    """处理Coze工作流的流式返回结果"""
    result = []
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            # 打印工作流返回的消息详情
            print("got message", event.message)
            # 收集工作流返回的消息内容
            if event.message and event.message.content:
                result.append(event.message.content)
        elif event.event == WorkflowEventType.ERROR:
            # 新增：打印工作流返回的错误详情
            print("got error", event.error)
            # 处理错误
            return {"success": False, "error": f"工作流错误: {event.error}"}
        elif event.event == WorkflowEventType.INTERRUPT:
            # 处理中断（如需补充信息，可在此处逻辑中添加）
            return {"success": False, "error": "工作流需要补充信息，请优化输入"}
    return {"success": True, "data": "".join(result)}


@app.route('/api/aigenerate', methods=['POST'])
def receive_and_process():
    try:
        # 1. 接收前端数据
        data = request.get_json()
        if not data or 'content' not in data:
            return jsonify({
                'code': 400,
                'message': '缺少content字段',
                'data': None
            }), 400

        # 前端传入的数据（例如用户输入的"生成计算机网络试卷"）
        input = data['content']
        print(f"前端传入的数据: {input}")

        # 2. 将前端数据传入Coze工作流的input参数
        input_parameters = {
            "input": input  # 这里的key需与工作流开始节点的变量名一致
        }

        # 3. 调用Coze工作流并处理结果
        stream = coze.workflows.runs.stream(
            workflow_id=WORKFLOW_ID,
            parameters=input_parameters
        )
        workflow_result = handle_workflow_stream(stream)

        # 4. 返回结果给前端
        if workflow_result["success"]:
            return jsonify({
                'code': 200,
                'message': '处理成功',
                'data': workflow_result["data"]  # 工作流生成的结果（如试卷内容）
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
    app.run(host='0.0.0.0', port=5000, debug=True)
