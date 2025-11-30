// 1. 补充依赖导入（SwiperController来自滑动组件库，Trace来自UI状态追踪库）
import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';

import { ExamDetail, ExamManager, QuestionTypeEnum, ClassificationTypeEnum } from '../model/QuestionAnswerRecord';

// 2. 基础配置与工具函数（URL保持为http://10.19.81.228:5001/api）
export const BACKEND_URL: string = 'http://10.19.16.227:5001/api';

/**
 * 工具方法：将ArrayBuffer转换为字符串（处理二进制响应）
 * @param buffer - 二进制响应数据
 * @returns 转换后的字符串
 */
export function arrayBufferToString(buffer: ArrayBuffer): string {
  const uint8Array = new Uint8Array(buffer);
  let result = '';
  for (let i = 0; i < uint8Array.length; i++) {
    result += String.fromCharCode(uint8Array[i]);
  }
  return result;
}

/**
 * 通用网络请求工具函数（双泛型实现，无any类型）
 * @param TData - 请求体数据类型
 * @param TResponse - 响应数据类型
 * @param url - 请求地址
 * @param method - 请求方法（GET/POST）
 * @param data - 请求体（可选）
 * @returns 类型化的响应数据
 */
async function requestHttp<TData, TResponse>(
  url: string,
  method: http.RequestMethod,
  data?: TData
): Promise<TResponse> {
  const httpRequest: http.HttpRequest = http.createHttp();

  try {
    // 构造请求配置（严格匹配HttpRequestOptions类型）
    const requestConfig: http.HttpRequestOptions = {
      method: method,
      header: { 'Content-Type': 'application/json' },
      extraData: data ? JSON.stringify(data) : '', // 自动转为JSON字符串
      readTimeout: 240000, // 240秒读取超时（适配大响应）
      connectTimeout: 5000 // 5秒连接超时
    };

    // 发送请求并获取响应
    const response: http.HttpResponse = await httpRequest.request(url, requestConfig);

    // 处理响应数据（兼容字符串/ArrayBuffer两种格式）
    let resultStr: string = '';
    if (typeof response.result === 'string') {
      resultStr = response.result;
    } else if (response.result instanceof ArrayBuffer) {
      resultStr = arrayBufferToString(response.result);
    } else {
      throw new Error(`不支持的响应格式：${typeof response.result}`);
    }

    // 验证HTTP状态码（2xx为成功）
    if (response.responseCode < 200 || response.responseCode >= 300) {
      throw new Error(`HTTP请求失败：状态码 ${response.responseCode}，响应内容：${resultStr}`);
    }

    // 解析JSON并返回类型化数据
    return JSON.parse(resultStr) as TResponse;
  } catch (error) {
    // 错误统一格式化（便于排查）
    const err: BusinessError = error as BusinessError;
    throw new Error(`网络请求异常：${err.code || '未知错误码'} - ${err.message || '未知错误信息'}`);
  } finally {
    // 确保请求资源释放（避免内存泄漏）
    httpRequest.destroy();
  }
}

// 3. 核心类型定义（完全保留原始结构，确保业务兼容性）
/** 接口响应通用格式 */
interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
  count: number;
  latest: boolean;
}

/** 选择题选项格式 */
interface ChoiceOptions {
  A: string;
  B: string;
  C: string;
  D: string;
}

/** 选择题数据格式 */
interface ChoiceData {
  id: number;
  choicePaperName: string;
  choicePaperId: string;
  choiceQuestion: string;
  choiceOptions: ChoiceOptions;
  choiceAnswer: string;
  choiceExplanation: string;
}

/** 判断题数据格式 */
interface JudgeData {
  id: number;
  judgePaperName: string;
  judgePaperId: string;
  judgeQuestion: string;
  judgeAnswer: boolean;
  judgeExplanation: string;
}

/** 填空题数据格式 */
interface FillData {
  id: number;
  fillPaperName: string;
  fillPaperId: string;
  fillQuestion: string;
  fillAnswer: string;
  fillExplanation: string;
}

/** 单题提交数据格式 */
interface SubmitSingleItem {
  questionId: string;
  userAnswer: string;
  questionType: "choice" | "judge" | "fill";
}

/** 单题判分结果格式 */
interface SubmitDetail {
  questionId: string;
  isCorrect: boolean;
  userAnswer: string;
  correctAnswer: string;
  error: string;
}

/** 批量交卷响应格式 */
interface BatchSubmitResponse {
  totalScore: number;
  totalQuestions: number;
  accuracy: string;
  detail: SubmitDetail[];
}

/** 提交接口统一响应格式 */
interface SubmitResponse {
  code: number;
  message: string;
  data: BatchSubmitResponse;
  count: number;
}

/** 单题提交结果返回格式 */
interface SingleSubmitResult {
  isCorrect: boolean;
  correctAnswer: string;
}

/** 批量交卷结果返回格式 */
interface BatchSubmitResult {
  totalScore: number;
  totalQuestions: number;
  accuracy: string;
}

