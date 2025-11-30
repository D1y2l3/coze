import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';


// 定义接口：后端返回的试卷列表结构
interface PaperResponse {
  paperNames: string[];
  message: string;
  status?: number;
}

// 定义接口：后端返回的题目查询结果结构（仅用于前端提示）
interface QuestionResponse {
  message: string;
  status?: number;
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
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        readTimeout: 10000,
        connectTimeout: 5000,
        expectDataType: http.HttpDataType.STRING
      };

      const response = await httpClient.request(
        'http://10.19.16.227:5000/api/student/papers', // 后端试卷列表接口（请替换为实际IP）
        requestOptions
      );

      if (!response) throw new Error("网络请求无响应，请检查网络连接");
      if (response.responseCode !== 200) throw new Error(`请求失败，状态码：${response.responseCode}`);
      if (typeof response.result === 'undefined') throw new Error("后端返回数据为空");

      let rawData: string;
      if (typeof response.result === 'string') {
        rawData = response.result;
      } else if (response.result instanceof ArrayBuffer) {
        const uint8Array = new Uint8Array(response.result);
        let str = '';
        for (let i = 0; i < uint8Array.length; i++) {
          str += String.fromCharCode(uint8Array[i]);
        }
        rawData = str;
      } else {
        throw new Error(`不支持的响应数据类型：${typeof response.result}`);
      }

      const data = JSON.parse(rawData) as PaperResponse;
      if (!Array.isArray(data.paperNames)) throw new Error("后端返回数据格式错误，paperNames应为数组");

      this.paperNames = data.paperNames;
      promptAction.showToast({ message: data.message || "试卷列表查询成功" });

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

  // 第二步：点击试卷后，查询对应题目（触发后端打印）
  async fetchPaperQuestions(paperName: string) {
    this.isLoading = true;
    this.errorMsg = '';
    let httpClient: http.HttpRequest | null = null;

    try {
      httpClient = http.createHttp();
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        readTimeout: 10000,
        connectTimeout: 5000,
        expectDataType: http.HttpDataType.STRING
      };

      // 调用后端题目查询接口，传递试卷名称（URL编码）
      const response = await httpClient.request(
        `http://10.19.16.227:5000/api/student/paper/questions?paper_name=${encodeURIComponent(paperName)}`,
        requestOptions
      );

      if (!response) throw new Error("网络请求无响应，请检查网络连接");
      if (response.responseCode !== 200) throw new Error(`请求失败，状态码：${response.responseCode}`);
      if (typeof response.result === 'undefined') throw new Error("后端返回数据为空");

      let rawData: string;
      if (typeof response.result === 'string') {
        rawData = response.result;
      } else if (response.result instanceof ArrayBuffer) {
        const uint8Array = new Uint8Array(response.result);
        let str = '';
        for (let i = 0; i < uint8Array.length; i++) {
          str += String.fromCharCode(uint8Array[i]);
        }
        rawData = str;
      } else {
        throw new Error(`不支持的响应数据类型：${typeof response.result}`);
      }

      const data = JSON.parse(rawData) as QuestionResponse;
      promptAction.showToast({ message: data.message || "题目查询成功（后端已打印题目）" });

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "未知错误";
      this.errorMsg = `题目查询失败：${errorMsg}`;
      promptAction.showToast({ message: this.errorMsg });
      console.error("题目查询详细错误：", error);
    } finally {
      if (httpClient) httpClient.destroy();
      this.isLoading = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      // 标题
      Text('作业管理中心 - 发布的试卷列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center);

      // 加载状态
      if (this.isLoading) {
        Column({ space: 5 }) {
          LoadingProgress().width(30).height(30).color('#007DFF');
          Text('正在加载...').fontSize(14);
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
            .padding(10);
        } else {
          List() {
            ForEach(this.paperNames, (name: string) => {
              ListItem() {
                Text(name)
                  .fontSize(16)
                  .padding(12)
                  .width('100%')
                  .backgroundColor('#F5F5F5')
                  .margin({ bottom: 8 })
                  .borderRadius(8)
                  .onClick(() => { // 点击试卷触发题目查询
                    this.fetchPaperQuestions(name);
                  });
              }
            }, (name: string) => name);
          }
          .width('100%')
          .height('auto');
        }
      }
    }
    .width('100%')
    .height('100%')
    .padding(12);
  }
}