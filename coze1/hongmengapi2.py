from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from coze_middleware import CozeMiddleware  # 导入中间层

app = Flask(__name__)
CORS(app, resources=r"/*")

# 初始化Coze中间件
coze_middleware = CozeMiddleware(
    api_token=os.getenv('COZE_API_TOKEN', 'pat_TlYEeblB2DWUBHgqQKPrweeGTg67kL36qj5zS3qfTcWrGkFrk2rpC1a1UEtarxuo'),
    workflow_id='7526153262711554084'
)


@app.route('/api/aigenerate', methods=['POST'])
def receive_string():
    try:
        # 解析前端发送的JSON数据
        data = request.get_json()

        # 调用中间层处理数据并启动工作流
        result = coze_middleware.process_frontend_data(data)

        if result["success"]:
            return jsonify({
                'code': 200,
                'message': '处理成功',
                'data': result["result"]
            }), 200
        else:
            return jsonify({
                'code': 500,
                'message': result["error"],
                'data': None
            }), 500

    except json.JSONDecodeError:
        return jsonify({
            'code': 400,
            'message': '无效的JSON格式',
            'data': None
        }), 400
    except Exception as e:
        return jsonify({
            'code': 500,
            'message': f'服务器错误: {str(e)}',
            'data': None
        }), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)