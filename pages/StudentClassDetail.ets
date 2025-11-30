import { router } from '@kit.ArkUI';
import { StudentConsole } from './StudentConsole';
import { StudentDBTable } from './StudentArtDate';
import { IStudent } from './StudentArtDate';
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import ArrayList from '@ohos.util.ArrayList';

interface StudentDetailParams {
  collegeName?: string;
  className?: string;
}
@Entry
@Component
struct StudentClassDetail {
  @State students: IStudent[] = [];
  private dbConsole: StudentConsole = new StudentConsole();
  private collegeName: string = (router.getParams() as StudentDetailParams)?.collegeName || '';
  private className: string = (router.getParams() as StudentDetailParams)?.className || '';

  aboutToAppear() {
    this.initDatabase();
  }

  private initDatabase() {
    const tables = new ArrayList<StudentDBTable>();
    tables.add(StudentDBTable.GetSTUDENTDBTableInstance());
    this.dbConsole = new StudentConsole(tables);

    this.dbConsole.GetDBStore(() => {
      console.info('学生详情数据库连接成功，开始查询学生');
      this.queryStudentsByCollegeAndClass();
    });
  }

  private async queryStudentsByCollegeAndClass() {
    if (!this.dbConsole.RDBStore || !this.collegeName || !this.className) {
      promptAction.showToast({ message: '数据加载异常' });
      return;
    }

    try {
      // 查询指定学院+班级的学生信息（含学号、姓名、年龄、班级）
      const querySql = `SELECT id, studentId, name, age, class FROM StudentTable WHERE college = ? AND class = ?`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, [this.collegeName, this.className]);

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
            college: '', // 其他字段按接口规范留空
            school: '',
            phone: '',
            gender: ''
          };
          this.students.push(student);
        } while (resultSet.goToNextRow());
      }

      resultSet.close();
    } catch (err) {
      console.error('查询学生失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询失败，请重试' });
    }
  }

  build() {
    Column() {
      // 页面标题
      Text(`【${this.collegeName}-${this.className}】学生列表`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .textAlign(TextAlign.Center)
        .width('100%');

      // 学生列表
      List() {
        ForEach(this.students, (student: IStudent) => {
          ListItem() {
            Column() {
              // 学号、姓名、年龄、班级信息行
              Row({ space: 16 }) {
                this.buildInfoColumn('学号:', student.studentId);
                this.buildInfoColumn('姓名:', student.name);
                this.buildInfoColumn('年龄:', student.age);
                this.buildInfoColumn('班级:', student.class);

                // 编辑、删除按钮列
                Column() {
                  Button('编辑')
                    .type(ButtonType.Normal)
                    .backgroundColor('#2196F3')
                    .fontColor(Color.White)
                    .width(60)
                    .height(36)
                    .margin({ bottom: 4 })
                    .onClick(() => {
                      // 编辑逻辑：可跳转编辑页并传递学生ID，此处先提示
                      promptAction.showToast({ message: `编辑${student.name}` });
                    });

                  Button('删除')
                    .type(ButtonType.Normal)
                    .backgroundColor('#F44336')
                    .fontColor(Color.White)
                    .width(60)
                    .height(36)
                    .onClick(() => {
                      // 删除逻辑：调用数据库删除方法，此处先提示
                      promptAction.showToast({ message: `删除${student.name}` });
                    });
                }
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround);
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 8 })
            .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 });
          };
        });
      }
      .width('90%')
      .height('auto')
      .align(Alignment.Center)
      .margin({ top: 0, bottom: 0 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }

  // 封装信息列组件，复用样式
  @Builder buildInfoColumn(label: string, value: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(14)
        .fontColor('#999999');
      Text(value)
        .fontSize(16)
        .fontColor('#333333');
    }
    .alignItems(HorizontalAlign.Center)
  }
}