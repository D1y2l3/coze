import { router } from "@kit.ArkUI";
import { DBConsole } from "./DBConsole";
import { DBTable } from "./enrollmentArtDate";
import { UserRegistrationEntity } from "./enrollmentArtDate";
import promptAction from "@ohos.promptAction";
import ArrayList from "@ohos.util.ArrayList";
import { BusinessError } from "@kit.BasicServicesKit";
import { relationalStore } from "@kit.ArkData";

@Entry
@Component
struct Page1 {
  // 数据库控制台实例
  private dbConsole: DBConsole = new DBConsole();
  // 表单数据
  @State phoneNumber: string = '';
  @State email: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State selectedIndex: number = 0;
  manager: string[] = ['学生', '教师', '管理者'];

  // 初始化
  aboutToAppear() {
    // 创建用户注册表实例（确保此处及 DBTable 内部无提示调用）
    const userTable = DBTable.GetUSERREGISTERDBTableInstance();

    // 添加表到数据库控制台（确保 DBConsole 构造函数/setter 无提示）
    const tables: ArrayList<DBTable> = new ArrayList<DBTable>();
    tables.add(userTable);
    this.dbConsole.DBTables = tables;

    // 初始化数据库连接（仅保留日志，无提示）
    this.initDatabase();
  }

  // 初始化数据库连接（移除任何提示逻辑）
  private initDatabase() {
    this.dbConsole.GetDBStore(() => {
      console.info('数据库初始化成功'); // 仅控制台日志，无UI提示
    });
  }

  // 验证表单数据（保留必要提示）
  private validateForm(): boolean {
    // 验证手机号码
    if (!this.phoneNumber || this.phoneNumber.length !== 11) {
      promptAction.showToast({ message: '请输入有效的11位手机号码' });
      return false;
    }

    // 验证邮箱
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!this.email || !emailRegex.test(this.email)) {
      promptAction.showToast({ message: '请输入有效的邮箱地址' });
      return false;
    }

    // 验证密码
    if (!this.password || this.password.length < 6) {
      promptAction.showToast({ message: '密码长度至少为6位' });
      return false;
    }

