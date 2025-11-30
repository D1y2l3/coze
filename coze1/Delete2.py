import pymysql
from pymysql import OperationalError, ProgrammingError

# 数据库配置信息
DB_CONFIG = {
    "host": "localhost",
    "user": "root",  # 替换为你的数据库用户名
    "password": "123456",  # 替换为你的数据库密码
    "database": "exam_db5",  # 替换为你的数据库名称
    "port": 3306,
    "charset": "utf8mb4"
}


def delete_homework_1to3_data():
    conn = None
    cursor = None
    try:
        # 建立数据库连接
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # 提示用户确认删除操作
        confirm = input("即将删除homework表中id为1-3的数据，此操作不可逆！请确认是否执行？(y/n): ")
        if confirm.lower() != 'y':
            print("操作已取消")
            return

        # 执行删除SQL
        sql = "DELETE FROM homework WHERE id BETWEEN 1 AND 3"
        affected_rows = cursor.execute(sql)
        conn.commit()  # 提交事务

        print(f"成功删除{affected_rows}条数据（id为1-3的记录）")

    except OperationalError as e:
        print(f"数据库连接/操作异常: {e}")
        if conn:
            conn.rollback()  # 回滚事务
    except ProgrammingError as e:
        print(f"SQL语法/表结构异常: {e}")
        if conn:
            conn.rollback()
    except Exception as e:
        print(f"未知异常: {e}")
        if conn:
            conn.rollback()
    finally:
        # 关闭游标和连接
        if cursor:
            cursor.close()
        if conn:
            conn.close()


if __name__ == "__main__":
    delete_homework_1to3_data()