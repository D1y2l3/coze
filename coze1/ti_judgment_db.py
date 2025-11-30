import mysql.connector
from mysql.connector import Error
from typing import Optional, Dict
import logging

# 数据库配置（统一配置）
db_config = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "123456",
    "database": "exam_db5"
}


def create_connection() -> Optional[mysql.connector.connection.MySQLConnection]:
    """建立与MySQL数据库的连接（增强日志）"""
    connection = None
    try:
        connection = mysql.connector.connect(**db_config)
        if connection.is_connected():
            logging.info("Ti_judgment_db - 数据库连接成功")
            return connection
    except Error as e:
        logging.error(f"Ti_judgment_db - 数据库连接错误：错误码={e.errno}, 描述={e.msg}")
    except Exception as e:
        logging.error(f"Ti_judgment_db - 数据库连接异常：{str(e)}")
    return connection


def create_ti_judgment_table(conn: mysql.connector.connection.MySQLConnection) -> None:
    """创建Ti_judgment表（增强错误捕捉）"""
    if not conn:
        logging.error("Ti_judgment_db - 未建立数据库连接，无法创建表")
        return

    try:
        with conn.cursor() as cursor:
            sql_create_table = """
            CREATE TABLE IF NOT EXISTS Ti_judgment (
                id INT PRIMARY KEY AUTO_INCREMENT,
                phone_number VARCHAR(20) NOT NULL COMMENT '关联用户手机号',
                试卷名称 VARCHAR(255) NOT NULL COMMENT '试卷的名称',
                试卷编号 VARCHAR(50) NOT NULL COMMENT '试卷的唯一编号',
                判断题问题 TEXT NOT NULL COMMENT '判断题的问题内容',
                判断题答案 TEXT NOT NULL COMMENT '判断题的答案（对/错）',
                判断题解析 TEXT COMMENT '判断题的答案解析',
                create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
                -- 联合唯一索引：TEXT字段指定长度（兼容MySQL）
                UNIQUE KEY uk_user_paper_question (phone_number, 试卷编号, 判断题问题(200)),
                -- 索引优化
                INDEX idx_phone (phone_number),
                INDEX idx_paper_id (试卷编号)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户关联的判断题表';
            """
            cursor.execute(sql_create_table)
            logging.info("Ti_judgment_db - Ti_judgment表创建成功（或已存在）")
    except Error as e:
        logging.error(f"Ti_judgment_db - 创建Ti_judgment表失败：错误码={e.errno}, 描述={e.msg}")
    except Exception as e:
        logging.error(f"Ti_judgment_db - 创建Ti_judgment表异常：{str(e)}")


def insert_ti_judgment(
        conn: mysql.connector.connection.MySQLConnection,
        ti_judgment_data: Dict[str, str]
) -> bool:
    """
    向Ti_judgment表插入数据（增强版）
    特性：字段非空校验 + 脱敏日志 + 详细错误码 + 结果区分
    """
    # 1. 基础校验
    if not conn:
        logging.error("Ti_judgment_db - 插入失败：数据库连接为空")
        return False
    if not ti_judgment_data:
        logging.error("Ti_judgment_db - 插入失败：待插入数据为空")
        return False

    # 2. 增强字段校验（存在性 + 非空）
    required_keys = ["phone_number", "试卷名称", "试卷编号", "判断题问题", "判断题答案", "判断题解析"]
    missing_or_empty = []
    for key in required_keys:
        if key not in ti_judgment_data:
            missing_or_empty.append(f"字段不存在：{key}")
        elif not str(ti_judgment_data[key]).strip():
            missing_or_empty.append(f"字段为空：{key}（值：{ti_judgment_data[key]}）")

    if missing_or_empty:
        logging.error(f"Ti_judgment_db - 插入失败：{'; '.join(missing_or_empty)}")
        return False

    try:
        with conn.cursor() as cursor:
            sql = """
            INSERT IGNORE INTO Ti_judgment (
                phone_number,
                试卷名称,
                试卷编号,
                判断题问题,
                判断题答案,
                判断题解析
            ) VALUES (%s, %s, %s, %s, %s, %s)
            """
            # 脱敏日志：手机号隐藏中间4位
            log_data = ti_judgment_data.copy()
            if log_data.get("phone_number"):
                log_data["phone_number"] = log_data["phone_number"][:3] + "****" + log_data["phone_number"][-4:]
            logging.debug(f"Ti_judgment_db - 执行插入：{log_data}")

            cursor.execute(sql, (
                ti_judgment_data["phone_number"],
                ti_judgment_data["试卷名称"],
                ti_judgment_data["试卷编号"],
                ti_judgment_data["判断题问题"],
                ti_judgment_data["判断题答案"],
                ti_judgment_data["判断题解析"]
            ))
            conn.commit()

            # 3. 区分插入结果
            affected_rows = cursor.rowcount
            if affected_rows == 1:
                logging.info(f"Ti_judgment_db - 插入成功，记录ID：{cursor.lastrowid}")
            elif affected_rows == 0:
                logging.warning(f"Ti_judgment_db - 插入忽略：数据已存在（触发唯一索引）")
            return True

    # 4. 捕获MySQL原生错误
    except Error as e:
        logging.error(
            f"Ti_judgment_db - 插入失败：错误码={e.errno}, 描述={e.msg}; "
            f"插入数据：{log_data if 'log_data' in locals() else ti_judgment_data}"
        )
        conn.rollback()
        return False
    # 5. 捕获未知异常（含堆栈）
    except Exception as e:
        logging.error(
            f"Ti_judgment_db - 插入异常：{str(e)}; "
            f"插入数据：{log_data if 'log_data' in locals() else ti_judgment_data}",
            exc_info=True
        )
        conn.rollback()
        return False