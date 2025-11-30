

/**
 * 题型枚举（对应后端：choice=单选，judge=判断，fill=填空）
 */
export enum QuestionTypeEnum {
  RADIO,   // 单选（后端choice）
  JUDGE,   // 判断（后端judge）
  FILL     // 填空（后端fill）
}

/**
 * 难度枚举（按原有逻辑保留）
 */
export enum ClassificationTypeEnum {
  EASY,
  SIMPLE,
  MIDDLE,
  HARD,
  EASY_MISTAKE
}

/**
 * 题目模型（适配三种题型）
 */
@ObservedV2
export class ExamDetail {
  id: string;                  // 题目ID
  question: string;            // 题干
  questionImage: string;       // 题目图片（无则空）
  options: Array<string>;      // 选项（单选/判断有值，填空空数组）
  selected: Array<string>;     // 用户答案（单选/判断存选项，填空存输入值）
  answer: Array<string>;       // 正确答案（数组格式）
  isCorrect?: boolean;         // 是否正确
  questionType: QuestionTypeEnum; // 题型
  classificationType: ClassificationTypeEnum; // 难度
  analysis: string;            // 解析
  videoExplainUrl: string;     // 视频讲解（无则空）
  chapterName: string;         // 章节名
  isCollect: boolean;          // 是否收藏

  constructor(
    question: string,
    questionImage: string = "",
    options: Array<string> = [], // 填空默认空数组
    answer: Array<string>,
    questionType: QuestionTypeEnum,
    classificationType: ClassificationTypeEnum = ClassificationTypeEnum.MIDDLE,
    analysis: string = "无解析",
    chapterName: string = "默认章节",
    videoExplainUrl: string = "",
    id: string = new Date().getTime().toString() // 默认用时间戳生成ID
  ) {
    this.id = id;
    this.question = question;
    this.questionImage = questionImage;
    this.options = options;
    this.selected = [];
    this.answer = answer;
    this.questionType = questionType;
    this.classificationType = classificationType;
    this.analysis = analysis;
    this.videoExplainUrl = videoExplainUrl;
    this.chapterName = chapterName;
    this.isCollect = false;
  }
}

/**
 * 考卷模型（管理整体答题状态）
 */
@ObservedV2
export class ExamManager {
  id: string;                  // 考卷ID
  name: string;                // 考卷名称
  currentQuestionId: number;   // 当前题目索引（从0开始）
  total: number;               // 总题数
  timeLimit: number;           // 时间限制（分钟，0表示无限制）
  @Trace correctNumber: number;// 正确题数
  @Trace errorNumber: number;  // 错误题数
  examDetails: Array<ExamDetail>; // 题目列表

  constructor(
    name: string = "默认考卷",
    examDetails: Array<ExamDetail> = [],
    currentQuestionId: number = 0,
    timeLimit: number = 0,
    correctNumber: number = 0,
    errorNumber: number = 0
  ) {
    this.id = new Date().getTime().toString();
    this.name = name;
    this.examDetails = examDetails;
    this.currentQuestionId = currentQuestionId;
    this.timeLimit = timeLimit;
    this.correctNumber = correctNumber;
    this.errorNumber = errorNumber;
    this.total = examDetails.length;
  }

  /**
   * 清空已选答案
   */
  clearSelectedOption(): void {
    this.examDetails.forEach(item => item.selected = []);
  }

  /**
   * 清空答题记录（保留收藏）
   */
  clearRecords(): void {
    this.correctNumber = 0;
    this.errorNumber = 0;
    this.examDetails.forEach(item => {
      item.selected = [];
      item.isCorrect = undefined;
    });
  }
}