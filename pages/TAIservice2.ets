import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import { GlobalUserState } from './baocun';



// 定义后端返回数据结构接口（不变）
export interface GenerateResponse {
  data?: string;
}

// 定义发送请求的返回结果接口（不变）
export interface RequestResult {
  success: boolean;
  data?: string;
  error?: string;
}

// 后端Python服务的URL（请替换为你的实际后端地址）
export const BACKEND_URL: string = 'http://10.19.16.227:5001/api/aigenerate';

// 工具方法：将ArrayBuffer转换为字符串（不变）
export function arrayBufferToString(buffer: ArrayBuffer): string {
  const uint8Array = new Uint8Array(buffer);
  let result = '';
  for (let i = 0; i < uint8Array.length; i++) {
    result += String.fromCharCode(uint8Array[i]);
  }
  return result;
}

// 发送字符串和手机号到后端的方法（新增phoneNumber参数）
export async function sendToBackend(content: string, phoneNumber: string): Promise<RequestResult> {
  // 校验输入（可额外校验手机号）
  if (!content.trim()) {
    return { success: false, error: '请输入内容后再生成' } as RequestResult;
  }
  if (!phoneNumber) {
    return { success: false, error: '未获取到手机号' } as RequestResult;
  }

  const httpRequest: http.HttpRequest = http.createHttp();

  try {
    const response: http.HttpResponse = await httpRequest.request(
      BACKEND_URL,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        // 请求体中新增phoneNumber字段
        extraData: JSON.stringify({
          content: content,
          phoneNumber: phoneNumber  // 传递手机号
        }),
        readTimeout: 240000,
        connectTimeout: 5000
      }
    );

    if (response.responseCode === 200) {
      let resultStr: string = '';
      if (typeof response.result === 'string') {
        resultStr = response.result;
      } else if (response.result instanceof ArrayBuffer) {
        resultStr = arrayBufferToString(response.result);
      } else {
        throw new Error('无法解析响应数据');
      }

      const result: GenerateResponse = JSON.parse(resultStr);
      return { success: true, data: result.data } as RequestResult;
    } else {
      return { success: false, error: `请求失败，状态码: ${response.responseCode}` } as RequestResult;
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    return { success: false, error: `请求出错: ${err.message || '未知错误'}` } as RequestResult;
  } finally {
    httpRequest.destroy();
  }
}