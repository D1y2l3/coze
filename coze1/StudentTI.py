from flask import Flask, jsonify, request
import mysql.connector
import re
from flask_cors import CORS
import logging

app = Flask(__name__)
CORS(app)  # 允许跨域访问

# 配置日志，方便调试（保留原有配置，补充SQL执行详情）
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 数据库配置（完全保留原有配置）
db_config = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "123456",
    "database": "exam_db5"
}


# -------------------------- 通用工具函数（保留+新增） --------------------------
def get_paginated_data(table_name, fields, latest_flag):
    """通用获取数据函数，支持返回最新10条（完全保留原有逻辑）"""
    base_sql = f"SELECT {', '.join(fields)} FROM {table_name}"

    if latest_flag:
        sql = f"{base_sql} ORDER BY id DESC LIMIT 10"
    else:
        sql = base_sql

    logger.debug(f"执行SQL: {sql}")

    with mysql.connector.connect(**db_config) as conn:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(sql)
            result = cursor.fetchall()
            logger.debug(f"查询 {table_name} 表，返回 {len(result)} 条数据")
            return result


def parse_options(option_str: str) -> dict:
    """解析选择题选项字符串为字典格式（完全保留原有逻辑）"""
    if not option_str:
        return {"A": "", "B": "", "C": "", "D": ""}

    pattern = r'([A-D])\.([^A-D]+)'
    matches = re.findall(pattern, option_str)

    options = {"A": "", "B": "", "C": "", "D": ""}
    for key, value in matches:
        options[key] = value.strip().replace("'", "").replace('"', '')

    return options


# 新增：通用查询单题正确答案（为提交判分接口服务）
def get_correct_answer(question_id, question_type):
    """根据题目ID和类型，从对应表查询正确答案"""
    table_map = {
        "choice": "exam_choose",   # 选择题表
        "fill": "exam_blank",      # 填空题表
        "judge": "exam_judgment"   # 判断题表
    }
    field_map = {
        "choice": "选择题答案 AS correct",
        "fill": "填空题答案 AS correct",
        "judge": "判断题答案 AS correct"
    }

    # 校验题目类型
    if question_type not in table_map:
        logger.error(f"不支持的题目类型: {question_type}")
        return None

    table_name = table_map[question_type]
    correct_field = field_map[question_type]
    sql = f"SELECT {correct_field} FROM {table_name} WHERE id = %s"
    logger.debug(f"查询正确答案 SQL: {sql} (question_id: {question_id})")

    with mysql.connector.connect(**db_config) as conn:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(sql, (question_id,))
            result = cursor.fetchone()
            if not result:
                logger.warning(f"未找到 ID={question_id} 的 {question_type} 类型题目")
                return None
            return result["correct"]


# -------------------------- 选择题相关功能（完全保留） --------------------------
@app.route('/api/choices', methods=['GET'])
def get_choices():
    """获取选择题数据（支持返回最新10条）"""
    try:
        latest_param = request.args.get('latest', 'true').lower()
        latest = latest_param in ('true', '1', 'yes', 'y')
        logger.debug(f"选择题 latest参数: {latest_param}, 解析结果: {latest}")

        fields = [
            "id",
            "试卷名称 AS choicePaperName",
            "试卷编号 AS choicePaperId",
            "选择题问题 AS choiceQuestion",
            "选择题选项 AS optionsStr",
            "选择题答案 AS choiceAnswer",
            "选择题解析 AS choiceExplanation"
        ]

        choices = get_paginated_data("exam_choose", fields, latest)

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
            "count": len(formatted_choices),
            "latest": latest
        })

    except mysql.connector.Error as e:
        logger.error(f"数据库错误: {str(e)}")
        return jsonify({"code": 500, "error": f"数据库错误: {str(e)}"})
    except Exception as e:
        logger.error(f"服务器错误: {str(e)}")
        return jsonify({"code": 500, "error": f"服务器错误: {str(e)}"})


# -------------------------- 填空题相关功能（完全保留） --------------------------
@app.route('/api/fills', methods=['GET'])
def get_fills():
    """获取填空题数据（支持返回最新10条）"""
    try:
        latest_param = request.args.get('latest', 'true').lower()
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


