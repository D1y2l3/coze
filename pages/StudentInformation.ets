import { router } from '@kit.ArkUI';
import { StudentConsole } from './StudentConsole';
import { StudentDBTable } from './StudentArtDate'; // 引入学生表定义
import { StudentEntity, IStudent } from './StudentArtDate'; // 引入实体类和接口
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import ArrayList from '@ohos.util.ArrayList';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalUserState } from './baocun';
@Entry
@Component
struct StudentInfo {
  private globalState = GlobalUserState.getInstance();

  // @State selectTime: Date | null = null; // 出生日期选择状态
  // gender: string[] = ['男', '女']; // 性别选项
  // titles: string[] = ['计算机科学与技术学院', '电子信息工程学院', '文学院', '理学院'];
  // @State selectedGenderIndex: number = 0; // 选中的性别索引
  // @State selectedTitleIndex: number = 0; // 选中的学院索引
  // @State birthDate: string = '出生日期'; // 出生日期显示文本


  @State college: string='';// 学院
  @State gender: string='';// 性别
  @State school: string = ''; // 学校
  @State name: string = ''; // 姓名
  @State studentId: string = ''; // 学号
  @State className: string = ''; // 班级
  @State phone: string = ''; // 联系电话
  @State age: string = ''; //年龄
  // 新增：标记是否为修改模式（查询到数据则为true）
  @State isEditMode: boolean = false;

  // 数据库控制台实例
  private dbConsole: StudentConsole = new StudentConsole();

  // 初始化（模仿 Page1 的 aboutToAppear + initDatabase 结构）
  aboutToAppear() {
    // 初始化数据库表
    const tables = new ArrayList<StudentDBTable>();
    tables.add(StudentDBTable.GetSTUDENTDBTableInstance());
    this.dbConsole = new StudentConsole(tables);

    // 初始化数据库连接
    this.initDatabase();
  }






  // 初始化数据库连接
  private initDatabase() {
    this.dbConsole.GetDBStore(() => {
      console.info('学生数据库初始化成功');
      // 手机号查询重试逻辑：最多重试3次，间隔300ms（适配异步赋值）
      let retryCount = 0;
      const queryWithRetry = () => {
        if (this.globalState.phoneNumber) {
          this.queryStudentByPhone(this.globalState.phoneNumber);
        } else if (retryCount < 3) {
          retryCount++;
          console.info(`第${retryCount}次重试查询：手机号尚未赋值`);
          setTimeout(queryWithRetry, 300);
        } else {
          console.info('重试3次后仍未获取到手机号，停止查询');
          promptAction.showToast({ message: '请先完成手机号注册/登录' });
        }
      };
      queryWithRetry();
    });
  }

  private async queryStudentByPhone(phone: string) {
    if (!this.dbConsole.RDBStore) {
      console.error('数据库未连接，不执行查询');
      promptAction.showToast({ message: '数据库连接异常，请重启页面' });
      return;
    }
    if (!phone) {
      console.error('手机号为空，不执行查询');
      promptAction.showToast({ message: '未获取到手机号，请重新登录' });
      return;
    }

    try {
      // 精准查询SQL（手机号唯一）
      const querySql = `SELECT * FROM StudentTable WHERE phone= ?`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, [phone]);

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        // 映射查询结果到页面状态
        this.name = resultSet.getString(resultSet.getColumnIndex('name')) || '';
        this.studentId = resultSet.getString(resultSet.getColumnIndex('studentId')) || '';
        this.school = resultSet.getString(resultSet.getColumnIndex('school')) || '';
        this.className = resultSet.getString(resultSet.getColumnIndex('class')) || '';
        this.phone = resultSet.getString(resultSet.getColumnIndex('phone')) || '';
        this.age = resultSet.getString(resultSet.getColumnIndex('age')) || '';
        this.gender = resultSet.getString(resultSet.getColumnIndex('gender')) || '';
        this.college = resultSet.getString(resultSet.getColumnIndex('college')) || '';
        // 标记为修改模式
        this.isEditMode = true;
        console.info(`查询到手机号${phone}对应的学生信息，进入修改模式`);
        promptAction.showToast({ message: '已加载您的信息，可直接修改' });
      } else {
        console.info(`未查询到手机号${phone}对应的学生信息，进入新增模式`);
        this.isEditMode = false;
        // 新增模式下，默认填充全局手机号（禁止修改）
        this.phone = phone;
      }

