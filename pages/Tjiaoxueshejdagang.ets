import web_webview from '@ohos.web.webview';
import promptAction from '@ohos.promptAction'
import { BusinessError, request } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { util } from '@kit.ArkTS';
import http from '@ohos.net.http'; // 对齐参考：使用@ohos.net.http

// pdf页面
interface pageTab {
  name: string;
}

interface IBase64 {
  base64: string;
  fileName: string;
}

// 对齐参考：定义响应数据接口（与Python后端返回格式匹配）
interface PdfUrlResponse {
  code: number;
  message: string;
  data: string;
}

/**
 * pdfPage的ViewModel（对齐参考：静态方法+http模块+完善错误处理）
 */
class PdfPageModel {
  // 当前索引
  curTabIndex: number = 0;
  // pdf页面tab（仅保留沙箱预览）
  tabList: pageTab[] = [
    { name: '预览PDF文件' },
  ];

  // 网络文件（用于下载到沙箱，从Python后端获取）
  fileUrl: string = '';
  // 本地沙箱文件地址
  tempFilePath: string = '';

  // 对齐参考：静态API地址
  private static readonly API_URL: string = "http://10.19.16.227:5001/api/get_latest_url";

  constructor() { }

  // 沙箱pdf文件转base64方法（保持不变）
  sandBoxPdfToBase64(url: string) {
    let file = fs.openSync(url, fs.OpenMode.READ_WRITE);
    let stat = fs.statSync(url);
    let buf = new ArrayBuffer(stat.size);
    let base64 = new util.Base64Helper();
    let num = fs.readSync(file.fd, buf);
    let data = base64.encodeSync(new Uint8Array(buf.slice(0, num)));
    let textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
    let retStr = textDecoder.decodeWithStream(data, { stream: false });
    let fileName = file.name;
    fs.closeSync(file);
    return { base64: retStr, fileName: fileName } as IBase64;
  }

  // 下载pdf文件（保持不变）
  getTempFile(fileUrl: string) {
    let context = getContext(this) as common.UIAbilityContext;
    const fileFullName = fileUrl.split('/')[fileUrl.split('/').length - 1];
    let tempFilePath = `${context.filesDir}/${fileFullName}`;
    if (fs.accessSync(tempFilePath)) {
      fs.unlink(tempFilePath);
    }
    request.downloadFile(getContext(), { url: fileUrl, filePath: tempFilePath }).then((data: request.DownloadTask) => {
      let downloadTask: request.DownloadTask = data;
      let progressCallback = (receivedSize: number, totalSize: number) => { };
      let completeCallback = () => {
        this.tempFilePath = tempFilePath;
      };
      downloadTask.on('progress', progressCallback);
      downloadTask.on('complete', completeCallback);
    }).catch((err: BusinessError) => {
      console.error(`Failed to request the download. Code: ${err.code}, message: ${err.message}`);
    });
  }

  // tab切换（保持不变）
  switchTab(index: number) {
    this.curTabIndex = index;
    if (index === 0 && !this.tempFilePath) {
      try {
        promptAction.showDialog({
          title: '温馨提示',
          message: 'pdf线上链接是经过第三方加密过的，首次预览会比较慢，但来回切换几次就好了',
          buttons: [{ text: '知道了', color: '#000000' }]
        }, (err, data) => {
          if (err) console.error('showDialog err: ' + err);
        });
      } catch (error) {
        console.error(`Failed to show dialog. Code: ${error.code}, message: ${error.message}`);
      }
      this.getTempFile(this.fileUrl);
    }
  }

  // 对齐参考：静态异步方法（获取最新PDF链接）
  static async getLatestPdfUrl(context: common.UIAbilityContext): Promise<string> {
    let httpRequest = http.createHttp();
    try {
      // 对齐参考：发起GET请求（需传入context）
      let response = await httpRequest.request(
        PdfPageModel.API_URL,
        { method: http.RequestMethod.GET }
      );

      // 对齐参考：逐步骤错误校验
      if (!response) {
        throw new Error("网络请求无响应");
      }

      if (response.responseCode !== 200) {
        throw new Error(`请求失败: 状态码 ${response.responseCode}`);
      }

      if (typeof response.result === 'undefined') {
        throw new Error("响应数据为空");
      }

      // 转换响应结果为字符串
      let rawData: string;
      try {
        rawData = response.result.toString();
      } catch (e) {
        throw new Error(`响应数据转换失败: ${(e as Error).message}`);
      }

      // 解析JSON
      let data: PdfUrlResponse;
      try {
        data = JSON.parse(rawData) as PdfUrlResponse;
      } catch (e) {
        throw new Error(`JSON解析失败: ${(e as Error).message}`);
      }

      // 验证数据格式
      if (typeof data?.data !== 'string' || !data.data.startsWith('https://')) {
        throw new Error("数据格式错误: 预期为有效的HTTPS链接");
      }

      return data.data;
    } catch (error) {
      console.error("PDF链接请求失败:", error);
      // 统一错误格式
      const safeError = error instanceof Error ? error : new Error(String(error));
      throw safeError;
    } finally {
      // 对齐参考：最终销毁http请求
      httpRequest.destroy();
    }
  }
}