# -------------------------- 判断题相关功能（保留+优化答案解析） --------------------------
@app.route('/api/judges', methods=['GET'])
def get_judges():
    """获取判断题数据（支持返回最新10条，优化答案解析逻辑）"""
    try:
        latest_param = request.args.get('latest', 'true').lower()
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
            # 优化：兼容数据库中答案为字符串（'true'/'false'）或布尔值的情况
            judge_answer = item.get("judgeAnswer", "")
            if isinstance(judge_answer, str):
                answer = judge_answer.strip().lower() == 'true'
            else:
                answer = bool(judge_answer)

            formatted_judges.append({
                "id": item["id"],
                "judgePaperName": item.get("judgePaperName", ""),
                "judgePaperId": item.get("judgePaperId", ""),
                "judgeQuestion": item.get("judgeQuestion", "无题目"),
                "judgeAnswer": answer,  # 返回布尔值，方便前端渲染
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


# -------------------------- 新增：答案提交判分接口（匹配原有风格） --------------------------
@app.route('/api/submit', methods=['POST'])
def submit_answers():
    """提交答案并判分（支持选择/填空/判断三种题型）"""
    try:
        # 1. 解析前端提交的JSON数据
        if not request.is_json:
            return jsonify({"code": 400, "error": "请求格式错误，需为JSON"}), 400

        submit_data = request.get_json()
        if not isinstance(submit_data, list) or len(submit_data) == 0:
            return jsonify({"code": 400, "error": "提交数据错误，需为非空数组"}), 400

        logger.debug(f"接收答案提交，共 {len(submit_data)} 道题")

        # 2. 初始化判分结果
        total_score = 0  # 总分
        total_questions = len(submit_data)  # 总题数
        detail_result = []  # 每题判分详情（前端可展示错题）

        # 3. 逐题判分
        for item in submit_data:
            # 提取单题信息（前端需传这3个字段）
            question_id = item.get("questionId")
            user_answer = item.get("userAnswer")
            question_type = item.get("questionType")  # 取值：choice/fill/judge

            # 校验单题数据
            if not all([question_id, user_answer, question_type]):
                detail_result.append({
                    "questionId": question_id,
                    "isCorrect": False,
                    "userAnswer": user_answer,
                    "correctAnswer": "",
                    "error": "提交数据缺失（需包含questionId、userAnswer、questionType）"
                })
                continue

            # 4. 查询正确答案
            correct_answer = get_correct_answer(question_id, question_type)
            if correct_answer is None:
                detail_result.append({
                    "questionId": question_id,
                    "isCorrect": False,
                    "userAnswer": user_answer,
                    "correctAnswer": "",
                    "error": f"未找到ID={question_id}的{question_type}类型题目"
                })
                continue

            # 5. 按题型对比答案（核心判分逻辑）
            is_correct = False
            if question_type == "choice":
                # 选择题：忽略大小写（如"A"和"a"都算对）
                is_correct = str(user_answer).strip().upper() == str(correct_answer).strip().upper()
            elif question_type == "fill":
                # 填空题：精确匹配（可根据需求改为模糊匹配，如去掉空格对比）
                is_correct = str(user_answer).strip() == str(correct_answer).strip()
            elif question_type == "judge":
                # 判断题：兼容前端传布尔值（true/false）或字符串（"对"/"错"）
                user_answer_norm = str(user_answer).strip().lower()
                correct_norm = str(correct_answer).strip().lower() == 'true'
                is_correct = (user_answer_norm in ("true", "对", "1")) == correct_norm

            # 6. 统计得分（每题1分，可自定义分值）
            if is_correct:
                total_score += 1

            # 7. 记录单题详情
            detail_result.append({
                "questionId": question_id,
                "questionType": question_type,
                "isCorrect": is_correct,
                "userAnswer": user_answer,
                "correctAnswer": correct_answer,
                "error": ""
            })

        # 8. 返回判分结果（匹配原有接口的返回格式）
        return jsonify({
            "code": 200,
            "message": "success",
            "data": {
                "totalScore": total_score,    # 总分
                "totalQuestions": total_questions,  # 总题数
                "accuracy": f"{(total_score / total_questions * 100):.1f}%" if total_questions > 0 else "0.0%",  # 正确率
                "detail": detail_result       # 每题详情
            },
            "count": total_questions  # 保持count字段，与原有接口风格一致
        })

    except mysql.connector.Error as e:
        logger.error(f"数据库错误: {str(e)}")
        return jsonify({"code": 500, "error": f"数据库错误: {str(e)}"})
    except Exception as e:
        logger.error(f"服务器错误: {str(e)}")
        return jsonify({"code": 500, "error": f"服务器错误: {str(e)}"})


# -------------------------- 服务启动（保留原有配置） --------------------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)