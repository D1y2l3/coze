export interface BlankPaper {
  id: number;         // 题目唯一ID
  paperName: string;  // 所属试卷名称
  blankQuestion: string; // 填空题题干
  blankAnswer: string;   // 正确答案
  blankExplanation?: string; // 答案解析（可选）
  paperId: string;    // 所属试卷编号
}