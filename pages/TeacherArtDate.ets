import { relationalStore } from '@kit.ArkData';

/**
 * 教师数据库配置类
 * 定义教师数据库的基本属性（名称、安全级别等）
 */
export class TeacherDBConfig {
  /**
   * 教师数据库存储配置
   * - name: 数据库文件名
   * - securityLevel: 安全级别
   * - encrypt: 是否加密
   * - isReadOnly: 是否只读
   */
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'teacher.db', // 教师数据库文件名
    securityLevel: relationalStore.SecurityLevel.S1, // 统一安全级别S1
    encrypt: false, // 不加密
    isReadOnly: false // 非只读模式（支持增删改查）
  };
}

/**
 * 教师数据表定义类
 * 单例模式管理教师表结构，统一表名、SQL语句、列名
 */
export class TeacherDBTable {
  public static Instance: TeacherDBTable; // 单例实例
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
   * 获取教师表的单例实例
   * 确保表定义唯一，避免重复创建
   * @returns 教师表单例实例
   */
  public static GetTEACHERDBTableInstance() {
    if (!TeacherDBTable.Instance) {
      TeacherDBTable.Instance = new TeacherDBTable(
        'TeacherTable', // 教师表表名
        // 创建教师表的SQL语句（适配教师信息字段）
        'CREATE TABLE IF NOT EXISTS TeacherTable(' +
          'id TEXT PRIMARY KEY,' + // 主键ID（唯一标识）
          'teacherId TEXT NOT NULL,' + // 工号（教师特有标识）
          'name TEXT NOT NULL,' + // 姓名
          'title TEXT NOT NULL,' + // 职称（如教授、讲师等）
          'department TEXT NOT NULL,' + // 所属部门/系
          'school TEXT NOT NULL,' + // 所属学校
          'phone TEXT NOT NULL,' + // 联系电话
          'gender TEXT NOT NULL,' + // 性别
          'teachingAge TEXT NOT NULL' + // 教龄
          ')',
        // 表的列名数组（与SQL字段顺序一致）
        ['id', 'teacherId', 'name',  'title', 'department', 'school', 'phone', 'gender','teachingAge']
      );
    }
    return TeacherDBTable.Instance;
  }
}

/**
 * 教师信息接口
 * 定义教师数据的结构规范，与表字段一一对应
 */
export interface ITeacher {
  id: string; // 教师唯一标识ID（与表主键一致）
  teacherId: string; // 工号
  name: string; // 姓名
  teachingAge: string;// 教龄
  title: string; // 职称
  department: string; // 所属部门
  school: string; // 所属学校
  phone: string; // 联系电话
  gender: string; // 性别
}

/**
 * 教师实体类
 * 实现教师信息接口，封装教师数据对象的创建与操作
 */
export class TeacherEntity implements ITeacher {
  id: string; // 教师ID
  teacherId: string; // 工号
  name: string; // 姓名
  title: string; // 职称
  department: string; // 所属部门
  school: string; // 所属学校
  phone: string; // 联系电话
  gender: string; // 性别
  teachingAge: string; // 新增教龄

  /**
   * 构造函数
   * @param options 教师信息对象（遵循ITeacher接口规范）
   */
  constructor(options: ITeacher) {
    this.id = options.id;
    this.teacherId = options.teacherId;
    this.name = options.name;
    this.title = options.title;
    this.department = options.department;
    this.school = options.school;
    this.phone = options.phone;
    this.gender = options.gender;
    this.teachingAge = options.teachingAge;
  }
}