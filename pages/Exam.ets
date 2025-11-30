import { ExamManager, ExamDetail } from '../exam/model/QuestionAnswerRecord';
import { SelectComponent } from '../exam/components/SelectComponent';
import { ExamController } from '../exam/controller/ExamController';
import { router } from '@kit.ArkUI';

@Entry
@ComponentV2
export struct Exam {
  @Param @Require appPathStack: NavPathStack; // 导航栈（用于返回）
  private examController: ExamController = ExamController.instance;
  @Local examManager: ExamManager = this.examController.examManager;
  @Local remainTime: number = this.examManager.timeLimit * 60; // 剩余时间（秒）
  @Local isShowAnswerSheet: boolean = false; // 是否显示答题卡
  @Local isStop: boolean = false; // 计时暂停（交卷/暂停时）

  // 交卷弹窗控制器
  private submitDialog: CustomDialogController = new CustomDialogController({
    builder: this.buildSubmitDialog,
    autoCancel: false
  });

  // 监听考卷数据变化（如题目切换）
  @Monitor('examController.examManager')
  onExamManagerChange() {
    this.examManager = this.examController.examManager;
  }

  // 页面加载时初始化
  aboutToAppear(): void {
    // 加载后端题目（首次进入时）
    if (this.examManager.total === 0) {
      this.examController.loadExamData().then((success: boolean) => {
        if (success) {
          this.examManager = this.examController.examManager;
          this.remainTime = this.examManager.timeLimit * 60;
          this.startCountdown(); // 启动倒计时
        }
      });
    } else {
      this.startCountdown(); // 非首次进入，直接启动计时
    }
  }

  // 页面离开时暂停计时
  aboutToDisappear(): void {
    this.isStop = true;
  }

  build() {
    Column() {
      // 1. 顶部导航栏（标题+剩余时间）
      this.buildTopBar();

      // 2. 题目区域（Swiper切换题目）
      this.buildQuestionSwiper();

      // 3. 底部操作栏（答题状态+答题卡+交卷）
      this.buildBottomBar();

      // 4. 答题卡弹窗
      this.buildAnswerSheet();
    }
    .width("100%")
    .height("100%")
    .backgroundColor("#F1F3F5");
  }

  /**
   * 构建顶部导航栏（标题+剩余时间）
   */
  @Builder
  buildTopBar() {
    Row({ space: 12 }) {
      // 返回按钮
      Button("返回")
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor("#64BB5C")
        .width(60)
        .height(32)
        .borderRadius(6)
        .onClick(() => {
          router.pushUrl({ url: 'pages/StudentIndex' });
        });

      // 标题
      Text('智能考卷')
        .fontSize(16)
        .fontColor("rgba(0,0,0,0.90)")
        .fontWeight(FontWeight.Bold)
        .flexGrow(1);

      // 剩余时间（有时间限制时显示）
      if (this.examManager.timeLimit > 0) {
        Row({ space: 4 }) {
          Image($r('app.media.clock'))
            .width(16)
            .height(16);

          Text(this.formatTime(this.remainTime))
            .fontSize(14)
            .fontColor("#E84026")
            .fontWeight(FontWeight.Bold);
        }
        .padding(12)
        .backgroundColor("#FFF2F0")
        .borderRadius(4);
      }
    }
    .width("100%")
    .height(56)
    .alignItems(VerticalAlign.Center)
    .padding({ left: "4%", right: "4%" })
    .backgroundColor(Color.White);
  }

