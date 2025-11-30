export  interface Student {
  id: number; // 主键自增，可选
  name: string;
  age: number;
  class: string;
  school: string; // 学校
  phone: string; // 联系电话
  birthDate: string; // 出生日期
  college: string; // 新增：学院字段
}
