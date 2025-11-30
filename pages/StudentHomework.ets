import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import { router } from '@kit.ArkUI';


interface PaperResponse {
  paperNames: string[];
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
        'http://10.19.16.227:5000/api/student/papers',
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
      promptAction.showToast({ message: data.message || "查询成功" });

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : "未知错误";
      this.errorMsg = `试卷查询失败：${errorMsg}`;
      promptAction.showToast({ message: this.errorMsg });
      console.error("试卷查询详细错误：", error);
    } finally {
      if (httpClient) httpClient.destroy();
      this.isLoading = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Text('作业管理中心 - 发布的试卷列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center);

      if (this.isLoading) {
        Column({ space: 5 }) {
          LoadingProgress().width(30).height(30).color('#007DFF');
          Text('正在加载试卷...').fontSize(14);
        }.padding(10);
      } else if (this.errorMsg) {
        Text(this.errorMsg)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin(10)
          .alignSelf(ItemAlign.Center);
      } else {
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
                  .borderRadius(8);
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