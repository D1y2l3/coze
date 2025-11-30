// choice.ets
interface GeneratedTypeLiteralInterface_1 {
  A: string;
  B: string;
  C: string;
  D: string;
}

export interface ChoicePaper {
  id: number;
  choiceQuestion: string; // 题干
  choiceOptions: GeneratedTypeLiteralInterface_1;
  choiceAnswer: string;   // 正确答案
  choiceExplanation: string; // 答案解析

}