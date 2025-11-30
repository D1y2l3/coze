import { ChoicePaper } from "./choice";


@Component
export struct ChoiceQuestionItem {
  // 接收单个选择题数据
  @Prop choice: ChoicePaper;

  build() {
    Column() {
      // 题干部分
      Text(this.choice.choiceQuestion)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })
        .textAlign(TextAlign.Start)
        .width('100%');

      // 选项区域
      Column() {
        Text(`A. ${this.choice.choiceOptions.A}`)
          .fontSize(14)
          .margin({ bottom: 4 });
        Text(`B. ${this.choice.choiceOptions.B}`)
          .fontSize(14)
          .margin({ bottom: 4 });
        Text(`C. ${this.choice.choiceOptions.C}`)
          .fontSize(14)
          .margin({ bottom: 4 });
        Text(`D. ${this.choice.choiceOptions.D}`)
          .fontSize(14);
      }
      .margin({ bottom: 8 })

      .width('100%');

      // 答案和解析
      Column() {
        Text(`正确答案：${this.choice.choiceAnswer}`)
          .fontSize(14)
          .fontColor(Color.Green)
          .margin({ bottom: 4 });
        Text(`解析：${this.choice.choiceExplanation}`)
          .fontSize(13)
          .fontColor(Color.Gray);
      }

      .width('100%');
    }
    .padding(12)
    .borderRadius(10)
    .backgroundColor(Color.White)
    .shadow({ radius: 2, color: '#EEEEEE' }) // 增加轻微阴影提升层次感
    .margin({ top: 6, bottom: 6, left: 12, right: 12 });
  }
}
