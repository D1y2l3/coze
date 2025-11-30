import { QuestionTypeEnum, ExamDetail, ClassificationTypeEnum, ExamManager } from '../exam/model/QuestionAnswerRecord';
import { SelectComponent } from '../exam/components/SelectComponent';
import { ExamController } from '../exam/controller/ExamController';
import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';


// 定义单选选项接口
interface RadioOptions {
  A?: string;
  B?: string;
  C?: string;
  D?: string;
}

// 定义判断选项类型
type JudgeOptions = ["对", "错"];

// 题目结构（兼容后端字符串/数组格式选项）
interface Question {
  questionType: "RADIO" | "JUDGE" | "FILL";
  id: string;
  question: string;
  options?: RadioOptions | JudgeOptions | string; // 支持字符串/数组/对象格式
  answer: string;
  analysis: string;
  index: number;
}

// 路由参数类型
interface RouteParams {
  questions: Question[];
  paperName: string;
}

@Entry
@ComponentV2
export struct Exam2 {
  @Local questions: Question[] = [];
  @Local paperName: string = '';

  private examController: ExamController = ExamController.instance;
  @Local examManager: ExamManager = new ExamManager();
  @Local remainTime: number = 60 * 60;
  @Local isShowAnswerSheet: boolean = false;
  @Local isStop: boolean = false;

