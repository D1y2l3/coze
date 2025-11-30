from flask import Flask, jsonify
import mysql.connector
import re
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # 允许跨域访问

# 数据库配置
db_config = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "123456",
    "database": "exam_db5"
}


# -------------------------- 选择题相关功能 --------------------------
def parse_options(option_str: str) -> dict:
    """解析选择题选项字符串为字典格式"""
    if not option_str:
        return {"A": "", "B": "", "C": "", "D": ""}

    pattern = r'([A-D])\.([^A-D]+)'
    matches = re.findall(pattern, option_str)

    options = {"A": "", "B": "", "C": "", "D": ""}
    for key, value in matches:
        options[key] = value.strip().replace("'", "").replace('"', '')

    return options


@app.route('/api/choices', methods=['GET'])
def get_choices():
    """获取所有选择题数据"""
    try:
        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute("""
                    SELECT 
                        id, 
                        试卷名称 AS choicePaperName,
                        试卷编号 AS choicePaperId,
                        选择题问题 AS choiceQuestion,
                        选择题选项 AS optionsStr,
                        选择题答案 AS choiceAnswer,
                        选择题解析 AS choiceExplanation
                    FROM exam_choose
                """)
                choices = cursor.fetchall()

        formatted_choices = []
        for item in choices:
            formatted_choices.append({
                "id": item["id"],
                "choicePaperName": item.get("choicePaperName", ""),
                "choicePaperId": item.get("choicePaperId", ""),
                "choiceQuestion": item.get("choiceQuestion", "无题目"),
                "choiceOptions": parse_options(item.get("optionsStr", "")),
                "choiceAnswer": item.get("choiceAnswer", ""),
                "choiceExplanation": item.get("choiceExplanation", "无解析")
            })

        return jsonify({
            "code": 200,
            "message": "success",
            "data": formatted_choices
        })

    except mysql.connector.Error as e:
        return jsonify({"code": 500, "error": f"数据库错误: {str(e)}"})
    except Exception as e:
        return jsonify({"code": 500, "error": f"服务器错误: {str(e)}"})


@app.route('/api/choices/<int:question_id>', methods=['GET'])
def get_choice(question_id):
    """根据ID获取单个选择题"""
    try:
        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute("""
                    SELECT 
                        id, 
                        试卷名称 AS choicePaperName,
                        试卷编号 AS choicePaperId,
                        选择题问题 AS choiceQuestion,
                        选择题选项 AS optionsStr,
                        选择题答案 AS choiceAnswer,
                        选择题解析 AS choiceExplanation
                    FROM exam_choose 
                    WHERE id = %s
                """, (question_id,))
                choice = cursor.fetchone()

        if not choice:
            return jsonify({"code": 404, "message": f"未找到ID为{question_id}的选择题"})

        formatted_choice = {
            "id": choice["id"],
            "choicePaperName": choice.get("choicePaperName", ""),
            "choicePaperId": choice.get("choicePaperId", ""),
            "choiceQuestion": choice.get("choiceQuestion", "无题目"),
            "choiceOptions": parse_options(choice.get("optionsStr", "")),
            "choiceAnswer": choice.get("choiceAnswer", ""),
            "choiceExplanation": choice.get("choiceExplanation", "无解析")
        }

        return jsonify({"code": 200, "message": "success", "data": formatted_choice})

    except Exception as e:
        return jsonify({"code": 500, "error": str(e)})


# -------------------------- 填空题相关功能 --------------------------
@app.route('/api/fills', methods=['GET'])
def get_fills():
    """获取所有填空题数据"""
    try:
        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                # 假设填空题表名为exam_fill，字段包括：
                # id、试卷名称、试卷编号、填空题问题、填空题答案、填空题解析
                cursor.execute("""
                    SELECT 
                        id, 
                        试卷名称 AS fillPaperName,
                        试卷编号 AS fillPaperId,
                        填空题问题 AS fillQuestion,
                        填空题答案 AS fillAnswer,
                        填空题解析 AS fillExplanation
                    FROM exam_blank
                """)
                fills = cursor.fetchall()

        # 格式化填空题数据（无需解析选项，直接映射字段）
        formatted_fills = []
        for item in fills:
            formatted_fills.append({
                "id": item["id"],
                "fillPaperName": item.get("fillPaperName", ""),  # 试卷名称
                "fillPaperId": item.get("fillPaperId", ""),  # 试卷编号
                "fillQuestion": item.get("fillQuestion", "无题目"),  # 题干
                "fillAnswer": item.get("fillAnswer", ""),  # 答案
                "fillExplanation": item.get("fillExplanation", "无解析")  # 解析
            })

        return jsonify({
            "code": 200,
            "message": "success",
            "data": formatted_fills
        })

    except mysql.connector.Error as e:
        return jsonify({"code": 500, "error": f"数据库错误: {str(e)}"})
    except Exception as e:
        return jsonify({"code": 500, "error": f"服务器错误: {str(e)}"})


@app.route('/api/fills/<int:question_id>', methods=['GET'])
def get_fill(question_id):
    """根据ID获取单个填空题"""
    try:
        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute("""
                    SELECT 
                        id, 
                        试卷名称 AS fillPaperName,
                        试卷编号 AS fillPaperId,
                        填空题问题 AS fillQuestion,
                        填空题答案 AS fillAnswer,
                        填空题解析 AS fillExplanation
                    FROM exam_blank
                    WHERE id = %s
                """, (question_id,))
                fill = cursor.fetchone()

        if not fill:
            return jsonify({"code": 404, "message": f"未找到ID为{question_id}的填空题"})

        # 格式化单个填空题数据
        formatted_fill = {
            "id": fill["id"],
            "fillPaperName": fill.get("fillPaperName", ""),
            "fillPaperId": fill.get("fillPaperId", ""),
            "fillQuestion": fill.get("fillQuestion", "无题目"),
            "fillAnswer": fill.get("fillAnswer", ""),
            "fillExplanation": fill.get("fillExplanation", "无解析")
        }

        return jsonify({"code": 200, "message": "success", "data": formatted_fill})

    except Exception as e:
        return jsonify({"code": 500, "error": str(e)})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
