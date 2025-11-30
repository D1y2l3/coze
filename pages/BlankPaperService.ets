import { BlankPaper } from './blank';
import http from '@ohos.net.http';
import { BlankApiResponse } from './blankapi'; // 导入修改后的响应接口

export class BlankService {
  // 填空题API地址（与后端新增的接口完全对齐）
  private static readonly API_URL_BY_PAPER: string = "http://10.19.16.227:5001/api/blanks/by-paper";

  /**
   * 根据试卷名称查询对应的填空题列表（与其他题型服务方法风格一致）
   * @param paperName 试卷名称
   * @returns 填空题数组的Promise
   */
  static async getBlankQuestionsByPaper(paperName: string): Promise<BlankPaper[]> {
    let httpRequest = http.createHttp();
    try {
      // 校验试卷名称参数（避免空值请求）
      if (!paperName?.trim()) {
        throw new Error("试卷名称不能为空");
      }

      // 配置POST请求（与后端接口请求方式、参数格式对齐）
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json' // 声明JSON格式请求体
        },
        extraData: JSON.stringify({ paperName: paperName.trim() }), // 传递试卷名称参数
        readTimeout: 10000, // 读取超时10秒（与其他服务统一）
        connectTimeout: 5000 // 连接超时5秒（与其他服务统一）
      };

      let response = await httpRequest.request(
        BlankService.API_URL_BY_PAPER,
        requestOptions
      );

      // 响应有效性校验（与选择题、判断题服务逻辑一致）
      if (!response) {
        throw new Error("网络请求无响应");
      }

      if (response.responseCode !== 200) {
        throw new Error(`请求失败: 状态码 ${response.responseCode}`);
      }

      if (typeof response.result === 'undefined') {
        throw new Error("响应数据为空");
      }

      // 响应数据转换（支持string/ArrayBuffer，兼容后端返回格式）
      let rawData: string;
      try {
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
          throw new Error(`不支持的响应数据类型: ${typeof response.result}`);
        }
      } catch (e) {
        throw new Error(`响应数据转换失败: ${(e as Error).message}`);
      }

      // JSON解析与格式校验
      let data: BlankApiResponse;
      try {
        data = JSON.parse(rawData) as BlankApiResponse;
      } catch (e) {
        throw new Error(`JSON解析失败: ${(e as Error).message}`);
      }

      if (!Array.isArray(data?.data)) {
        throw new Error("数据格式错误: 预期为填空题数组");
      }

      return data.data as BlankPaper[];
    } catch (error) {
      console.error(`根据试卷名称查询填空题失败（试卷名：${paperName}）:`, error);
      const safeError = error instanceof Error ? error : new Error(String(error));
      throw safeError;
    } finally {
      httpRequest.destroy(); // 确保请求资源释放（与其他服务统一）
    }
  }
}