/** 试卷信息格式 */
interface PaperInfo {
  name: string;
}

// 4. 考试控制器（单例模式，统一管理考试流程）
@ObservedV2
export class ExamController {
  // 单例实例（确保全局唯一）
  private static _instance: ExamController;
  public static get instance(): ExamController {
    if (!this._instance) this._instance = new ExamController();
    return this._instance;
  }

  // UI状态与控制器（Trace修饰确保状态可追踪）
  swiperController: SwiperController = new SwiperController(); // 滑动控制器
  @Trace fontSize: number = 16; // 字体大小（默认16px）
  @Trace showNext: boolean = false; // 是否显示"下一题"按钮
  @Trace isShowMockExamDialog: boolean = false; // 是否显示模拟考试弹窗
  @Trace renderView: boolean = false; // 视图是否渲染（防止重复加载）

  // 业务核心实例
  examManager: ExamManager = new ExamManager(); // 考试数据管理器

  /**
   * 加载考试数据（选择题+判断题+填空题）
   * @returns 加载成功返回true，失败返回false
   */
  async loadExamData(): Promise<boolean> {
    try {
      this.renderView = false; // 加载前关闭视图渲染（避免白屏）

      // 并行请求三类题目（提升加载效率）
      const GeneratedDestructArray_1 = await Promise.all([
        // GET请求：无请求体（TData=void），响应为选择题列表
        requestHttp<void, ApiResponse<ChoiceData[]>>(
          `${BACKEND_URL}/choices?latest=true`,
          http.RequestMethod.GET
        ),
        // GET请求：无请求体，响应为判断题列表
        requestHttp<void, ApiResponse<JudgeData[]>>(
          `${BACKEND_URL}/judges?latest=true`,
          http.RequestMethod.GET
        ),
        // GET请求：无请求体，响应为填空题列表
        requestHttp<void, ApiResponse<FillData[]>>(
          `${BACKEND_URL}/fills?latest=true`,
          http.RequestMethod.GET
        )
      ]);
      const choicesData = GeneratedDestructArray_1[0];
      const judgesData = GeneratedDestructArray_1[1];
      const fillsData = GeneratedDestructArray_1[2];

      // 验证接口返回状态（非200视为失败）
      if (choicesData.code !== 200) throw new Error(`选择题加载失败：${choicesData.message}`);
      if (judgesData.code !== 200) throw new Error(`判断题加载失败：${judgesData.message}`);
      if (fillsData.code !== 200) throw new Error(`填空题加载失败：${fillsData.message}`);

      // 构建统一的考试详情列表（适配ExamDetail构造函数）
      const examDetails: ExamDetail[] = [];

      // 处理选择题数据
      choicesData.data.forEach((choice: ChoiceData, index: number) => {
        // 过滤空选项（避免显示无效选项）
        const validOptions = [choice.choiceOptions.A, choice.choiceOptions.B, choice.choiceOptions.C, choice.choiceOptions.D]
          .filter(opt => opt.trim())

        const paperInfo: PaperInfo = { name: choice.choicePaperName }; // 显式绑定PaperInfo接口
        examDetails.push(new ExamDetail(
          choice.choiceQuestion,    // 题目内容
          "",                       // 用户答案（初始为空）
          validOptions,             // 有效选项
          [choice.choiceAnswer],    // 正确答案（数组格式适配）
          QuestionTypeEnum.RADIO,   // 题型（单选）
          ClassificationTypeEnum.MIDDLE, // 难度（中等）
          choice.choiceExplanation, // 解析
          "单选题章节",             // 章节名称
          paperInfo.name,           // 试卷名称
          choice.id.toString()      // 题目ID（转为字符串适配）
        ));
      });

      // 处理判断题数据
      judgesData.data.forEach((judge: JudgeData) => {
        examDetails.push(new ExamDetail(
          judge.judgeQuestion,      // 题目内容
          "",                       // 用户答案（初始为空）
          ["对", "错"],             // 固定选项
          [judge.judgeAnswer ? "对" : "错"], // 正确答案（布尔转字符串）
          QuestionTypeEnum.JUDGE,   // 题型（判断）
          ClassificationTypeEnum.EASY, // 难度（简单）
          judge.judgeExplanation,   // 解析
          "判断题章节",             // 章节名称
          judge.judgePaperName,     // 试卷名称
          judge.id.toString()       // 题目ID
        ));
      });

      // 处理填空题数据
      fillsData.data.forEach((fill: FillData) => {
        examDetails.push(new ExamDetail(
          fill.fillQuestion,        // 题目内容
          "",                       // 用户答案（初始为空）
          [],                       // 填空题无选项
          [fill.fillAnswer],        // 正确答案
          QuestionTypeEnum.FILL,    // 题型（填空）
          ClassificationTypeEnum.MIDDLE, // 难度（中等）
          fill.fillExplanation,     // 解析
          "填空题章节",             // 章节名称
          fill.fillPaperName,       // 试卷名称
          fill.id.toString()        // 题目ID
        ));
      });

      // 初始化考试管理器（传入加载的题目数据）
      this.examManager = new ExamManager(
        "后端加载考卷",  // 考卷名称
        examDetails,     // 题目列表
        0,               // 初始得分
        60               // 考试时长（分钟）
      );

      this.renderView = true; // 加载成功，开启视图渲染
      console.log(`考试数据加载完成：共${examDetails.length}道题`);
      return true;

    } catch (error) {
      // 错误捕获与日志打印（便于调试）
      const errorMsg = error instanceof Error ? error.message : "未知加载错误";
      console.error(`考试数据加载失败：${errorMsg}`);
      this.renderView = false; // 加载失败，关闭视图渲染
      return false;
    }
  }