@Entry
@Component
struct PdfPage {
  webviewController: web_webview.WebviewController = new web_webview.WebviewController();
  @State vm: PdfPageModel = new PdfPageModel();

  // 验证是否选中（保持不变）
  VerifySelectedFun(curIndex: number, itemIndex: number): boolean {
    return curIndex == itemIndex;
  }

  async aboutToAppear(): Promise<void> {
    try {
      promptAction.showDialog({
        title: '温馨提示',
        message: '首次加载可能出现渲染不出来，点击上面的预览PDF文件，切换几次就好了',
        buttons: [{ text: '知道了', color: '#000000' }]
      }, (err, data) => {
        if (err) console.error('showDialog err: ' + err);
      });
    } catch (error) {
      console.error(`Failed to show dialog. Code: ${error.code}, message: ${error.message}`);
    }

    // 对齐参考：调用静态异步方法获取链接
    try {
      const context = getContext(this) as common.UIAbilityContext;
      // 等待链接返回后赋值给fileUrl
      this.vm.fileUrl = await PdfPageModel.getLatestPdfUrl(context);
      console.info('fileUrl已赋值: ' + this.vm.fileUrl);
    } catch (error) {
      // 错误提示（对齐参考的错误处理风格）
      promptAction.showToast({
        message: `获取PDF链接失败: ${(error as Error).message}`,
        duration: 3000
      });
    }
  }

  build() {
    // 页面结构保持不变
    Stack() {
      Column() {
        // tab标签条
        Row() {
          Scroll() {
            Row() {
              ForEach(this.vm.tabList, (item: pageTab, index) => {
                Row() {
                  if (this.VerifySelectedFun(this.vm.curTabIndex, index)) {
                    Stack() {
                      Row() {}
                      .width(40)
                      .height(10)
                      .borderRadius(20)
                      .offset({ y: 7 })
                      .linearGradient({ angle: 89.11, colors: [
                        ['rgba(255, 255, 255, 0.55)', 0.0682],
                        ['rgba(217, 217, 217, 0)', 1]
                      ] });
                      Text(item.name)
                        .fontSize(18)
                        .fontWeight(600)
                        .height('100%');
                    }
                  } else {
                    Text(item.name)
                      .fontSize(16)
                      .fontWeight(400);
                  }
                }
                .height('100%')
                .justifyContent(FlexAlign.Start)
                .padding({ left: index == 0 ? 0 : 20 })
                .onClick(() => {
                  this.vm.switchTab(index);
                });
              });
            }
          }
          .edgeEffect(EdgeEffect.Fade)
          .layoutWeight(1)
          .align(Alignment.Center)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off);
        }
        .width('100%')
        .height(50)
        .justifyContent(FlexAlign.Start)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Color.White);

        // 页面内容
        Scroll() {
          Column() {
            if (this.vm.curTabIndex === 0) {
              if (this.vm.tempFilePath) {
                Web({ src: $rawfile('pdfviewer/viewer.html'), controller: this.webviewController })
                  .onProgressChange((event) => {
                    console.log("newProgress", event?.newProgress);
                  })
                  .domStorageAccess(true)
                  .onPageEnd(() => {
                    let file = this.vm.sandBoxPdfToBase64(this.vm.tempFilePath);
                    this.webviewController.runJavaScript(`openFile("${file.base64}", "${file.fileName}")`);
                  });
              }
            }
          }
          .padding({ left: 16, right: 16, bottom: 16 });
        }
        .edgeEffect(EdgeEffect.Fade)
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart);
      }
      .height('100%')
      .backgroundColor('#F5F5F5')
      .padding({ bottom: 16 });
    }
  }
}