  /**
   * 构建题目Swiper（切换题目）
   */
  @Builder
  buildQuestionSwiper() {
    Swiper(this.examController.swiperController) {
      ForEach(this.examManager.examDetails, (item: ExamDetail, index: number) => {
        SelectComponent({
          item: item,
          onAnswerSubmit: (isCorrect: boolean) => {
            // 仅保留答题状态记录（正确/错误数，用于显示，非分数计算）
            if (isCorrect) this.examManager.correctNumber++;
            else this.examManager.errorNumber++;
          }
        });
      }, (item: ExamDetail) => item.id);
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
    .padding({ bottom: 80 }); // 给底部操作栏留空间
  }

  /**
   * 构建底部操作栏（答题状态+答题卡+交卷）
   */
  @Builder
  buildBottomBar() {
    Row({ space: 24 }) {
      // 正确/错误数（保留答题状态显示，非分数）
      Row({ space: 16 }) {
        Row({ space: 4 }) {
          Image($r('app.media.correct'))
            .width(16)
            .height(16);

          Text(`${this.examManager.correctNumber}`)
            .fontSize(14)
            .fontColor("rgba(0,0,0,0.90)");
        }

        Row({ space: 4 }) {
          Image($r('app.media.error'))
            .width(16)
            .height(16);

          Text(`${this.examManager.errorNumber}`)
            .fontSize(14)
            .fontColor("rgba(0,0,0,0.90)");
        }
      }

      // 答题卡按钮
      Button("答题卡")
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor("#64BB5C")
        .width(80)
        .height(36)
        .borderRadius(6)
        .onClick(() => {
          this.isShowAnswerSheet = true;
        });

      // 交卷按钮（有时间限制时显示，移除分数处理）
      if (this.examManager.timeLimit > 0) {
        Button("交卷")
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor("#E84026")
          .width(80)
          .height(36)
          .borderRadius(6)
          .onClick(() => {
            this.isStop = true;
            this.submitDialog.open(); // 直接显示交卷弹窗，无分数计算
          });
      }
    }
    .width("100%")
    .height(60)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor(Color.White)
    .position({ bottom: 0 });
  }

  /**
   * 构建答题卡（显示所有题目状态）
   */
  @Builder
  buildAnswerSheet() {
    Column() {
      // 答题卡标题
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
          .onClick(() => {
            this.isShowAnswerSheet = false;
          });
      }
      .width("100%")
      .padding(12)
      .backgroundColor("#F9F9F9");

      // 题目状态网格（每行6题）
      Grid() {
        ForEach(this.examManager.examDetails, (item: ExamDetail, index: number) => {
          GridItem() {
            Stack() {
              // 背景色：未答→浅灰，正确→绿，错误→红
              Row()
                .width(40)
                .height(40)
                .borderRadius(20)
                .backgroundColor(this.getAnswerSheetBgColor(item.isCorrect));

              // 题目序号
              Text(`${index + 1}`)
                .fontSize(14)
                .fontColor(item.isCorrect === undefined ? "rgba(0,0,0,0.90)" : Color.White);
            }
            .onClick(() => {
              // 点击跳转到对应题目
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
    .borderRadius(16);
  }

  /**
   * 空的 CustomBuilder（用于 bindSheet 类型匹配）
   */
  @Builder
  emptySheetBuilder() {}

  /**
   * 构建交卷结果弹窗（移除分数显示）
   */
  @Builder
  buildSubmitDialog() {
    Column({ space: 20 }) {
      Text("考试结束")
        .fontSize(20)
        .fontColor("rgba(0,0,0,0.90)")
        .fontWeight(FontWeight.Bold);

      // 仅保留总题数显示（移除得分、正确率）
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text("总题数：")
            .fontSize(16)
            .fontColor("rgba(0,0,0,0.70)");

          Text(`${this.examManager.total} 题`)
            .fontSize(16)
            .fontColor("rgba(0,0,0,0.90)");
        }
      }

      // 按钮组（查看错题/返回首页）
      Row({ space: 24 }) {
        Button("查看错题")
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor("#64BB5C")
          .width(120)
          .height(40)
          .borderRadius(6)
          .onClick(() => {
            this.submitDialog.close();
          });

        Button("返回首页")
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor("#E84026")
          .width(120)
          .height(40)
          .borderRadius(6)
          .onClick(() => {
            this.submitDialog.close();
            this.appPathStack.pop();
          });
      }
    }
    .width("80%")
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16);
  }

  /**
   * 启动倒计时（时间到自动交卷，移除分数处理）
   */
  private startCountdown(): void {
    if (this.examManager.timeLimit === 0) return; // 无时间限制，不启动
    this.isStop = false;

    setInterval(() => {
      if (this.isStop) return;
      if (this.remainTime > 0) {
        this.remainTime--;
      } else {
        // 时间到自动交卷，直接显示弹窗（无分数计算）
        this.isStop = true;
        this.examController.submitAllAnswers().then(() => {
          this.submitDialog.open();
        });
      }
    }, 1000);
  }

  /**
   * 格式化时间（秒→mm:ss）
   */
  private formatTime(seconds: number): string {
    const minute = Math.floor(seconds / 60);
    const second = seconds % 60;
    return `${minute.toString().padStart(2, '0')}:${second.toString().padStart(2, '0')}`;
  }

  /**
   * 获取答题卡题目背景色
   */
  private getAnswerSheetBgColor(isCorrect?: boolean): string {
    if (isCorrect === undefined) return "#F1F3F5"; // 未答
    return isCorrect ? "#64BB5C" : "#E84026"; // 正确→绿，错误→红
  }
}