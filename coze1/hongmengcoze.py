from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

app = Flask(__name__)
# 解决跨域问题
CORS(app, resources=r"/*")

# Coze配置
coze_api_token = os.getenv('COZE_API_TOKEN', 'pat_TlYEeblB2DWUBHgqQKPrweeGTg67kL36qj5zS3qfTcWrGkFrk2rpC1a1UEtarxuo')
coze_api_base = COZE_CN_BASE_URL
coze = Coze(auth=TokenAuth(token=coze_api_token), base_url=coze_api_base)
workflow_id = '7526153262711554084'  # 你的工作流ID


def handle_workflow_iterator(stream: Stream[WorkflowEvent]):
    """处理工作流返回的流式事件"""
    result = []
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            # 收集消息内容
            if event.message and event.message.content:
                result.append(event.message.content)
        elif event.event == WorkflowEventType.ERROR:
            return {"success": False, "error": str(event.error)}
        elif event.event == WorkflowEventType.INTERRUPT:
            # 处理中断情况，这里简单返回需要补充信息
            return {"success": False, "error": "需要补充信息才能继续", "interrupt": True}
    return {"success": True, "result": "\n".join(result)}


@app.route('/api/aigenerate', methods=['POST'])
def receive_and_process():
    try:
        # 1. 解析前端发送的JSON数据
        data = request.get_json()

        # 检查是否包含必要的字段
        if not data or 'content' not in data:
            return jsonify({
                'code': 400,
                'message': '缺少content字段',
                'data': None
            }), 400

        # 2. 获取前端数据并构建工作流输入参数
        input = data['content']
        print(f"收到前端数据: {input}")

        input_parameters = {
            "input": input  # 这里的key与工作流开始节点定义的变量名一致
        }

        # 3. 调用Coze工作流
        stream = coze.workflows.runs.stream(
            workflow_id=workflow_id,
            parameters=input_parameters
        )

        # 4. 处理工作流返回结果
        workflow_result = handle_workflow_iterator(stream)

        if workflow_result["success"]:
            return jsonify({
                'code': 200,
                'message': '处理成功',
                'data': workflow_result["result"]
            }), 200
        else:
            return jsonify({
                'code': 500,
                'message': workflow_result["error"],
                'data': None
            }), 500

    except json.JSONDecodeError:
        return jsonify({
            'code': 400,
            'message': '无效的JSON格式',
            'data': None
        }), 400
    except Exception as e:
        return jsonify({
            'code': 500,
            'message': f'服务器错误: {str(e)}',
            'data': None
        }), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
