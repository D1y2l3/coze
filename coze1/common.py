# common.py
_callback = None

def register_callback(func):
    """注册回调函数"""
    global _callback
    _callback = func
    return func

def get_callback():
    """获取已注册的回调函数"""
    return _callback