  private submitDialog: CustomDialogController = new CustomDialogController({
    builder: this.buildSubmitDialog,
    autoCancel: false
  });

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams | undefined;
    if (params && params.questions && params.paperName) {
      this.questions = params.questions;
      this.paperName = params.paperName;

      console.log("从路由接收的题目数量：", this.questions.length);

      // 转换题目数据为ExamDetail格式（核心：区分题型解析选项）
      const examDetails: ExamDetail[] = this.questions.map((q, qIndex) => {
        let options: string[] = [];
        let questionTypeEnum: QuestionTypeEnum = QuestionTypeEnum.RADIO;

        // 1. 转换题型
        switch (q.questionType) {
          case "RADIO":
            questionTypeEnum = QuestionTypeEnum.RADIO;
            break;
          case "JUDGE":
            questionTypeEnum = QuestionTypeEnum.JUDGE;
            break;
          case "FILL":
            questionTypeEnum = QuestionTypeEnum.FILL;
            break;
          default:
            questionTypeEnum = QuestionTypeEnum.RADIO;
            console.warn(`第${qIndex+1}题题型未知：${q.questionType}`);
        }

        // 2. 转换选项（区分单选题、判断题、填空题）
        if (q.options) {
          if (Array.isArray(q.options)) {
            // 判断题：直接使用数组选项（如["对", "错"]）
            options = q.options;
          } else if (typeof q.options === 'string') {
            console.log(`第${qIndex+1}题原始选项字符串：`, q.options);
            // 单选题：解析字符串格式选项（如"A:选项A;B:选项B"）
            const optionList = q.options.split(';');
            const radioOpts: RadioOptions = {};
            optionList.forEach(opt => {
              const parts = opt.split(':', 1);
              const key = parts[0]?.trim();
              const val = parts[1]?.trim();
              if (key && val) {
                switch (key) {
                  case 'A':
                    radioOpts.A = val;
                    break;
                  case 'B':
                    radioOpts.B = val;
                    break;
                  case 'C':
                    radioOpts.C = val;
                    break;
                  case 'D':
                    radioOpts.D = val;
                    break;
                  default:
                    break;
                }
              }
            });
            // 提取有效选项（A/B/C/D）
            options = [
              radioOpts.A || '无选项A',
              radioOpts.B || '无选项B',
              radioOpts.C || '无选项C',
              radioOpts.D || '无选项D'
            ].filter(opt => opt.trim() !== '');
          } else {
            // 兼容对象格式选项
            const radioOpts = q.options as RadioOptions;
            options = [
              radioOpts.A || '无选项A',
              radioOpts.B || '无选项B',
              radioOpts.C || '无选项C',
              radioOpts.D || '无选项D'
            ].filter(opt => opt.trim() !== '');
          }
        } else if (questionTypeEnum === QuestionTypeEnum.FILL) {
          // 填空题：无选项
          options = [];
        } else {
          // 其他题型无选项时提示
          options = ['暂无选项，请联系老师确认题目'];
        }

        console.log(`第${qIndex+1}题（${questionTypeEnum}）转换后选项：`, options);
        return new ExamDetail(
          q.question,
          "",
          options,
          [q.answer],
          questionTypeEnum,
          ClassificationTypeEnum.MIDDLE,
          q.analysis,
          "默认章节",
          this.paperName,
          q.id
        );
      });

      console.log("转换后ExamDetail数量：", examDetails.length);
      this.examManager = new ExamManager(
        this.paperName,
        examDetails,
        0,
        60
      );
      console.log("ExamManager中待渲染题目数量：", this.examManager.examDetails.length);
      this.remainTime = this.examManager.timeLimit * 60;
      this.startCountdown();
    } else {
      console.error("路由参数缺失！未获取到questions或paperName");
      promptAction.showToast({ message: "试卷数据加载失败，请返回重试" });
      router.back();
    }
  }

  aboutToDisappear(): void {
    this.isStop = true;
  }

  build() {
    Column() {
      this.buildTopBar();
      this.buildQuestionSwiper();
      this.buildBottomBar();
      if (this.isShowAnswerSheet) {
        this.buildAnswerSheet();
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor("#F1F3F5");
  }

  @Builder
  buildTopBar() {
    Row({ space: 12 }) {
      Button("返回")
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor("#64BB5C")
        .width(60)
        .height(32)
        .borderRadius(6)
        .onClick(() => router.back());

      Text(`试卷：${this.paperName}`)
        .fontSize(16)
        .fontColor("rgba(0,0,0,0.90)")
        .fontWeight(FontWeight.Bold)
        .flexGrow(1)
        .textAlign(TextAlign.Center);

      Row({ space: 4 }) {
        Image($r('app.media.clock'))
          .width(16)
          .height(16);
        Text(this.formatTime(this.remainTime))
          .fontSize(14)
          .fontColor("#E84026")
          .fontWeight(FontWeight.Bold);
      }
      .padding(8)
      .backgroundColor("#FFF2F0")
      .borderRadius(4);
    }
    .width("100%")
    .height(56)
    .alignItems(VerticalAlign.Center)
    .padding({ left: "4%", right: "4%" })
    .backgroundColor(Color.White);
  }

  @Builder
  buildQuestionSwiper() {
    Swiper(this.examController.swiperController) {
      ForEach(
        this.examManager.examDetails,
        (item: ExamDetail, index: number) => {
          SelectComponent({
            item: item,
            onAnswerSubmit: (isCorrect: boolean) => {
              item.isCorrect = isCorrect;
              const hasCounted = this.examManager.examDetails.some(i => i.id === item.id && i.isCorrect !== undefined);
              if (isCorrect && !hasCounted) {
                this.examManager.correctNumber++;
              } else if (!isCorrect && !hasCounted) {
                this.examManager.errorNumber++;
              }
            }
          });
        },
        (item: ExamDetail) => item.id
      );
    }
    .index(this.examManager.currentQuestionId)
    .height("100%")
    .width("100%")
    .autoPlay(false)
    .loop(false)
    .indicator(false)
    .onChange((targetIndex: number) => {
      this.examManager.currentQuestionId = targetIndex;
    })
    .padding({ bottom: 80 });
  }

  @Builder
  buildBottomBar() {
    Row({ space: 24 }) {
    //   Row({ space: 16 }) {
    //     Row({ space: 4 }) {
    //       Image($r('app.media.correct'))
    //         .width(16)
    //         .height(16);
    //       Text(`${this.examManager.correctNumber}`)
    //         .fontSize(14)
    //         .fontColor("rgba(0,0,0,0.90)");
    //     }
    //
    //     Row({ space: 4 }) {
    //       Image($r('app.media.error'))
    //         .width(16)
    //         .height(16);
    //       Text(`${this.examManager.errorNumber}`)
    //         .fontSize(14)
    //         .fontColor("rgba(0,0,0,0.90)");
    //     }
    //   }
    //
    //   Button("答题卡")
    //     .fontSize(14)
    //     .fontColor(Color.White)
    //     .backgroundColor("#64BB5C")
    //     .width(80)
    //     .height(36)
    //     .borderRadius(6)
    //     .onClick(() => this.isShowAnswerSheet = true);

      Button("交卷")
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor("#E84026")
        .width(80)
        .height(36)
        .borderRadius(6)
        .onClick(() => {
          this.isStop = true;
          this.submitDialog.open();
        });
    }
    .width("100%")
    .height(60)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor(Color.White)
    .position({ bottom: 0 });
  }

  @Builder
  buildAnswerSheet() {
    Column() {
      Row({ space: 8 }) {
        Text("答题卡")
          .fontSize(16)
          .fontColor("rgba(0,0,0,0.90)")
          .fontWeight(FontWeight.Bold);

        Button("关闭")
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor("#64BB5C")
          .width(60)
          .height(28)
          .borderRadius(4)
          .onClick(() => this.isShowAnswerSheet = false);
      }
      .width("100%")
      .padding(12)
      .backgroundColor("#F9F9F9");

      Grid() {
        ForEach(this.examManager.examDetails, (item: ExamDetail, index: number) => {
          GridItem() {
            Stack() {
              Row()
                .width(40)
                .height(40)
                .borderRadius(20)
                .backgroundColor(this.getAnswerSheetBgColor(item.isCorrect));

              Text(`${index + 1}`)
                .fontSize(14)
                .fontColor(item.isCorrect === undefined ? "rgba(0,0,0,0.90)" : Color.White);
            }
            .onClick(() => {
              this.examManager.currentQuestionId = index;
              this.examController.swiperController.changeIndex(index);
              this.isShowAnswerSheet = false;
            });
          }
        }, (item: ExamDetail) => item.id);
      }
      .rowsGap(12)
      .columnsTemplate("repeat(auto-stretch, 6)")
      .width("100%")
      .height("80%")
      .padding(12);
    }
    .width("100%")
    .height("70%")
    .backgroundColor(Color.White)
    .borderRadius(16)
    .position({ top: "15%" });
  }

  @Builder
  buildSubmitDialog() {
    Column({ space: 20 }) {
      Text("考试结束")
        .fontSize(20)
        .fontColor("rgba(0,0,0,0.90)")
        .fontWeight(FontWeight.Bold);

      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text("总题数：")
            .fontSize(16)
            .fontColor("rgba(0,0,0,0.70)");
          Text(`${this.examManager.total} 题`)
            .fontSize(16)
            .fontColor("rgba(0,0,0,0.90)");
        }
        Row({ space: 8 }) {
          Text("做对：")
            .fontSize(16)
            .fontColor("rgba(0,0,0,0.70)");
          Text(`${this.examManager.correctNumber} 题`)
            .fontSize(16)
            .fontColor("#64BB5C");
        }
        Row({ space: 8 }) {
          Text("做错：")
            .fontSize(16)
            .fontColor("rgba(0,0,0,0.70)");
          Text(`${this.examManager.errorNumber} 题`)
            .fontSize(16)
            .fontColor("#E84026");
        }
      }

      Row({ space: 24 }) {
        Button("返回试卷列表")
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor("#E84026")
          .width(120)
          .height(40)
          .borderRadius(6)
          .onClick(() => {
            this.submitDialog.close();
            router.back();
          });
      }
    }
    .width("80%")
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16);
  }

  private startCountdown(): void {
    if (this.examManager.timeLimit === 0) return;
    this.isStop = false;

    setInterval(() => {
      if (this.isStop) return;
      this.remainTime = Math.max(0, this.remainTime - 1);
      if (this.remainTime === 0) {
        this.isStop = true;
        this.submitDialog.open();
      }
    }, 1000);
  }

  private formatTime(seconds: number): string {
    const minute = Math.floor(seconds / 60);
    const second = seconds % 60;
    return `${minute.toString().padStart(2, '0')}:${second.toString().padStart(2, '0')}`;
  }

  private getAnswerSheetBgColor(isCorrect?: boolean): string {
    if (isCorrect === undefined) return "#F1F3F5";
    return isCorrect ? "#64BB5C" : "#E84026";
  }
}