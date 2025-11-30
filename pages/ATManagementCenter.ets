import { TeacherConsole } from './TeacherConsole';
import { TeacherDBTable } from './TeacherArtDate';
import { ITeacher } from './TeacherArtDate';
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import ArrayList from '@ohos.util.ArrayList';
import { BusinessError } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct TeacherCollegeList {
  @State teachers: ITeacher[] = []; // 存储教师学院数据
  private dbConsole: TeacherConsole = new TeacherConsole();

  aboutToAppear() {
    this.initDatabaseAndQuery(); // 页面初始化时连接数据库并查询
  }

  /** 初始化数据库连接并执行查询 */
  private initDatabaseAndQuery() {
    const tables = new ArrayList<TeacherDBTable>();
    tables.add(TeacherDBTable.GetTEACHERDBTableInstance());
    this.dbConsole = new TeacherConsole(tables);

    this.dbConsole.GetDBStore(() => {
      console.info('教师数据库连接成功，开始查询学院数据');
      this.queryTeacherCollege();
    });
  }

  /** 查询教师所属学院 */
  private async queryTeacherCollege() {
    if (!this.dbConsole.RDBStore) {
      console.error('数据库未连接，查询失败');
      promptAction.showToast({ message: '数据库连接异常', duration: 3000 });
      return;
    }

    try {
      // 仅查询id和department（学院）字段，减少数据开销
      const querySql = `SELECT id, department FROM TeacherTable`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, []);

      this.teachers = [];

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const teacher: ITeacher = {
            id: resultSet.getString(resultSet.getColumnIndex('id')) || '',
            department: resultSet.getString(resultSet.getColumnIndex('department')) || '',
            teacherId: '',
            name: '',
            title: '',
            school: '',
            phone: '',
            gender: '',
            teachingAge: ''
          };
          this.teachers.push(teacher);
        } while (resultSet.goToNextRow());

        console.info(`查询到${this.teachers.length}个教师学院数据`);
      } else {
        console.info('未查询到教师学院数据');
      }

      resultSet.close();
    } catch (err) {
      console.error('查询教师学院数据失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询失败，请重试', duration: 3000 });
    }
  }

  build() {
    Column() {
      Text('教师学院列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      List() {
        ForEach(this.teachers, (teacher: ITeacher) => {
          ListItem() {
            Column() {
              Text('学院:')
                .fontSize(14)
                .fontColor('#999999')
                .alignSelf(ItemAlign.Start);
              Text(teacher.department)
                .fontSize(16)
                .fontColor('#333333')
                .alignSelf(ItemAlign.Start)
                .margin({ top: 4 });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 20 })
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 12 })
            .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/TeacherListByCollege', // 需在pages.json中注册
                params: { collegeName: teacher.department } // 传递学院名称
              });

            });
          }
        });
      }
      .width('90%') // 将width和height移动到List组件上
      .height('80%')
      .width('100%')
      .backgroundColor('#F5F5F5');
    }
  }
}