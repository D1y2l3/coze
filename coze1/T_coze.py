from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
import logging
import time
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

# ===================== 全局配置 =====================
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)
CORS(app, resources=r"/*")

COZE_API_TOKEN = 'pat_ObtKbqWHYEimyO5jeQqxEfigFjAl8wXoqezh0FDtPOYDKjARpP9QKTqvXafTSJIN'
WORKFLOW_ID = '7526153262711554084'
coze = Coze(auth=TokenAuth(token=COZE_API_TOKEN), base_url=COZE_CN_BASE_URL)

# ===================== 核心函数：数据库存储与同步 =====================
def save_to_database(content: str, phone_number: str):
    conn = None
    cursor = None
    try:
        # 1. 解析Coze数据
        try:
            coze_result = json.loads(content)
            logging.info("Coze返回数据解析成功")
        except json.JSONDecodeError as e:
            err_msg = f"JSON解析失败：{str(e)}"
            logging.error(err_msg)
            return False, err_msg

        # 2. 处理各题型数据
        choose_data = coze_result.get('output1', '[]')
        from exam_processor_choose import process_exam_data
        processed_choose = process_exam_data(choose_data)
        logging.info(f"选择题处理完成：共{len(processed_choose)}道")

        blank_data = coze_result.get('output2', '[]')
        from exam_processor_blanks import process_blank_data
        processed_blank = process_blank_data(blank_data)
        logging.info(f"填空题处理完成：共{len(processed_blank)}道")

        judgment_data = coze_result.get('output3', '[]')
        from exam_processor_judgment import process_judgment_data
        processed_judgment = process_judgment_data(judgment_data)
        logging.info(f"判断题处理完成：共{len(processed_judgment)}道")

        # 3. 数据库连接
        from exam_db_choose import create_connection
        conn = create_connection()
        if not conn:
            err_msg = "数据库连接失败"
            logging.error(err_msg)
            return False, err_msg
        logging.info("MySQL数据库连接成功")

        # 4. 创建表
        from exam_db_choose import create_table as create_choose_table
        from exam_db_blanks import create_table as create_blank_table
        from exam_db_judgment import create_table as create_judgment_table
        from ti_choose_db import create_ti_choose_table
        from ti_blank_db import create_ti_blank_table
        from ti_judgment_db import create_ti_judgment_table

        try:
            create_choose_table(conn)
            create_blank_table(conn)
            create_judgment_table(conn)
            create_ti_choose_table(conn)
            create_ti_blank_table(conn)
            create_ti_judgment_table(conn)
            logging.info("所有表创建/验证成功")
        except Exception as e:
            err_msg = f"表创建失败：{str(e)}"
            logging.error(err_msg)
            return False, err_msg

        # 5. 插入原有题库
        from exam_db_choose import insert_exam as insert_choose_exam
        from exam_db_blanks import insert_blank as insert_blank_exam
        from exam_db_judgment import insert_judgment as insert_judgment_exam
        try:
            for item in processed_choose:
                insert_choose_exam(conn, item)
            for item in processed_blank:
                insert_blank_exam(conn, item)
            for item in processed_judgment:
                insert_judgment_exam(conn, item)
            conn.commit()
            logging.info("原有题库数据插入成功")
        except Exception as e:
            err_msg = f"原有题库插入失败：{str(e)}"
            logging.error(err_msg)
            conn.rollback()
            return False, err_msg

        cursor = conn.cursor()

        # -------------------------- 6.1 同步选择题（已修复）--------------------------
        try:
            logging.info("开始同步最新10道选择题到Ti_choose表...")
            cursor.execute("""
                SELECT 试卷名称, 试卷编号, 选择题问题, 选择题选项, 选择题答案, 选择题解析 
                FROM exam_choose 
                ORDER BY id DESC LIMIT 10
            """)
            latest_10_chooses = cursor.fetchall()
            logging.info(f"查询到最新选择题：{len(latest_10_chooses)}道")
            logging.debug(f"选择题查询原始数据：{latest_10_chooses}")

            sync_fail = 0
            from ti_choose_db import insert_ti_choose
            for idx, choose in enumerate(latest_10_chooses, 1):
                try:
                    logging.debug(f"\n第{idx}道选择题原始数据：{choose}")
                    logging.debug(f"数据类型：{type(choose)}")

                    paper_name_raw = choose.get("试卷名称")
                    paper_name = paper_name_raw if (paper_name_raw and str(paper_name_raw).strip()) else f"未命名试卷_{int(time.time())}_{idx}"
                    paper_id_raw = choose.get("试卷编号")
                    paper_id = paper_id_raw if (paper_id_raw and str(paper_id_raw).strip()) else f"PAPER_{int(time.time())}_{idx}"
                    question_raw = choose.get("选择题问题")
                    question = question_raw if (question_raw and str(question_raw).strip()) else f"选择题_{idx}_无描述"
                    options_raw = choose.get("选择题选项")
                    options = options_raw if (options_raw and str(options_raw).strip()) else "无选项"
                    answer_raw = choose.get("选择题答案")
                    answer = answer_raw if (answer_raw and str(answer_raw).strip()) else "无"
                    explanation_raw = choose.get("选择题解析")
                    explanation = explanation_raw if (explanation_raw and str(explanation_raw).strip()) else "无解析"

                    ti_data = {
                        "phone_number": phone_number,
                        "试卷名称": paper_name,
                        "试卷编号": paper_id,
                        "选择题问题": question,
                        "选择题选项": options,
                        "选择题答案": answer,
                        "选择题解析": explanation
                    }
                    logging.debug(f"构建插入数据：{ti_data}")

                    success = insert_ti_choose(conn, ti_data)
                    if success:
                        logging.info(f"第{idx}道选择题同步成功：{paper_name}-{question[:20]}...")
                    else:
                        logging.error(f"第{idx}道选择题同步失败：{ti_data}")
                        sync_fail += 1
                except Exception as e:
                    logging.error(f"第{idx}道选择题同步异常：{str(e)}", exc_info=True)
                    sync_fail += 1

            if sync_fail == len(latest_10_chooses) and len(latest_10_chooses) > 0:
                err_msg = "选择题同步全部失败"
                logging.error(err_msg)
                conn.rollback()
                return False, err_msg
            logging.info("选择题同步完成")
        except Exception as e:
            err_msg = f"选择题同步异常：{str(e)}"
            logging.error(err_msg, exc_info=True)
            conn.rollback()
            return False, err_msg

        # -------------------------- 6.2 同步填空题（修复字典访问）--------------------------
        try:
            logging.info("开始同步最新10道填空题到Ti_blank表...")
            cursor.execute("""
                SELECT 试卷名称, 试卷编号, 填空题问题, 填空题答案, 填空题解析 
                FROM exam_blank 
                ORDER BY id DESC LIMIT 10
            """)
            latest_10_blanks = cursor.fetchall()
            logging.info(f"查询到最新填空题：{len(latest_10_blanks)}道")
            logging.debug(f"填空题查询原始数据：{latest_10_blanks}")

            sync_fail = 0
            from ti_blank_db import insert_ti_blank
            for idx, blank in enumerate(latest_10_blanks, 1):
                try:
                    logging.debug(f"\n第{idx}道填空题原始数据：{blank}")
                    logging.debug(f"数据类型：{type(blank)}")

                    # 按字典键名获取字段（核心修复）
                    paper_name_raw = blank.get("试卷名称")
                    paper_name = paper_name_raw if (paper_name_raw and str(paper_name_raw).strip()) else f"未命名试卷_{int(time.time())}_{idx}"
                    paper_id_raw = blank.get("试卷编号")
                    paper_id = paper_id_raw if (paper_id_raw and str(paper_id_raw).strip()) else f"PAPER_{int(time.time())}_{idx}"
                    question_raw = blank.get("填空题问题")
                    question = question_raw if (question_raw and str(question_raw).strip()) else f"填空题_{idx}_无描述"
                    answer_raw = blank.get("填空题答案")
                    answer = answer_raw if (answer_raw and str(answer_raw).strip()) else "无"
                    explanation_raw = blank.get("填空题解析")
                    explanation = explanation_raw if (explanation_raw and str(explanation_raw).strip()) else "无解析"

                    ti_data = {
                        "phone_number": phone_number,
                        "试卷名称": paper_name,
                        "试卷编号": paper_id,
                        "填空题问题": question,
                        "填空题答案": answer,
                        "填空题解析": explanation
                    }
                    logging.debug(f"构建插入数据：{ti_data}")

                    success = insert_ti_blank(conn, ti_data)
                    if success:
                        logging.info(f"第{idx}道填空题同步成功：{paper_name}-{question[:20]}...")
                    else:
                        logging.error(f"第{idx}道填空题同步失败：{ti_data}")
                        sync_fail += 1
                except Exception as e:
                    logging.error(f"第{idx}道填空题同步异常：{str(e)}", exc_info=True)
                    sync_fail += 1

            if sync_fail == len(latest_10_blanks) and len(latest_10_blanks) > 0:
                err_msg = "填空题同步全部失败"
                logging.error(err_msg)
                conn.rollback()
                return False, err_msg
            logging.info("填空题同步完成")
        except Exception as e:
            err_msg = f"填空题同步异常：{str(e)}"
            logging.error(err_msg, exc_info=True)
            conn.rollback()
            return False, err_msg

        # -------------------------- 6.3 同步判断题（修复字典访问）--------------------------
        try:
            logging.info("开始同步最新10道判断题到Ti_judgment表...")
            cursor.execute("""
                SELECT 试卷名称, 试卷编号, 判断题问题, 判断题答案, 判断题解析 
                FROM exam_judgment 
                ORDER BY id DESC LIMIT 10
            """)
            latest_10_judgments = cursor.fetchall()
            logging.info(f"查询到最新判断题：{len(latest_10_judgments)}道")
            logging.debug(f"判断题查询原始数据：{latest_10_judgments}")

            sync_fail = 0
            from ti_judgment_db import insert_ti_judgment
            for idx, judgment in enumerate(latest_10_judgments, 1):
                try:
                    logging.debug(f"\n第{idx}道判断题原始数据：{judgment}")
                    logging.debug(f"数据类型：{type(judgment)}")

                    # 按字典键名获取字段（核心修复）
                    paper_name_raw = judgment.get("试卷名称")
                    paper_name = paper_name_raw if (paper_name_raw and str(paper_name_raw).strip()) else f"未命名试卷_{int(time.time())}_{idx}"
                    paper_id_raw = judgment.get("试卷编号")
                    paper_id = paper_id_raw if (paper_id_raw and str(paper_id_raw).strip()) else f"PAPER_{int(time.time())}_{idx}"
                    question_raw = judgment.get("判断题问题")
                    question = question_raw if (question_raw and str(question_raw).strip()) else f"判断题_{idx}_无描述"
                    answer_raw = judgment.get("判断题答案")
                    answer = answer_raw if (answer_raw and str(answer_raw).strip()) else "无"
                    explanation_raw = judgment.get("判断题解析")
                    explanation = explanation_raw if (explanation_raw and str(explanation_raw).strip()) else "无解析"

                    ti_data = {
                        "phone_number": phone_number,
                        "试卷名称": paper_name,
                        "试卷编号": paper_id,
                        "判断题问题": question,
                        "判断题答案": answer,
                        "判断题解析": explanation
                    }
                    logging.debug(f"构建插入数据：{ti_data}")

                    success = insert_ti_judgment(conn, ti_data)
                    if success:
                        logging.info(f"第{idx}道判断题同步成功：{paper_name}-{question[:20]}...")
                    else:
                        logging.error(f"第{idx}道判断题同步失败：{ti_data}")
                        sync_fail += 1
                except Exception as e:
                    logging.error(f"第{idx}道判断题同步异常：{str(e)}", exc_info=True)
                    sync_fail += 1

            if sync_fail == len(latest_10_judgments) and len(latest_10_judgments) > 0:
                err_msg = "判断题同步全部失败"
                logging.error(err_msg)
                conn.rollback()
                return False, err_msg
            logging.info("判断题同步完成")
        except Exception as e:
            err_msg = f"判断题同步异常：{str(e)}"
            logging.error(err_msg, exc_info=True)
            conn.rollback()
            return False, err_msg

        conn.commit()
        logging.info("所有数据同步完成")
        return True, "数据处理成功"

    except Exception as e:
        err_msg = f"全局异常：{str(e)}"
        logging.error(err_msg, exc_info=True)
        if conn:
            conn.rollback()
        return False, err_msg

    finally:
        if cursor:
            try:
                cursor.close()
                logging.info("游标已关闭")
            except Exception as e:
                logging.warning(f"关闭游标失败：{str(e)}")
        if conn:
            try:
                conn.close()
                logging.info("连接已关闭")
            except Exception as e:
                logging.warning(f"关闭连接失败：{str(e)}")

