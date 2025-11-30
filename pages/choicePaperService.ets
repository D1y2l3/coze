import { ChoicePaper } from './choice';
import http from '@ohos.net.http';
import { ApiResponse } from './choiceapi';

export class ChoiceService {
  // 原有获取所有选择题的接口地址
  private static readonly API_URL: string = "http://10.19.16.227:5001/api/choices";
  // 新增：根据试卷名称查询选择题的接口地址（与后端新增接口对应）
  private static readonly API_URL_BY_PAPER: string = "http://10.19.16.227:5001/api/choices/by-paper";

  /**
   * 获取所有选择题
   * @returns 选择题数组（Promise<ChoicePaper[]>）
   */
  static async getChoiceQuestions(): Promise<ChoicePaper[]> {
    let httpRequest = http.createHttp();
    try {
      let response = await httpRequest.request(
        ChoiceService.API_URL,
        { method: http.RequestMethod.GET }
      );

      if (!response) {
        throw new Error("网络请求无响应");
      }

      if (response.responseCode !== 200) {
        throw new Error(`请求失败: 状态码 ${response.responseCode}`);
      }

      if (typeof response.result === 'undefined') {
        throw new Error("响应数据为空");
      }

      let rawData: string;
      try {
        rawData = response.result.toString();
      } catch (e) {
        throw new Error(`响应数据转换失败: ${(e as Error).message}`);
      }

      let data: ApiResponse;
      try {
        data = JSON.parse(rawData) as ApiResponse;
      } catch (e) {
        throw new Error(`JSON解析失败: ${(e as Error).message}`);
      }

      if (!Array.isArray(data?.data)) {
        throw new Error("数据格式错误: 预期为选择题数组");
      }

      return data.data as ChoicePaper[];
    } catch (error) {
      console.error("选择题数据请求失败:", error);
      const safeError = error instanceof Error ? error : new Error(String(error));
      throw safeError;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 根据试卷名称查询对应的选择题
   * @param paperName 试卷名称
   * @returns 该试卷的选择题数组（Promise<ChoicePaper[]>）
   */
  static async getQuestionsByPaper(paperName: string): Promise<ChoicePaper[]> {
    let httpRequest = http.createHttp();
    try {
      // 配置POST请求参数（传递试卷名称）
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json' // 声明JSON格式请求体
        },
        extraData: JSON.stringify({ paperName: paperName.trim() }), // 传递试卷名称参数
        readTimeout: 10000, // 读取超时时间（10秒）
        connectTimeout: 5000 // 连接超时时间（5秒）
      };

      let response = await httpRequest.request(
        ChoiceService.API_URL_BY_PAPER,
        requestOptions
      );

      // 响应有效性校验
      if (!response) {
        throw new Error("网络请求无响应");
      }

      if (response.responseCode !== 200) {
        throw new Error(`请求失败: 状态码 ${response.responseCode}`);
      }

      if (typeof response.result === 'undefined') {
        throw new Error("响应数据为空");
      }

      // 响应数据转换（支持string和ArrayBuffer类型）
      let rawData: string;
      try {
        if (typeof response.result === 'string') {
          rawData = response.result;
        } else if (response.result instanceof ArrayBuffer) {
          // 处理二进制数据转换为字符串（替换apply调用，避免ArkTS语法检查错误）
          const uint8Array = new Uint8Array(response.result);
          let str = '';
          for (let i = 0; i < uint8Array.length; i++) {
            str += String.fromCharCode(uint8Array[i]);
          }
          rawData = str;
        } else {
          throw new Error(`不支持的响应数据类型: ${typeof response.result}`);
        }
      } catch (e) {
        throw new Error(`响应数据转换失败: ${(e as Error).message}`);
      }

      // JSON解析与格式校验
      let data: ApiResponse;
      try {
        data = JSON.parse(rawData) as ApiResponse;
      } catch (e) {
        throw new Error(`JSON解析失败: ${(e as Error).message}`);
      }

      if (!Array.isArray(data?.data)) {
        throw new Error("数据格式错误: 预期为选择题数组");
      }

      return data.data as ChoicePaper[];
    } catch (error) {
      console.error(`根据试卷名称查询选择题失败（试卷名：${paperName}）:`, error);
      const safeError = error instanceof Error ? error : new Error(String(error));
      throw safeError;
    } finally {
      httpRequest.destroy(); // 确保请求资源释放
    }
  }
}