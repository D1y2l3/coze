from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import mysql.connector
from mysql.connector import Error
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

# 初始化Flask应用
app = Flask(__name__)
CORS(app, resources=r"/*")  # 解决跨域问题

# Coze配置（替换为你的实际API Token和工作流ID）
COZE_API_TOKEN = 'pat_ObtKbqWHYEimyO5jeQqxEfigFjAl8wXoqezh0FDtPOYDKjARpP9QKTqvXafTSJIN'
WORKFLOW_ID = '7553477857655291955'
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)

# 数据库配置
db_config = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "123456",
    "database": "pdf_db"
}


def create_table():
    """初始化数据库表（存储前端输入和Coze响应）"""
    connection = None
    try:
        # 连接数据库（如果数据库不存在，需先手动创建pdf_db）
        connection = mysql.connector.connect(
            host=db_config["host"],
            port=db_config["port"],
            user=db_config["user"],
            password=db_config["password"],
            database=db_config["database"]
        )
        if connection.is_connected():
            cursor = connection.cursor()
            # 创建存储交互记录的表（表名改为coze_pdf）
            create_table_sql = """
            CREATE TABLE IF NOT EXISTS coze_pdf (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_input TEXT NOT NULL,  # 前端传入的数据
                coze_response TEXT,       # Coze返回的数据（或错误信息）
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP  # 记录创建时间
            )
            """
            cursor.execute(create_table_sql)
            connection.commit()
            print("数据库表 'coze_pdf' 创建成功（或已存在）")
    except Error as e:
        print(f"创建数据库表失败: {str(e)}")
    finally:
        # 关闭连接
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


def save_to_database(user_input, coze_response):
    """将前端输入和Coze响应保存到数据库（表名改为coze_pdf）"""
    connection = None
    try:
        connection = mysql.connector.connect(**db_config)
        if connection.is_connected():
            cursor = connection.cursor()
            # 插入数据的SQL（表名改为coze_pdf）
            insert_sql = """
            INSERT INTO coze_pdf (user_input, coze_response)
            VALUES (%s, %s)
            """
            # 执行插入（参数化查询防止SQL注入）
            cursor.execute(insert_sql, (user_input, coze_response))
            connection.commit()
            print(f"数据已保存到数据库表coze_pdf，记录ID: {cursor.lastrowid}")
            return True
    except Error as e:
        print(f"保存数据到数据库表coze_pdf失败: {str(e)}")
        return False


def handle_workflow_stream(stream: Stream[WorkflowEvent]):
    """处理Coze工作流的流式返回结果"""
    result = []
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            if event.message and event.message.content:
                result.append(event.message.content)
        elif event.event == WorkflowEventType.ERROR:
            error_msg = f"工作流错误: {event.error}"
            print(f"[错误] {error_msg}")
            return {"success": False, "error": error_msg}
        elif event.event == WorkflowEventType.INTERRUPT:
            print(f"[中断] 工作流需要交互，尝试恢复...")
            resume_result = handle_workflow_stream(
                coze.workflows.runs.resume(
                    workflow_id=WORKFLOW_ID,
                    event_id=event.interrupt.interrupt_data.event_id,
                    resume_data="请继续完成内容生成",
                    interrupt_type=event.interrupt.interrupt_data.type,
                )
            )
            if not resume_result["success"]:
                return resume_result
            result.append(resume_result["data"])

    content = "".join(result)
    return {"success": True, "data": content}


@app.route('/api/sheji', methods=['POST'])
def receive_and_process():
    """接收前端数据→调用Coze→保存数据到数据库→返回结果"""
    try:
        # 解析前端请求
        data = request.get_json()
        if not data or 'content' not in data:
            err_msg = "缺少content字段"
            print(f"[请求错误] {err_msg}")
            return jsonify({'code': 400, 'message': err_msg, 'data': None}), 400

        # 提取前端传入的数据
        user_input = data['content']
        print(f"\n===== 收到前端请求 =====")
        print(f"前端传入的数据: {user_input}")

        # 调用Coze工作流
        print(f"正在调用Coze工作流（ID: {WORKFLOW_ID}）...")
        stream = coze.workflows.runs.stream(
            workflow_id=WORKFLOW_ID,
            parameters={"input": user_input}
        )
        workflow_result = handle_workflow_stream(stream)

        # 打印工作流处理结果
        print(f"\n===== 工作流处理完成 =====")
        if workflow_result["success"]:
            coze_response = workflow_result["data"]
            print(f"处理结果: 成功\n返回给前端的数据: \n{coze_response}")
        else:
            coze_response = workflow_result["error"]
            print(f"处理结果: 失败\n错误信息: {coze_response}")

        # 保存数据到数据库（无论成功/失败都保存）
        save_to_database(user_input, coze_response)

        # 返回结果给前端
        if workflow_result["success"]:
            return jsonify({
                'code': 200,
                'message': '处理成功',
                'data': coze_response
            }), 200
        else:
            return jsonify({
                'code': 500,
                'message': coze_response,
                'data': None
            }), 500

    except json.JSONDecodeError:
        err_msg = "无效的JSON格式"
        print(f"[解析错误] {err_msg}")
        return jsonify({'code': 400, 'message': err_msg, 'data': None}), 400
    except Exception as e:
        err_msg = f"服务器错误: {str(e)}"
        print(f"[服务器错误] {err_msg}")
        return jsonify({'code': 500, 'message': err_msg, 'data': None}), 500


if __name__ == '__main__':
    # 启动时初始化数据库表
    create_table()
    # 启动Flask服务
    print(f"Flask服务已启动，监听地址: http://0.0.0.0:5001")
    print(f"接口地址: POST http://0.0.0.0:5001/api/sheji")
    app.run(host='0.0.0.0', port=5001, debug=True)