import { router } from '@kit.ArkUI';
import { TeacherConsole } from './TeacherConsole';
import { TeacherDBTable } from './TeacherArtDate'; // 引入教师表定义
import { TeacherEntity, ITeacher } from './TeacherArtDate'; // 引入实体类和接口
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import ArrayList from '@ohos.util.ArrayList';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalUserState } from './baocun';

@Entry
@Component
struct TeacherInfo {
  private globalState = GlobalUserState.getInstance();

  // 教师信息状态变量（与表字段一一对应）
  @State school: string = ''; // 学校
  @State name: string = ''; // 姓名
  @State gender: string = ''; // 性别
  @State teacherId: string = ''; // 工号
  @State department: string = ''; // 所属部门
  @State title: string = ''; // 职称
  @State teachingAge: string = ''; // 教龄
  @State phone: string = ''; // 联系电话
  @State isEditMode: boolean = false; // 标记是否为修改模式

  // 数据库控制台实例
  private dbConsole: TeacherConsole = new TeacherConsole();

  // 生命周期：组件加载时初始化
  aboutToAppear() {
    // 初始化数据库表
    const tables = new ArrayList<TeacherDBTable>();
    tables.add(TeacherDBTable.GetTEACHERDBTableInstance());
    this.dbConsole = new TeacherConsole(tables);

    // 初始化数据库连接并查询数据
    this.initDatabase();
  }

  // 初始化数据库连接
  private initDatabase() {
    this.dbConsole.GetDBStore(() => {
      console.info('教师数据库初始化成功');
      // 手机号查询重试逻辑：最多重试3次，间隔300ms
      let retryCount = 0;
      const queryWithRetry = () => {
        if (this.globalState.phoneNumber) {
          this.queryTeacherByPhone(this.globalState.phoneNumber);
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

  // 根据手机号查询教师信息
  private async queryTeacherByPhone(phone: string) {
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
      const querySql = `SELECT * FROM TeacherTable WHERE phone= ?`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, [phone]);

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        // 映射查询结果到页面状态
        this.name = resultSet.getString(resultSet.getColumnIndex('name')) || '';
        this.teacherId = resultSet.getString(resultSet.getColumnIndex('teacherId')) || '';
        this.school = resultSet.getString(resultSet.getColumnIndex('school')) || '';
        this.department = resultSet.getString(resultSet.getColumnIndex('department')) || '';
        this.phone = resultSet.getString(resultSet.getColumnIndex('phone')) || '';
        this.teachingAge = resultSet.getString(resultSet.getColumnIndex('teachingAge')) || '';
        this.gender = resultSet.getString(resultSet.getColumnIndex('gender')) || '';
        this.title = resultSet.getString(resultSet.getColumnIndex('title')) || '';
        // 标记为修改模式
        this.isEditMode = true;
        console.info(`查询到手机号${phone}对应的教师信息，进入修改模式`);
        promptAction.showToast({ message: '已加载您的信息，可直接修改' });
      } else {
        console.info(`未查询到手机号${phone}对应的教师信息，进入新增模式`);
        this.isEditMode = false;
        // 新增模式下，默认填充全局手机号（禁止修改）
        this.phone = phone;
      }

      resultSet.close(); // 释放结果集资源
    } catch (err) {
      console.error('查询教师信息失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询教师信息失败' });
    }
  }

  // 表单验证（适配教师字段规则）
  private validateForm(): boolean {
    if (!this.name) {
      promptAction.showToast({ message: '请输入姓名' });
      return false;
    }
    if (!this.teacherId) {
      promptAction.showToast({ message: '请输入工号' });
      return false;
    }
    if (!this.school) {
      promptAction.showToast({ message: '请输入学校' });
      return false;
    }
    if (!this.department) {
      promptAction.showToast({ message: '请输入所属部门' });
      return false;
    }
    if (!this.title) {
      promptAction.showToast({ message: '请输入职称' });
      return false;
    }
    if (!this.phone || this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入有效的11位手机号码' });
      return false;
    }
    // 教龄校验（1-40年合理范围）
    const ageNum = Number(this.teachingAge);
    if (!this.teachingAge || ageNum < 1 || ageNum > 40) {
      promptAction.showToast({ message: '请输入有效的教龄（1-40）' });
      return false;
    }
    return true;
  }

  // 处理保存/更新逻辑
  private handleSave() {
    if (!this.validateForm()) {
      return;
    }

    // 构造教师数据（遵循ITeacher接口）
    const teacherData: ITeacher = {
      id: Date.now() + '' + Math.floor(Math.random() * 1000), // 唯一ID
      teacherId: this.teacherId,
      name: this.name,
      title: this.title,
      department: this.department,
      school: this.school,
      phone: this.phone,
      gender: this.gender,
      teachingAge: this.teachingAge
    };

    this.saveTeacherToDatabase(teacherData);
  }

  // 保存教师数据到数据库
  private async saveTeacherToDatabase(teacherData: ITeacher) {
    // 1. 校验数据库连接
    if (!this.dbConsole.RDBStore) {
      promptAction.showToast({ message: '数据库连接失败，请重试' });
      return;
    }

    try {
      // 2. 打印调试数据
      console.log('teacherData', JSON.stringify(teacherData));

      // 3. 构造数据桶
      const valueBucket: relationalStore.ValuesBucket = {
        "id": teacherData.id,
        "teacherId": teacherData.teacherId,
        "name": teacherData.name,
        "title": teacherData.title,
        "department": teacherData.department,
        "school": teacherData.school,
        "phone": teacherData.phone,
        "gender": teacherData.gender,
        "teachingAge": teacherData.teachingAge
      };

      if (this.isEditMode) {
        // 修改模式：根据手机号更新
        const updateSql = `UPDATE TeacherTable SET
          teacherId = ?, name = ?, title = ?, department = ?,
          school = ?, gender = ?, teachingAge = ?
          WHERE phone = ?`;
        const updateCount = await this.dbConsole.RDBStore.executeSql(updateSql, [
          teacherData.teacherId,
          teacherData.name,
          teacherData.title,
          teacherData.department,
          teacherData.school,
          teacherData.gender,
          teacherData.teachingAge,
          teacherData.phone // where条件：手机号
        ]);
        promptAction.showToast({ message: `信息更新成功！影响行数：${updateCount}` });
      } else {
        // 新增模式：执行插入
        valueBucket["teachingAge"] = this.teachingAge; // 补充教龄字段
        const rowId = await this.dbConsole.RDBStore.insert(
          TeacherDBTable.GetTEACHERDBTableInstance().TableName,
          valueBucket
        );
        promptAction.showToast({ message: `信息保存成功！行ID：${rowId}` });
      }

    } catch (err) {
      console.error(`${this.isEditMode ? '更新' : '插入'}教师数据失败:`, JSON.stringify(err));
      promptAction.showToast({ message: `${this.isEditMode ? '更新' : '保存'}失败，请重试` });
    }
  }

  build() {
    Column() {
      Column() {
        // 学校输入
        TextInput({ placeholder: '学校', text: this.school })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.school = value.trim());

        // 姓名输入
        TextInput({ placeholder: '姓名', text: this.name })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.name = value.trim());

        // 性别输入
        TextInput({ placeholder: '性别', text: this.gender })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.gender = value.trim());

        // 工号输入
        TextInput({ placeholder: '工号', text: this.teacherId })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.teacherId = value.trim());

