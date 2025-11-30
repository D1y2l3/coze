export interface JudgePaper {
  id: number;
  paperName: string;
  judgeQuestion: string;
  judgeAnswer: string; // 字段值为“对”或“错”（无句号）
  judgeExplanation: string;
  paperId: string;
}