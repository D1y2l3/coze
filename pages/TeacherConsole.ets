import { relationalStore } from '@kit.ArkData';
import { Context } from '@ohos.arkui.UIContext';
import ArrayList from '@ohos.util.ArrayList';
import promptAction from '@ohos.promptAction';
import { TeacherDBConfig, TeacherDBTable } from './TeacherArtDate'; // 替换为教师数据配置导入路径
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 教师数据库控制台
 * 用于管理教师数据库的连接及表的创建操作
 */
export class TeacherConsole {
  /** 教师数据库连接对象 RdbStore */
  public RDBStore: relationalStore.RdbStore | null = null;
  /** 教师数据库表集合 */
  public DBTables: ArrayList<TeacherDBTable> | undefined;

  /**
   * 构造函数
   * @param dbTables 教师数据库表的ArrayList集合（可选）
   */
  constructor(dbTables?: ArrayList<TeacherDBTable>) {
    if (!this.DBTables && dbTables) {
      this.DBTables = dbTables;
    } else {
      this.DBTables = new ArrayList<TeacherDBTable>();
    }
  }

  /**
   * 获取教师数据库连接RdbStore，若不存在教师表则创建
   * @param callback 连接成功后的回调函数（无参数）
   */
  public GetDBStore(callback: Function) {
    // 校验回调函数合法性
    if (!callback || typeof callback !== 'function') {
      console.info('教师数据库：回调函数不能为空且必须为函数类型！');
      promptAction.showToast({ message: '回调函数格式错误', duration: 3000 });
      return;
    }

    // 若已存在连接，直接执行回调
    if (this.RDBStore !== null) {
      console.info('教师数据库连接已初始化！');
      callback();
      return;
    }

    // 获取上下文并初始化数据库连接
    let context: Context = getContext(this) as Context;
    relationalStore.getRdbStore(context, TeacherDBConfig.STORE_CONFIG, (err, rdb) => {
      if (err) {
        console.error(`教师数据库连接失败：${JSON.stringify(err)}`);
        promptAction.showToast({ message: '数据库连接失败', duration: 3000 });
        return;
      }

      if (rdb !== null) {
        this.RDBStore = rdb;
        console.info('教师数据库连接初始化成功');

        // 遍历表集合，执行建表语句
        if (this.DBTables) {
          for (let i = 0; i < this.DBTables.length; i++) {
            const table = this.DBTables[i];
            if (table.SQLCreateTable) {
              this.RDBStore.executeSql(table.SQLCreateTable)
                .then(() => {
                  console.info(`教师表【${table.TableName}】创建成功`);
                })
                .catch((e: BusinessError) => {
                  console.error(`教师表【${table.TableName}】创建失败：${JSON.stringify(e)}`);
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