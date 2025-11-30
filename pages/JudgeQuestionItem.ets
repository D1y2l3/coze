import { JudgePaper } from "./judge";


@Component
export struct JudgeQuestionItem {
  // 接收单个判断题数据
  @Prop judge: JudgePaper;

  build() {
    Column() {
      // 题干部分
      Text(this.judge.judgeQuestion)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })
        .textAlign(TextAlign.Start)
        .width('100%');

      // 答案和解析区域
      Column() {
        // 判断题答案为字符串“对”/“错”，需做字符串比较
        Text(`正确答案：${this.judge.judgeAnswer === '对' ? '对' : '错'}`)
          .fontSize(14)
          .fontColor(this.judge.judgeAnswer === '对' ? Color.Green : Color.Red)
          .margin({ bottom: 4 });
        Text(`解析：${this.judge.judgeExplanation}`)
          .fontSize(13)
          .fontColor(Color.Gray);
      }
      .width('100%');
    }
    // 保持与其他题型一致的容器样式
    .padding(12)
    .borderRadius(10)
    .backgroundColor(Color.White)
    .shadow({ radius: 2, color: '#EEEEEE' })
    .margin({ top: 6, bottom: 6, left: 12, right: 12 });
  }
}