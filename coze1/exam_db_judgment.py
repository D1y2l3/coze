import pymysql
from pymysql import OperationalError, ProgrammingError
from dotenv import load_dotenv
import os
from exam_processor_judgment import process_judgment_data, RAW_JUDGMENT_DATA  # 导入分类模块

# 加载.env配置文件
load_dotenv()


def create_connection():
    """创建MySQL数据库连接（从.env读取配置）"""
    try:
        conn = pymysql.connect(
            host=os.getenv("DB_HOST"),
            port=int(os.getenv("DB_PORT")),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            db=os.getenv("DB_NAME"),
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor
        )
        print("MySQL数据库连接成功")
        return conn
    except OperationalError as e:
        print(f"数据库连接失败: {e}")
        return None


def create_table(conn):
    """创建判断题表结构（表名：exam_judgment）"""
    try:
        sql_create_table = """CREATE TABLE IF NOT EXISTS exam_judgment (
                            id INT PRIMARY KEY AUTO_INCREMENT,
                            试卷名称 TEXT,
                            试卷编号 TEXT,
                            判断题问题 TEXT,
                            判断题答案 TEXT,
                            判断题解析 TEXT
                          );"""
        with conn.cursor() as cursor:
            cursor.execute(sql_create_table)
            # 改用DESCRIBE检查字段是否存在（避免依赖information_schema）
            try:
                # 尝试查询字段，若不存在会抛出异常
                cursor.execute("DESCRIBE exam_judgment create_time")
            except ProgrammingError:
                # 字段不存在，执行添加
                cursor.execute("""
                              ALTER TABLE exam_judgment 
                              ADD COLUMN create_time DATETIME DEFAULT CURRENT_TIMESTAMP;
                          """)
                print("已为exam_judgment表添加create_time字段")
        conn.commit()
        print("表 exam_judgment 创建成功（或已存在）")
    except ProgrammingError as e:
        print(f"创建表错误: {e}")
        conn.rollback()


def insert_judgment(conn, judgment_data):
    """插入单条判断题数据到 exam_judgment 表"""
    try:
        sql = ''' INSERT INTO exam_judgment(
                    试卷名称, 
                    试卷编号, 
                    判断题问题, 
                    判断题答案, 
                    判断题解析
                  )
                  VALUES(%s, %s, %s, %s, %s) '''  # MySQL占位符
        with conn.cursor() as cursor:
            cursor.execute(sql, (
                judgment_data["试卷名称"],
                judgment_data["试卷编号"],
                judgment_data["判断题问题"],
                judgment_data["判断题答案"],
                judgment_data["判断题解析"]
            ))
        conn.commit()
        return cursor.lastrowid  # 返回自增ID
    except Exception as e:
        print(f"插入数据错误: {e}")
        conn.rollback()
        return None


def main():
    """主函数：协调数据处理和入库流程"""
    # 1. 处理数据
    processed_data = process_judgment_data(RAW_JUDGMENT_DATA)
    if not processed_data:
        print("数据处理失败，无法继续入库")
        return

    # 2. 连接数据库并插入数据
    conn = create_connection()
    if conn:
        # 创建表
        create_table(conn)

        # 插入所有数据
        for item in processed_data:
            judgment_id = insert_judgment(conn, item)
            if judgment_id:
                print(f"成功插入判断题，ID: {judgment_id}")

        # 关闭连接
        conn.close()
        print("\n所有判断题已成功存入 exam_judgment 表！")
    else:
        print("无法建立数据库连接")


if __name__ == "__main__":
    main()