from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType
# 导入数据库处理模块
from exam_db_choose import create_connection, insert_exam, create_table as create_choose_table
from exam_db_blanks import insert_blank, create_table as create_blank_table
from exam_db_judgment import insert_judgment, create_table as create_judgment_table
from exam_processor_choose import process_exam_data
from exam_processor_blanks import process_blank_data
from exam_processor_judgment import process_judgment_data

app = Flask(__name__)
CORS(app, resources=r"/*")  # 解决跨域问题

# Coze 配置
COZE_API_TOKEN = 'pat_ObtKbqWHYEimyO5jeQqxEfigFjAl8wXoqezh0FDtPOYDKjARpP9QKTqvXafTSJIN'
WORKFLOW_ID = '7526153262711554084'
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)


def save_to_database(content):
    """将解析后的试题数据存入数据库"""
    try:
        # 解析Coze返回的JSON数据
        coze_result = json.loads(content)

        # 1. 处理选择题数据 (output1)
        choose_data = coze_result.get('output1', '[]')
        processed_choose = process_exam_data(choose_data)

        # 2. 处理填空题数据 (output2)
        blank_data = coze_result.get('output2', '[]')
        processed_blank = process_blank_data(blank_data)

        # 3. 处理判断题数据 (output3)
        judgment_data = coze_result.get('output3', '[]')
        processed_judgment = process_judgment_data(judgment_data)

        # 建立数据库连接
        conn = create_connection()
        if not conn:
            return False, "数据库连接失败"

        # 创建对应的数据表（如果不存在）
        create_choose_table(conn)
        create_blank_table(conn)
        create_judgment_table(conn)

        # 插入选择题数据
        for item in processed_choose:
            insert_exam(conn, item)

        # 插入填空题数据
        for item in processed_blank:
            insert_blank(conn, item)

        # 插入判断题数据
        for item in processed_judgment:
            insert_judgment(conn, item)

        # 关闭连接
        conn.close()
        return True, "数据成功存入数据库"

    except json.JSONDecodeError as e:
        return False, f"JSON解析错误: {str(e)}"
    except Exception as e:
        return False, f"数据库操作失败: {str(e)}"


def handle_workflow_stream(stream: Stream[WorkflowEvent]):
    """处理Coze工作流的流式返回结果"""
    result = []
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            if event.message and event.message.content:
                result.append(event.message.content)
        elif event.event == WorkflowEventType.ERROR:
            return {"success": False, "error": f"工作流错误: {event.error}"}
        elif event.event == WorkflowEventType.INTERRUPT:
            return {"success": False, "error": "工作流需要补充信息，请优化输入"}

    # 合并结果并尝试存入数据库
    content = "".join(result)
    db_success, db_msg = save_to_database(content)

    if not db_success:
        print(f"数据库存储警告: {db_msg}")  # 不阻断主流程，仅警告

    return {"success": True, "data": content, "db_message": db_msg}


@app.route('/api/aigenerate', methods=['POST'])
def receive_and_process():
    try:
        data = request.get_json()
        if not data or 'content' not in data:
            return jsonify({
                'code': 400,
                'message': '缺少content字段',
                'data': None
            }), 400

        input = data['content']
        print(f"前端传入的数据: {input}")

        input_parameters = {"input": input}

        stream = coze.workflows.runs.stream(
            workflow_id=WORKFLOW_ID,
            parameters=input_parameters
        )
        workflow_result = handle_workflow_stream(stream)

        if workflow_result["success"]:
            return jsonify({
                'code': 200,
                'message': '处理成功',
                'data': workflow_result["data"],
                'db_status': workflow_result["db_message"]
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
    app.run(host='0.0.0.0', port=5001, debug=True)