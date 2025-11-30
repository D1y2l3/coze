from flask import Flask, jsonify, request
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
    """获取选择题数据（支持返回最新10条）"""
    try:
        latest = request.args.get('latest', type=bool, default=False)

        # 构建基础查询语句
        base_sql = """
            SELECT 
                id, 
                试卷名称 AS choicePaperName,
                试卷编号 AS choicePaperId,
                选择题问题 AS choiceQuestion,
                选择题选项 AS optionsStr,
                选择题答案 AS choiceAnswer,
                选择题解析 AS choiceExplanation
            FROM exam_choose
        """

        # 根据latest参数拼接完整SQL
        if latest:
            # 用id排序（假设id自增，越大越新），取最新10条
            sql = f"{base_sql} ORDER BY id DESC LIMIT 10"
        else:
            sql = base_sql

        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute(sql)  # 只执行一次正确的SQL
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


# -------------------------- 填空题相关功能 --------------------------
@app.route('/api/fills', methods=['GET'])
def get_fills():
    """获取填空题数据（支持返回最新10条）"""
    try:
        latest = request.args.get('latest', type=bool, default=False)

        base_sql = """
            SELECT 
                id, 
                试卷名称 AS fillPaperName,
                试卷编号 AS fillPaperId,
                填空题问题 AS fillQuestion,
                填空题答案 AS fillAnswer,
                填空题解析 AS fillExplanation
            FROM exam_blank
        """

        if latest:
            sql = f"{base_sql} ORDER BY id DESC LIMIT 10"
        else:
            sql = base_sql

        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute(sql)
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


# -------------------------- 判断题相关功能 --------------------------
@app.route('/api/judges', methods=['GET'])
def get_judges():
    """获取判断题数据（支持返回最新10条）"""
    try:
        latest = request.args.get('latest', type=bool, default=False)

        base_sql = """
            SELECT 
                id, 
                试卷名称 AS judgePaperName,
                试卷编号 AS judgePaperId,
                判断题问题 AS judgeQuestion,
                判断题答案 AS judgeAnswer,
                判断题解析 AS judgeExplanation
            FROM exam_judgment
        """

        if latest:
            sql = f"{base_sql} ORDER BY id DESC LIMIT 10"
        else:
            sql = base_sql

        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute(sql)
                judges = cursor.fetchall()

        formatted_judges = []
        for item in judges:
            answer = item.get("judgeAnswer", "").lower() == 'true'
            formatted_judges.append({
                "id": item["id"],
                "judgePaperName": item.get("judgePaperName", ""),
                "judgePaperId": item.get("judgePaperId", ""),
                "judgeQuestion": item.get("judgeQuestion", "无题目"),
                "judgeAnswer": answer,
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


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)