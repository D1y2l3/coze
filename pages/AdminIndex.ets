import { GlobalUserState } from './baocun';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct StudentPage {
  private globalState = GlobalUserState.getInstance();

  build() {
    Column() {
      Text(`管理者页面 - 欢迎您：${this.globalState.phoneNumber}`)
        .fontSize(20)
        .margin(20)

      Column({ space: 20 }) {

      Button('教师管理中心')
        .width('80%')
        .height(80)
        .fontSize(18)
        .onClick(() => router.pushUrl({ url: 'pages/ATManagementCenter' }))

      Button('学生管理中心')
        .width('80%')
        .height(80)
        .fontSize(18)
        .onClick(() => router.pushUrl({ url: 'pages/ASManagementCenter2' }))

        // Button('管理数据中心')
        //   .width('80%')
        //   .height(80)
        //   .fontSize(18)
        //   .onClick(() => router.pushUrl({ url: 'pages/AManagementCenter' }))


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