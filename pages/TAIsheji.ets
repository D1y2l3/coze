import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';


// 定义后端返回数据结构接口
export interface GenerateResponse2 {
  data?: string;
}

// 定义发送请求的返回结果接口
export interface RequestResult2 {
  success: boolean;
  data?: string;
  error?: string;
}

// 后端Python服务的URL（请替换为你的实际后端地址）
export const BACKEND_URL: string = 'http://10.19.16.227:5001/api/sheji';

// 工具方法：将ArrayBuffer转换为字符串
export function arrayBufferToString(buffer: ArrayBuffer): string {
  const uint8Array = new Uint8Array(buffer);
  let result = '';
  for (let i = 0; i < uint8Array.length; i++) {
    result += String.fromCharCode(uint8Array[i]);
  }
  return result;
}

// 发送字符串到后端的方法
export async function sendToBackend2(content: string): Promise<RequestResult2> {
  if (!content.trim()) {
    return { success: false, error: '请输入内容后再生成' } as RequestResult2;
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
        extraData: JSON.stringify({
          content: content
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

      const result: GenerateResponse2 = JSON.parse(resultStr);
      return { success: true, data: result.data } as RequestResult2;
    } else {
      return { success: false, error: `请求失败，状态码: ${response.responseCode}` } as RequestResult2;
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    return { success: false, error: `请求出错: ${err.message || '未知错误'}` } as RequestResult2;
  } finally {
    httpRequest.destroy();
  }
}
