import { sendToBackend2 } from './TAIsheji';
import { router } from '@kit.ArkUI';


@Entry
@Component
struct PrepareLesson {
  @State teachingOutline: string = '';
  @State generatedContent: string = '';
  @State isLoading: boolean = false;
  @State errorMsg: string = '';


  private async handleGenerate() {
    this.isLoading = true;
    this.errorMsg = '';

    const result = await sendToBackend2(this.teachingOutline);

    this.isLoading = false;

    if (!result.success) {
      this.errorMsg = result.error || '生成失败，请重试';
    }

  }


  build() {
    Column({ space: 20 }) {

      TextArea({ placeholder: '如生成关于二叉树的教学大纲' , text: this.teachingOutline})
        .onChange((value: string) => {
          this.teachingOutline = value;
        })
        .fontFamily('思源黑体, 宋体, sans-serif') // 优先使用中文字体
        .fontSize(16)
        .width('90%')
        .height(150)
        .width('100%')
        .height(150)
        .backgroundColor('#F5F5F5')
        .fontSize(20)
        .padding(10)
        .borderRadius(8)


      // 添加点击事件的按钮
      Button('生成教学内容')
        .width('80%')
        .height(80)
        .fontSize(18)
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

      Button('教学大纲预览')
        .width('80%')
        .height(80)
        .fontSize(18)
        .onClick(() => router.pushUrl({ url: 'pages/Tjiaoxueshejdagang' }))

      Button('返回主界面')
        .width('80%')
        .height(80)
        .fontSize(18)
        .onClick(() => router.pushUrl({ url: 'pages/TeacherIndex' }))



    }
    .width('100%')
    .height('100%')
    .padding(15)
  }
}