        // 所属部门输入
        TextInput({ placeholder: '所属部门', text: this.department })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.department = value.trim());

        // 职称输入
        TextInput({ placeholder: '职称', text: this.title })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .onChange((value) => this.title = value.trim());

        // 教龄输入
        TextInput({ placeholder: '教龄(年)', text: this.teachingAge })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .type(InputType.Number)
          .onChange((value) => this.teachingAge = value.trim());

        // 联系电话输入
        TextInput({ placeholder: '联系电话', text: this.phone })
          .width('80%')
          .height(45)
          .backgroundColor('#F1F3F5')
          .fontSize(20)
          .placeholderColor('#99182431')
          .margin({ top: 12 })
          .padding({ left: 15 })
          .type(InputType.PhoneNumber)
          .onChange((value) => this.phone = value.trim());
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)

      // 保存/更新按钮
      Button(this.isEditMode ? '更新信息' : '保存信息')
        .width('80%')
        .height(50)
        .fontSize(20)
        .backgroundColor('#2787d9')
        .borderRadius(25)
        .margin({ top: 30 })
        .onClick(() => this.handleSave());

      // 返回主界面按钮
      Button('返回主界面')
        .width('80%')
        .height(50)
        .fontSize(20)
        .backgroundColor('#2787d9')
        .borderRadius(25)
        .margin({ top: 30 })
        .onClick(() => router.pushUrl({ url: 'pages/TeacherIndex' }));
    }
    .width('100%')
    .padding({ top: 20 })
  }
}