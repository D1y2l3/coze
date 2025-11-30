import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import { router } from '@kit.ArkUI';


// 定义单选选项类型（适配后端返回的A/B/C/D格式）
interface RadioOptions {
  A: string;
  B: string;
  C?: string;
  D?: string;
}

// 定义判断选项类型（固定“对”“错”，与后端转换格式一致）
type JudgeOptions = ["对", "错"];

// 定义题目结构（严格匹配后端修改后的返回格式）
interface Question {
  questionType: "RADIO" | "JUDGE" | "FILL"; // 与后端返回的类型字符串一致
  id: string; // 后端生成的唯一ID
  question: string; // 题干
  options?: RadioOptions | JudgeOptions; // 单选/判断有选项，填空为undefined
  answer: string; // 正确答案
  analysis: string; // 题目解析
  index: number; // 题目序号（从0开始）
}

// 题目接口响应类型（兼容后端正常/异常返回格式）
interface QuestionResponse {
  message: string;
  status: number;
  questions?: Question[]; // 后端可能未返回，设为可选
  paperName?: string; // 后端可能未返回，设为可选
}

// 试卷列表接口响应类型（严格匹配后端返回）
interface PaperListResponse {
  paperNames: string[];
  message: string;
  status: number;
}

@Entry
@Component
struct StudentHomework {
  @State paperNames: string[] = [];
  @State isLoading: boolean = false;
  @State errorMsg: string = '';

  aboutToAppear() {
    this.fetchPaperNames();
  }

  // 第一步：查询所有试卷名称
  async fetchPaperNames() {
    this.isLoading = true;
    this.errorMsg = '';
    let httpClient: http.HttpRequest | null = null;

    try {
      httpClient = http.createHttp();
      const response = await httpClient.request(
        'http://10.19.16.227:5000/api/student/papers',
        {
          method: http.RequestMethod.GET,
          header: { 'Content-Type': 'application/json' },
          readTimeout: 10000,
          connectTimeout: 5000,
          expectDataType: http.HttpDataType.STRING
        }
      );

      if (response.responseCode !== 200) {
        throw new Error(`请求失败，状态码：${response.responseCode}`);
      }

      // 严格解析试卷列表响应，增加容错
      const rawData = response.result.toString();
      const data = JSON.parse(rawData) as PaperListResponse;
      this.paperNames = Array.isArray(data.paperNames) ? data.paperNames : [];

      promptAction.showToast({ message: data.message || "试卷列表查询成功" });
      console.log("试卷列表加载成功，数量：", this.paperNames.length);
      console.log("试卷列表详情：", this.paperNames);

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "未知错误";
      this.errorMsg = `试卷列表查询失败：${errorMsg}`;
      promptAction.showToast({ message: this.errorMsg });
      console.error("试卷列表查询详细错误：", error);
    } finally {
      if (httpClient) httpClient.destroy();
      this.isLoading = false;
    }
  }

  //点击试卷后，请求题目并跳转至Exam页面
  async fetchPaperQuestions(paperName: string): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';
    let httpClient: http.HttpRequest | null = null;

    try {
      httpClient = http.createHttp();
      // 请求URL，编码试卷名称
      const requestUrl = `http://10.19.16.227:5000/api/student/paper/questions?paper_name=${encodeURIComponent(paperName)}`;
      console.log("请求题目接口URL：", requestUrl);

      const response = await httpClient.request(
        requestUrl,
        {
          method: http.RequestMethod.GET,
          header: { 'Content-Type': 'application/json' },
          readTimeout: 10000,
          connectTimeout: 5000,
          expectDataType: http.HttpDataType.STRING
        }
      );

      // 打印后端返回的完整原始数据
      const rawResponse = response.result.toString();
      console.log(`后端返回完整数据（试卷：${paperName}）：`, rawResponse);

      if (response.responseCode !== 200) {
        throw new Error(`请求失败，状态码：${response.responseCode}，响应内容：${rawResponse}`);
      }

      // 解析响应并容错处理
      const data = JSON.parse(rawResponse) as QuestionResponse;

      // 容错1：questions字段不存在则设为空数组
      const validQuestions: Question[] = Array.isArray(data.questions) ? data.questions : [];
      // 容错2：paperName不存在则用点击的试卷名兜底
      const validPaperName: string = (typeof data.paperName === 'string' && data.paperName.trim()) || paperName;

      // 业务校验：题目为空提示
      if (validQuestions.length === 0) {
        throw new Error("该试卷暂无题目数据，请联系老师确认");
      }

      // 打印即将传递给Exam2的参数（确认数据有效性）
      console.log(`===== 传递到Exam2的参数 =====`);
      console.log(`试卷名称：${validPaperName}`);
      console.log(`题目总数：${validQuestions.length}`);
      console.log(`第一题示例：`, validQuestions[0]);
      console.log(`=============================`);

      // 跳转至Exam2页面，传递参数
      router.pushUrl({
        url: 'pages/Exam2', // 确保路径与实际页面存放路径一致
        params: {
          questions: validQuestions, // 键名与Exam2的RouteParams完全一致
          paperName: validPaperName
        }
      });

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "未知错误";
      this.errorMsg = `题目查询失败：${errorMsg}`;
      promptAction.showToast({ message: this.errorMsg, duration: 3000 }); // 延长提示时间
      console.error(`题目查询详细错误（试卷：${paperName}）：`, error);
    } finally {
      if (httpClient) httpClient.destroy();
      this.isLoading = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      // 页面标题
      Text('作业管理中心 - 发布的试卷列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center);

      // 加载状态
      if (this.isLoading) {
        Column({ space: 5 }) {
          LoadingProgress().width(30).height(30).color('#64BB5C');
          Text('正在加载...').fontSize(14).fontColor('rgba(0,0,0,0.70)');
        }.padding(10);
      }

      // 错误提示
      else if (this.errorMsg) {
        Text(this.errorMsg)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin(10)
          .alignSelf(ItemAlign.Center);
      }

      // 试卷列表
      else {
        if (this.paperNames.length === 0) {
          Text('暂无发布的试卷')
            .fontSize(14)
            .fontColor('rgba(0,0,0,0.50)')
            .padding(10);
        } else {
          List() {
            ForEach(
              this.paperNames,
              (name: string) => {
                ListItem() {
                  Text(name)
                    .fontSize(16)
                    .fontColor('rgba(0,0,0,0.90)')
                    .padding(12)
                    .width('100%')
                    .backgroundColor('#F5F5F5')
                    .margin({ bottom: 8, left: 10, right: 10 })
                    .borderRadius(8)
                    .onClick(() => this.fetchPaperQuestions(name));
                }
                .padding({ left: 10, right: 10 });
              },
              (name: string) => name // 唯一标识：试卷名称（确保不重复）
            );
          }
          .width('100%')
          .height('auto');
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F9F9F9');
  }
}