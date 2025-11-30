from flask import Flask, request, jsonify

app = Flask(__name__)


@app.route('/api/aigenerate', methods=['POST'])
def aigenerate():
    data = request.get_json()
    content = data.get('content')  # 获取内容
    phone_number = data.get('phoneNumber')  # 获取手机号

    # 打印手机号到控制台（标注类型，确保是字符串）
    print(f"接收到的手机号（字符串类型）：{phone_number}")
    # 可选：同时打印内容和手机号，方便关联日志
    print(f"接收到的请求内容：{content}，关联手机号：{phone_number}")

    # 处理逻辑...
    return jsonify({"data": "处理结果"})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)