
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
struct TeacherListByCollege {
  @State teachers: ITeacher[] = [];
  @State collegeName: string = ''; // 接收的学院名称
  private dbConsole: TeacherConsole = new TeacherConsole();

  aboutToAppear() {
    // 获取路由传递的学院名称参数
    const params = router.getParams() as Record<string, string>;
    if (params && params.collegeName) {
      this.collegeName = params.collegeName;
      this.initDatabaseAndQuery();
    } else {
      promptAction.showToast({ message: '未获取到学院信息', duration: 3000 });
      router.back(); // 无参数则返回上一页
    }
  }

  private initDatabaseAndQuery() {
    const tables = new ArrayList<TeacherDBTable>();
    tables.add(TeacherDBTable.GetTEACHERDBTableInstance());
    this.dbConsole = new TeacherConsole(tables);

    this.dbConsole.GetDBStore(() => {
      console.info(`开始查询【${this.collegeName}】的教师数据`);
      this.queryTeachersByCollege();
    });
  }

  private async queryTeachersByCollege() {
    if (!this.dbConsole.RDBStore) {
      console.error('数据库未连接，查询失败');
      promptAction.showToast({ message: '数据库连接异常', duration: 3000 });
      return;
    }

    try {
      // 按学院名称查询教师，展示姓名、工号、职称
      const querySql = `SELECT id, teacherId, name, title, department FROM TeacherTable WHERE department = ?`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, [this.collegeName]);

      this.teachers = [];

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const teacher: ITeacher = {
            id: resultSet.getString(resultSet.getColumnIndex('id')) || '',
            teacherId: resultSet.getString(resultSet.getColumnIndex('teacherId')) || '',
            name: resultSet.getString(resultSet.getColumnIndex('name')) || '',
            title: resultSet.getString(resultSet.getColumnIndex('title')) || '',
            department: resultSet.getString(resultSet.getColumnIndex('department')) || '',
            school: '',
            phone: '',
            gender: '',
            teachingAge: ''
          };
          this.teachers.push(teacher);
        } while (resultSet.goToNextRow());
      }

      resultSet.close();
    } catch (err) {
      console.error('查询教师数据失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询失败，请重试', duration: 3000 });
    }
  }

  build() {
    Column() {
      Text(`${this.collegeName} - 教师列表`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      List() {
        ForEach(this.teachers, (teacher: ITeacher) => {
          ListItem() {
            Column() {
              Text(`姓名: ${teacher.name}`)
                .fontSize(16)
                .fontColor('#333333')
                .alignSelf(ItemAlign.Start);
              Text(`工号: ${teacher.teacherId}`)
                .fontSize(14)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
                .margin({ top: 2 });
              Text(`职称: ${teacher.title}`)
                .fontSize(14)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
                .margin({ top: 2 });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
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