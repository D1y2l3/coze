import json
import logging
from cozepy import COZE_CN_BASE_URL, Coze, TokenAuth, Stream, WorkflowEvent, WorkflowEventType

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class CozeMiddleware:
    def __init__(self, api_token, workflow_id, base_url=COZE_CN_BASE_URL):
        """初始化Coze中间件

        Args:
            api_token: Coze API访问令牌
            workflow_id: 要调用的工作流ID
            base_url: Coze API基础地址，默认使用中国区地址
        """
        self.api_token = api_token
        self.workflow_id = workflow_id
        self.base_url = base_url
        self.coze_client = self._init_coze_client()

    def _init_coze_client(self):
        """初始化Coze客户端"""
        try:
            return Coze(auth=TokenAuth(token=self.api_token), base_url=self.base_url)
        except Exception as e:
            logger.error(f"Coze客户端初始化失败: {str(e)}")
            return None

    def process_frontend_data(self, frontend_data):
        """处理前端数据并启动工作流

        Args:
            frontend_data: 从前端接收的数据字典，应包含'content'字段

        Returns:
            工作流处理结果字典，包含success、result/error等字段
        """
        # 验证前端数据
        if not frontend_data or 'content' not in frontend_data:
            error_msg = "前端数据缺少content字段"
            logger.warning(error_msg)
            return {"success": False, "error": error_msg}

        # 提取并准备工作流输入参数
        input = frontend_data['content']
        logger.info(f"处理前端输入: {input}")

        input_parameters = {
            "input": input  # 确保与工作流开始节点的变量名一致
        }

        # 检查Coze客户端是否初始化成功
        if not self.coze_client:
            error_msg = "Coze客户端未初始化，无法启动工作流"
            logger.error(error_msg)
            return {"success": False, "error": error_msg}

        # 启动工作流并处理结果
        try:
            logger.info(f"启动工作流，ID: {self.workflow_id}")
            stream = self.coze_client.workflows.runs.stream(
                workflow_id=self.workflow_id,
                parameters=input_parameters
            )
            return self._handle_workflow_stream(stream)

        except Exception as e:
            # 捕获所有异常并判断类型
            error_str = str(e)
            if "authentication" in error_str.lower() or "token" in error_str.lower():
                error_msg = "Coze API认证失败，请检查令牌有效性"
            else:
                error_msg = f"Coze API调用错误: {error_str}"
            logger.error(error_msg)
            return {"success": False, "error": error_msg}

    def _handle_workflow_stream(self, stream: Stream[WorkflowEvent]):
        """处理工作流返回的流式事件"""
        result = []
        try:
            for event in stream:
                logger.info(f"收到工作流事件: {event.event}")

                if event.event == WorkflowEventType.MESSAGE:
                    if event.message and event.message.content:
                        logger.info(f"工作流消息: {event.message.content}")
                        result.append(event.message.content)

                elif event.event == WorkflowEventType.ERROR:
                    error_msg = f"工作流执行错误: {str(event.error)}"
                    logger.error(error_msg)
                    return {"success": False, "error": error_msg}

                elif event.event == WorkflowEventType.INTERRUPT:
                    interrupt_msg = "工作流需要补充信息才能继续"
                    logger.warning(interrupt_msg)
                    return {
                        "success": False,
                        "error": interrupt_msg,
                        "interrupt": True,
                        "event_id": event.interrupt.interrupt_data.event_id
                    }

                elif event.event == WorkflowEventType.FINISHED:
                    logger.info("工作流执行完成")
                    break

        except Exception as e:
            error_msg = f"处理工作流事件时出错: {str(e)}"
            logger.error(error_msg)
            return {"success": False, "error": error_msg}

        return {"success": True, "result": "\n".join(result)}
