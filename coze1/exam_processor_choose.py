import json


def process_exam_data(raw_data):
    """解析原始JSON数据，提取所需字段"""
    try:
        # 处理转义字符
        processed_data = raw_data.replace('\\\\', '\\')
        exam_list = json.loads(processed_data)

        # 提取字段
        result = []
        for exam in exam_list:
            extracted = {
                "试卷名称": exam.get("试卷名称", ""),
                "试卷编号": exam.get("试卷编号", ""),
                "选择题问题": exam.get("选择题问题", ""),
                "选择题选项": exam.get("选择题选项", ""),
                "选择题答案": exam.get("选择题答案", ""),
                "选择题解析": exam.get("选择题解析", "")
            }
            result.append(extracted)
        return result

    except json.JSONDecodeError as e:
        print(f"JSON解析错误: {e}")
        return []
    except Exception as e:
        print(f"数据处理错误: {e}")
        return []


# 原始数据（必须定义，供导入）
RAW_EXAM_DATA = "[{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"B\",\"选择题解析\":\"在Python中，使用def关键字来创建函数。function在Python中不是创建函数的关键字；create和make也不是用于创建函数的关键字。所以选B。\",\"选择题选项\":\"A. function B. def C. create D. make\",\"选择题问题\":\"以下哪个是Python中用于创建函数的关键字？\"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"C\",\"选择题解析\":\"在Python中，list = []和list = list()都可以正确定义一个空列表。[]是列表的字面量表示法，list()是使用内置的list函数创建空列表。所以选C。\",\"选择题选项\":\"A. list = [] B. list = list() C. 以上两种方式都可以 D. 以上两种方式都不可以\",\"选择题问题\":\"在Python中，以下哪种方式可以正确定义一个空列表？\"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"B\",\"选择题解析\":\"根据Python的运算符优先级，先计算乘法再计算加法。3 * 2 = 6，然后5 + 6 = 11。所以变量x的值是11，选B。\",\"选择题选项\":\"A. 16 B. 11 C. 10 D. 26\",\"选择题问题\":\"执行以下代码后，变量x的值是？x = 5 + 3 * 2  \"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"A\",\"选择题解析\":\"在Python中，布尔值只有True和False。Yes、On和1都不是Python中的布尔值。所以选A。\",\"选择题选项\":\"A. True B. Yes C. On D. 1\",\"选择题问题\":\"以下哪个是Python中的布尔值？\"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"B\",\"选择题解析\":\"在Python中，'r'模式用于只读打开文件；'w'模式用于写入文件，如果文件存在则清空内容，如果不存在则创建新文件；'a'模式用于追加写入文件；'x'模式用于创建新文件并写入，如果文件已存在则报错。所以要打开一个文件进行写入操作，应使用'w'模式，选B。\",\"选择题选项\":\"A. 'r' B. 'w' C. 'a' D. 'x'\",\"选择题问题\":\"在Python中，要打开一个文件进行写入操作，应该使用以下哪种模式？\"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"B\",\"选择题解析\":\"字符串的切片操作s[1:3]表示从索引1（包含）到索引3（不包含）的子字符串。s = \\\"Hello\\\"，索引1的字符是e，索引2的字符是l，所以s[1:3]的结果是el，选B。\",\"选择题选项\":\"A. He B. el C. ll D. lo\",\"选择题问题\":\"以下代码的输出结果是？s = \\\"Hello\\\"  print(s[1:3])  \"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"C\",\"选择题解析\":\"在Python中，元组（tuple）是不可变的数据结构，一旦创建就不能修改其元素。列表（list）、字典（dict）和集合（set）都是可变的数据结构。所以选C。\",\"选择题选项\":\"A. 列表（list） B. 字典（dict） C. 元组（tuple） D. 集合（set）\",\"选择题问题\":\"Python中，以下哪个数据结构是不可变的？\"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"C\",\"选择题解析\":\"选项A中使用for i in range(len(my_list))结合索引来遍历列表；选项B中使用for item in my_list直接遍历列表中的元素。两种方式都可以正确遍历列表。所以选C。\",\"选择题选项\":\"A. my_list = [1, 2, 3]  for i in range(len(my_list)):  print(my_list[i])  B. my_list = [1, 2, 3]  for item in my_list:  print(item)  C. 以上两种方式都可以 D. 以上两种方式都不可以\",\"选择题问题\":\"要遍历一个列表中的元素，以下哪种方式是正确的？\"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"B\",\"选择题解析\":\"在Python中，b = a是将b指向与a相同的列表对象。所以当b.append(4)时，实际上是对同一个列表进行操作，a和b都指向这个列表，因此a也会变成[1, 2, 3, 4]。所以选B。\",\"选择题选项\":\"A. [1, 2, 3] B. [1, 2, 3, 4] C. [4] D. 报错\",\"选择题问题\":\"以下代码的输出结果是？a = [1, 2, 3]  b = a  b.append(4)  print(a)  \"},{\"试卷名称\":\"生成关于python语言的试题\",\"试卷编号\":\"https://lf6-appstore-sign.oceancloudapi.com/ocean-cloud-tos/b9b22076-6444-4230-a086-34bc411e0b06.html?lk3s=edeb9e45&x-expires=1755119721&x-signature=icNHJF2LxdqxvlRn46%2B1iEyEaB0%3D\",\"选择题答案\":\"C\",\"选择题解析\":\"int()函数用于将一个字符串或数字转换为整数；str()函数用于将其他类型的数据转换为字符串；float()函数用于将其他类型的数据转换为浮点数；Python中没有convert()函数。所以选C。\",\"选择题选项\":\"A. str() B. float() C. int() D. convert()\",\"选择题问题\":\"在Python中，要将一个字符串转换为整数，应该使用以下哪个函数？\"}]"