      resultSet.close(); // 释放结果集资源
    } catch (err) {
      console.error('查询学生信息失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询学生信息失败' });
    }
  }

  // 表单验证
  private validateForm(): boolean {
    // 姓名校验
    if (!this.name) {
      promptAction.showToast({ message: '请输入姓名' });
      return false;
    }
    // 学号校验
    if (!this.studentId) {
      promptAction.showToast({ message: '请输入学号' });
      return false;
    }
    // 学校校验
    if (!this.school) {
      promptAction.showToast({ message: '请输入学校' });
      return false;
    }
    // 班级校验
    if (!this.className) {
      promptAction.showToast({ message: '请输入班级' });
      return false;
    }
    // 电话校验（11位手机号）
    if (!this.phone || this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入有效的11位手机号码' });
      return false;
    }
    // // 年龄校验
    // if (this.age <= 0 || this.age > 100) {
    //   promptAction.showToast({ message: '请输入有效的年龄（1-100）' });
    //   return false;
    // }

    return true;
  }

  // 处理保存逻辑
  private handleSave() {
    if (!this.validateForm()) {
      return;
    }

    // 构造学生数据
    const studentData: IStudent = {
      id: Date.now() + '' + Math.floor(Math.random() * 1000), // 唯一ID
      studentId: this.studentId,
      name: this.name,
      age: this.age,
      class: this.className,
      school: this.school,
      phone: this.phone,
      college: this.college,
      gender: this.gender
    };


    this.saveStudentToDatabase(studentData);
  }

  // 保存学生数据到数据库
  private async saveStudentToDatabase(studentData: IStudent) {

    const sql = `INSERT INTO StudentTable (
    id, studentId, name, age, class,
    school, phone,  college, gender
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?,?)`;

    // 1. 校验数据库连接
    if (!this.dbConsole.RDBStore) {
      promptAction.showToast({ message: '数据库连接失败，请重试' });
      return;
    }

    try {
      // 2. 打印调试数据
      console.log('studentData', JSON.stringify(studentData));

      // 3. 直接用对象字面量定义
      const valueBucket: relationalStore.ValuesBucket = {
        "id": studentData.id,
        "studentId": studentData.studentId,
        "name": studentData.name,
        "age": studentData.age,
        "class": studentData.class,
        "school": studentData.school,
        "phone": studentData.phone,
        "college": studentData.college,
        "gender": studentData.gender
      };
      if (this.isEditMode) {
        // 修改模式：执行更新（根据phone唯一标识更新）
        const updateSql = `UPDATE StudentTable SET
          studentId = ?, name = ?, age = ?, class = ?,
          school = ?, college = ?, gender = ?
          WHERE phone = ?`;
        // 执行更新：参数顺序与SQL字段顺序一致
        const updateCount = await this.dbConsole.RDBStore.executeSql(updateSql, [
          studentData.studentId,
          studentData.name,
          studentData.age,
          studentData.class,
          studentData.school,
          studentData.college,
          studentData.gender,
          studentData.phone // where条件：手机号
        ]);
        promptAction.showToast({ message: `信息更新成功！影响行数：${updateCount}` });
      } else {
        // 新增模式：执行插入（保留原逻辑，补充id字段）
        valueBucket["id"] = studentData.id;
        const rowId = await this.dbConsole.RDBStore.insert(
          StudentDBTable.GetSTUDENTDBTableInstance().TableName,
          valueBucket
        );
        promptAction.showToast({ message: `信息保存成功！行ID：${rowId}` });
      }

    } catch (err) {
      console.error(`${this.isEditMode ? '更新' : '插入'}学生数据失败:`, JSON.stringify(err));
      promptAction.showToast({ message: `${this.isEditMode ? '更新' : '保存'}失败，请重试` });
    }
  }
  //     // 4. 执行插入
  //     let Srow = await this.dbConsole.RDBStore.insert(
  //       StudentDBTable.GetSTUDENTDBTableInstance().TableName,
  //       valueBucket
  //     );
  //
  //     // 5. 成功提示
  //     promptAction.showToast({ message: `信息保存成功！行ID：${Srow}` });
  //
  //     // 6. 成功后处理
  //     setTimeout(() => {
  //     }, 1000);
  //
  //   } catch (err) {
  //     // 7. 错误处理
  //     console.error('插入学生数据失败:', JSON.stringify(err));
  //     promptAction.showToast({ message: '保存失败，请重试' });
  //   }
  // }



  build() {
    Column() {
      Column() {


        //学校输入
        TextInput({ placeholder: '学校' ,text: this.school})
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.school = value.trim() );

        // 姓名输入
        TextInput({ placeholder: '姓名' ,text: this.name})
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.name = value.trim());

        // 学号输入
        TextInput({ placeholder: '学号' , text: this.studentId})
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.studentId = value.trim());

        // 所属年级
        TextInput({ placeholder: '班级', text: this.className  })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.className = value.trim());

        // 联系电话
        TextInput({ placeholder: '联系电话', text: this.phone  })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .type(InputType.PhoneNumber) // 电话键盘
          .onChange((value) => this.phone = value.trim());

        // 年龄输入框
        TextInput({ placeholder: '年龄', text: this.age })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .type(InputType.Number)
          .onChange((value) => this.age = value.trim());




        // 性别输入框
        TextInput({ placeholder: '性别', text: this.gender})
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.gender = value.trim());


        // 学院输入框
        TextInput({ placeholder: '学院', text: this.college })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.college = value.trim());



        // //出生年月选择
        // TextInput({
        //   placeholder: '出生年月',
        //   text: this.birthDate
        // })
        //   .width('80%')
        //   .height(45)
        //   .backgroundColor('#F1F3F5')
        //   .fontSize(20)
        //   .fontColor(Color.Black)
        //   .placeholderColor('#99182431')
        //   .margin({ top: 12 })
        //   .padding({ left: 15 })
          // .onClick(() => {

            // this.getUIContext().showDatePickerDialog({
            //   start: new Date("2000-1-1"),
            //   end: new Date("2025-12-31"),
            //   selected: this.selectTime,
            //   textStyle: { color: '#2787d9', font: { size: '14fp', weight: FontWeight.Normal } },
            //   selectedTextStyle: { color: '#004aaf', font: { size: '18fp', weight: FontWeight.Regular } },
            //   acceptButtonStyle: { fontColor: '#2787d9', fontSize: '16fp', backgroundColor: '#f7f7f7', borderRadius: 10
            //   },
            //   cancelButtonStyle: { fontColor: Color.Red, fontSize: '16fp', backgroundColor: '#f7f7f7', borderRadius: 10
            //   },
            //   onAccept: (value: DatePickerResult) => {
            //     if (value.year !== undefined && value.month !== undefined && value.day !== undefined) {
            //       this.selectTime = new Date(value.year, value.month - 1, value.day);
            //       this.birthDate = `${value.year}-${value.month}-${value.day}`;
            //     } else {
            //       console.error('日期选择器返回值缺少必要属性');
            //     }
            //   }
            // })
          // })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)

      // // 性别选择行
      // Row({ space: 50 }) {
      //   Text('性别')
      //     .width('50%')
      //     .height(45)
      //     .backgroundColor('#F1F3F5')
      //     .fontSize(20)
      //     .borderRadius(24)
      //     .textAlign(TextAlign.Center)
      //     .alignSelf(ItemAlign.Auto)
      //
      //   Text(this.gender[this.selectedGenderIndex])
      //     .fontSize(20)
      //     .fontWeight(FontWeight.Normal)
      //     .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      //     .backgroundColor('#F1F3F5')
      //     .borderRadius(24)
      //     .textAlign(TextAlign.Center)
      //     .onClick(() => {
      //       TextPickerDialog.show({
      //         range: this.gender,
      //         selected: this.selectedGenderIndex,
      //         onAccept: (value: TextPickerResult) => {
      //           this.selectedGenderIndex = value.index as number;
      //         },
      //         onCancel: () => {
      //           console.info('取消性别选择')
      //         }
      //       })
      //     })
      // }
      // .width('80%')
      // .justifyContent(FlexAlign.Start)
      // .margin({ top: 12 })


      // Row({ space: 20 }) {
      //   Text('学院')
      //     .width('20%')
      //     .height(45)
      //     .backgroundColor('#F1F3F5')
      //     .fontSize(20)
      //     .borderRadius(24)
      //     .textAlign(TextAlign.Center)
      //     .alignSelf(ItemAlign.Auto)
      //
      //   Text(this.titles[this.selectedTitleIndex])
      //     .fontSize(20)
      //     .fontWeight(FontWeight.Normal)
      //     .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      //     .backgroundColor('#F1F3F5')
      //     .borderRadius(24)
      //     .textAlign(TextAlign.Center)
      //     .onClick(() => {
      //       TextPickerDialog.show({
      //         range: this.titles,
      //         selected: this.selectedTitleIndex,
      //         onAccept: (value: TextPickerResult) => {
      //           this.selectedTitleIndex = value.index as number;
      //         },
      //         onCancel: () => {
      //           console.info('取消学院选择')
      //         }
      //       })
      //     })
      // }
      // .width('80%')
      // .justifyContent(FlexAlign.Start)
      // .margin({ top: 12 })

      // 保存按钮
      Button(this.isEditMode ? '更新信息' : '保存信息')
        .width('80%')
        .height(50)
        .fontSize(20)
        .backgroundColor('#2787d9')
        .borderRadius(25)
        .margin({ top: 30 })
        .onClick(() => this.handleSave());



      Button('返回主界面')
        .width('80%')
        .height(50)
        .fontSize(20)
        .backgroundColor('#2787d9')
        .borderRadius(25)
        .margin({ top: 30 })
        .onClick(() => router.pushUrl({ url: 'pages/StudentIndex' }))





    }






    .width('100%')
    .padding({ top: 20 })
  }
}

