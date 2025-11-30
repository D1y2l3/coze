import mysql.connector
from mysql.connector import Error
from typing import Optional, Dict
import logging  # 新增日志导入，与主程序日志统一

# 数据库配置
db_config = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "123456",
    "database": "exam_db5"
}


def create_connection() -> Optional[mysql.connector.connection.MySQLConnection]:
    """建立与MySQL数据库的连接"""
    connection = None
    try:
        connection = mysql.connector.connect(**db_config)
        if connection.is_connected():
            logging.info("Ti_choose_db - 数据库连接成功")
            return connection
    except Error as e:
        logging.error(f"Ti_choose_db - 数据库连接错误：错误码={e.errno}, 描述={e.msg}")
    except Exception as e:
        logging.error(f"Ti_choose_db - 数据库连接异常：{str(e)}")
    return connection


def create_ti_choose_table(connection: mysql.connector.connection.MySQLConnection) -> None:
    """创建Ti_choose表（适配新字段：试卷名称、试卷编号等）"""
    if not connection:
        logging.error("Ti_choose_db - 未建立数据库连接，无法创建表")
        return

    try:
        # 使用上下文管理器自动关闭cursor
        with connection.cursor() as cursor:
            create_table_sql = """
            CREATE TABLE IF NOT EXISTS Ti_choose (
                id INT AUTO_INCREMENT PRIMARY KEY,
                phone_number VARCHAR(20) NOT NULL COMMENT '关联用户手机号',
                试卷名称 VARCHAR(255) NOT NULL COMMENT '试卷的名称',
                试卷编号 VARCHAR(50) NOT NULL COMMENT '试卷唯一编号',
                选择题问题 TEXT NOT NULL COMMENT '选择题的问题内容',
                选择题选项 TEXT COMMENT '选择题的选项（如A.xxx; B.xxx）',
                选择题答案 VARCHAR(10) NOT NULL COMMENT '选择题的正确答案',
                选择题解析 TEXT COMMENT '选择题的答案解析',
                create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
                -- 联合唯一索引：为TEXT字段指定长度（兼容MySQL）
                UNIQUE KEY uk_user_paper_question (phone_number, 试卷编号, 选择题问题(200)),
                -- 索引优化查询
                INDEX idx_phone (phone_number),
                INDEX idx_paper_id (试卷编号)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户关联的选择题表（含试卷信息）';
            """
            cursor.execute(create_table_sql)
            logging.info("Ti_choose_db - Ti_choose表创建成功（或已存在）")
    except Error as e:
        logging.error(f"Ti_choose_db - 创建Ti_choose表失败：错误码={e.errno}, 描述={e.msg}")
    except Exception as e:
        logging.error(f"Ti_choose_db - 创建Ti_choose表异常：{str(e)}")


def insert_ti_choose(
        connection: mysql.connector.connection.MySQLConnection,
        ti_choose_data: Dict[str, str]
) -> bool:
    """
    向Ti_choose表插入数据（使用INSERT IGNORE避免重复，接收字典类型数据）
    增强：字段非空校验 + 详细错误信息输出
    """
    # 1. 基础校验：连接和数据是否存在
    if not connection:
        logging.error("Ti_choose_db - 插入失败：数据库连接为空")
        return False
    if not ti_choose_data:
        logging.error("Ti_choose_db - 插入失败：待插入数据为空")
        return False

    # 2. 增强校验：必要字段是否存在且非空
    required_keys = ["phone_number", "试卷名称", "试卷编号", "选择题问题", "选择题选项", "选择题答案", "选择题解析"]
    missing_or_empty_keys = []
    for key in required_keys:
        # 检查键是否存在 + 值是否为非空（去除首尾空格）
        if key not in ti_choose_data:
            missing_or_empty_keys.append(f"字段不存在：{key}")
        elif not str(ti_choose_data[key]).strip():
            missing_or_empty_keys.append(f"字段为空：{key}（值：{ti_choose_data[key]}）")

    if missing_or_empty_keys:
        logging.error(f"Ti_choose_db - 插入失败：{'; '.join(missing_or_empty_keys)}")
        return False

    try:
        with connection.cursor() as cursor:
            sql = ''' 
            INSERT IGNORE INTO Ti_choose(
                phone_number,
                试卷名称, 
                试卷编号, 
                选择题问题, 
                选择题选项, 
                选择题答案, 
                选择题解析
            ) VALUES(%s, %s, %s, %s, %s, %s, %s) 
            '''
            # 打印插入数据（脱敏手机号，仅保留前3后4位）
            log_data = ti_choose_data.copy()
            if log_data.get("phone_number"):
                log_data["phone_number"] = log_data["phone_number"][:3] + "****" + log_data["phone_number"][-4:]
            logging.debug(f"Ti_choose_db - 执行插入：{log_data}")

            cursor.execute(sql, (
                ti_choose_data["phone_number"],
                ti_choose_data["试卷名称"],
                ti_choose_data["试卷编号"],
                ti_choose_data["选择题问题"],
                ti_choose_data["选择题选项"],
                ti_choose_data["选择题答案"],
                ti_choose_data["选择题解析"]
            ))
            connection.commit()

            # 打印插入结果（受影响行数：0=重复，1=新增）
            affected_rows = cursor.rowcount
            if affected_rows == 1:
                logging.info(f"Ti_choose_db - 插入成功，记录ID：{cursor.lastrowid}")
            elif affected_rows == 0:
                logging.warning(f"Ti_choose_db - 插入忽略：数据已存在（触发唯一索引）")
            return True

    # 3. 捕获MySQL具体错误（含错误码）
    except Error as e:
        logging.error(
            f"Ti_choose_db - 插入失败：错误码={e.errno}, 描述={e.msg}; "
            f"插入数据：{log_data if 'log_data' in locals() else ti_choose_data}"
        )
        connection.rollback()
        return False
    # 4. 捕获其他未知异常
    except Exception as e:
        logging.error(
            f"Ti_choose_db - 插入异常：{str(e)}; "
            f"插入数据：{log_data if 'log_data' in locals() else ti_choose_data}",
            exc_info=True  # 打印完整堆栈信息
        )
        connection.rollback()
        return False