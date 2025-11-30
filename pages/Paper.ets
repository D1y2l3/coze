export interface Paper {
  id?: number; // 数据库自增ID
  name: string; // 试卷名称
  createTime?: number; // 创建时间戳
  description?: string; // 试卷描述
}