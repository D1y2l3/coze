from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import pymysql
import re  # 导入正则模块，用于解析选项格式

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
    """查询试卷题目及解析，返回前端所需结构（包含questions数组）"""
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
            return jsonify({
                "message": "未找到该试卷的题型信息",
                "status": 404,
                "questions": [],  # 即使失败也返回空数组，避免前端崩溃
                "paperName": paper_name
            }), 404
        choice_id, judge_id, blank_id = result

        # 存储所有题目的列表（适配前端Question类型）
        questions = []
        question_index = 0  # 题目序号（从0开始）

        # --------------------------
        # 1. 选择题（适配ti_choose表格式，返回选项键作为答案）
        # --------------------------
        choose_sql = """
            SELECT `选择题问题`, `选择题选项`, `选择题答案`, `选择题解析` 
            FROM ti_choose 
            WHERE `试卷编号` = %s AND `试卷名称` = %s  
        """
        cursor.execute(choose_sql, (choice_id, paper_name))
        choose_questions = cursor.fetchall()
        for question, options_str, answer_val, analysis in choose_questions:
            options = {}
            answer_key = ""  # 存储正确选项的键（A/B/C/D）
            if options_str:
                options_str = options_str.strip()
                # 正则匹配A.、B.、C.、D.开头的选项，提取键和值
                matches = re.findall(r'([ABCD])\. (.*?)(?= [ABCD]\. |$)', options_str)
                for key, val in matches:
                    options[key] = val.strip()
                # 补充缺失的选项，避免前端无内容
                for k in ['A', 'B', 'C', 'D']:
                    if k not in options:
                        options[k] = f'无有效选项{k}'
                # 核心：根据选项值匹配对应的选项键（A/B/C/D）
                target_answer = answer_val.strip()
                for key, val in options.items():
                    if val.strip() == target_answer:
                        answer_key = key
                        break
                # 容错：如果未匹配到选项键，使用原始答案值（避免前端完全错误）
                if not answer_key:
                    answer_key = target_answer
                    logging.warning(f"第{question_index + 1}题未找到匹配的选项键，原始答案：{target_answer}")
            else:
                # 选项为空时的默认处理
                options = {
                    "A": "无有效选项A",
                    "B": "无有效选项B",
                    "C": "无有效选项C",
                    "D": "无有效选项D"
                }
                answer_key = "无答案"  # 选项为空时的默认答案

            # 构建题目对象（answer为选项键A/B/C/D）
            questions.append({
                "questionType": "RADIO",
                "id": f"radio_{question_index}",
                "question": question.strip(),
                "options": options,
                "answer": answer_key,  # 前端用选项键判分
                "analysis": analysis.strip() if analysis else "无解析",
                "index": question_index
            })
            question_index += 1

        # --------------------------
        # 2. 判断题（清洗答案，去除句号和多余字符）
        # --------------------------
        judge_sql = """
            SELECT `判断题问题`, `判断题答案`, `判断题解析` 
            FROM ti_judgment 
            WHERE `试卷编号` = %s AND `试卷名称` = %s  
        """
        cursor.execute(judge_sql, (judge_id, paper_name))
        judge_questions = cursor.fetchall()
        for question, answer, analysis in judge_questions:
            # 核心修改：清洗答案（去除前后空格、中文句号“。”、英文句号“.”）
            judge_answer = answer.strip()  # 去除前后空格
            judge_answer = judge_answer.replace('。', '').replace('.', '')  # 去除句号
            # 打印验证：清洗前后的答案对比（方便调试）
            print(f"判断题 {question_index + 1} 原始答案: [{answer.strip()}]，清洗后: [{judge_answer}]")

            questions.append({
                "questionType": "JUDGE",
                "id": f"judge_{question_index}",
                "question": question.strip(),
                "options": ["对", "错"],
                "answer": judge_answer,  # 用清洗后的答案返回
                "analysis": analysis.strip() if analysis else "无解析",
                "index": question_index
            })
            question_index += 1

        # --------------------------
        # 3. 填空题（保持不变，答案为具体文本）
        # --------------------------
        blank_sql = """
            SELECT `填空题问题`, `填空题答案`, `填空题解析` 
            FROM ti_blank 
            WHERE `试卷编号` = %s AND `试卷名称` = %s  
        """
        cursor.execute(blank_sql, (blank_id, paper_name))
        blank_questions = cursor.fetchall()
        for question, answer, analysis in blank_questions:
            questions.append({
                "questionType": "FILL",
                "id": f"fill_{question_index}",
                "question": question.strip(),
                "options": None,
                "answer": answer.strip(),
                "analysis": analysis.strip() if analysis else "无解析",
                "index": question_index
            })
            question_index += 1

        conn.close()

        # 打印调试信息（验证整体转换结果）
        print(f"\n===== 试卷[{paper_name}]处理完成，共{len(questions)}题 =====")

        return jsonify({
            "message": "题目及解析查询成功",
            "status": 200,
            "questions": questions,
            "paperName": paper_name
        }), 200

    except Exception as e:
        logging.error(f"题目查询失败：{str(e)}", exc_info=True)
        return jsonify({
            "message": f"查询题目失败：{str(e)}",
            "status": 500,
            "questions": [],
            "paperName": paper_name
        }), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)