  /**
   * 单题提交判分
   * @param examDetail - 当前题目详情
   * @returns 单题判分结果（是否正确+正确答案）
   */
  async submitSingleAnswer(examDetail: ExamDetail): Promise<SingleSubmitResult> {
    try {
      // 前置校验（避免无效提交）
      if (!examDetail.id) throw new Error("提交失败：题目ID缺失");
      if (examDetail.selected.length === 0) throw new Error("提交失败：未选择答案");

      // 构建单题提交数据（显式类型）
      const submitData: SubmitSingleItem[] = [{
        questionId: examDetail.id,
        userAnswer: examDetail.selected[0].trim(), // 去空格避免格式问题
        questionType: this.getQuestionTypeStr(examDetail.questionType)
      }];

      // POST请求：请求体为SubmitSingleItem数组，响应为判分结果
      const result = await requestHttp<SubmitSingleItem[], SubmitResponse>(
        `${BACKEND_URL}/submit`,
        http.RequestMethod.POST,
        submitData
      );

      // 验证判分接口状态
      if (result.code !== 200) throw new Error(`判分失败：${result.message || '后端未返回原因'}`);

      // 提取单题判分结果（批量接口返回数组，取第一个元素）
      const detail = result.data.detail[0];
      return {
        isCorrect: detail.isCorrect,
        correctAnswer: detail.correctAnswer
      };

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "未知判分错误";
      console.error(`单题提交失败：${errorMsg}`);
      // 失败时返回默认结果（提示用户重试）
      return {
        isCorrect: false,
        correctAnswer: "判分失败，请重试"
      };
    }
  }

  /**
   * 批量交卷（提交所有已答题目的答案）
   * @returns 交卷结果（总分+总题数+正确率）
   */
  async submitAllAnswers(): Promise<BatchSubmitResult> {
    try {
      // 筛选已答题目（selected不为空）并构建提交数据
      const submitData: SubmitSingleItem[] = this.examManager.examDetails
        .filter(detail => detail.selected.length > 0)
        .map(detail => ({
          questionId: detail.id,
          userAnswer: detail.selected[0].trim(),
          questionType: this.getQuestionTypeStr(detail.questionType)
        } as SubmitSingleItem)); // 显式绑定接口，消除编译器错误

      // 无已答题目时，返回空结果
      if (submitData.length === 0) {
        return {
          totalScore: 0,
          totalQuestions: this.examManager.total,
          accuracy: "0.0%"
        };
      }

      // POST请求：批量提交已答题目，响应为交卷统计
      const result = await requestHttp<SubmitSingleItem[], SubmitResponse>(
        `${BACKEND_URL}/submit`,
        http.RequestMethod.POST,
        submitData
      );

      // 验证交卷接口状态
      if (result.code !== 200) throw new Error(`交卷失败：${result.message || '后端处理异常'}`);

      // 更新考试管理器的统计数据（正确题数/错误题数）
      this.examManager.correctNumber = result.data.totalScore;
      this.examManager.errorNumber = submitData.length - result.data.totalScore;

      // 返回交卷结果（适配前端展示）
      return {
        totalScore: result.data.totalScore,
        totalQuestions: this.examManager.total,
        accuracy: result.data.accuracy
      };

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "未知交卷错误";
      console.error(`批量交卷失败：${errorMsg}`);
      // 失败时返回默认结果（提示用户重试）
      return {
        totalScore: 0,
        totalQuestions: this.examManager.total,
        accuracy: "0.0%"
      };
    }
  }

  /**
   * 辅助方法：将QuestionTypeEnum转为接口需要的字符串（choice/judge/fill）
   * @param type - 题型枚举
   * @returns 题型字符串
   */
  private getQuestionTypeStr(type: QuestionTypeEnum): "choice" | "judge" | "fill" {
    switch (type) {
      case QuestionTypeEnum.RADIO:
        return "choice"; // 单选题对应choice
      case QuestionTypeEnum.JUDGE:
        return "judge"; // 判断题对应judge
      case QuestionTypeEnum.FILL:
        return "fill";  // 填空题对应fill
      default:
        console.warn(`未知题型：${type}，默认按单选题处理`);
        return "choice";
    }
  }
}