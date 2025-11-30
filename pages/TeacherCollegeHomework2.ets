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


// 新增：接收路由参数（试卷名称+各题型编号）
interface RouterParams {
  paperName: string;
  choicePaperId?: string;
  judgePaperId?: string;
  blankPaperId?: string;
}

// 定义请求参数接口（与前端传递的字段一致）
interface GeneratedObjectLiteralInterface_1 {
  className: string;
  paperName: string;
  choicePaperId: string;
  judgePaperId: string;
  blankPaperId: string;
}

@Entry
@Component
struct TeacherCollegeHomework2 {
  @State classes: string[] = [];
  @State teacherCollege: string = '';
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  // 新增：存储从路由接收的试卷信息
  @State paperName: string = '';
  @State choicePaperId: string = '';
  @State judgePaperId: string = '';
  @State blankPaperId: string = '';

  private dbConsole: StudentConsole = new StudentConsole();
  private teacherConsole: TeacherConsole = new TeacherConsole();
  private globalState: GlobalUserState = GlobalUserState.getInstance();

  aboutToAppear() {
    // 接收路由参数
    this.receiveRouterParams();
    this.initData();
  }

  // 新增：接收路由传递的试卷名称和各题型编号
  private receiveRouterParams(): void {
    const params = router.getParams() as RouterParams;
    if (params) {
      this.paperName = params.paperName || '';
      this.choicePaperId = params.choicePaperId || '';
      this.judgePaperId = params.judgePaperId || '';
      this.blankPaperId = params.blankPaperId || '';
      console.info(`接收路由参数：试卷名称=${this.paperName}，选择题编号=${this.choicePaperId}，判断题编号=${this.judgePaperId}，填空题编号=${this.blankPaperId}`);
    } else {
      promptAction.showToast({ message: '未获取到试卷信息' });
      router.back();
    }
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

  // 发布作业：使用路由传递的真实paperId（替换硬编码）
  private handlePublish(className: string): void {
    // 构造请求参数（使用接收的真实数据）
    const requestData: GeneratedObjectLiteralInterface_1 = {
      className: className,
      paperName: this.paperName, // 路由传递的试卷名称
      choicePaperId: this.choicePaperId || 'NO_CHOICE', // 无选择题时用默认值
      judgePaperId: this.judgePaperId || 'NO_JUDGE',   // 无判断题时用默认值
      blankPaperId: this.blankPaperId || 'NO_BLANK'    // 无填空题时用默认值
    };

    const requestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify(requestData),
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 10000,
      readTimeout: 10000
    };

    let httpClient = http.createHttp();
    httpClient.request(
      'http://10.19.16.227:5000/publish/homework', // 确保后端地址正确（注意：后端服务端口是5001，若发布接口在5001需修改）
      requestOptions,
      (err: BusinessError | undefined, response: http.HttpResponse | undefined) => {
        if (!err && response) {
          promptAction.showToast({ message: '发布成功，数据已存储到数据库' });
          console.info('后端响应:', response.result?.toString());
        } else {
          promptAction.showToast({ message: `发布失败：${err?.message}` });
          console.error('HTTP请求错误:', err?.message);
        }
        httpClient.destroy();
      }
    );
  }

  build() {
    Column() {
      // 标题显示试卷名称和学院
      Text(`${this.teacherCollege || '加载中...'} - ${this.paperName || '试卷'}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center);

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(30).height(30).color('#007DFF');
          Text('正在加载班级列表...').fontSize(14).margin({ top: 10 });
        }.layoutWeight(1).justifyContent(FlexAlign.Center);
      } else if (this.errorMsg) {
        Column() {
          Text(this.errorMsg).fontSize(14).fontColor(Color.Red).margin(20);
        }.layoutWeight(1).justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(this.classes, (className: string) => {
            ListItem() {
              Row({ space: 12 }) {
                Column() {
                  Text('班级:').fontSize(14).fontColor('#999999').alignSelf(ItemAlign.Start);
                  Text(className).fontSize(16).fontColor('#333333').alignSelf(ItemAlign.Start).margin({ top: 4 });
                }.flexGrow(1);

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
          }, (className: string) => className);
        }.width('90%').height('80%');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}