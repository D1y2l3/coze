import { relationalStore } from '@kit.ArkData';

/**
 * 学生数据库配置类
 * 定义学生数据库的基本属性（名称、安全级别等）
 */
export class StudentDBConfig {
  /**
   * 学生数据库存储配置
   * - name: 数据库文件名
   * - securityLevel: 安全级别
   * - encrypt: 是否加密
   * - isReadOnly: 是否只读
   */
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'student.db', // 学生数据库文件名
    securityLevel: relationalStore.SecurityLevel.S1, // 统一安全级别S1
    encrypt: false, // 不加密（与参考保持一致）
    isReadOnly: false // 非只读模式（支持增删改查）
  };
}

/**
 * 学生数据表定义类
 * 单例模式管理学生表结构，统一表名、SQL语句、列名
 */
export class StudentDBTable {
  public static Instance: StudentDBTable; // 单例实例（与参考结构一致）
  public TableName: string; // 表名称
  public SQLCreateTable: string | null = null; // 创建表的SQL语句
  public Columns: Array<string>; // 表的列名数组

  /**
   * 构造函数（私有，通过单例方法创建）
   * @param tableName 表名称
   * @param sqlCreateTable 创建表的SQL语句
   * @param columns 表的列名数组
   */
  private constructor(tableName: string, sqlCreateTable: string | null, columns: Array<string>) {
    this.TableName = tableName;
    this.SQLCreateTable = sqlCreateTable;
    this.Columns = columns;
  }

  /**
   * 获取学生表的单例实例
   * 确保表定义唯一，避免重复创建
   * @returns 学生表单例实例
   */
  public static GetSTUDENTDBTableInstance() {
    if (!StudentDBTable.Instance) { // 补充单例判空，避免重复初始化
      StudentDBTable.Instance = new StudentDBTable(
        'StudentTable', // 学生表表名
        // 创建学生表的SQL语句（包含所有字段，与之前数据库表结构一致）
        'CREATE TABLE IF NOT EXISTS StudentTable(' +
          'id TEXT PRIMARY KEY,' + // 主键ID（文本类型，与参考一致）
          'studentId TEXT NOT NULL,' + // 新增：学号（页面输入）
          'name TEXT NOT NULL,' + // 姓名（非空）
          'age TEXT NOT NULL,' + // 年龄（非空）
          'class TEXT NOT NULL,' + // 班级（非空）
          'school TEXT NOT NULL,' + // 学校（非空）
          'phone TEXT NOT NULL,' + // 联系电话（非空）
          'college TEXT NOT NULL,' + // 学院（非空）
          'gender TEXT NOT NULL' + // 新增：性别（页面选择）
          ')',
        // 表的列名数组（与SQL字段顺序一致）
        ['id','studentId', 'name', 'age', 'class', 'school', 'phone',  'college', 'gender']
      );
    }
    return StudentDBTable.Instance;
  }
}

/**
 * 学生信息接口
 * 定义学生数据的结构规范，与表字段一一对应
 */
export interface IStudent {
  id: string; // 学生唯一标识ID（与表主键一致）
  studentId: string; // 学号
  name: string; // 姓名
  age: string; // 年龄（数字类型，匹配SQL的INTEGER）
  class: string; // 班级
  school: string; // 学校
  phone: string; // 联系电话
  college: string; // 学院
  gender: string; // 性别
}
/**
 * 学生实体类
 * 实现学生信息接口，封装学生数据对象的创建与操作
 */
export class StudentEntity implements IStudent {
  id: string; // 学生ID
  studentId: string;
  name: string; // 姓名
  age: string; // 年龄
  class: string; // 班级
  school: string; // 学校
  phone: string; // 联系电话
  college: string; // 学院
  gender: string;
  /**
   * 构造函数
   * @param options 学生信息对象（遵循IStudent接口规范）
   */
  constructor(options: IStudent) {
    this.id = options.id; // 初始化学生ID
    this.studentId = options.studentId;
    this.name = options.name; // 初始化姓名
    this.age = options.age; // 初始化年龄
    this.class = options.class; // 初始化班级
    this.school = options.school; // 初始化学校
    this.phone = options.phone; // 初始化联系电话
    this.college = options.college; // 初始化学院
    this.gender = options.gender;
  }


}




