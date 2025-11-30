import { BlankPaper } from './blank'; // 导入修改后的填空题接口

// 定义填空题API响应结构（与选择题、判断题保持一致的格式）
export interface BlankApiResponse {
  data: BlankPaper[]; // 数据字段为填空题数组
  message: string;    // 消息提示（成功/错误说明）
}