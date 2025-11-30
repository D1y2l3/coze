import { router } from '@kit.ArkUI';
import { StudentConsole } from './StudentConsole';
import { StudentDBTable } from './StudentArtDate';
import { IStudent } from './StudentArtDate';
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import ArrayList from '@ohos.util.ArrayList';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalUserState } from './baocun';


@Entry
@Component
struct AManagementCenter {
  @State students: IStudent[] = [];
  private dbConsole: StudentConsole = new StudentConsole();
  private globalState = GlobalUserState.getInstance();

  aboutToAppear() {
    this.initDatabaseAndQuery();
  }

  private initDatabaseAndQuery() {
    const tables = new ArrayList<StudentDBTable>();
    tables.add(StudentDBTable.GetSTUDENTDBTableInstance());
    this.dbConsole = new StudentConsole(tables);

    this.dbConsole.GetDBStore(() => {
      console.info('学生数据库连接成功，开始查询数据');
      this.queryStudentInfo();
    });
  }

  private async queryStudentInfo() {
    if (!this.dbConsole.RDBStore) {
      console.error('数据库未连接，查询失败');
      promptAction.showToast({ message: '数据库连接异常' });
      return;
    }

    try {
      const querySql = `SELECT id, studentId, name, age, class FROM StudentTable`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, []);

      this.students = [];

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const student: IStudent = {
            id: resultSet.getString(resultSet.getColumnIndex('id')) || '',
            studentId: resultSet.getString(resultSet.getColumnIndex('studentId')) || '',
            name: resultSet.getString(resultSet.getColumnIndex('name')) || '',
            age: resultSet.getString(resultSet.getColumnIndex('age')) || '',
            class: resultSet.getString(resultSet.getColumnIndex('class')) || '',
            school: '',
            phone: '',
            college: '',
            gender: ''
          };
          this.students.push(student);
        } while (resultSet.goToNextRow());

        console.info(`查询到${this.students.length}条学生数据`);
      } else {
        console.info('未查询到学生数据');
      }

      resultSet.close();
    } catch (err) {
      console.error('查询学生数据失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询失败，请重试' });
    }
  }

  // 跳转到编辑页面
  private navigateToEdit(student: IStudent) {
    router.pushUrl({
      url: 'pages/StudentInfo', // 假设编辑页路径为StudentInfo
      params: { studentId: student.studentId } // 传递学号用于查询
    });
  }

  // 删除学生数据
  private async deleteStudent(student: IStudent) {
    if (!this.dbConsole.RDBStore) {
      promptAction.showToast({ message: '数据库连接失败，请重试' });
      return;
    }

    try {
      const deleteSql = `DELETE FROM StudentTable WHERE studentId = ?`;
      await this.dbConsole.RDBStore.executeSql(deleteSql, [student.studentId]);
      promptAction.showToast({ message: '删除成功' });
      this.queryStudentInfo(); // 删除后重新查询刷新列表
    } catch (err) {
      console.error('删除学生数据失败:', JSON.stringify(err));
      promptAction.showToast({ message: '删除失败，请重试' });
    }
  }

  build() {
    Column() {
      Text('学生列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })


      List() {
        ForEach(this.students, (student: IStudent) => {
          ListItem() {
            Column({ space: 12 }) {
              // 第一行：学号、姓名、操作按钮
              Row() {
                Column() {
                  Text('学号:')
                    .fontSize(14)
                    .fontColor('#999999')
                    .alignSelf(ItemAlign.Start);
                  Text(student.studentId)
                    .fontSize(14)
                    .fontColor('#333333')
                    .alignSelf(ItemAlign.Start)
                    .margin({ top: 2 });
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Column() {
                  Text('姓名:')
                    .fontSize(14)
                    .fontColor('#999999')
                    .alignSelf(ItemAlign.Start);
                  Text(student.name)
                    .fontSize(14)
                    .fontColor('#333333')
                    .alignSelf(ItemAlign.Start)
                    .margin({ top: 2 });
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Row({ space: 8 }) {
                  Button('编辑')
                    .type(ButtonType.Normal)
                    .backgroundColor('#007AFF')
                    .fontColor(Color.White)
                    .fontSize(12)
                    .borderRadius(4)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .onClick(() => this.navigateToEdit(student));

                  Button('删除')
                    .type(ButtonType.Normal)
                    .backgroundColor('#FF3B30')
                    .fontColor(Color.White)
                    .fontSize(12)
                    .borderRadius(4)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .onClick(() => this.deleteStudent(student));
                }
                .alignItems(VerticalAlign.Top)
                .layoutWeight(1);
              }
              .width('100%')
              .alignItems(VerticalAlign.Top);

              // 第二行：年龄、班级
              Row() {
                Column() {
                  Text('年龄:')
                    .fontSize(14)
                    .fontColor('#999999')
                    .alignSelf(ItemAlign.Start);
                  Text(student.age)
                    .fontSize(14)
                    .fontColor('#333333')
                    .alignSelf(ItemAlign.Start)
                    .margin({ top: 2 });
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Column() {
                  Text('班级:')
                    .fontSize(14)
                    .fontColor('#999999')
                    .alignSelf(ItemAlign.Start);
                  Text(student.class)
                    .fontSize(14)
                    .fontColor('#333333')
                    .alignSelf(ItemAlign.Start)
                    .margin({ top: 2 });
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Row().layoutWeight(1).margin({ left: 16 });
              }
              .width('100%')
              .alignItems(VerticalAlign.Top);
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 12 })
            .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 });
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