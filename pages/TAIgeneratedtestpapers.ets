import { sendToBackend } from './TAIservice2';
import { router } from '@kit.ArkUI';
import { GlobalUserState } from './baocun';

@Entry
@Component
struct AIGenerate {
  @State teachingOutline: string = '';
  @State isLoading: boolean = false;
  @State errorMsg: string = '';
  // 获取全局状态实例（用于获取手机号）
  private globalState = GlobalUserState.getInstance();
  // 处理生成请求
  private async handleGenerate() {
    this.isLoading = true;
    this.errorMsg = '';
    // 获取全局状态中的手机号
    const phoneNumber = this.globalState.phoneNumber;

    const result = await sendToBackend(this.teachingOutline,phoneNumber);

    this.isLoading = false;

    if (!result.success) {
      this.errorMsg = result.error || '生成失败，请重试';
    }

  }

  build() {
    Column({ space: 20 }) {
      // 输入区域
      TextArea({
        placeholder: '例如：生成关于二叉树的试卷',
        text: this.teachingOutline
      })
        .onChange((value: string) => {
          this.teachingOutline = value;
        })
        .fontFamily('思源黑体, 宋体, sans-serif')
        .fontSize(16)
        .width('100%')
        .height(150)
        .backgroundColor('#F5F5F5')
        .padding(10)
        .borderRadius(8)

      // 生成按钮
      Button(this.isLoading ? '生成中...' : '生成考卷内容')
        .width('100%')
        .height(48)
        .fontSize(18)
        .backgroundColor('#007DFF')
        .borderRadius(8)
        .onClick(() => {
          this.handleGenerate();
        })
        .enabled(!this.isLoading)

      // 错误信息展示
      if (this.errorMsg) {
        Text(this.errorMsg)
          .fontColor('#FF4D4F')
          .fontSize(14)
          .width('100%')
          .textAlign(TextAlign.Start)
      }


      Button('返回主界面')
        .width('80%')
        .height(80)
        .fontSize(18)
        .onClick(() => router.pushUrl({ url: 'pages/TeacherIndex' }))
    }
    .width('100%')
    .height('100%')
    .padding(15)
    .backgroundColor('#F5F5F5')
  }
}
