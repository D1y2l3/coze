import os
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType
from workflow_classifier import WorkflowOutputClassifier
from common import register_callback  # 导入你的回调注册函数

# Coze配置
coze_api_token = 'cztei_htpqzfVbgW3anKOvM9EJL3qV3oDG9v6RyJYPSYNJC1mvUtFxNIoKKH3LWGg2EpHnN'
coze_api_base = COZE_CN_BASE_URL
workflow_id = '7537788037603426354'

# 初始化Coze客户端
coze = Coze(auth=TokenAuth(token=coze_api_token), base_url=coze_api_base)


def process_content(content):
    """
    处理从回调接收的content
    - 将content作为input参数传入工作流
    - 将分类结果作为input1-input3传入工作流
    """
    print(f"通过回调收到content：{content}")

    # 1. 调用分类工具处理content
    classify_result = WorkflowOutputClassifier.classify(content)
    if not classify_result["success"]:
        print(f"分类失败: {classify_result['error']}")
        return

    classified_data = classify_result["data"]

    # 2. 构建工作流参数（核心映射）
    input_parameters = {
        "input": content,  # 回调传来的content赋值给input
        "input1": classified_data.get("output1_1", ""),  # 分类结果1
        "input2": classified_data.get("output2_2", ""),  # 分类结果2
        "input3": classified_data.get("output3_3", "")  # 分类结果3
    }
    print("工作流输入参数:", input_parameters)

    # 3. 调用工作流
    stream = coze.workflows.runs.stream(
        workflow_id=workflow_id,
        parameters=input_parameters
    )
    handle_workflow_events(stream)


# 注册回调函数到common.py（关键步骤）
register_callback(process_content)


def handle_workflow_events(stream: Stream[WorkflowEvent]):
    """处理工作流返回的事件"""
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            print(event.message)  # 打印原始消息
        elif event.event == WorkflowEventType.ERROR:
            print("工作流错误:", event.error)
        elif event.event == WorkflowEventType.INTERRUPT:
            print("工作流中断，尝试恢复...")
            handle_workflow_events(
                coze.workflows.runs.resume(
                    workflow_id=workflow_id,
                    event_id=event.interrupt.interrupt_data.event_id,
                    resume_data="",
                    interrupt_type=event.interrupt.interrupt_data.type,
                )
            )
