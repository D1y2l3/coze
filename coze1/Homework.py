import pymysql
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources=r'/*')  # 允许所有跨域请求

# 数据库连接配置（再次确认正确）
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "123456",
    "database": "exam_db5",
    "port": 3306,
    "charset": "utf8mb4"
}


# 测试数据库连接并建表（添加详细日志）
def test_db_connection_and_create_table():
    conn = None
    try:
        # 1. 测试数据库连接
        conn = pymysql.connect(**DB_CONFIG)
        print(" 数据库连接成功！当前数据库：", DB_CONFIG["database"])

        # 2. 执行建表（即使手动建过，再执行一次也不影响）
        cursor = conn.cursor()
        create_sql = """
        CREATE TABLE IF NOT EXISTS homework (
            id INT AUTO_INCREMENT PRIMARY KEY,
            class_name VARCHAR(255) NOT NULL,
            paper_name VARCHAR(255) NOT NULL,
            choice_paper_id VARCHAR(50) NOT NULL,
            judge_paper_id VARCHAR(50) NOT NULL,
            blank_paper_id VARCHAR(50) NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        """
        cursor.execute(create_sql)
        conn.commit()
        print(" 建表语句执行成功（表已存在或新建）")

        # 3. 验证表是否存在
        cursor.execute("SHOW TABLES LIKE 'homework';")
        table_exists = cursor.fetchone()
        if table_exists:
            print("homework 表存在！")
        else:
            print(" 警告：执行建表后，表仍不存在！")

    except Exception as e:
        print(" 数据库操作失败：", str(e))
        print("失败原因可能：1. 数据库配置错误 2. 无建表权限 3. 数据库不存在")
    finally:
        if conn:
            conn.close()


# 启动时立即执行连接测试和建表
test_db_connection_and_create_table()


@app.route('/publish/homework', methods=['POST'])
def publish_homework():
    print("\n===== 收到发布请求 =====")
    data = request.get_json()
    print("收到参数：", data)

    if not data:
        print(" 未接收到参数")
        return jsonify({"status": "error", "message": "未接收到参数"}), 400

    # 提取参数并验证
    class_name = data.get('className')
    paper_name = data.get('paperName')
    choice_id = data.get('choicePaperId')
    judge_id = data.get('judgePaperId')
    blank_id = data.get('blankPaperId')

    if not all([class_name, paper_name, choice_id, judge_id, blank_id]):
        print("参数不能为空：", {class_name, paper_name, choice_id, judge_id, blank_id})
        return jsonify({"status": "error", "message": "参数不能为空"}), 400

    conn = None
    try:
        # 连接数据库并插入数据
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # 先再次验证表是否存在（终极验证）
        cursor.execute("SHOW TABLES LIKE 'homework';")
        if not cursor.fetchone():
            print(" 严重错误：数据库中无 homework 表！")
            return jsonify({"status": "error", "message": "数据库表不存在"}), 500

        # 执行插入
        insert_sql = """
        INSERT INTO homework (class_name, paper_name, choice_paper_id, judge_paper_id, blank_paper_id)
        VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(insert_sql, (class_name, paper_name, choice_id, judge_id, blank_id))
        conn.commit()
        print(f" 数据插入成功！ID：{cursor.lastrowid}")
        return jsonify({"status": "success", "message": "作业发布成功，数据已存储"}), 200

    except Exception as e:
        if conn:
            conn.rollback()
        print(" 插入数据失败：", str(e))
        return jsonify({"status": "error", "message": f"数据库操作失败: {str(e)}"}), 500

    finally:
        if conn:
            conn.close()


if __name__ == '__main__':
    print("===== 后端服务启动 =====")
    app.run(host='0.0.0.0', port=5000, debug=True)