import { GlobalUserState } from './baocun';
import { queryPapersByPhone, RequestResult } from '../pages/QuesttionSerice';
// 补充所有用到的UI组件和枚举（关键：解决标识符未定义报错）

import promptAction from '@ohos.promptAction';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct QuestionPage {
  private globalState = GlobalUserState.getInstance();
  @State paperNames: string[] = [];
  @State errorMsg: string = '';
  @State isLoading: boolean = false;

  async onPageShow(): Promise<void> {
    this.fetchPapers();
  }

  async fetchPapers(): Promise<void> {
    const phoneNumber: string = this.globalState.phoneNumber;
    console.log('当前用户手机号：', phoneNumber);

    this.isLoading = true;
    this.errorMsg = '';

    try {
      const result: RequestResult = await queryPapersByPhone(phoneNumber);
      if (result.success && result.paperNames) {
        this.paperNames = result.paperNames;
        console.log(`查询成功，共${result.paperNames.length}份试卷`);
        console.log('试卷名称列表：', JSON.stringify(this.paperNames));
        promptAction.showToast({ message: `查询到${result.paperNames.length}份试卷` });
      } else {
        this.errorMsg = result.error || '查询失败，请稍后重试';
        console.error('查询失败：', this.errorMsg);
        promptAction.showToast({ message: this.errorMsg });
      }
    } catch (err) {
      this.errorMsg = '查询过程发生异常';
      console.error('查询异常：', err);
      promptAction.showToast({ message: this.errorMsg });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 页面标题
      Text('题库试卷')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .alignSelf(ItemAlign.Center);

      // 加载状态提示
      if (this.isLoading) {
        Text('正在查询试卷...')
          .fontSize(14)
          .fontColor('#999999')
          .margin(10);
      }

      // 错误提示
      if (this.errorMsg && !this.isLoading) {
        Text(this.errorMsg)
          .fontSize(14)
          .fontColor('#ff0000')
          .margin(10)
          .alignSelf(ItemAlign.Center);
      }

      // 试卷列表
      if (this.paperNames.length > 0) {
        List()
         {
          ForEach(
            this.paperNames,
            (name: string) => {
              ListItem() {
                Column() {
                  Text(name)
                    .fontSize(16)
                    .fontColor('#333333')
                    .padding({ left: 16, right: 16, top: 20, bottom: 20 })
                    .width('100%');
                  Divider()
                    .color('#eeeeee')
                    .height(1)
                    .width('100%');
                }
                .width('100%')
                .backgroundColor(Color.White)
                .borderRadius(8)
                .shadow({
                  radius: 2,
                  color: '#1A000000',
                  offsetX: 0,
                  offsetY: 1
                })
                .margin({ bottom: 12 })
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/PaperQuestionsPage', // 新建的题目展示页面
                    params: { paperName: name }      // 传递试卷名称
                  });
                });
              }
            },
            (name: string) => name
          );
        }
      } else if (!this.isLoading && !this.errorMsg) {
        Text('暂无匹配的试卷')
          .fontSize(14)
          .fontColor('#999999')
          .margin(20)
          .alignSelf(ItemAlign.Center);
      }

      // 重新查询按钮
      Button('重新查询')
        .onClick(() => this.fetchPapers())
        .margin({ bottom: 30 })
        .backgroundColor('#007dff')
        .padding({ left: 30, right: 30, top: 10, bottom: 10 })
        .borderRadius(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}