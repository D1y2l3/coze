import { router } from '@kit.ArkUI';
import { StudentConsole } from './StudentConsole';
import { StudentDBTable } from './StudentArtDate';
import { TeacherConsole } from './TeacherConsole';
import { TeacherDBTable } from './TeacherArtDate';
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import ArrayList from '@ohos.util.ArrayList';
import { GlobalUserState } from './baocun';
import { BusinessError } from '@kit.BasicServicesKit';
import http from '@ohos.net.http';

@Entry
@Component
struct TeacherCollegeHomework {
  @State classes: string[] = [];
  @State teacherCollege: string = '';
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  private dbConsole: StudentConsole = new StudentConsole();
  private teacherConsole: TeacherConsole = new TeacherConsole();
  private globalState: GlobalUserState = GlobalUserState.getInstance();

  aboutToAppear() {
    this.initData();
  }

  private initData(): void {
    this.isLoading = true;
    const teacherTables: ArrayList<TeacherDBTable> = new ArrayList<TeacherDBTable>();
    teacherTables.add(TeacherDBTable.GetTEACHERDBTableInstance());
    this.teacherConsole = new TeacherConsole(teacherTables);

    this.teacherConsole.GetDBStore(() => {
      console.info('教师数据库连接成功，查询所属学院');
      this.queryTeacherCollege();
    });
  }

  private async queryTeacherCollege(): Promise<void> {
    if (!this.teacherConsole.RDBStore) {
      this.handleError('教师数据库连接失败');
      return;
    }

    const phone: string | undefined = this.globalState.phoneNumber;
    if (!phone) {
      this.handleError('未获取到教师信息，请重新登录');
      return;
    }

    try {
      const querySql: string = `SELECT department FROM TeacherTable WHERE phone = ?`;
      this.teacherConsole.RDBStore.querySql(querySql, [phone])
        .then((resultSet: relationalStore.ResultSet) => {
          if (resultSet && resultSet.rowCount > 0) {
            resultSet.goToFirstRow();
            this.teacherCollege = resultSet.getString(resultSet.getColumnIndex('department')) || '';
            if (this.teacherCollege) {
              this.initStudentDBAndQueryClasses();
            } else {
              this.handleError('未查询到教师所属学院');
            }
          } else {
            this.handleError('未查询到教师信息');
          }
          resultSet.close();
        })
        .catch((err: BusinessError) => {
          this.handleError(`查询学院失败：${JSON.stringify(err)}`);
        });
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      this.handleError(`查询学院异常：${JSON.stringify(error)}`);
    }
  }

  private initStudentDBAndQueryClasses(): void {
    const studentTables: ArrayList<StudentDBTable> = new ArrayList<StudentDBTable>();
    studentTables.add(StudentDBTable.GetSTUDENTDBTableInstance());
    this.dbConsole = new StudentConsole(studentTables);

    this.dbConsole.GetDBStore(() => {
      console.info('学生数据库连接成功，开始查询班级');
      this.queryClassesByCollege();
    });
  }

  private queryClassesByCollege(): void {
    if (!this.teacherCollege) {
      this.handleError('学院信息为空，无法查询班级');
      return;
    }
    if (!this.dbConsole.RDBStore) {
      this.handleError('学生数据库未连接，无法查询班级');
      return;
    }

    try {
      const querySql: string = `SELECT class FROM StudentTable WHERE college = ?`;
      this.dbConsole.RDBStore.querySql(querySql, [this.teacherCollege])
        .then((resultSet: relationalStore.ResultSet) => {
          this.classes = [];
          if (resultSet && resultSet.rowCount > 0) {
            resultSet.goToFirstRow();
            do {
              const className: string = resultSet.getString(resultSet.getColumnIndex('class')) || '';
              if (className && !this.classes.includes(className)) {
                this.classes.push(className);
              }
            } while (resultSet.goToNextRow());
          } else {
            this.errorMsg = `未查询到【${this.teacherCollege}】的班级`;
            promptAction.showToast({ message: this.errorMsg });
          }
          resultSet.close();
          this.isLoading = false;
        })
        .catch((err: BusinessError) => {
          this.handleError(`查询班级失败：${JSON.stringify(err)}`);
        });
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      this.handleError(`班级查询异常：${JSON.stringify(error)}`);
    }
  }

  private handleError(msg: string): void {
    console.error(msg);
    this.errorMsg = msg;
    promptAction.showToast({ message: msg });
    this.isLoading = false;
  }

  // 处理发布逻辑（可根据需求扩展）
  private handlePublish(className: string): void {
    promptAction.showToast({ message: `即将发布到班级：${className}` });

  }

  build() {
    Column() {
      Text(`${this.teacherCollege || '加载中...'} 班级列表`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center);

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#007DFF');
          Text('正在加载班级列表...')
            .fontSize(14)
            .margin({ top: 10 });
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.errorMsg) {
        Column() {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor(Color.Red)
            .margin(20);
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(
            this.classes,
            (className: string) => {
              ListItem() {
                Row({ space: 12 }) {
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
                  .flexGrow(1);

                  Button('发布')
                    .type(ButtonType.Normal)
                    .backgroundColor('#007AFF')
                    .fontColor(Color.White)
                    .fontSize(12)
                    .borderRadius(4)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .onClick(() => this.handlePublish(className));
                }
                .width('100%')
                .padding(16)
                .backgroundColor(Color.White)
                .borderRadius(8)
                .margin({ bottom: 12 })
                .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 });
              }
            },
            (className: string) => className
          );
        }
        .width('90%')
        .height('80%');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}