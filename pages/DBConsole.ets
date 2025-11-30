import { relationalStore } from '@kit.ArkData';
import { Context } from '@ohos.arkui.UIContext';
import ArrayList from '@ohos.util.ArrayList';
import promptAction from '@ohos.promptAction';
import { DBConfig, DBTable} from './enrollmentArtDate';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 数据库控制台
 * 用于添删改查数据库表
 */
export class DBConsole {
  /** 数据库连接对象 RdbStore */
  public RDBStore: relationalStore.RdbStore | null = null;
  /** 数据库表 DBTables */
  public DBTables: ArrayList<DBTable> | undefined;

  /**
   * 构造函数
   * 参数为数据库表的 ArrayList 集合类型
   */
  constructor(dbTables?: ArrayList<DBTable>) {
    if (!this.DBTables && dbTables) {
      this.DBTables = dbTables;
    } else {
      this.DBTables = new ArrayList<DBTable>();
    }
  }

  /**
   * 获取数据库连接 RdbStore，如果不存在数据库表 StudentInfo，创建它
   * 参数为一个不带参数的回调函数
   */
  public GetDBStore(callback: Function) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      console.info('callback 回调函数不能为空！');
      promptAction.showToast({ message: 'callback 回调函数不能为空！', duration: 3000 });
      return;
    }
    if (this.RDBStore !== null) {
      console.info('数据库连接对象已初始化！');
      callback();
    } else {
      let context: Context = getContext(this) as Context;
      relationalStore.getRdbStore(context, DBConfig.STORE_CONFIG, (err, rdb) => {
        if (err) {
          console.error('错误：' + err);
          promptAction.showToast({ message: '错误：' + err, duration: 3000 });
          return;
        }
        if (rdb !== null) {
          this.RDBStore = rdb;

          if (this.DBTables) {
            for (let i = 0; i < this.DBTables.length; i++) {
              if (this.DBTables[i].SQLCreateTable) {


              this.RDBStore.executeSql(  'CREATE TABLE IF NOT EXISTS UserRegistrationTable(' +
                'ID TEXT PRIMARY KEY,' + // 主键ID，文本类型
                'PhoneNumber TEXT, ' + // 手机号码，文本类型
                'Password TEXT, ' + // 密码，文本类型
                'Email TEXT, ' + // 邮箱，文本类型
                'UserType TEXT' +      // 新增：存储人员类型（学生/教师/管理者）
                ')')
                  .then(()=>{

                    console.info('成功创建数据库和数据库表！');
                    console.info(this.DBTables![i].SQLCreateTable);
                  })
                    .catch((e:BusinessError)=>{
                      console.log("错误",JSON.stringify(e))
                    })



              }
            }
          }

          callback();
        }
      });
    }
  }
}
