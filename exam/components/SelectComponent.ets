import { ExamDetail, QuestionTypeEnum } from '../model/QuestionAnswerRecord';


@ComponentV2
export struct SelectComponent {
  @Param @Require item: ExamDetail;
  @Param @Require onAnswerSubmit: (isCorrect: boolean) => void;
  @Local showAnswer: boolean = false;
  @Local fillUserInput: string = "";
  @Local isSubmitted: boolean = false;
  @Local keyMap: string[] = ['A', 'B', 'C', 'D'];

  build() {
    Column({ space: 16 }) {
      this.buildQuestionTypeTag();
      this.buildQuestionContent();

      if (this.item.questionType === QuestionTypeEnum.RADIO || this.item.questionType === QuestionTypeEnum.JUDGE) {
        if (this.item.options.length === 0) {
          Text("暂无有效选项，请联系老师确认题目")
            .fontSize(14)
            .fontColor(Color.Red)
            .padding(12);
        } else {
          this.buildOptionList();
        }
      } else if (this.item.questionType === QuestionTypeEnum.FILL) {
        this.buildFillInput();
      }

      if (this.showAnswer) {
        this.buildAnswerAndAnalysis();
      }
    }
    .padding({ left: "4%", right: "4%" })
    .width("100%")
    .padding(16);
  }

  @Builder
  buildQuestionTypeTag() {
    Row() {
      Text(this.getItemTypeText())
        .fontSize(14)
        .fontColor(Color.White);
    }
    .width(80)
    .height(32)
    .justifyContent(FlexAlign.Center)
    .borderRadius(8)
    .backgroundColor("#64BB5C")
    .alignSelf(ItemAlign.Start);
  }

  @Builder
  buildQuestionContent() {
    Column({ space: 12 }) {
      Text(this.item.question)
        .fontSize(18)
        .fontColor("rgba(0,0,0,0.90)")
        .lineHeight(24)
        .alignSelf(ItemAlign.Start);
    }
  }

  @Builder
  buildOptionList() {
    Column({ space: 12 }) {
      ForEach(this.item.options, (option: string, index: number) => {
        Row({ space: 12 }) {
          Image(this.getOptionImage(option, index))
            .width(20)
            .height(20);
          Text(option)
            .fontSize(16)
            .fontColor("rgba(0,0,0,0.90)")
            .flexGrow(1);
        }
        .width("100%")
        .padding(12)
        .backgroundColor(this.item.selected.includes(option) ? "#F1F3F5" : Color.White)
        .borderRadius(8)
        .borderWidth(1)
        .borderColor(this.item.selected.includes(option) ? "#64BB5C" : "#EEEEEE")
        .onClick(async () => {
          if (this.showAnswer || this.isSubmitted) return;
          this.item.selected = [option];
          this.isSubmitted = true;

          // 严格区分题型：单选题用A/B/C/D映射，判断题用选项文本
          let optionKey = option;
          if (this.item.questionType === QuestionTypeEnum.RADIO) {
            optionKey = this.getOptionKey(index);
          }

          const isCorrect = this.item.answer.includes(optionKey);
          this.item.isCorrect = isCorrect;
          this.showAnswer = true;
          this.onAnswerSubmit(isCorrect);
        });
      }, (option: string) => option);
    }
    .margin({ top: 8 });
  }

  @Builder
  buildFillInput() {
    Column({ space: 12 }) {
      TextInput({
        text: this.fillUserInput,
        placeholder: "请输入答案"
      })
        .width("100%")
        .height(40)
        .backgroundColor("#F1F3F5")
        .borderRadius(8)
        .padding({ left: 12 })
        .enabled(!this.isSubmitted)
        .onChange((value: string) => this.fillUserInput = value);

      Button("提交答案")
        .width("80%")
        .height(40)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor(this.fillUserInput.trim() ? "#64BB5C" : "rgba(0,0,0,0.10)")
        .enabled(!this.isSubmitted && this.fillUserInput.trim().length > 0)
        .onClick(async () => {
          this.isSubmitted = true;
          const userAnswer = this.fillUserInput.trim();
          this.item.selected = [userAnswer];
          const isCorrect = this.item.answer.includes(userAnswer);
          this.item.isCorrect = isCorrect;
          this.showAnswer = true;
          this.onAnswerSubmit(isCorrect);
        });
    }
  }

  @Builder
  buildAnswerAndAnalysis() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Text("正确答案：")
          .fontSize(14)
          .fontColor("rgba(0,0,0,0.90)");
        Text(this.item.answer.join(","))
          .fontSize(14)
          .fontColor("#64BB5C")
          .fontWeight(FontWeight.Bold);
        if (this.item.isCorrect === false) {
          Text(`（你的答案：${this.item.selected.join(",")}）`)
            .fontSize(14)
            .fontColor("#E84026");
        }
      }
      .alignSelf(ItemAlign.Start);

      Column({ space: 8 }) {
        Text("题目解析：")
          .fontSize(14)
          .fontColor("rgba(0,0,0,0.90)")
          .alignSelf(ItemAlign.Start);
        Text(this.item.analysis || "无解析")
          .fontSize(14)
          .fontColor("rgba(0,0,0,0.70)")
          .lineHeight(20);
      }
      .width("100%")
      .padding(12)
      .backgroundColor("#F9F9F9")
      .borderRadius(8);
    }
    .margin({ top: 12 });
  }

  private getItemTypeText(): string {
    switch (this.item.questionType) {
      case QuestionTypeEnum.RADIO:
        return "单选题";
      case QuestionTypeEnum.JUDGE:
        return "判断题";
      case QuestionTypeEnum.FILL:
        return "填空题";
      default:
        return "未知题型";
    }
  }

  private getOptionKey(index: number): string {
    return this.keyMap[index] || '';
  }

  private getOptionImage(option: string, index: number): ResourceStr {
    if (!this.showAnswer) return $r("app.media.no_select");

    let optionKey = option;
    if (this.item.questionType === QuestionTypeEnum.RADIO) {
      optionKey = this.getOptionKey(index);
    }

    if (this.item.answer.includes(optionKey)) return $r("app.media.correct");
    if (this.item.selected.includes(option) && !this.item.answer.includes(optionKey)) return $r("app.media.error");
    return $r("app.media.no_select");
  }
}