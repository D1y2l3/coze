import { ChoicePaper } from './choice';
import { ChoiceService } from './choicePaperService';
import { ChoiceQuestionItem } from './ChoiceQuestionItem';
import { JudgePaper } from './judge';
import { JudgeService } from './judgeService';
import { JudgeQuestionItem } from './JudgeQuestionItem';
import { BlankPaper } from './blank';
import { BlankService } from './BlankPaperService';
import { BlankQuestionItem } from './BlankQuestionItem';
import promptAction from '@ohos.promptAction';
import { router } from '@kit.ArkUI';


interface RouterParams {
  paperName: string;
  choicePaperId?: string;
  judgePaperId?: string;
  blankPaperId?: string;
}

@Entry
@Component
struct PaperQuestionsPage {
  @State paperName: string = '';
  @State choices: ChoicePaper[] = [];
  @State judges: JudgePaper[] = [];
  @State blanks: BlankPaper[] = [];
  @State isLoadingChoices: boolean = false;
  @State isLoadingJudges: boolean = false;
  @State isLoadingBlanks: boolean = false;
  @State errorMsg: string = '';
  @State judgeErrorMsg: string = '';
  @State blankErrorMsg: string = '';
  @State choicePaperId: string = '';
  @State judgePaperId: string = '';
  @State blankPaperId: string = '';

  aboutToAppear() {
    const params = router.getParams() as RouterParams;
    if (params && params.paperName) {
      this.paperName = params.paperName;
      this.fetchChoices();
      this.fetchJudges();
      this.fetchBlanks();
    } else {
      this.errorMsg = '未获取到试卷名称';
      promptAction.showToast({ message: this.errorMsg });
      router.back();
    }
  }

  async fetchChoices() {
    this.isLoadingChoices = true;
    this.errorMsg = '';
    try {
      const data = await ChoiceService.getQuestionsByPaper(this.paperName);
      this.choices = data;
      if (data.length > 0) {
        this.choicePaperId = data[0].paperId || '';
        console.info(`选择题试卷编号：${this.choicePaperId}`);
      }
    } catch (error) {
      this.errorMsg = (error as Error).message || '加载选择题失败';
      promptAction.showToast({ message: this.errorMsg });
    } finally {
      this.isLoadingChoices = false;
    }
  }

  async fetchJudges() {
    this.isLoadingJudges = true;
    this.judgeErrorMsg = '';
    try {
      const data = await JudgeService.getJudgeQuestionsByPaper(this.paperName);
      this.judges = data;
      if (data.length > 0) {
        this.judgePaperId = data[0].paperId || '';
        console.info(`判断题试卷编号：${this.judgePaperId}`);
      }
    } catch (error) {
      this.judgeErrorMsg = (error as Error).message || '加载判断题失败';
      promptAction.showToast({ message: this.judgeErrorMsg });
    } finally {
      this.isLoadingJudges = false;
    }
  }

  async fetchBlanks() {
    this.isLoadingBlanks = true;
    this.blankErrorMsg = '';
    try {
      const data = await BlankService.getBlankQuestionsByPaper(this.paperName);
      this.blanks = data;
      if (data.length > 0) {
        this.blankPaperId = data[0].paperId || '';
        console.info(`填空题试卷编号：${this.blankPaperId}`);
      }
    } catch (error) {
      this.blankErrorMsg = (error as Error).message || '加载填空题失败';
      promptAction.showToast({ message: this.blankErrorMsg });
    } finally {
      this.isLoadingBlanks = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        Text(`试卷：${this.paperName}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 16 })
          .textAlign(TextAlign.Center)
          .width('100%');

        // 选择题部分
        Column() {
          Text("一、选择题")
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10, left: 12 })
            .width('100%');

          if (this.isLoadingChoices) {
            Column() {
              LoadingProgress()
                .width(30)
                .height(30)
                .color('#007DFF');
              Text('正在加载选择题...')
                .fontSize(14)
                .margin({ top: 5 });
            }
            .padding(10);
          } else if (this.errorMsg) {
            Text(this.errorMsg)
              .fontSize(14)
              .fontColor(Color.Red)
              .margin(10)
              .alignSelf(ItemAlign.Center);
          } else {
            if (this.choices.length === 0) {
              Text('该试卷暂无选择题')
                .fontSize(14)
                .padding(10);
            } else {
              List() {
                ForEach(
                  this.choices,
                  (choice: ChoicePaper) => {
                    ListItem() {
                      ChoiceQuestionItem({ choice: choice });
                    }
                  },
                  (choice: ChoicePaper) => `${choice.id}`
                );
              }
              .width('100%')
              .height('auto')
              .margin({ top: 10 });
            }
          }
        }
        .width('100%')
        .margin({ bottom: 20 });

        // 判断题部分
        Column() {
          Text("二、判断题")
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10, left: 12 })
            .width('100%');

          if (this.isLoadingJudges) {
            Column() {
              LoadingProgress()
                .width(30)
                .height(30)
                .color('#007DFF');
              Text('正在加载判断题...')
                .fontSize(14)
                .margin({ top: 5 });
            }
            .padding(10);
          } else if (this.judgeErrorMsg) {
            Text(this.judgeErrorMsg)
              .fontSize(14)
              .fontColor(Color.Red)
              .margin(10)
              .alignSelf(ItemAlign.Center);
          } else {
            if (this.judges.length === 0) {
              Text('该试卷暂无判断题')
                .fontSize(14)
                .padding(10);
            } else {
              List() {
                ForEach(
                  this.judges,
                  (judge: JudgePaper) => {
                    ListItem() {
                      JudgeQuestionItem({ judge: judge });
                    }
                  },
                  (judge: JudgePaper) => `${judge.id}`
                );
              }
              .width('100%')
              .height('auto')
              .margin({ top: 10 });
            }
          }
        }
        .width('100%')
        .margin({ bottom: 20 });

        // 填空题部分
        Column() {
          Text("三、填空题")
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10, left: 12 })
            .width('100%');

          if (this.isLoadingBlanks) {
            Column() {
              LoadingProgress()
                .width(30)
                .height(30)
                .color('#007DFF');
              Text('正在加载填空题...')
                .fontSize(14)
                .margin({ top: 5 });
            }
            .padding(10);
          } else if (this.blankErrorMsg) {
            Text(this.blankErrorMsg)
              .fontSize(14)
              .fontColor(Color.Red)
              .margin(10)
              .alignSelf(ItemAlign.Center);
          } else {
            if (this.blanks.length === 0) {
              Text('该试卷暂无填空题')
                .fontSize(14)
                .padding(10);
            } else {
              List() {
                ForEach(
                  this.blanks,
                  (blank: BlankPaper) => {
                    ListItem() {
                      BlankQuestionItem({ blank: blank });
                    }
                  },
                  (blank: BlankPaper) => `${blank.id}`
                );
              }
              .width('100%')
              .height('auto')
              .margin({ top: 10 });
            }
          }
        }
        .width('100%')
        .margin({ bottom: 20 });

        Button('发布作业')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => {
            if (!this.choicePaperId && !this.judgePaperId && !this.blankPaperId) {
              promptAction.showToast({ message: '该试卷无有效题目，无法发布' });
              return;
            }
            router.pushUrl({
              url: 'pages/TeacherCollegeHomework2',
              params: {
                paperName: this.paperName,
                choicePaperId: this.choicePaperId,
                judgePaperId: this.judgePaperId,
                blankPaperId: this.blankPaperId
              } as RouterParams
            });
          });
      }
      .width('100%')
      .backgroundColor('#F5F5F5')
      .padding(12);
    }
    .width('100%')
    .height('100%');
  }
}