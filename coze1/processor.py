# processor.py
from common import register_callback

# 定义处理函数
def handle_input_content(content):
    """处理从Flask接口传来的input_content"""
    print(f"另一个文件收到数据：{content}")
    # 这里写你的处理逻辑（如存储、分析等）

# 注册回调函数，让Flask文件能调用它
register_callback(handle_input_content)