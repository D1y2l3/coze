import json


def process_judgment_data(raw_data):
    """
    处理原始JSON数据，提取数据库判断题所需字段
    :param raw_data: 原始JSON字符串
    :return: 结构化的判断题数据列表
    """
    try:
        # 处理转义字符问题
        processed_data = raw_data.replace('\\\\', '\\')

        # 解析JSON数据
        judgment_list = json.loads(processed_data)

        # 提取所需字段
        result = []
        for judgment in judgment_list:
            extracted = {
                "试卷名称": judgment.get("试卷名称", ""),
                "试卷编号": judgment.get("试卷编号", ""),
                "判断题问题": judgment.get("判断题问题", ""),
                "判断题答案": judgment.get("判断题答案", ""),
                "判断题解析": judgment.get("判断题解析", "")
            }
            result.append(extracted)

        return result

    except json.JSONDecodeError as e:
        print(f"JSON解析错误: {e}")
        return []
    except Exception as e:
        print(f"数据处理错误: {e}")
        return []


# 原始判断题数据（保持不变）
RAW_JUDGMENT_DATA = "[{\"判断题答案\":\"错。\",\"判断题解析\":\"数据库管理系统（DBMS）是位于用户与操作系统之间的一层数据管理软件，并非操作系统。它负责对数据库进行统一的管理和控制，而操作系统是管理计算机硬件与软件资源的计算机程序。\",\"判断题问题\":\"数据库管理系统（DBMS）是一种操作系统，用于管理数据库。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"错。\",\"判断题解析\":\"在关系数据库中，主键是唯一标识表中每一行记录的字段或字段组合，一个表只能有一个主键，但主键可以由多个字段组成（复合主键）。\",\"判断题问题\":\"关系数据库中的主键可以有多个。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"错。\",\"判断题解析\":\"SQL 语言中的 SELECT 语句不仅可以用于查询单表数据，还可以通过连接操作查询多表数据，也能进行子查询等复杂的查询操作。\",\"判断题问题\":\"SQL 语言中的 SELECT 语句只能用于查询单表数据。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"对。\",\"判断题解析\":\"事务是数据库中不可分割的操作序列，具有原子性（要么全部执行，要么全部不执行）、一致性（事务执行前后数据库的状态保持一致）、隔离性（多个事务并发执行时相互不干扰）和持久性（事务一旦提交，其对数据库的修改是永久性的）。\",\"判断题问题\":\"数据库中的事务具有原子性、一致性、隔离性和持久性。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"错。\",\"判断题解析\":\"外模式是用户与数据库系统的接口，一个数据库可以有多个外模式，不同的用户或应用程序可以根据自己的需求定义不同的外模式，以满足不同的使用要求。\",\"判断题问题\":\"数据库的外模式是用户与数据库系统的接口，一个数据库只能有一个外模式。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"对。\",\"判断题解析\":\"在数据库设计过程中，E - R 图（实体 - 联系图）主要用于概念设计阶段，它可以将现实世界中的事物抽象为实体、属性和联系，为后续的逻辑设计和物理设计提供基础。\",\"判断题问题\":\"在数据库设计中，E - R 图是概念设计阶段的工具。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"错。\",\"判断题解析\":\"数据库的索引主要是为了提高数据的查询效率，因为索引可以帮助数据库快速定位到所需的数据。但索引会增加数据插入、删除和更新操作的开销，因为在进行这些操作时，需要同时维护索引。\",\"判断题问题\":\"数据库的索引可以提高数据的插入、删除和更新操作的效率。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"对。\",\"判断题解析\":\"视图是从一个或多个表中导出的虚拟表，它本身不实际存储数据，只是存储了查询定义。当查询视图时，数据库会根据视图的定义从基表中获取数据。\",\"判断题问题\":\"视图是一种虚拟表，它不实际存储数据。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"对。\",\"判断题解析\":\"数据库的完整性约束是一组规则，用于保证数据库中数据的准确性、一致性和有效性。常见的完整性约束包括实体完整性、参照完整性和用户定义的完整性。\",\"判断题问题\":\"数据库的完整性约束是为了保证数据库中数据的准确性和一致性。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"},{\"判断题答案\":\"错。\",\"判断题解析\":\"数据库的并发控制主要是为了保证多个事务并发执行时数据的一致性和正确性，避免出现数据不一致的问题，如丢失更新、脏读、不可重复读等，而不是为了提高数据库的访问速度。\",\"判断题问题\":\"数据库的并发控制主要是为了提高数据库的访问速度。（ ）\",\"试卷名称\":\"生成关于数据库的试题\",\"试卷编号\":\"https://lf26-appstore-sign.oceancloudapi.com/ocean-cloud-tos/ec459c6c-484d-42a2-ab75-c69cda56444d.html?lk3s=edeb9e45&x-expires=1755066940&x-signature=4NCySmBytr70gybcRvJeRFPAjCU%3D\"}]"

