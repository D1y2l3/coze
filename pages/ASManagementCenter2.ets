import { StudentConsole } from './StudentConsole';
import { StudentDBTable } from './StudentArtDate';
import { IStudent } from './StudentArtDate';
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import ArrayList from '@ohos.util.ArrayList';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalUserState } from './baocun';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct ASManagementCenter2 {
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
      console.info('学生数据库连接成功，开始查询学院数据');
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
      // 简化SQL：仅查询id（用于唯一标识）和college（学院）字段
      const querySql = `SELECT id, college FROM StudentTable`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, []);

      this.students = [];

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const student: IStudent = {
            id: resultSet.getString(resultSet.getColumnIndex('id')) || '',
            college: resultSet.getString(resultSet.getColumnIndex('college')) || '',
            studentId: '',
            name: '',
            age: '',
            class: '',
            school: '',
            phone: '',
            gender: ''
          };
          this.students.push(student);
        } while (resultSet.goToNextRow());

        console.info(`查询到${this.students.length}个学院数据`);
      } else {
        console.info('未查询到学院数据');
      }

      resultSet.close();
    } catch (err) {
      console.error('查询学院数据失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询失败，请重试' });
    }
  }

  build() {
    Column() {
      Text('学院列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      List() {
        ForEach(this.students, (student: IStudent) => {
          ListItem() {
            Column() {
              Text('学院:')
                .fontSize(14)
                .fontColor('#999999')
                .alignSelf(ItemAlign.Start);
              Text(student.college)
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
            // 点击学院时，跳转至班级列表页并传递学院名称
            .onClick(() => {
              router.pushUrl({
                url: 'pages/StudentCollegeClassList',
                params: { collegeName: student.college }
              });
            });
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