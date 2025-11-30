import pymysql
from pymysql import OperationalError, ProgrammingError
from dotenv import load_dotenv
import os
from exam_processor_choose import process_exam_data, RAW_EXAM_DATA

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
    """创建试题表结构（表名改为 exam_choose）"""
    try:

        sql_create_table = """CREATE TABLE IF NOT EXISTS exam_choose (
                            id INT PRIMARY KEY AUTO_INCREMENT,
                            试卷名称 TEXT,
                            试卷编号 TEXT,
                            选择题问题 TEXT,
                            选择题选项 TEXT,
                            选择题答案 TEXT,
                            选择题解析 TEXT
                          );"""
        with conn.cursor() as cursor:

            cursor.execute(sql_create_table)
            # 改用DESCRIBE检查字段
            try:
                cursor.execute("DESCRIBE exam_choose create_time")
            except ProgrammingError:
                cursor.execute("""
                              ALTER TABLE exam_choose 
                              ADD COLUMN create_time DATETIME DEFAULT CURRENT_TIMESTAMP;
                          """)
                print("已为exam_choose表添加create_time字段")
        conn.commit()
        print("表 exam_choose 创建成功（或已存在）")
    except ProgrammingError as e:
        print(f"创建表错误: {e}")
        conn.rollback()


def insert_exam(conn, exam_data):
    """插入单条试题数据（表名同步改为 exam_choose）"""
    try:
        # 核心修改：插入的表名从 python_exams 改为 exam_choose
        sql = ''' INSERT INTO exam_choose(
                    试卷名称, 
                    试卷编号, 
                    选择题问题, 
                    选择题选项, 
                    选择题答案, 
                    选择题解析
                  )
                  VALUES(%s, %s, %s, %s, %s, %s) '''
        with conn.cursor() as cursor:
            cursor.execute(sql, (
                exam_data["试卷名称"],
                exam_data["试卷编号"],
                exam_data["选择题问题"],
                exam_data["选择题选项"],
                exam_data["选择题答案"],
                exam_data["选择题解析"]
            ))
        conn.commit()
        return cursor.lastrowid
    except Exception as e:
        print(f"插入数据错误: {e}")
        conn.rollback()
        return None



def insert_ti_choose(conn, ti_choose_data):
    """插入数据到 Ti_choose 表（需传入手机号+试题数据）"""
    try:
        sql = ''' INSERT IGNORE INTO Ti_choose(
                    phone_number,
                    试卷名称, 
                    试卷编号, 
                    选择题问题, 
                    选择题选项, 
                    选择题答案, 
                    选择题解析
                  )
                  VALUES(%s, %s, %s, %s, %s, %s, %s) '''
        with conn.cursor() as cursor:
            cursor.execute(sql, (
                ti_choose_data["phone_number"],  # 手机号
                ti_choose_data["试卷名称"],
                ti_choose_data["试卷编号"],
                ti_choose_data["选择题问题"],
                ti_choose_data["选择题选项"],
                ti_choose_data["选择题答案"],
                ti_choose_data["选择题解析"]
            ))
        conn.commit()
        # 返回插入成功的ID（若重复插入则返回0，因使用INSERT IGNORE）
        return cursor.lastrowid if cursor.rowcount > 0 else 0
    except Exception as e:
        print(f"插入 Ti_choose 数据错误: {e}")
        conn.rollback()
        return None


def get_latest_10_chooses(conn):
    """查询 exam_choose 表中最新的10道选择题（按 create_time 倒序）"""
    try:
        sql = ''' SELECT 试卷名称, 试卷编号, 选择题问题, 选择题选项, 选择题答案, 选择题解析
                  FROM exam_choose
                  ORDER BY create_time DESC
                  LIMIT 10 '''
        with conn.cursor() as cursor:
            cursor.execute(sql)
            # 返回字典格式的结果（因cursorclass是DictCursor）
            return cursor.fetchall()
    except Exception as e:
        print(f"查询最新10道选择题错误: {e}")
        return None



def create_ti_choose_table(conn):
    """创建Ti_choose表（存储最新10道选择题，关联用户手机号）"""
    try:
        sql = """
        CREATE TABLE IF NOT EXISTS Ti_choose (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone_number TEXT NOT NULL,  -- 关联用户手机号
            question TEXT NOT NULL,      -- 题目内容
            optionA TEXT NOT NULL,       -- 选项A
            optionB TEXT NOT NULL,       -- 选项B
            optionC TEXT NOT NULL,       -- 选项C
            optionD TEXT NOT NULL,       -- 选项D
            answer TEXT NOT NULL,        -- 正确答案
            explanation TEXT,            -- 解析
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- 创建时间
        );
        """
        cursor = conn.cursor()
        cursor.execute(sql)
        conn.commit()
        print("Ti_choose表创建成功或已存在")
    except Exception as e:
        print(f"创建Ti_choose表失败: {str(e)}")

def main():
    """主函数：协调数据处理和入库流程"""
    processed_data = process_exam_data(RAW_EXAM_DATA)
    if not processed_data:
        print("数据处理失败，无法继续入库")
        return

    conn = create_connection()
    if conn:
        create_table(conn)  # 会创建 exam_choose 表

        for item in processed_data:
            exam_id = insert_exam(conn, item)  # 数据存入 exam_choose 表
            if exam_id:
                print(f"成功插入试题到 exam_choose 表，ID: {exam_id}")

        conn.close()
        print("\n所有试题已成功存入 exam_choose 表！")
    else:
        print("无法建立数据库连接")


if __name__ == "__main__":
    main()