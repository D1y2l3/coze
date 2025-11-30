import { router } from '@kit.ArkUI';
import { StudentConsole } from './StudentConsole';
import { StudentDBTable } from './StudentArtDate';
import { IStudent } from './StudentArtDate';
import promptAction from '@ohos.promptAction';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import ArrayList from '@ohos.util.ArrayList';


interface RouteParams {
  collegeName?: string;
}

@Entry
@Component
struct StudentCollegeClassList {
  @State classes: string[] = [];
  private dbConsole: StudentConsole = new StudentConsole();
  private collegeName: string = (router.getParams() as RouteParams)?.collegeName || '';

  aboutToAppear() {
    this.initDatabase();
  }

  private initDatabase() {
    const tables = new ArrayList<StudentDBTable>();
    tables.add(StudentDBTable.GetSTUDENTDBTableInstance());
    this.dbConsole = new StudentConsole(tables);

    this.dbConsole.GetDBStore(() => {
      console.info('班级列表数据库连接成功，开始查询班级');
      this.queryClassesByCollege();
    });
  }

  private async queryClassesByCollege() {
    if (!this.dbConsole.RDBStore || !this.collegeName) {
      promptAction.showToast({ message: '数据加载异常' });
      return;
    }

    try {
      const querySql = `SELECT class FROM StudentTable WHERE college = ?`;
      const resultSet = await this.dbConsole.RDBStore.querySql(querySql, [this.collegeName]);

      this.classes = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const className = resultSet.getString(resultSet.getColumnIndex('class')) || '';
          if (className && !this.classes.includes(className)) {
            this.classes.push(className);
          }
        } while (resultSet.goToNextRow());
      }

      resultSet.close();
    } catch (err) {
      console.error('查询班级失败:', JSON.stringify(err));
      promptAction.showToast({ message: '查询失败，请重试' });
    }
  }

  build() {
    Column() {
      Text(`【${this.collegeName}】班级列表`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .textAlign(TextAlign.Center)
        .width('100%');

      List() {
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
              top: 16,
              bottom: 16
            })
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 8 })
            .shadow({
              radius: 2,
              color: '#1A000000',
              offsetX: 0,
              offsetY: 1
            })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/StudentClassDetail', // 需确保该页面在路由配置中注册
                params: { collegeName: this.collegeName, className: className }
              });
            });
          }
        });
      }
      .width('90%')
      .height('auto')
      .align(Alignment.Center) // 关键：让List在Column中水平居中
      .margin({ top: 0, bottom: 0 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}