    // 验证确认密码
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return false;
    }

    return true;
  }

  // 处理注册逻辑（保留必要提示）
  private handleRegistration() {
    if (!this.validateForm()) {
      return;
    }

    const userId = 'user_' + new Date().getTime();
    const user = new UserRegistrationEntity({
      id: userId,
      phoneNumber: this.phoneNumber,
      password: this.password,
      email: this.email,
      userType: this.manager[this.selectedIndex] // 传入人员类型
    });

    this.saveUserToDatabase(user);
  }

  // 保存用户到数据库
   private async saveUserToDatabase(user: UserRegistrationEntity) {
    if (!this.dbConsole.RDBStore) {
      promptAction.showToast({ message: '数据库连接失败，请重试' });
      return;
    }


    const sql = `INSERT INTO UserRegistrationTable (ID, PhoneNumber, Password, Email,UserType)
                VALUES (?, ?, ?, ?,?)`;
    try {
      console.log('user',JSON.stringify(user))
      const valueBucket: relationalStore.ValuesBucket = {
        "ID":user.id,
        "PhoneNumber":user.phoneNumber,
        "Password": user.password,
        "Email": user.email,
        "UserType":user.userType,
      }
   let row =  await this.dbConsole.RDBStore.insert("UserRegistrationTable",valueBucket )
      promptAction.showToast({ message: `注册成功，请登录${row}` });

      setTimeout(() => {
        router.pushUrl({ url: "pages/Index" });
      }, 1000); // 延迟1秒跳转，让用户看到提示

    } catch (e) {
      console.error('插入用户数据失败:', JSON.stringify(e));
    }

  }

  build() {
    // 根组件布局（无提示相关修改）
    Column({ space: 20 }) {
      // logo区域
      Column() {
        Row() {
          Image($r('app.media.denglu'))
            .width(60)
            .height(60)
            .margin({ top: 20 })
        }

        Row() {
          Text("教与学与管助手")
            .fontSize(15)
            .fontWeight(400)
            .margin({ top: 12 })
        }

        Row() {
          Text("注册界面")
            .onClick(async ()=>{
              await  this.dbConsole.RDBStore?.querySql("SELECT * FROM UserRegistrationTable ").then((resSet: relationalStore.ResultSet) => {
                console.info(`UserRegistrationTable=>结果集行数: ${resSet.rowCount}`);
                resSet.close()
              }).catch((err: BusinessError) => {
                console.error(`allData()=>query失败 code is ${err.code},message is ${err.message}`);
              })
            })
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 16 })
        }
      }.width("100%").margin({ top: 10 })

      // 输入框区域
      Column() {
        Column({ space: 15 }) {
          Row({ space: 10 }) {
            // 人员标签
            Text('人员选择')
              .width('30%')
              .height(45)
              .backgroundColor('#F1F3F5')
              .fontSize(20)
              .borderRadius(24) // 圆角半径
              .textAlign(TextAlign.Center) // 文本水平居中
              .alignSelf(ItemAlign.Auto) // 修改为ItemAlign类型

            // 性别选项
            Text(this.manager[this.selectedIndex])
              .fontSize(20)
              .fontWeight(FontWeight.Normal) // 加粗文本
              .padding({
                left: 20,
                right: 20,
                top: 8,
                bottom: 8
              }) // 调整内边距
              .backgroundColor('#F1F3F5') // 设置背景色
              .borderRadius(24) // 圆角半径（高度的一半，实现胶囊形）
              .textAlign(TextAlign.Center) // 文本水平居中

              .onClick(() => {
                TextPickerDialog.show({
                  range: this.manager,
                  selected: this.selectedIndex,
                  onAccept: (value: TextPickerResult) => {
                    this.selectedIndex = value.index as number;
                  },
                  onCancel: () => {
                    console.info('取消选择')
                  },
                  onChange: (value: TextPickerResult) => {
                    console.info('当前文本:${JSON.stringify(value)}')
                  }
                })
              })
          }

          // 手机号码输入框
          TextInput({ placeholder: '手机号码' })
            .width('100%')
            .height(45)
            .backgroundColor('#F1F3F5')
            .fontSize(20)
            .placeholderColor('#99182431')
            .margin({ top: 12 })
            .padding({ left: 0 })
            .maxLength(11)
            .type(InputType.Number)
            .onChange((value) => this.phoneNumber = value)
          Line().width('100%').height(1).backgroundColor(Color.Gray)

          // 邮箱输入框
          TextInput({ placeholder: '邮箱' })
            .width('100%')
            .height(45)
            .backgroundColor('#F1F3F5')
            .fontSize(20)
            .placeholderColor('#99182431')
            .margin({ top: 12 })
            .padding({ left: 0 })
            .maxLength(50)
            .type(InputType.Email)
            .onChange((value) => this.email = value)
          Line().width('100%').height(1).backgroundColor(Color.Gray)

          // 密码输入框
          TextInput({ placeholder: '密码' })
            .width('100%')
            .height(45)
            .backgroundColor('#F1F3F5')
            .fontSize(20)
            .placeholderColor('#99182431')
            .margin({ top: 12 })
            .padding({ left: 0 })
            .maxLength(8)
            .type(InputType.Password)
            .onChange((value) => this.password = value)
          Line().width('100%').height(1).backgroundColor(Color.Gray)

          // 确认密码输入框
          TextInput({ placeholder: '确认密码' })
            .width('100%')
            .height(45)
            .backgroundColor('#F1F3F5')
            .fontSize(20)
            .placeholderColor('#99182431')
            .margin({ top: 12 })
            .padding({ left: 0 })
            .maxLength(8)
            .type(InputType.Password)
            .onChange((value) => this.confirmPassword = value)
          Line().width('100%').height(1).backgroundColor(Color.Gray)

          // 验证码和重置按钮
          Row() {
            Row() {
              Text('发送信息验证码')
                .fontSize(16)
                .fontColor('#007DFF')
            }.width('50%').justifyContent(FlexAlign.Start)

            Row() {
              Text('重置')
                .fontSize(16)
                .fontColor('#007DFF')
                .onClick(() => {
                  this.phoneNumber = '';
                  this.email = '';
                  this.password = '';
                  this.confirmPassword = '';
                })
            }.width('50%').justifyContent(FlexAlign.End)
          }.width('100%').margin({ top: -5, bottom: 0 })

          // 注册按钮
          Row() {
            Button('注册')
              .fontSize(20)
              .fontColor(Color.White)
              .width('40%')
              .onClick(() => this.handleRegistration())

          }.margin({ bottom: 20, top: 20 })

          // 登录按钮
          Row() {
            Button('登录')
              .fontSize(20)
              .fontColor(Color.White)
              .width('40%')
              .onClick(() => router.pushUrl({ url: "pages/Index" }))
          }.justifyContent(FlexAlign.Center)
        }
      }.width("100%").height("auto")

      //.margin({ top: -50 })
    }
    .height('100%')
    .width('100%')
    .border({ width: 1 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
