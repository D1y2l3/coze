import json
from typing import Dict, Any


class WorkflowOutputClassifier:
    """工作流输出结果分类器，用于提取 output1_1、output2_2、output3_3 字段"""

    @staticmethod
    def classify(content_str: str) -> Dict[str, Any]:
        try:
            content_dict = json.loads(content_str)
            classified_data = {
                "output1_1": content_dict.get("output1_1", "未获取到output1_1数据"),
                "output2_2": content_dict.get("output2_2", "未获取到output2_2数据"),
                "output3_3": content_dict.get("output3_3", "未获取到output3_3数据")
            }
            return {
                "success": True,
                "data": classified_data,
                "error": ""
            }
        except json.JSONDecodeError:
            return {
                "success": False,
                "data": None,
                "error": f"JSON解析失败：输入内容不是有效的JSON格式"
            }
        except Exception as e:
            return {
                "success": False,
                "data": None,
                "error": f"分类处理失败：{str(e)}"
            }