import requests

BASE_URL = "http://192.168.110.158:5000/api/choices"

def test_get_all_choices():
    """测试获取所有选择题"""
    response = requests.get(BASE_URL)
    print("获取所有选择题响应：")
    print(f"状态码：{response.status_code}")
    print(f"响应内容：{response.json()}\n")
    assert response.status_code == 200  # 断言成功状态码

def test_get_single_choice():
    """测试获取单个选择题"""
    # 测试存在的ID
    response = requests.get(f"{BASE_URL}/1")
    print("获取单个选择题（存在）响应：")
    print(f"状态码：{response.status_code}")
    print(f"响应内容：{response.json()}\n")
    assert response.status_code == 200

    # 测试不存在的ID
    response = requests.get(f"{BASE_URL}/999")
    print("获取单个选择题（不存在）响应：")
    print(f"状态码：{response.status_code}")
    print(f"响应内容：{response.json()}\n")
    assert response.status_code == 404

if __name__ == "__main__":
    test_get_all_choices()
    test_get_single_choice()
    print("所有测试完成！")