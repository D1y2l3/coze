// 定义选项的接口
export interface ChoiceOptions {  // 注意需要导出接口供其他文件使用
  A: string;
  B: string;
  C: string;
  D: string;
}
// 选择题试卷类（添加id属性）
export class ChoicePaper {
  // 新增id属性（用于唯一标识选择题，与后端数据对应）
  id: number = 0;  // 通常为数字类型的自增ID

  // 选择题题干
  choiceQuestion: string = "";

  // 选项（使用ChoiceOptions接口）
  choiceOptions: ChoiceOptions = { A: "", B: "", C: "", D: "" };

  // 正确答案
  choiceAnswer: string = "";

  // 答案解析
  choiceExplanation: string = "";

  // 试卷名称
  choicePaperName: string = "";

  // 试卷编号
  paperId: string = "";
}
