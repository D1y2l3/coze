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
CORS(app, resources=r'/*')  # 允许所有跨域请求

# 数据库连接配置（请根据实际环境修改用户名、密码）
DB_CONFIG = {
    "host": "localhost",
    "user": "root",  # 数据库用户名
    "password": "123456",  # 数据库密码
    "database": "exam_db5",  # 数据库名
    "port": 3306,
    "charset": "utf8mb4"
}


@app.route('/api/student/papers', methods=['GET'])
def get_student_papers():
    """查询所有发布的试卷名称"""
    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()
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
        logging.error(f"试卷名称查询失败：{str(e)}", exc_info=True)
        return jsonify({
            "paperNames": None,
            "message": "查询数据失败",
            "status": 500
        }), 500


@app.route('/api/student/paper/questions', methods=['GET'])
def get_paper_questions():
    """查询试卷题目及解析，并打印到控制台（联合“试卷名称+试卷编号”精准匹配）"""
    paper_name = request.args.get('paper_name')
    if not paper_name:
        return jsonify({"message": "缺少试卷名称参数", "status": 400}), 400

    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # 步骤1：查询试卷对应的题型ID（选择题、判断题、填空题的唯一编号）
        homework_sql = """
            SELECT choice_paper_id, judge_paper_id, blank_paper_id 
            FROM homework 
            WHERE paper_name = %s
        """
        cursor.execute(homework_sql, (paper_name,))
        result = cursor.fetchone()
        if not result:
            conn.close()
            return jsonify({"message": "未找到该试卷的题型信息", "status": 404}), 404
        choice_id, judge_id, blank_id = result  # 解构三个题型的唯一编号

        # 调试输出：打印当前试卷的名称和题型编号（验证关联正确性）
        print(f"\n===== 调试信息：当前试卷[{paper_name}]的题型编号 =====")
        print(f"选择题编号：{choice_id}")
        print(f"判断题编号：{judge_id}")
        print(f"填空题编号：{blank_id}\n")

        # --------------------------
        # 1. 选择题（含解析）- 联合条件：试卷名称 + 试卷编号
        # --------------------------
        choose_sql = """
            SELECT `选择题问题`, `选择题选项`, `选择题答案`, `选择题解析` 
            FROM ti_choose 
            WHERE `试卷编号` = %s AND `试卷名称` = %s  
        """
        cursor.execute(choose_sql, (choice_id, paper_name))
        choose_questions = cursor.fetchall()
        print("\n===== 选择题列表（含解析）======")
        if not choose_questions:
            print("该试卷暂无选择题\n")
        else:
            for idx, (question, options, answer, analysis) in enumerate(choose_questions, 1):
                print(f"第{idx}题：{question}")
                print(f"选项：{options}")
                print(f"答案：{answer}")
                print(f"解析：{analysis}\n")

        # --------------------------
        # 2. 判断题（含解析）- 联合条件：试卷名称 + 试卷编号
        # --------------------------
        judge_sql = """
            SELECT `判断题问题`, `判断题答案`, `判断题解析` 
            FROM ti_judgment 
            WHERE `试卷编号` = %s AND `试卷名称` = %s  
        """
        cursor.execute(judge_sql, (judge_id, paper_name))
        judge_questions = cursor.fetchall()
        print("===== 判断题列表（含解析）======")
        if not judge_questions:
            print("该试卷暂无判断题\n")
        else:
            for idx, (question, answer, analysis) in enumerate(judge_questions, 1):
                print(f"第{idx}题：{question}")
                print(f"答案：{answer}（正确/错误）")
                print(f"解析：{analysis}\n")

        # --------------------------
        # 3. 填空题（含解析）- 联合条件：试卷名称 + 试卷编号
        # --------------------------
        blank_sql = """
            SELECT `填空题问题`, `填空题答案`, `填空题解析` 
            FROM ti_blank 
            WHERE `试卷编号` = %s AND `试卷名称` = %s  
        """
        cursor.execute(blank_sql, (blank_id, paper_name))  # 传入试卷编号和名称双条件
        blank_questions = cursor.fetchall()
        print("===== 填空题列表（含解析）======")
        if not blank_questions:
            print(f"警告：未找到试卷[{paper_name}]的填空题，请检查关联是否正确\n")
        else:
            for idx, (question, answer, analysis) in enumerate(blank_questions, 1):
                print(f"第{idx}题：{question}（请填写横线处内容）")
                print(f"答案：{answer}")
                print(f"解析：{analysis}\n")

        conn.close()
        return jsonify({"message": "题目及解析查询成功", "status": 200}), 200

    except Exception as e:
        logging.error(f"题目查询失败：{str(e)}", exc_info=True)
        return jsonify({"message": "查询题目失败", "status": 500}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)