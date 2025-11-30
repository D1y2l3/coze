import { router } from '@kit.ArkUI';
import { StudentConsole } from './StudentConsole';
import { StudentDBTable } from './StudentArtDate';
import { TeacherConsole } from './TeacherConsole';
import { TeacherDBTable } from './TeacherArtDate';
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import ArrayList from '@ohos.util.ArrayList';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalUserState } from './baocun';



@Entry
@Component
struct TManagementCenter {
  @State classes: string[] = []; // 存储班级列表（修改：从学生列表改为班级列表）
  @State teacherCollege: string = ''; // 存储教师所属学院
  private dbConsole: StudentConsole = new StudentConsole();
  private teacherConsole: TeacherConsole = new TeacherConsole(); // 教师数据库控制台
  private globalState = GlobalUserState.getInstance();

  aboutToAppear() {
    this.initTeacherAndClassData(); // 调整：初始化流程获取学院→学院和班级数据
  }

  /** 初始化流程：先查教师学院，再查该学院班级 */
  private initTeacherAndClassData() {
    // 1. 初始化教师数据库，查询当前教师的学院
    const teacherTables = new ArrayList<TeacherDBTable>();
    teacherTables.add(TeacherDBTable.GetTEACHERDBTableInstance());
    this.teacherConsole = new TeacherConsole(teacherTables);

    this.teacherConsole.GetDBStore(() => {
      console.info('教师数据库连接成功，开始查询教师学院');
      this.queryTeacherCollege(); // 查询教师所属学院
    });
  }

  /** 查询当前教师的学院（通过全局手机号关联） */
  private async queryTeacherCollege() {
    if (!this.teacherConsole.RDBStore) {
      console.error('教师数据库未连接，查询失败');
      promptAction.showToast({ message: '教师数据库连接异常' });
      return;
    }

    const phone = this.globalState.phoneNumber;
    if (!phone) {
      console.error('未获取到当前教师手机号');
      promptAction.showToast({ message: '请先登录' });
      return;
    }

    try {
      // 查询教师表中当前手机号对应的教师学院
      const querySql = `SELECT department FROM TeacherTable WHERE phone = ?`;
      const resultSet = await this.teacherConsole.RDBStore.querySql(querySql, [phone]);

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        this.teacherCollege = resultSet.getString(resultSet.getColumnIndex('department')) || '';
        console.info(`当前教师所属学院：${this.teacherCollege}`);

        if (this.teacherCollege) {
          // 2. 教师学院获取成功后，查询该学院的班级
          this.initStudentDatabaseAndQueryClasses(); // 调整：查询班级而非学生
        } else {
          promptAction.showToast({ message: '未查询到教师所属学院' });
        }
      } else {
        console.info(`未查询到手机号${phone}对应的教师信息`);
        promptAction.showToast({ message: '未查询到教师信息' });
      }

      resultSet.close();
    } catch (err) {
      console.error('查询教师学院失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询教师信息失败' });
    }
  }

  /** 初始化学生数据库，并查询指定学院的班级 */
  private initStudentDatabaseAndQueryClasses() {
    const studentTables = new ArrayList<StudentDBTable>();
    studentTables.add(StudentDBTable.GetSTUDENTDBTableInstance());
    this.dbConsole = new StudentConsole(studentTables);

    this.dbConsole.GetDBStore(() => {
      console.info('学生数据库连接成功，开始查询指定学院班级');
      this.queryClassesByCollege(this.teacherCollege); // 调整：查询班级
    });
  }

  /** 根据学院查询班级（核心修改：查询班级并去重） */
  private async queryClassesByCollege(college: string) {
    if (!this.dbConsole.RDBStore) {
      console.error('学生数据库未连接，查询失败');
      promptAction.showToast({ message: '学生数据库连接异常' });
      return;
    }

    if (!college) {
      console.error('学院信息为空，无法筛选班级');
      return;
    }

    try {
      // 查询学生表中属于当前教师学院的所有班级
      const querySql = `SELECT class FROM StudentTable WHERE college = ?`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, [college]);

      this.classes = []; // 清空现有班级列表

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const className = resultSet.getString(resultSet.getColumnIndex('class')) || '';
          // 去重逻辑：仅添加未包含的班级
          if (className && !this.classes.includes(className)) {
            this.classes.push(className);
          }
        } while (resultSet.goToNextRow());

        console.info(`查询到${this.classes.length}个【${college}】学院的班级`);
      } else {
        console.info(`未查询到【${college}】学院的班级数据`);
        promptAction.showToast({ message: `未查询到${college}的班级` });
      }

      resultSet.close();
    } catch (err) {
      console.error('查询班级数据失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询班级失败，请重试' });
    }
  }

  // 点击班级跳转至班级详情（新增：班级点击事件）
  private navigateToClassDetail(className: string) {
    router.pushUrl({
      url: 'pages/StudentClassDetail', // 假设的班级详情页
      params: {
        collegeName: this.teacherCollege,
        className: className
      }
    });
  }

  build() {
    Column() {
      // 标题修改：从学生列表改为班级列表
      Text(`【${this.teacherCollege || '加载中...'}】班级列表`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })


      List() {
        // 遍历班级列表（核心UI修改）
        ForEach(this.classes, (className: string) => {
          ListItem() {
            Column() {
              Text('班级:')
                .fontSize(14)
                .fontColor('#999999')
                .alignSelf(ItemAlign.Start);
              Text(className)
                .fontSize(16)
                .fontColor('#333333')
                .alignSelf(ItemAlign.Start)
                .margin({ top: 4 });
            }
            .width('100%')
            .padding({
              left: 16,
              right: 16,
              top: 20,
              bottom: 20
            })
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 12 })
            .shadow({
              radius: 2,
              color: '#1A000000',
              offsetX: 0,
              offsetY: 1
            })
            .onClick(() => this.navigateToClassDetail(className)); // 点击跳转详情
          }
        });
      }
      .width('90%')
      .height('80%');
    }
    .width('100%')
    .backgroundColor('#F5F5F5');
  }
}