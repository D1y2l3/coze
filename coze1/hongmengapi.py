from flask import Flask, request, jsonify
from flask_cors import CORS
import json

app = Flask(__name__)
# 解决跨域问题，允许前端访问
CORS(app, resources=r"/*")


@app.route('/api/aigenerate', methods=['POST'])
def receive_string():
    try:
        # 解析前端发送的JSON数据
        data = request.get_json()

        # 检查是否包含content字段
        if not data or 'content' not in data:
            return jsonify({
                'code': 400,
                'message': '缺少content字段',
                'data': None
            }), 400

        # 获取前端传输的字符串
        received_str = data['content']
        print(f"收到前端数据: {received_str}")

        # 这里可以添加对字符串的处理逻辑
        # 示例：简单处理字符串（在实际应用中替换为你的业务逻辑）
        processed_str = f"已处理: {received_str}"

        # 返回处理结果给前端
        return jsonify({
            'code': 200,
            'message': '处理成功',
            'data': processed_str
        }), 200

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
