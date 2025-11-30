from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType
from workflow_classifier import WorkflowOutputClassifier  # 导入分类工具

app = Flask(__name__)
CORS(app, resources=r"/*")  # 仍保留跨域配置，避免请求被拦截

# Coze 配置
COZE_API_TOKEN = 'cztei_htpqzfVbgW3anKOvM9EJL3qV3oDG9v6RyJYPSYNJC1mvUtFxNIoKKH3LWGg2EpHnN'
WORKFLOW_ID = '7526153262711554084'
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)


def handle_workflow_stream(stream: Stream[WorkflowEvent]):
    """处理工作流流式结果，调用分类工具并打印分类数据"""
    classified_results = []  # 存储所有分类结果
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            print("\n===== 原始消息 =====")
            print(event.message)  # 打印原始消息

            if not event.message or not event.message.content:
                print("消息内容为空，跳过处理")
                continue

            # 调用分类工具
            classify_result = WorkflowOutputClassifier.classify(event.message.content)

            if classify_result["success"]:
                print("\n===== 分类后的数据 =====")
                print(f"output1_1: {classify_result['data']['output1_1']}")
                print(f"output2_2: {classify_result['data']['output2_2']}")
                print(f"output3_3: {classify_result['data']['output3_3']}")
                classified_results.append(classify_result["data"])
            else:
                print("\n===== 分类失败 =====")
                print(classify_result["error"])
                classified_results.append({"error": classify_result["error"]})

        elif event.event == WorkflowEventType.ERROR:
            print("\n===== 工作流错误 =====")
            print(event.error)
            return {"success": False, "error": str(event.error)}
        elif event.event == WorkflowEventType.INTERRUPT:
            print("\n===== 工作流中断 =====")
            return {"success": False, "error": "工作流需要补充信息"}

    return {"success": True, "data": classified_results}


@app.route('/api/aigenerate', methods=['POST'])
def receive_and_process():
    try:
        # 接收前端请求数据
        data = request.get_json()
        if not data or 'content' not in data:
            return jsonify({
                'code': 400,
                'message': '缺少content字段，无需返回分类数据'
            }), 400

        input_content = data['content']
        print(f"\n===== 前端传入的数据 =====")
        print(input_content)

        # 调用工作流
        input_parameters = {"input": input_content}
        stream = coze.workflows.runs.stream(
            workflow_id=WORKFLOW_ID,
            parameters=input_parameters
        )
        workflow_result = handle_workflow_stream(stream)

        # 仅返回状态，不返回分类数据（分类数据已在后端打印）
        if workflow_result["success"]:
            return jsonify({
                'code': 200,
                'message': '分类数据已在后端打印，无需返回给前端'
            }), 200
        else:
            return jsonify({
                'code': 500,
                'message': workflow_result["error"]
            }), 500

    except json.JSONDecodeError:
        return jsonify({'code': 400, 'message': '无效的JSON格式'}), 400
    except Exception as e:
        return jsonify({'code': 500, 'message': f'服务器错误：{str(e)}'}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)