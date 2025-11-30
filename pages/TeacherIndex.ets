import { router } from '@kit.ArkUI';
import { GlobalUserState } from './baocun';

@Entry
@Component
struct TeacherIndex {
  private globalState = GlobalUserState.getInstance();

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text(`教师工作台 - ${this.globalState.phoneNumber}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#007DFF')

      // 功能入口卡片
      Column({ space: 20 }) {
        // 1. 备课与设计
        Button('备课与教学设计')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => router.pushUrl({ url: 'pages/TPrepareLesson' }))

        // // 2. 考核内容生成
        // Button('考核内容生成')
        //   .width('80%')
        //   .height(80)
        //   .fontSize(18)
        //   .onClick(() => router.pushUrl({ url: 'pages/TGenerateExam' }))

        // 3. 学情数据分析
        // Button('学情数据分析')
        //   .width('80%')
        //   .height(80)
        //   .fontSize(18)
        //   .onClick(() => router.pushUrl({ url: 'pages/TAnalyze' }))

        // 4. AI生成考题
        Button('AI生成考题页面')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => router.pushUrl({ url: 'pages/TAIgeneratedtestpapers' }))

        // 5. 考核试题中心
        Button('千问AI大模型')
          .width('80%')
          .height(80)
          .fontSize(18)
           .onClick(() => router.pushUrl({ url: 'pages/Aichat' }))

        Button('学生管理中心')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => router.pushUrl({ url: 'pages/TManagementCenter' }))

        Button('题库管理中心')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => router.pushUrl({ url: 'pages/QuestionManagement' }))


        Button('个人信息中心')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => router.pushUrl({ url: 'pages/TeacherInformation' }))

      }
      .margin({ top: 50 })

      // 退出登录
      Button('退出登录')
        .fontColor(Color.Red)
        .backgroundColor(Color.Transparent)
        .margin({ top: 'auto', bottom: 30 })
        .onClick(() => {
          this.globalState.logout();
          router.pushUrl({ url: 'pages/Index' });})
    }
    .width('100%')
    .height('100%')
  }
}