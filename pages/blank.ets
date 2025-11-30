// 填空题数据模型（与后端字段完全对齐，使用interface强调数据契约）
export interface BlankPaper {
  id: number;         // 题目唯一ID（与后端数据库id对应）
  paperName: string;  // 所属试卷名称
  blankQuestion: string; // 填空题题干（如"Python的创始人是______"）
  blankAnswer: string;   // 正确答案
  blankExplanation: string; // 答案解析
  paperId: string;    // 所属试卷编号
}