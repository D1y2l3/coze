import { JudgePaper } from './judge'; // 导入判断题类（路径根据实际文件位置调整）

// 定义判断题API响应结构（与其他题型保持一致的格式）
export interface JudgeApiResponse {
  code: number; // 业务状态码（200=成功，404=未找到等）
  message?: string; // 可选的消息提示（成功/错误说明）
  data: JudgePaper[]; // 数据字段为判断题数组（对应后端返回的判断题列表）
}