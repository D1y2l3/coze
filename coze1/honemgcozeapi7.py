from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

app = Flask(__name__)
CORS(app, resources=r"/*")  # 解决跨域问题

# Coze 配置（建议将敏感信息放在环境变量中，此处为示例）
COZE_API_TOKEN = 'cztei_htpqzfVbgW3anKOvM9EJL3qV3oDG9v6RyJYPSYNJC1mvUtFxNIoKKH3LWGg2EpHnN'  # 替换为你的令牌
WORKFLOW_ID = '7526153262711554084'  # 替换为你的工作流ID
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)

# 全局变量存储填空题原始数据
RAW_BLANK_DATA = ""


def process_blank_data(raw_data):
    """
    处理原始JSON数据，提取填空题所需字段
    :param raw_data: 原始JSON字符串
    :return: 结构化的填空题数据列表
    """
    try:
        # 处理转义字符问题
        processed_data = raw_data.replace('\\\\', '\\')

        # 解析JSON数据
        blank_list = json.loads(processed_data)

        # 提取所需字段
        result = []
        for blank in blank_list:
            extracted = {
                "试卷名称": blank.get("试卷名称", ""),
                "试卷编号": blank.get("试卷编号", ""),
                "填空题问题": blank.get("填空题问题", ""),
                "填空题答案": blank.get("填空题答案", ""),
                "填空题解析": blank.get("填空题解析", "")
            }
            result.append(extracted)

        return result

    except json.JSONDecodeError as e:
        print(f"JSON解析错误: {e}")
        return []
    except Exception as e:
        print(f"数据处理错误: {e}")
        return []


def handle_workflow_stream(stream: Stream[WorkflowEvent]):
    """处理Coze工作流的流式返回结果，分类提取填空题数据"""
    global RAW_BLANK_DATA  # 声明使用全局变量
    result = []
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            print("got message", event.message)

            # 解析消息内容，提取填空题数据（output2）
            if event.message and event.message.content:
                try:
                    # 工作流返回的content是JSON字符串，先解析为字典
                    message_content = json.loads(event.message.content)
                    # 提取output2（填空题原始数据）并赋值给全局变量
                    RAW_BLANK_DATA = message_content.get("output2", "")
                    print("已提取填空题原始数据到RAW_BLANK_DATA")
                except json.JSONDecodeError as e:
                    print(f"解析消息内容失败: {e}")

                # 收集完整结果（原逻辑保留）
                result.append(event.message.content)

        elif event.event == WorkflowEventType.ERROR:
            print("got error", event.error)
            return {"success": False, "error": f"工作流错误: {event.error}"}

        elif event.event == WorkflowEventType.INTERRUPT:
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

        input = data['content']
        print(f"前端传入的数据: {input}")

        # 2. 调用Coze工作流
        input_parameters = {"input": input}
        stream = coze.workflows.runs.stream(
            workflow_id=WORKFLOW_ID,
            parameters=input_parameters
        )
        workflow_result = handle_workflow_stream(stream)

        # 3. 工作流处理完成后，可直接使用RAW_BLANK_DATA和process_blank_data
        if RAW_BLANK_DATA:
            processed_blanks = process_blank_data(RAW_BLANK_DATA)
            print("处理后的填空题数据:", processed_blanks)
        else:
            print("未提取到填空题数据")

        # 4. 返回结果给前端
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
    app.run(host='0.0.0.0', port=5000, debug=True)
