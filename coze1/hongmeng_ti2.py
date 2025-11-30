from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import pymysql
from pymysql.cursors import DictCursor

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)
# 允许所有来源访问/api/*路径的接口（解决跨域）
CORS(app, resources={r"/api/*": {"origins": "*"}})

# 数据库连接配置
DB_CONFIG = {
    "host": "localhost",
    "user": "root",        # 替换为你的数据库用户名
    "password": "123456",  # 替换为你的数据库密码
    "database": "exam_db5",# 数据库名保持不变
    "port": 3306,
    "charset": "utf8mb4"
}

def get_db_connection():
    """获取数据库连接（字典游标）"""
    try:
        conn = pymysql.connect(
            **DB_CONFIG,
            cursorclass=DictCursor
        )
        logging.info("数据库连接成功")
        return conn
    except Exception as e:
        logging.error(f"数据库连接失败：{str(e)}")
        return None

@app.route('/api/question', methods=['POST'])
def query_papers():
    """根据手机号查询匹配的试卷名称列表"""
    try:
        data = request.get_json()
        if not data or "phoneNumber" not in data:
            logging.warning("请求参数缺失：未提供手机号")
            return jsonify({
                "paperNames": None,
                "message": "请提供手机号"
            }), 400

        phone_number = data["phoneNumber"].strip()
        if not phone_number:
            logging.warning("手机号为空")
            return jsonify({
                "paperNames": None,
                "message": "手机号不能为空"
            }), 400

        logging.info(f"收到试卷查询请求，手机号：{phone_number}")

        conn = get_db_connection()
        if not conn:
            return jsonify({
                "paperNames": None,
                "message": "数据库连接失败"
            }), 500

        cursor = conn.cursor()
        try:
            # 联合查询选择题、判断题、填空题的试卷名称（确保不遗漏）
            query_sql = """
                SELECT 试卷名称 
                FROM (
                    SELECT 试卷名称, phone_number, create_time FROM ti_choose 
                    UNION ALL 
                    SELECT 试卷名称, phone_number, create_time FROM ti_judgment
                    UNION ALL
                    SELECT 试卷名称, phone_number, create_time FROM ti_blank
                ) AS combined 
                WHERE phone_number = %s 
                GROUP BY 试卷名称 
                ORDER BY MAX(create_time) DESC
            """
            cursor.execute(query_sql, (phone_number,))
            results = cursor.fetchall()

            paper_names = [item["试卷名称"] for item in results] if results else []
            logging.info(f"试卷查询完成，找到{len(paper_names)}份试卷")

            if paper_names:
                return jsonify({
                    "paperNames": paper_names,
                    "message": f"查询成功，共{len(paper_names)}份试卷"
                }), 200
            else:
                return jsonify({
                    "paperNames": [],
                    "message": "未查询到该手机号对应的试卷"
                }), 200

        except Exception as e:
            logging.error(f"试卷查询数据库失败：{str(e)}", exc_info=True)
            return jsonify({
                "paperNames": None,
                "message": "查询数据失败"
            }), 500

        finally:
            cursor.close()
            conn.close()
            logging.info("试卷查询的数据库连接已关闭")

    except Exception as e:
        logging.error(f"试卷查询请求处理异常：{str(e)}", exc_info=True)
        return jsonify({
            "paperNames": None,
            "message": "请求处理失败"
        }), 500

@app.route('/api/choices/by-paper', methods=['POST'])
def get_choices_by_paper():
    """根据试卷名称查询对应的选择题列表，将选项拆分为A/B/C/D"""
    try:
        data = request.get_json()
        if not data or "paperName" not in data:
            logging.warning("请求参数缺失：未提供试卷名称")
            return jsonify({
                "data": None,
                "message": "请提供试卷名称"
            }), 400

        paper_name = data["paperName"].strip()
        if not paper_name:
            logging.warning("试卷名称为空")
            return jsonify({
                "data": None,
                "message": "试卷名称不能为空"
            }), 400

        logging.info(f"收到选择题查询请求，试卷名称：{paper_name}")

        conn = get_db_connection()
        if not conn:
            return jsonify({
                "data": None,
                "message": "数据库连接失败"
            }), 500

        cursor = conn.cursor()
        try:
            # 拆分选择题选项为A、B、C、D（假设选项格式为“A. 选项1;B. 选项2;C. 选项3;D. 选项4”）
            query_sql = """
                SELECT 
                    id, 
                    `试卷名称`, 
                    `选择题问题` as choiceQuestion, 
                    SUBSTRING_INDEX(SUBSTRING_INDEX(`选择题选项`, ';', 1), ';', -1) as 'choiceOptions.A',
                    SUBSTRING_INDEX(SUBSTRING_INDEX(`选择题选项`, ';', 2), ';', -1) as 'choiceOptions.B',
                    SUBSTRING_INDEX(SUBSTRING_INDEX(`选择题选项`, ';', 3), ';', -1) as 'choiceOptions.C',
                    SUBSTRING_INDEX(SUBSTRING_INDEX(`选择题选项`, ';', 4), ';', -1) as 'choiceOptions.D',
                    `选择题答案` as choiceAnswer, 
                    `选择题解析` as choiceExplanation, 
                    `试卷编号` as paperId,
                    create_time
                FROM ti_choose 
                WHERE `试卷名称` = %s 
                ORDER BY id ASC
            """
            cursor.execute(query_sql, (paper_name,))
            results = cursor.fetchall()

            # 组装前端需要的结构
            formatted_results = []
            for item in results:
                formatted_item = {
                    "id": item["id"],
                    "choiceQuestion": item["choiceQuestion"],
                    "choiceOptions": {
                        "A": item["choiceOptions.A"],
                        "B": item["choiceOptions.B"],
                        "C": item["choiceOptions.C"],
                        "D": item["choiceOptions.D"]
                    },
                    "choiceAnswer": item["choiceAnswer"],
                    "choiceExplanation": item["choiceExplanation"],
                    "paperId": item["paperId"]
                }
                formatted_results.append(formatted_item)

            logging.info(f"选择题查询完成，找到{len(formatted_results)}道题")

            return jsonify({
                "data": formatted_results,
                "message": "查询成功"
            }), 200

        except Exception as e:
            logging.error(f"选择题查询数据库失败：{str(e)}", exc_info=True)
            return jsonify({
                "data": None,
                "message": "查询数据失败"
            }), 500

        finally:
            cursor.close()
            conn.close()
            logging.info("选择题查询的数据库连接已关闭")

    except Exception as e:
        logging.error(f"选择题查询请求处理异常：{str(e)}", exc_info=True)
        return jsonify({
            "data": None,
            "message": "请求处理失败"
        }), 500

