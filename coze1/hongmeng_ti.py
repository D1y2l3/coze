from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import pymysql
from pymysql.cursors import DictCursor

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

DB_CONFIG = {
    "host": "localhost",
    "user": "root",  # 替换为真实用户名
    "password": "123456",  # 替换为真实密码
    "database": "exam_db5",    # 数据库名保持不变
    "port": 3306,
    "charset": "utf8mb4"
}

def get_db_connection():
    try:
        conn = pymysql.connect(
            **DB_CONFIG,
            cursorclass=DictCursor
        )
        logging.info("数据库连接成功")
        return conn
    except Exception as e:
        logging.error(f"数据库连接失败：{str(e)}")
        return None

@app.route('/api/question', methods=['POST'])
def query_papers():
    try:
        data = request.get_json()
        if not data or "phoneNumber" not in data:
            logging.warning("请求参数缺失")
            return jsonify({
                "paperNames": None,
                "message": "请提供手机号"
            }), 400

        phone_number = data["phoneNumber"].strip()
        if not phone_number:
            logging.warning("手机号为空")
            return jsonify({
                "paperNames": None,
                "message": "手机号不能为空"
            }), 400

        logging.info(f"收到查询请求，手机号：{phone_number}")

        conn = get_db_connection()
        if not conn:
            return jsonify({
                "paperNames": None,
                "message": "数据库连接失败"
            }), 500

        cursor = conn.cursor()
        try:
            # 最终SQL：按试卷名称分组，取每组最新的创建时间排序
            query_sql = """
                SELECT 试卷名称 
                FROM ti_choose 
                WHERE phone_number = %s 
                GROUP BY 试卷名称 
                ORDER BY MAX(create_time) DESC
            """
            cursor.execute(query_sql, (phone_number,))
            results = cursor.fetchall()

            paper_names = [item["试卷名称"] for item in results] if results else []
            logging.info(f"查询完成，找到{len(paper_names)}份试卷")

            if paper_names:
                return jsonify({
                    "paperNames": paper_names,
                    "message": f"查询成功，共{len(paper_names)}份试卷"
                }), 200
            else:
                return jsonify({
                    "paperNames": [],
                    "message": "未查询到该手机号对应的试卷"
                }), 200

        except Exception as e:
            logging.error(f"数据库查询失败：{str(e)}", exc_info=True)
            return jsonify({
                "paperNames": None,
                "message": "查询数据失败"
            }), 500

        finally:
            cursor.close()
            conn.close()
            logging.info("数据库连接已关闭")

    except Exception as e:
        logging.error(f"请求处理异常：{str(e)}", exc_info=True)
        return jsonify({
            "paperNames": None,
            "message": "请求处理失败"
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)