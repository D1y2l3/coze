from flask import Flask, jsonify, request
import mysql.connector
import re
from flask_cors import CORS
import logging

app = Flask(__name__)
CORS(app)  # 允许跨域访问

# 配置日志，方便调试
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# 数据库配置
db_config = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "123456",
    "database": "exam_db5"
}


# 通用函数：获取带分页的数据
def get_paginated_data(table_name, fields, latest_flag):
    """通用获取数据函数，支持返回最新10条"""
    base_sql = f"SELECT {', '.join(fields)} FROM {table_name}"

    # 根据latest_flag构建SQL
    if latest_flag:
        sql = f"{base_sql} ORDER BY id DESC LIMIT 10"
    else:
        sql = base_sql

    logger.debug(f"执行SQL: {sql}")  # 输出执行的SQL语句

    with mysql.connector.connect(**db_config) as conn:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(sql)
            result = cursor.fetchall()
            logger.debug(f"查询结果数量: {len(result)}")  # 输出返回的数据数量
            return result


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
        # 更健壮的参数解析：支持true/1/yes等多种真值形式
        # 修改为（默认返回最新10条）
        latest_param = request.args.get('latest', 'true').lower()  # 默认值设为'true'
        latest = latest_param in ('true', '1', 'yes', 'y')
        logger.debug(f"选择题 latest参数: {latest_param}, 解析结果: {latest}")

        # 定义查询字段
        fields = [
            "id",
            "试卷名称 AS choicePaperName",
            "试卷编号 AS choicePaperId",
            "选择题问题 AS choiceQuestion",
            "选择题选项 AS optionsStr",
            "选择题答案 AS choiceAnswer",
            "选择题解析 AS choiceExplanation"
        ]

        # 获取数据
        choices = get_paginated_data("exam_choose", fields, latest)

        # 格式化数据
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
            "data": formatted_choices,
            "count": len(formatted_choices),  # 增加返回数据数量
            "latest": latest  # 增加返回当前是否为最新数据标记
        })

    except mysql.connector.Error as e:
        logger.error(f"数据库错误: {str(e)}")
        return jsonify({"code": 500, "error": f"数据库错误: {str(e)}"})
    except Exception as e:
        logger.error(f"服务器错误: {str(e)}")
        return jsonify({"code": 500, "error": f"服务器错误: {str(e)}"})


# -------------------------- 填空题相关功能 --------------------------
@app.route('/api/fills', methods=['GET'])
def get_fills():
    """获取填空题数据（支持返回最新10条）"""
    try:
        # 修改为（默认返回最新10条）
        latest_param = request.args.get('latest', 'true').lower()  # 默认值设为'true'
        latest = latest_param in ('true', '1', 'yes', 'y')
        logger.debug(f"填空题 latest参数: {latest_param}, 解析结果: {latest}")

        fields = [
            "id",
            "试卷名称 AS fillPaperName",
            "试卷编号 AS fillPaperId",
            "填空题问题 AS fillQuestion",
            "填空题答案 AS fillAnswer",
            "填空题解析 AS fillExplanation"
        ]

        fills = get_paginated_data("exam_blank", fields, latest)

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
            "data": formatted_fills,
            "count": len(formatted_fills),
            "latest": latest
        })

    except mysql.connector.Error as e:
        logger.error(f"数据库错误: {str(e)}")
        return jsonify({"code": 500, "error": f"数据库错误: {str(e)}"})
    except Exception as e:
        logger.error(f"服务器错误: {str(e)}")
        return jsonify({"code": 500, "error": f"服务器错误: {str(e)}"})


# -------------------------- 判断题相关功能 --------------------------
@app.route('/api/judges', methods=['GET'])
def get_judges():
    """获取判断题数据（支持返回最新10条）"""
    try:
        # 修改为（默认返回最新10条）
        latest_param = request.args.get('latest', 'true').lower()  # 默认值设为'true'
        latest = latest_param in ('true', '1', 'yes', 'y')
        logger.debug(f"判断题 latest参数: {latest_param}, 解析结果: {latest}")

        fields = [
            "id",
            "试卷名称 AS judgePaperName",
            "试卷编号 AS judgePaperId",
            "判断题问题 AS judgeQuestion",
            "判断题答案 AS judgeAnswer",
            "判断题解析 AS judgeExplanation"
        ]

        judges = get_paginated_data("exam_judgment", fields, latest)

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
            "data": formatted_judges,
            "count": len(formatted_judges),
            "latest": latest
        })

    except mysql.connector.Error as e:
        logger.error(f"数据库错误: {str(e)}")
        return jsonify({"code": 500, "error": f"数据库错误: {str(e)}"})
    except Exception as e:
        logger.error(f"服务器错误: {str(e)}")
        return jsonify({"code": 500, "error": f"服务器错误: {str(e)}"})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
