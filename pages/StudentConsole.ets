import { relationalStore } from '@kit.ArkData';
import { Context } from '@ohos.arkui.UIContext';
import ArrayList from '@ohos.util.ArrayList';
import promptAction from '@ohos.promptAction';
import { StudentDBConfig, StudentDBTable } from './StudentArtDate';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 学生数据库控制台
 * 用于管理学生数据库的连接及表的创建操作
 */
export class StudentConsole {
  /** 学生数据库连接对象 RdbStore */
  public RDBStore: relationalStore.RdbStore | null = null;
  /** 学生数据库表集合 */
  public DBTables: ArrayList<StudentDBTable> | undefined;

  /**
   * 构造函数
   * @param dbTables 学生数据库表的ArrayList集合（可选）
   */
  constructor(dbTables?: ArrayList<StudentDBTable>) {
    if (!this.DBTables && dbTables) {
      this.DBTables = dbTables;
    } else {
      this.DBTables = new ArrayList<StudentDBTable>();
    }
  }

  /**
   * 获取学生数据库连接RdbStore，若不存在学生表则创建
   * @param callback 连接成功后的回调函数（无参数）
   */
  public GetDBStore(callback: Function) {
    // 校验回调函数合法性
    if (!callback || typeof callback !== 'function') {
      console.info('学生数据库：回调函数不能为空且必须为函数类型！');
      promptAction.showToast({ message: '回调函数格式错误', duration: 3000 });
      return;
    }

    // 若已存在连接，直接执行回调
    if (this.RDBStore !== null) {
      console.info('学生数据库连接已初始化！');
      callback();
      return;
    }

    // 获取上下文并初始化数据库连接
    let context: Context = getContext(this) as Context;
    relationalStore.getRdbStore(context, StudentDBConfig.STORE_CONFIG, (err, rdb) => {
      if (err) {
        console.error(`学生数据库连接失败：${JSON.stringify(err)}`);
        promptAction.showToast({ message: '数据库连接失败', duration: 3000 });
        return;
      }

      if (rdb !== null) {
        this.RDBStore = rdb;
        console.info('学生数据库连接初始化成功');

        // 遍历表集合，执行建表语句
        if (this.DBTables) {
          for (let i = 0; i < this.DBTables.length; i++) {
            const table = this.DBTables[i];
            if (table.SQLCreateTable) {
              this.RDBStore.executeSql(table.SQLCreateTable)
                .then(() => {
                  console.info(`学生表【${table.TableName}】创建成功`);
                })
                .catch((e: BusinessError) => {
                  console.error(`学生表【${table.TableName}】创建失败：${JSON.stringify(e)}`);
                });
            }
          }
        }

        // 执行回调函数
        callback();
      }
    });
  }
}