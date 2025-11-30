import requests

# 基础URL配置
BASE_URL_CHOICES = "http://192.168.110.158:5000/api/choices"
BASE_URL_FILLS = "http://192.168.110.158:5000/api/fills"      # 填空题接口基础URL
BASE_URL_JUDGMENTS = "http://192.168.110.158:5000/api/judges"  # 判断题接口基础URL


# -------------------------- 选择题测试 --------------------------
def test_get_all_choices():
    """测试获取所有选择题"""
    response = requests.get(BASE_URL_CHOICES)
    print("=== 选择题 - 获取所有题目 ===")
    print(f"状态码：{response.status_code}")
    print(f"响应内容：{response.json()}\n")
    assert response.json()["code"] == 200  # 断言业务码为200


def test_get_single_choice():
    """测试获取单个选择题"""
    print("=== 选择题 - 获取单个题目 ===")
    # 测试存在的ID
    response = requests.get(f"{BASE_URL_CHOICES}/1")
    print(f"存在的ID响应状态码：{response.status_code}")
    print(f"存在的ID响应内容：{response.json()}")
    assert response.json()["code"] == 200  # 断言业务码为200

    # 测试不存在的ID
    response = requests.get(f"{BASE_URL_CHOICES}/999")
    print(f"不存在的ID响应状态码：{response.status_code}")
    print(f"不存在的ID响应内容：{response.json()}\n")
    assert response.json()["code"] == 404  # 断言业务码为404


# -------------------------- 填空题测试 --------------------------
def test_get_all_fills():
    """测试获取所有填空题"""
    response = requests.get(BASE_URL_FILLS)
    print("=== 填空题 - 获取所有题目 ===")
    print(f"状态码：{response.status_code}")
    print(f"响应内容：{response.json()}\n")
    assert response.json()["code"] == 200  # 断言业务码为200


def test_get_single_fill():
    """测试获取单个填空题"""
    print("=== 填空题 - 获取单个题目 ===")
    # 测试存在的ID（根据实际数据调整ID值）
    response = requests.get(f"{BASE_URL_FILLS}/1")
    print(f"存在的ID响应状态码：{response.status_code}")
    print(f"存在的ID响应内容：{response.json()}")
    assert response.json()["code"] == 200  # 断言业务码为200

    # 测试不存在的ID
    response = requests.get(f"{BASE_URL_FILLS}/999")
    print(f"不存在的ID响应状态码：{response.status_code}")
    print(f"不存在的ID响应内容：{response.json()}\n")
    assert response.json()["code"] == 404  # 断言业务码为404


# -------------------------- 判断题测试 --------------------------
def test_get_all_judgments():
    """测试获取所有判断题"""
    response = requests.get(BASE_URL_JUDGMENTS)
    print("=== 判断题 - 获取所有题目 ===")
    print(f"状态码：{response.status_code}")
    print(f"响应内容：{response.json()}\n")
    assert response.json()["code"] == 200  # 断言业务码为200


def test_get_single_judgment():
    """测试获取单个判断题"""
    print("=== 判断题 - 获取单个题目 ===")
    # 测试存在的ID（根据实际数据调整ID值）
    response = requests.get(f"{BASE_URL_JUDGMENTS}/1")
    print(f"存在的ID响应状态码：{response.status_code}")
    print(f"存在的ID响应内容：{response.json()}")
    assert response.json()["code"] == 200  # 断言业务码为200

    # 测试不存在的ID
    response = requests.get(f"{BASE_URL_JUDGMENTS}/999")
    print(f"不存在的ID响应状态码：{response.status_code}")
    print(f"不存在的ID响应内容：{response.json()}\n")
    assert response.json()["code"] == 404  # 断言业务码为404


if __name__ == "__main__":
    # 执行所有测试
    test_get_all_choices()
    test_get_single_choice()
    test_get_all_fills()
    test_get_single_fill()
    test_get_all_judgments()  # 新增：执行所有判断题测试
    test_get_single_judgment()  # 新增：执行单个判断题测试
    print("所有测试完成！")
