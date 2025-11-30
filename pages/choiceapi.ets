




import { ChoicePaper } from './choice'; // 导入选择题类

// 定义选择题API响应结构
export interface ApiResponse {
  code: number;
  message?: string; // 可选的消息字段（如成功/错误提示）
  data: ChoicePaper[]; // 数据字段改为选择题数组
}