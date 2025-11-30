from flask import Flask, jsonify
from flask_cors import CORS
import json
import mysql.connector
from mysql.connector import Error

# 初始化Flask应用
app = Flask(__name__)
CORS(app, resources=r"/*")  # 解决跨域问题

# 数据库配置（根据实际环境修改）
db_config = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "123456",
    "database": "pdf_db"
}


def create_table():
    """初始化数据库表（存储链接相关记录）"""
    connection = None
    try:
        # 连接数据库（需提前创建pdf_db数据库）
        connection = mysql.connector.connect(**db_config)
        if connection.is_connected():
            cursor = connection.cursor()
            # 创建存储链接的表（保留原有结构，确保兼容性）
            create_table_sql = """
            CREATE TABLE IF NOT EXISTS coze_pdf (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_input TEXT NOT NULL,  # 可存储前端原始输入
                coze_response TEXT,       # 存储包含链接的内容（格式：{"output":"链接"}）
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP  # 记录时间（用于排序取最新）
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


def get_latest_url_from_db():
    """从数据库查询最新的一条链接（按时间倒序取第一条）"""
    connection = None
    try:
        connection = mysql.connector.connect(** db_config)
        if connection.is_connected():
            cursor = connection.cursor(dictionary=True)  # 返回字典格式，方便解析
            # 查询最新的一条包含有效链接的记录
            query_sql = """
            SELECT coze_response 
            FROM coze_pdf 
            WHERE coze_response LIKE '%%"output":"https://%%'  # 匹配包含https链接的记录
            ORDER BY created_at DESC  # 按时间倒序（最新的在前）
            LIMIT 1  # 只取第一条（最新的）
            """
            cursor.execute(query_sql)
            result = cursor.fetchone()

            if not result:
                return {"success": False, "error": "未找到任何链接记录"}

            # 解析记录中的链接（假设格式为{"output":"链接"}）
            coze_response = result['coze_response']
            try:
                response_json = json.loads(coze_response)
                url = response_json.get('output')
                if not url or not url.startswith('https://'):
                    return {"success": False, "error": "记录中未包含有效的https链接"}
                return {"success": True, "data": url}
            except json.JSONDecodeError:
                return {"success": False, "error": "记录格式错误，无法解析链接"}
    except Error as e:
        return {"success": False, "error": f"数据库查询失败: {str(e)}"}
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


@app.route('/api/get_latest_url', methods=['GET'])
def get_latest_url():
    """接口：返回数据库中最新的一条链接"""
    db_result = get_latest_url_from_db()
    if db_result["success"]:
        return jsonify({
            'code': 200,
            'message': '查询成功',
            'data': db_result["data"]  # 返回最新链接
        }), 200
    else:
        # 根据错误类型返回对应状态码
        status_code = 404 if "未找到" in db_result["error"] else 500
        return jsonify({
            'code': status_code,
            'message': db_result["error"],
            'data': None
        }), status_code


if __name__ == '__main__':
    # 启动时初始化数据库表
    create_table()
    # 启动Flask服务
    print(f"服务已启动，监听地址: http://0.0.0.0:5001")
    print(f"最新链接查询接口: GET http://0.0.0.0:5001/api/get_latest_url")
    app.run(host='0.0.0.0', port=5001, debug=True)