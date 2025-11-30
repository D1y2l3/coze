import http from '@ohos.net.http';
import { GlobalUserState } from './baocun';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct StudentPage {
  private globalState = GlobalUserState.getInstance();

  build() {
    Column() {
      Text(`学生页面 - 欢迎您：${this.globalState.phoneNumber}`)
        .fontSize(20)
        .margin(20)

      // 功能入口卡片
      Column({ space: 20 }) {
     //1.考核作业
      Button('作业管理中心')
        .width('80%')
        .height(80)
        .fontSize(18)
        .onClick(() => {
          // this.globalState.logout();
          router.pushUrl({ url: 'pages/StudentHomework3' });})


      Button('番茄时钟')
        .width('80%')
        .height(80)
        .fontSize(18)
        .onClick(() => {
          // this.globalState.logout();
          router.pushUrl({ url: 'pages/fanqieshizhong' });})

        // Button('错题集')
        //   .width('80%')
        //   .height(80)
        //   .fontSize(18)
        //   .onClick(() => {
        //     this.globalState.logout();
        //     router.pushUrl({ url: 'pages/cuotiiben' });})

        Button('笔记事项列表')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => {
            // this.globalState.logout();
            router.pushUrl({ url: 'pages/StudentStickynote' });})

        Button('千问AI大模型')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => {
            // this.globalState.logout();
            router.pushUrl({ url: 'pages/Aichat' });})

        // Button('舒缓音乐')
        //   .width('80%')
        //   .height(80)
        //   .fontSize(18)
        //   .onClick(() => {
        //     this.globalState.logout();
        //     router.pushUrl({ url: 'pages/StudentStickynote' });})
        Button('个人信息中心')
          .width('80%')
          .height(80)
          .fontSize(18)
          .onClick(() => {
            // this.globalState.logout();
            router.pushUrl({ url: 'pages/StudentInformation' });})




      }
      .margin({ top: 50 })

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