import json


def process_blank_data(raw_data):
    """
    处理原始JSON数据，提取填空题所需字段
    :param raw_data: 原始JSON字符串
    :return: 结构化的填空题数据列表
    """
    try:
        # 处理转义字符问题
        processed_data = raw_data.replace('\\\\', '\\')

        # 解析JSON数据
        blank_list = json.loads(processed_data)

        # 提取所需字段
        result = []
        for blank in blank_list:
            extracted = {
                "试卷名称": blank.get("试卷名称", ""),
                "试卷编号": blank.get("试卷编号", ""),
                "填空题问题": blank.get("填空题问题", ""),
                "填空题答案": blank.get("填空题答案", ""),
                "填空题解析": blank.get("填空题解析", "")
            }
            result.append(extracted)

        return result

    except json.JSONDecodeError as e:
        print(f"JSON解析错误: {e}")
        return []
    except Exception as e:
        print(f"数据处理错误: {e}")
        return []

RAW_BLANK_DATA = ""



