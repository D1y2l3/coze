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

        formatted_fills = []
        for item in fills:
            formatted_fills.append({
                "id": item["id"],
                "fillPaperName": item.get("fillPaperName", ""),
                "fillPaperId": item.get("fillPaperId", ""),
                "fillQuestion": item.get("fillQuestion", "无题目"),
                "fillAnswer": item.get("fillAnswer", ""),
                "fillExplanation": item.get("fillExplanation", "无解析")
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


# -------------------------- 判断题相关功能 --------------------------
@app.route('/api/judges', methods=['GET'])
def get_judges():
    """获取所有判断题数据"""
    try:
        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                # 假设判断题表名为exam_judge，字段包括：
                # id、试卷名称、试卷编号、判断题问题、判断题答案、判断题解析
                cursor.execute("""
                    SELECT 
                        id, 
                        试卷名称 AS judgePaperName,
                        试卷编号 AS judgePaperId,
                        判断题问题 AS judgeQuestion,
                        判断题答案 AS judgeAnswer,
                        判断题解析 AS judgeExplanation
                    FROM exam_judgment
                """)
                judges = cursor.fetchall()

        formatted_judges = []
        for item in judges:
            # 转换答案为布尔值（假设数据库存储为'True'/'False'字符串）
            answer = item.get("judgeAnswer", "").lower() == 'true'

            formatted_judges.append({
                "id": item["id"],
                "judgePaperName": item.get("judgePaperName", ""),
                "judgePaperId": item.get("judgePaperId", ""),
                "judgeQuestion": item.get("judgeQuestion", "无题目"),
                "judgeAnswer": answer,  # 布尔值：True=正确，False=错误
                "judgeExplanation": item.get("judgeExplanation", "无解析")
            })

        return jsonify({
            "code": 200,
            "message": "success",
            "data": formatted_judges
        })

    except mysql.connector.Error as e:
        return jsonify({"code": 500, "error": f"数据库错误: {str(e)}"})
    except Exception as e:
        return jsonify({"code": 500, "error": f"服务器错误: {str(e)}"})


@app.route('/api/judges/<int:question_id>', methods=['GET'])
def get_judge(question_id):
    """根据ID获取单个判断题"""
    try:
        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute("""
                    SELECT 
                        id, 
                        试卷名称 AS judgePaperName,
                        试卷编号 AS judgePaperId,
                        判断题问题 AS judgeQuestion,
                        判断题答案 AS judgeAnswer,
                        判断题解析 AS judgeExplanation
                    FROM exam_judgment
                    WHERE id = %s
                """, (question_id,))
                judge = cursor.fetchone()

        if not judge:
            return jsonify({"code": 404, "message": f"未找到ID为{question_id}的判断题"})

        # 转换答案为布尔值
        answer = judge.get("judgeAnswer", "").lower() == 'true'

        formatted_judge = {
            "id": judge["id"],
            "judgePaperName": judge.get("judgePaperName", ""),
            "judgePaperId": judge.get("judgePaperId", ""),
            "judgeQuestion": judge.get("judgeQuestion", "无题目"),
            "judgeAnswer": answer,  # 布尔值：True=正确，False=错误
            "judgeExplanation": judge.get("judgeExplanation", "无解析")
        }

        return jsonify({"code": 200, "message": "success", "data": formatted_judge})

    except Exception as e:
        return jsonify({"code": 500, "error": str(e)})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
