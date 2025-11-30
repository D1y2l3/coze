from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import pymysql

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)
# 允许所有跨域请求
CORS(app, resources=r'/*')

# 数据库连接配置
DB_CONFIG = {
    "host": "localhost",
    "user": "root",        # 替换为你的数据库用户名
    "password": "123456",  # 替换为你的数据库密码
    "database": "exam_db5",# 数据库名保持不变
    "port": 3306,
    "charset": "utf8mb4"
}

@app.route('/api/student/papers', methods=['GET'])
def get_student_papers():
    """学生端查询所有发布的试卷名称（从homework表读取）"""
    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()
        # 查询homework表中所有不重复的试卷名称
        query_sql = "SELECT DISTINCT paper_name FROM homework"
        cursor.execute(query_sql)
        results = cursor.fetchall()
        paper_names = [item[0] for item in results]
        conn.close()
        return jsonify({
            "paperNames": paper_names,
            "message": "查询成功",
            "status": 200
        }), 200
    except Exception as e:
        logging.error(f"学生试卷查询失败：{str(e)}", exc_info=True)
        return jsonify({
            "paperNames": None,
            "message": "查询数据失败",
            "status": 500
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)