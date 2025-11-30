from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType
# 导入数据库处理模块（包含新增的 Ti_choose 操作）
from exam_db_choose import (
    create_connection, insert_exam, create_table as create_choose_table,
    create_ti_choose_table, insert_ti_choose  # 新增 Ti_choose 相关函数
)
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


def save_to_database(content, phone_number):
    """将解析后的试题数据存入数据库，同步最新10道选择题到 Ti_choose 表"""
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
        create_ti_choose_table(conn)  # 创建 Ti_choose 表

        # 插入选择题数据到原表
        for item in processed_choose:
            insert_exam(conn, item)

        # 插入填空题数据
        for item in processed_blank:
            insert_blank(conn, item)

        # 插入判断题数据
        for item in processed_judgment:
            insert_judgment(conn, item)

        # 关键：查询原选择题表中最新的10条数据，同步到 Ti_choose 表
        cursor = conn.cursor()
        # 假设原选择题表名为 exam_choose，按主键 id 倒序取前10（若有 create_time 字段，可替换为 ORDER BY create_time DESC）
        cursor.execute("SELECT question, optionA, optionB, optionC, optionD, answer, explanation FROM exam_choose ORDER BY id DESC LIMIT 10")
        latest_10_chooses = cursor.fetchall()

        # 将最新10条数据插入 Ti_choose 表（关联手机号）
        for choose in latest_10_chooses:
            ti_choose_item = (
                phone_number,  # 关联当前用户手机号
                choose[0],  # question
                choose[1],  # optionA
                choose[2],  # optionB
                choose[3],  # optionC
                choose[4],  # optionD
                choose[5],  # answer
                choose[6]   # explanation
            )
            insert_ti_choose(conn, ti_choose_item)

        # 提交事务并关闭连接
        conn.commit()
        conn.close()
        return True, "数据成功存入数据库，最新10道选择题已同步到 Ti_choose 表"

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

    # 合并结果并尝试存入数据库（此处暂不传递手机号，在主接口中处理）
    content = "".join(result)
    return {"success": True, "data": content}


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

        # 获取前端传入的手机号，做非空校验
        phone_number = data.get('phoneNumber', '')
        if not phone_number.strip():
            return jsonify({
                'code': 400,
                'message': '缺少phoneNumber字段或手机号为空',
                'data': None
            }), 400

        input_content = data['content']
        # 打印手机号和传入内容到控制台
        print(f"前端传入的手机号: {phone_number}")
        print(f"前端传入的生成需求: {input_content}")

        input_parameters = {"input": input_content}

        stream = coze.workflows.runs.stream(
            workflow_id=WORKFLOW_ID,
            parameters=input_parameters
        )
        workflow_result = handle_workflow_stream(stream)

        if workflow_result["success"]:
            # 调用存储函数，传入内容和手机号
            db_success, db_msg = save_to_database(workflow_result["data"], phone_number)
            return jsonify({
                'code': 200,
                'message': '处理成功',
                'data': workflow_result["data"],
                'db_status': db_msg
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