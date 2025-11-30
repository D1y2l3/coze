import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';

// 定义后端返回数据结构接口
export interface QuestionResponse {
  paperNames?: string[]; // 匹配手机号的试卷名称列表
  message?: string;      // 后端返回的提示信息
}

// 定义发送请求的返回结果接口
export interface RequestResult {
  success: boolean;
  paperNames?: string[]; // 成功时返回试卷名称列表
  error?: string;        // 失败时返回错误信息
}

// 后端查询接口URL
export const BACKEND_URL: string = 'http://10.19.16.227:5001/api/question';

// 工具方法：将ArrayBuffer转换为字符串（显式类型，无隐式any）
export function arrayBufferToString(buffer: ArrayBuffer): string {
  const uint8Array: Uint8Array = new Uint8Array(buffer);
  let result: string = '';
  for (let i: number = 0; i < uint8Array.length; i++) {
    result += String.fromCharCode(uint8Array[i]);
  }
  return result;
}

// 发送手机号到后端查询试卷名称（完全显式类型 + 修复BusinessError报错）
export async function queryPapersByPhone(phoneNumber: string): Promise<RequestResult> {
  // 校验手机号
  if (!phoneNumber || !phoneNumber.trim()) {
    return { success: false, error: '手机号不能为空' };
  }

  const httpRequest: http.HttpRequest = http.createHttp();

  try {
    // 显式声明请求配置项类型
    const requestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: JSON.stringify({
        phoneNumber: phoneNumber.trim()
      }),
      readTimeout: 10000,
      connectTimeout: 5000
    };

    const response: http.HttpResponse = await httpRequest.request(BACKEND_URL, requestOptions);

    // 处理响应状态码
    if (response.responseCode === 200) {
      let resultStr: string = '';
      // 严格判断响应数据类型
      if (typeof response.result === 'string') {
        resultStr = response.result;
      } else if (response.result instanceof ArrayBuffer) {
        resultStr = arrayBufferToString(response.result);
      } else {
        throw new Error(`响应数据格式不支持，类型：${typeof response.result}`);
      }

      // 解析JSON并校验类型
      const result: QuestionResponse = JSON.parse(resultStr) as QuestionResponse;
      if (Array.isArray(result.paperNames)) {
        return {
          success: true,
          paperNames: result.paperNames
        };
      } else {
        return {
          success: false,
          error: result.message || '未查询到匹配的试卷'
        };
      }
    } else {
      return {
        success: false,
        error: `请求失败，状态码: ${response.responseCode}（${http.ResponseCode[response.responseCode] || '未知状态'}）`
      };
    }
  } catch (error) { // 显式声明为unknown，安全处理
    // 修复：移除BusinessError的instanceof判断（仅作为类型声明，不能作为值使用）
    if (error instanceof Error) {
      // 处理常规Error类型（如主动throw的错误）
      return {
        success: false,
        error: `查询出错: ${error.message}`
      };
    } else {
      // 处理其他未知错误（含业务错误），统一转为字符串描述
      return {
        success: false,
        error: `查询出错: 未知错误（${String(error || '无错误信息')}）`
      };
    }
  } finally {
    // 销毁请求实例，释放资源
    httpRequest.destroy();
  }
}