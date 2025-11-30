export class JudgePaper {
  id: number = 0;               // 题目唯一ID
  paperName: string = "";       // 所属试卷名称（原judgePaperName）
  judgeQuestion: string = "";   // 判断题题干
  judgeAnswer: string = "";     // 答案（后端返回“对”/“错”，字符串类型）
  judgeExplanation: string = ""; // 答案解析
  paperId: string = "";         // 所属试卷编号（原judgePaperId）
}