@app.route('/api/judgments/by-paper', methods=['POST'])
def get_judgments_by_paper():
    """根据试卷名称查询对应的判断题列表，包含详细日志"""
    try:
        data = request.get_json()
        paper_name = data["paperName"].strip()
        logging.info(f"查询判断题，试卷名称：{paper_name}")

        conn = get_db_connection()
        cursor = conn.cursor()
        query_sql = """
            SELECT 
                id, 
                `试卷名称` as paperName,
                `判断题问题` as judgeQuestion, 
                `判断题答案` as judgeAnswer, 
                `判断题解析` as judgeExplanation, 
                `试卷编号` as paperId
            FROM ti_judgment 
            WHERE `试卷名称` = %s 
            ORDER BY id ASC
        """
        cursor.execute(query_sql, (paper_name,))
        results = cursor.fetchall()
        logging.info(f"判断题查询结果：{results}")  # 新增日志打印

        return jsonify({
            "data": results,
            "message": "查询成功"
        }), 200
    except Exception as e:
        logging.error(f"判断题查询异常：{str(e)}", exc_info=True)
        return jsonify({
            "data": None,
            "message": "查询数据失败"
        }), 500

@app.route('/api/blanks/by-paper', methods=['POST'])
def get_blanks_by_paper():
    """根据试卷名称查询对应的填空题列表（包含答案和解析）"""
    try:
        data = request.get_json()
        if not data or "paperName" not in data:
            logging.warning("请求参数缺失：未提供试卷名称")
            return jsonify({
                "data": None,
                "message": "请提供试卷名称"
            }), 400

        paper_name = data["paperName"].strip()
        if not paper_name:
            logging.warning("试卷名称为空")
            return jsonify({
                "data": None,
                "message": "试卷名称不能为空"
            }), 400

        logging.info(f"收到填空题查询请求，试卷名称：{paper_name}")

        conn = get_db_connection()
        if not conn:
            return jsonify({
                "data": None,
                "message": "数据库连接失败"
            }), 500

        cursor = conn.cursor()
        try:
            query_sql = """
                SELECT 
                    id, 
                    `试卷名称` as paperName,
                    `填空题问题` as blankQuestion, 
                    `填空题答案` as blankAnswer,  -- 新增：填空题答案字段
                    `填空题解析` as blankExplanation, -- 新增：填空题解析字段
                    `试卷编号` as paperId
                FROM ti_blank 
                WHERE `试卷名称` = %s 
                ORDER BY id ASC
            """
            cursor.execute(query_sql, (paper_name,))
            results = cursor.fetchall()
            logging.info(f"填空题查询结果：{results}")

            return jsonify({
                "data": results,
                "message": "查询成功"
            }), 200
        except Exception as e:
            logging.error(f"填空题查询数据库失败：{str(e)}", exc_info=True)
            return jsonify({
                "data": None,
                "message": "查询数据失败"
            }), 500
        finally:
            cursor.close()
            conn.close()
            logging.info("填空题查询的数据库连接已关闭")
    except Exception as e:
        logging.error(f"填空题查询请求处理异常：{str(e)}", exc_info=True)
        return jsonify({
            "data": None,
            "message": "请求处理失败"
        }), 500

if __name__ == '__main__':
    # 以0.0.0.0启动，端口5001，开启调试模式
    app.run(host='0.0.0.0', port=5001, debug=True)