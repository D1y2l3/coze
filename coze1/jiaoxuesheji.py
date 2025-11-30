import os
from cozepy import COZE_CN_BASE_URL
from cozepy import Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

# 初始化参数（替换为你的实际信息）
coze_api_token = 'pat_ObtKbqWHYEimyO5jeQqxEfigFjAl8wXoqezh0FDtPOYDKjARpP9QKTqvXafTSJIN'
coze_api_base = COZE_CN_BASE_URL
workflow_id = '7553477857655291955'

# 初始化Coze客户端
coze = Coze(auth=TokenAuth(token=coze_api_token), base_url=coze_api_base)

def handle_workflow_iterator(stream: Stream[WorkflowEvent]):
    for event in stream:
        if event.event == WorkflowEventType.MESSAGE:
            print("收到消息:", event.message)
        elif event.event == WorkflowEventType.ERROR:
            print("发生错误:", event.error)
        elif event.event == WorkflowEventType.INTERRUPT:
            # 处理中断时的交互
            handle_workflow_iterator(
                coze.workflows.runs.resume(
                    workflow_id=workflow_id,
                    event_id=event.interrupt.interrupt_data.event_id,
                    resume_data="继续的内容",  # 中断时的输入
                    interrupt_type=event.interrupt.interrupt_data.type,
                )
            )

# 启动工作流并传入初始字符串（修改参数名为parameters）
initial_input = "生成关于python算法的大纲"
handle_workflow_iterator(
    coze.workflows.runs.stream(
        workflow_id=workflow_id,
        parameters={"input": initial_input}  # 用parameters参数传递
    )
)