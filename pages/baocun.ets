// baocun.ets
export class GlobalUserState {
  private static instance: GlobalUserState | null = null;
  isLoggedIn: boolean = false; // 是否登录
  phoneNumber: string = ''; // 登录手机号
  userType: string = ''; // 用户类型（学生/教师/管理者）

  // 单例模式
  static getInstance() {
    if (!GlobalUserState.instance) {
      GlobalUserState.instance = new GlobalUserState();
    }
    return GlobalUserState.instance;
  }

  // 登录方法：补充用户类型参数
  login(phoneNumber: string, userType: string) {
    this.isLoggedIn = true;
    this.phoneNumber = phoneNumber;
    this.userType = userType; // 保存用户类型
  }

  // 登出方法：清空所有状态
  logout() {
    this.isLoggedIn = false;
    this.phoneNumber = '';
    this.userType = '';
  }

  // 获取用户类型（供其他页面使用）
  getUserType(): string {
    return this.userType;
  }
}