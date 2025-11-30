import { BlankPaper } from "./blank";



@Component
export struct BlankQuestionItem {
  // 接收单个填空题数据（与数据模型命名对齐）
  @Prop blank: BlankPaper;

  build() {
    Column() {
      // 题干部分
      Text(this.blank.blankQuestion)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })
        .textAlign(TextAlign.Start)
        .width('100%');

      // 答案和解析区域
      Column() {
        Text(`正确答案：${this.blank.blankAnswer}`)
          .fontSize(14)
          .fontColor(Color.Green)
          .margin({ bottom: 4 });
        // 解析字段可能为可选，添加默认值避免undefined
        Text(`解析：${this.blank.blankExplanation || '无解析'}`)
          .fontSize(13)
          .fontColor(Color.Gray);
      }
      .width('100%');
    }
    // 保持与选择题、判断题完全一致的容器样式，确保UI统一
    .padding(12)
    .borderRadius(10)
    .backgroundColor(Color.White)
    .shadow({ radius: 2, color: '#EEEEEE' })
    .margin({ top: 6, bottom: 6, left: 12, right: 12 });
  }
}