# ===================== 辅助函数与接口 =====================
def handle_workflow_stream(stream: Stream[WorkflowEvent]):
    result = []
    try:
        for event in stream:
            if event.event == WorkflowEventType.MESSAGE and event.message and event.message.content:
                result.append(event.message.content)
            elif event.event == WorkflowEventType.ERROR:
                logging.error(f"Coze错误：{event.error}")
                return {"success": False, "error": event.error}
        return {"success": True, "data": "".join(result)}
    except Exception as e:
        logging.error(f"处理Coze流失败：{str(e)}")
        return {"success": False, "error": str(e)}

@app.route('/api/aigenerate', methods=['POST'])
def receive_and_process():
    try:
        data = request.get_json()
        if not data or 'content' not in data or not data.get('phoneNumber', '').strip():
            return jsonify({"code": 400, "message": "参数缺失"}), 400

        input_content = data['content']
        phone_number = data['phoneNumber'].strip()
        logging.info(f"收到请求：手机号={phone_number}，需求={input_content}")

        stream = coze.workflows.runs.stream(workflow_id=WORKFLOW_ID, parameters={"input": input_content})
        workflow_result = handle_workflow_stream(stream)
        if not workflow_result["success"]:
            return jsonify({"code": 500, "message": workflow_result["error"]}), 500

        db_success, db_msg = save_to_database(workflow_result["data"], phone_number)
        return jsonify({
            "code": 200 if db_success else 500,
            "message": db_msg,
            "data": workflow_result["data"]
        }), 200 if db_success else 500
    except Exception as e:
        logging.error(f"接口异常：{str(e)}", exc_info=True)
        return jsonify({"code": 500, "message": str(e)}), 500

if __name__ == '__main__':
    logging.info("服务启动：http://0.0.0.0:5001")
    app.run(host='0.0.0.0', port=5001, debug=True)