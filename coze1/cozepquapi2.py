from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType
from workflow_classifier import WorkflowOutputClassifier  # 导入分类工具

app = Flask(__name__)
CORS(app, resources=r"/*")  # 跨域配置

# Coze 配置 - 更新为新的工作流ID
COZE_API_TOKEN = 'pat_ObtKbqWHYEimyO5jeQqxEfigFjAl8wXoqezh0FDtPOYDKjARpP9QKTqvXafTSJIN'
WORKFLOW_ID = '7537788037603426354'  # 新的工作流ID
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)


def handle_workflow_iterator(stream: Stream[WorkflowEvent], classified_data=None):
    """处理工作流迭代器，包含中断处理逻辑"""
    # 如果有分类数据，将其作为后续参数
    input_parameters = {}
    if classified_data:
        input_parameters = {
            "input1": classified_data.get("output1_1", ""),
            "input2": classified_data.get("output2_2", ""),
            "input3": classified_data.get("output3_3", "")
        }

    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            print("收到消息:", event.message)

        elif event.event == WorkflowEventType.ERROR:
            print("工作流错误:", event.error)
            return {"success": False, "error": str(event.error)}

        elif event.event == WorkflowEventType.INTERRUPT:
            print("工作流中断，需要补充信息")
            # 中断时使用分类数据作为补充参数继续工作流
            return handle_workflow_iterator(
                coze.workflows.runs.resume(
                    workflow_id=WORKFLOW_ID,
                    event_id=event.interrupt.interrupt_data.event_id,
                    resume_data=json.dumps(input_parameters),  # 使用分类数据作为补充参数
                    interrupt_type=event.interrupt.interrupt_data.type,
                ),
                classified_data  # 传递分类数据
            )

    return {"success": True}


def process_with_workflow(input_content, classified_data):
    """使用分类后的数据调用工作流"""
    # 构建包含前端输入和分类结果的参数
    input_parameters = {
        "input": input_content,  # 前端传入的数据
        "input1": classified_data.get("output1_1", ""),  # 分类结果1
        "input2": classified_data.get("output2_2", ""),  # 分类结果2
        "input3": classified_data.get("output3_3", "")  # 分类结果3
    }

    print("传递给工作流的参数:", input_parameters)

    # 调用工作流
    stream = coze.workflows.runs.stream(
        workflow_id=WORKFLOW_ID,
        parameters=input_parameters
    )

    # 处理工作流返回结果
    return handle_workflow_iterator(stream, classified_data)


@app.route('/api/aigenerate', methods=['POST'])
def receive_and_process():
    try:
        # 接收前端请求数据
        data = request.get_json()
        if not data or 'content' not in data:
            return jsonify({
                'code': 400,
                'message': '缺少content字段'
            }), 400

        input_content = data['content']
        print(f"前端传入的数据: {input_content}")

        # 调用分类工具处理前端输入
        classify_result = WorkflowOutputClassifier.classify(input_content)

        if not classify_result["success"]:
            return jsonify({
                'code': 500,
                'message': f'分类失败: {classify_result["error"]}'
            }), 500

        classified_data = classify_result["data"]
        print("分类后的数据:", classified_data)

        # 调用工作流处理
        workflow_result = process_with_workflow(input_content, classified_data)

        if workflow_result["success"]:
            return jsonify({
                'code': 200,
                'message': '工作流处理完成',
                'data': {
                    'input_used': input_content,
                    'classified_used': classified_data
                }
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
    app.run(host='0.0.0.0', port=5001, debug=True)
