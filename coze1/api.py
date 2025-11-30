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


def parse_options(option_str: str) -> dict:
    """
    解析选择题选项字符串（如"A. 'r' B. 'w' C. 'a' D. 'x'"）
    转换为前端需要的选项格式：{A: "", B: "", C: "", D: ""}
    """
    if not option_str:
        return {"A": "", "B": "", "C": "", "D": ""}

    # 正则匹配选项（A.xxx B.xxx C.xxx D.xxx格式）
    pattern = r'([A-D])\.([^A-D]+)'  # 匹配A.、B.等标识及其后的内容
    matches = re.findall(pattern, option_str)

    # 初始化选项字典
    options = {"A": "", "B": "", "C": "", "D": ""}
    for key, value in matches:
        # 去除多余空格和特殊字符
        options[key] = value.strip().replace("'", "").replace('"', '')

    return options


@app.route('/api/choices', methods=['GET'])
def get_choices():
    """获取所有选择题数据（适配选择题选项字段）"""
    try:
        # 使用上下文管理器自动管理数据库连接
        with mysql.connector.connect(**db_config) as conn:
            with conn.cursor(dictionary=True) as cursor:
                # 查询表中所有字段（使用新的字段名）
                cursor.execute("""
                    SELECT 
                        id, 
                        试卷名称 AS choicePaperName,
                        试卷编号 AS choicePaperId,
                        选择题问题 AS choiceQuestion,
                        选择题选项 AS optionsStr,  # 选择题选项字段
                        选择题答案 AS choiceAnswer,
                        选择题解析 AS choiceExplanation
                    FROM exam_choose
                """)
                choices = cursor.fetchall()

        # 格式化数据（重点处理选项字段）
        formatted_choices = []
        for item in choices:
            formatted_choices.append({
                "id": item["id"],
                "choicePaperName": item.get("choicePaperName", ""),  # 处理可能的空值
                "choicePaperId": item.get("choicePaperId", ""),
                "choiceQuestion": item.get("choiceQuestion", "无题目"),
                "choiceOptions": parse_options(item.get("optionsStr", "")),  # 解析选项
                "choiceAnswer": item.get("choiceAnswer", ""),
                "choiceExplanation": item.get("choiceExplanation", "无解析")
            })

        return jsonify({
            "code": 200,
            "message": "success",
            "data": formatted_choices
        })

    except mysql.connector.Error as e:
        return jsonify({
            "code": 500,
            "error": f"数据库错误: {str(e)}"
        })
    except Exception as e:
        return jsonify({
            "code": 500,
            "error": f"服务器错误: {str(e)}"
        })


@app.route('/api/choices/<int:question_id>', methods=['GET'])
def get_choice(question_id):
    """根据ID获取单个选择题（适配新表结构）"""
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
            return jsonify({
                "code": 404,
                "message": f"未找到ID为{question_id}的选择题"
            })

        # 格式化单个选择题数据
        formatted_choice = {
            "id": choice["id"],
            "choicePaperName": choice.get("choicePaperName", ""),
            "choicePaperId": choice.get("choicePaperId", ""),
            "choiceQuestion": choice.get("choiceQuestion", "无题目"),
            "choiceOptions": parse_options(choice.get("optionsStr", "")),  # 解析选项
            "choiceAnswer": choice.get("choiceAnswer", ""),
            "choiceExplanation": choice.get("choiceExplanation", "无解析")
        }

        return jsonify({
            "code": 200,
            "message": "success",
            "data": formatted_choice
        })

    except Exception as e:
        return jsonify({
            "code": 500,
            "error": str(e)
        })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
