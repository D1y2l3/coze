
import { CategoryService } from '../Note/common/datasource/CategoryService';
import { NoteService } from '../Note/common/datasource/NoteService';
import { BreakpointTypeEnum, GlobalInfoModel } from '../Note/common/utils/model/GlobalInfoModel';
import { SecretLock } from '../Note/components/secretlock/model/SecretLock';
import { CategoryController } from '../Note/product/controller/CategoryController';
import { NoteSearchController } from '../Note/product/controller/NoteSearchController';
import { SelectedController } from '../Note/product/controller/SelectedController';
import { SettingController } from '../Note/product/controller/SettingController';
import { SortController } from '../Note/product/controller/SortController';
import { AppStorageV2, PersistenceV2,  } from '@kit.ArkUI';
import { Category, SortEnum } from '../Note/common/datasource/Model';
import { Note } from '../Note/components/richeditor/model/Note';
import { LazyDataSource } from '../Note/components/richeditor/model/LazyDataSource';
import { toolBarList, ToolBar, TOOL_BAR_NAME , sortData ,
  SortType, showType, ShowMethod, SHOW_METHOD_ENUM} from '../Note/product/constants/HomeUiConstant';
import { NotificationUtil } from '../Note/common/utils/util/NotificationUtil';
import { BreakpointType } from '../Note/common/utils/util/BreakpointSystem';
import { DateUtil } from '../Note/common/utils/util/DateUtil';
import { SearchNoResult } from '../Note/product/components/SearchNoResult';
import { EmptyNotes } from '../Note/product/components/EmptyNotes';
import { DateConstants } from '../Note/common/utils/constants/DateConstants';


@Entry
@ComponentV2
struct Index {
  @Provider('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  noteService: NoteService = NoteService.instance;
  categoryService: CategoryService = CategoryService.instance;
  sortController: SortController = SortController.instance;
  noteSearchController: NoteSearchController = NoteSearchController.instance;
  categoryController: CategoryController = CategoryController.instance;
  selectedController: SelectedController = SelectedController.instance;
  settingController: SettingController = SettingController.instance

  @Local secretLock: SecretLock = PersistenceV2.connect(SecretLock, () => new SecretLock())!;
  @Local globalInfo: GlobalInfoModel =
    AppStorageV2.connect<GlobalInfoModel>(GlobalInfoModel, () => new GlobalInfoModel())!;
  @Local noteList: Note[] = [];
  @Local currentCategory: Category = this.categoryService.getFirstCategory();
  @Local dataList:LazyDataSource<Note> = new LazyDataSource();
  @Local showListType: SHOW_METHOD_ENUM  = SHOW_METHOD_ENUM.normalList;


  aboutToAppear(): void {
    // 判断通知是否授权
    NotificationUtil.authorizeNotification().then(grant => {
      this.settingController.isNoticeGrant = grant;
    })

    if (this.secretLock.gesture) {
      const params: Record<string, Object> = { 'fromEntrance': true, 'appPathStack': this.appPathStack };
      this.appPathStack.pushPathByName('DrawLock', params);
    }
  }

  // 更新瀑布流卡片数据
  updateDataList() {
    this.dataList.clear();
    this.noteList.forEach((item:Note) => {
      this.dataList.pushData(item);
    })
  }

  // 笔记卡片长按事件
  handleLangPress(item: Note) {
    // 非多选状态下生效
    if (!this.selectedController.isCtrl) {
      this.selectedController.isCtrl = true;
      item.isSelected = true;
      this.selectedController.selectedCount = 1;
    }
  }

  getSelectedImage(isSelect: boolean): ResourceStr{
    return isSelect ? $r('app.media.selected') : $r('app.media.unselected');
  }

  getNoteItemBgColor(isSelect: boolean): ResourceStr{
    if (this.selectedController.isCtrl) {
      return isSelect ? $r('sys.color.background_tertiary') : $r('sys.color.comp_background_list_card');
    }
    return $r('sys.color.comp_background_list_card');
  }

  // 获取选中的笔记
  getSelectData():Note[] {
    let tempArray: Note[] = [];
    this.noteList.forEach((item) => {
      if (item.isSelected) {
        tempArray.push(item);
      }
    })
    if (tempArray.length === 0) {
      this.getUIContext().getPromptAction().showToast({
        message: '还未选中任何笔记',
        alignment: Alignment.Center
      })
    }
    return tempArray;
  }

  // 全选
  handleSelectAll() {
    if (this.selectedController.selectedCount === this.noteList.length) {
      this.noteList.forEach(item => item.isSelected = false);
      this.selectedController.selectedCount = 0;
    } else {
      this.noteList.forEach(item => item.isSelected = true);
      this.selectedController.selectedCount = this.noteList.length;
    }
  }

  // 底部工具栏点击事件 分类、删除、全选
  handleToolBarClick(name: TOOL_BAR_NAME) {
    if (name === TOOL_BAR_NAME.select_all) {
      this.handleSelectAll()
      return;
    }

    const selectDataList = this.getSelectData();
    if (selectDataList.length === 0) {
      return;
    }

    if (name === TOOL_BAR_NAME.move_category) {
      const params: Record<string, Object> =
        { 'isEditCategory': false, 'currentCategory': this.currentCategory, 'noteList': selectDataList };
      this.appPathStack.pushPathByName('EditCategory', params);
    } else if (name === TOOL_BAR_NAME.delete) {
      const params: Record<string, Object> = {'noteList': selectDataList };
      this.appPathStack.pushPathByName('DeleteNoteDialog', params);
    }
  }

  // 重置分类
  resetCategory(category:Category) {
    this.currentCategory = category;
    this.noteSearchController.isSearching = false; // 重置搜索状态
    this.noteSearchController.searchKeyword = '';
    this.noteList = this.noteService.getNoteList(
      this.currentCategory.id, this.sortController.sortBy, this.noteSearchController.searchKeyword);
    this.categoryController.openCategorySheet = false;
    this.updateDataList();
  }

  // 列表排序
  sort = (type: SortEnum) => {
    this.sortController.onSortConfirm(this.currentCategory.id, type,
      this.noteSearchController.searchKeyword);
  }

  // 列表展示方式
  toggleShowType = (useWaterFlow: SHOW_METHOD_ENUM) => {
    this.showListType = useWaterFlow;
    this.sortController.openSortSheet = false;
  }

  @Builder
  addNoteBuilder(){
    if (this.selectedController.isCtrl === false){
      Row(){
        SymbolGlyph($r('sys.symbol.plus'))
          .fontColor([Color.White])
          .fontSize(35);
      }
      .justifyContent(FlexAlign.Center)
      .width(50)
      .height(50)
      .borderRadius(44)
      .backgroundColor('#FFAA00')
      .zIndex(10)
      .position({ right: 30, bottom: 100 })
      .onClick(() => {
        const params: Record<string, Object> = { 'noteId': '', 'currentCategory': this.currentCategory };
        this.appPathStack.pushPathByName('EditNotes', params);
      })
    }
  }

  @Builder
  toolBarBuilder(){
    if (this.selectedController.isCtrl){
      Row(){
        ForEach(toolBarList, (item: ToolBar) => {
          Column({ space: 5 }){
            Image(item.icon)
              .width(24)
              .height(24)

            Text(item.name)
              .fontSize(10)
              .fontColor($r('sys.color.font_secondary'))
          }
          .onClick(() => {
            this.handleToolBarClick(item.name)
          })
        }, (item: ToolBar) => JSON.stringify(item))
      }
      .margin({ top: 10 })
      .padding({ bottom: 10 })
      .justifyContent(FlexAlign.SpaceAround)
      .width('100%')
      .height(70)
      .backgroundColor($r('sys.color.comp_background_list_card'))
    }
  }

  @Styles
  topAreaStyle() {
    .width('100%')
    .padding(new BreakpointType<Padding>({
      sm: {
        top: 12,
        bottom: 20,
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8'),
      },
      md: {
        top: 12,
        bottom: 20,
        left: $r('sys.float.padding_level12'),
        right: $r('sys.float.padding_level12'),
      },
      lg: {
        top: 12,
        bottom: 20,
        left: $r('sys.float.padding_level16'),
        right: $r('sys.float.padding_level16'),
      },
    }).getValue(this.globalInfo.currentBreakpoint));
  }

  @Builder
  topArea() {
    Row() {
      Text(this.selectedController.isCtrl ? `已选${this.selectedController.selectedCount}项` : ('首页'))
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      Blank();
      Image(this.selectedController.isCtrl ? $r('app.media.exit_ctrl') : $r('app.media.user_avatar'))
        .width(this.selectedController.isCtrl ? 24 : 40)
        .height(this.selectedController.isCtrl ? 24 : 40)
        .onClick(() => {
          if (this.selectedController.isCtrl) {
            this.noteList.forEach(item => item.isSelected = false)
            this.selectedController.recoverInitState();
          } else {
            this.appPathStack.pushPathByName('MineView', undefined);
          }
        });
    }
    .topAreaStyle()
  }

  @Builder
  editorNoteList() {
    if (!this.selectedController.isCtrl){
      Row() {
        Row({ space: 4 }) {
          Text(this.currentCategory.name)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          SymbolGlyph($r('sys.symbol.arrowtriangle_down_fill'))
            .fontColor([$r('sys.color.font_secondary')]);
        }.onClick(() => {
          this.categoryController.openCategorySheet = true;
        })
        .bindSheet($$this.categoryController.openCategorySheet, this.showCategoryDialog(), {
          title: { title: ('笔记分类') },
          width: '100%',
          height: 400,
          radius:{
            topLeft:16,
            topRight:16
          }
        })

        Blank();
        Image($r('app.media.icon_more'))
          .height(20)
          .width(20)
          .onClick(() => {
            this.sortController.openSortSheet = true;
          })
          .bindSheet($$this.sortController.openSortSheet, this.sortSheet(), {
            width: '100%',
            showClose: false,
            height: 376,
            radius:{
              topLeft:16,
              topRight:16
            }
          })
      }
      .width('100%')
      .padding(new BreakpointType<Padding>({
        sm: {
          left: $r('sys.float.padding_level8'),
          right: $r('sys.float.padding_level8'),
          top: 12,
          bottom: 12
        },
        md: {
          left: $r('sys.float.padding_level12'),
          right: $r('sys.float.padding_level12'),
          top: 12,
          bottom: 12
        },
        lg: {
          left: $r('sys.float.padding_level16'),
          right: $r('sys.float.padding_level16'),
          top: 12,
          bottom: 12
        },
      }).getValue(this.globalInfo.currentBreakpoint))
    }
  }

  @Builder
  cardItem(item: Note, maxLines: number) {
    Stack({ alignContent: Alignment.TopEnd }){
      Column({space:12}) {
        Text(item.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(item.description)
          .maxLines(maxLines)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontSize(14)
          .lineHeight(19)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Regular)

        Text(DateUtil.getFormatDateStr(item.createTime, DateConstants.DATE_FORMAT4))
          .fontSize(12)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(this.getNoteItemBgColor(item.isSelected))
      .borderRadius(16)
      .width('100%')
      .padding(12)

      if (this.selectedController.isCtrl) {
        Image(this.getSelectedImage(item.isSelected))
          .width(35)
          .height(35)
          .padding({ top: 10, right: 10})
      }
    }
    .onClick(() => {
      if (this.selectedController.isCtrl) {
        item.isSelected = !item.isSelected;
        let count: number = 0;
        this.noteList.forEach(item => {
          if (item.isSelected) {
            count++;
          }
        })
        this.selectedController.selectedCount = count;
      } else {
        const params: Record<string, Object> = { 'noteId': item.id, 'currentCategory': this.currentCategory };
        this.appPathStack.pushPathByName('EditNotes', params);
      }
    });
  }

  @Styles
  cardWrapperStyle() {
    .width('100%')
    .margin({ bottom: 10 })
    .padding(new BreakpointType<Padding>({
      sm: {
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8'),
      },
      md: {
        left: $r('sys.float.padding_level12'),
        right: $r('sys.float.padding_level12'),
      },
      lg: {
        left: $r('sys.float.padding_level16'),
        right: $r('sys.float.padding_level16'),
      },
    }).getValue(this.globalInfo.currentBreakpoint))
    .layoutWeight(1)
  }

  @Builder
  cardList() {
    Column(){
      List({ space: 12 }) {
        ForEach(this.noteList, (item: Note) => {
          ListItem() {
            this.cardItem(item,1)
          }
          .gesture(
            // 绑定可以重复触发的LongPressGesture
            LongPressGesture({ repeat: false, fingers: 1, duration: 500 })
              .onAction((event: GestureEvent|undefined) => {
                if(event){
                  this.handleLangPress(item)
                }
              })
          )
        }, (item: Note) => item.id);
      }
      .lanes(this.globalInfo.currentBreakpoint === BreakpointTypeEnum.SM ? 1 : 2,
        obtainGutter(this.globalInfo.currentBreakpoint, 'List'))
      .scrollBar(BarState.Off);
    }
    .cardWrapperStyle()
  }

  @Builder
  waterCardList() {
    Column() {
      WaterFlow() {
        LazyForEach(this.dataList, (item: Note) => {
          FlowItem() {
            this.cardItem(item, 9)
          }
          .width('100%')
          .gesture(
            // 绑定可以重复触发的LongPressGesture
            LongPressGesture({ repeat: false, fingers: 1, duration: 500 })
              .onAction((event: GestureEvent|undefined) => {
                if(event){
                  this.handleLangPress(item)
                }
              })
          )
        }, (item:Note) => item.id)
      }
      .cachedCount(1)
      .columnsTemplate('1fr 1fr')
      .columnsGap(obtainGutter(this.globalInfo.currentBreakpoint, 'WaterFlow'))
      .rowsGap(16)
      .width('100%')
      .height('100%')
    }
    .cardWrapperStyle()
  }

  @Builder
  showNoteList() {
    if (this.noteSearchController.isSearching && this.noteList.length === 0) {
      SearchNoResult()
    }
    if (!this.noteSearchController.isSearching && this.noteList.length === 0){
      EmptyNotes()
    } else if (this.showListType === SHOW_METHOD_ENUM.normalList) {
      this.cardList()
    } else {
      this.waterCardList()
    }
  }

  @Builder
  showCategoryDialog() {
    Column() {
      Column() {
        List() {
          ForEach(this.categoryService.getCategoryList(), (category: Category, index: number) => {
            ListItem() {
              Column() {
                if (index !== 0) {
                  Divider()
                    .color($r('sys.color.comp_divider'));
                }
                Row() {
                  Text(category.name)
                    .fontSize(16)
                    .fontColor(this.currentCategory.id === category.id ?
                      $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
                    .fontWeight(this.currentCategory?.id === category.id ? FontWeight.Medium : FontWeight.Regular)

                  Blank();
                  Text(String(category.totalCount))
                    .fontSize(16);
                }
                .width('100%')
                .height(50)
              }
            }
            .backgroundColor($r('sys.color.comp_background_list_card'))
            .padding({
              left: 12,
              right: 12,
            })
            .onClick(() => {
              this.resetCategory(category)
            });
          }, (category: Category) => category.id);
        }
        .borderRadius(8)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None);
      }
      .height(250);

      Blank();
      Button() {
        Row() {
          Text('前往笔记分类')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium);
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontWeight(FontWeight.Medium)
            .fontSize(18)
            .fontColor([Color.White])
            .padding({
              left: 13,
            })
        }
      }
      .height(40)
      .width('100%')
      .backgroundColor('#FFAA00')
      .margin({
        bottom: 30,
      })
      .onClick(() => {
        this.categoryController.openCategorySheet = false;
        if (this.currentCategory) {
          const params: Record<string, Object | undefined> =
            { 'isEditCategory': true, 'currentCategory': this.currentCategory, 'noteList': undefined };
          this.appPathStack.pushPathByName('EditCategory', params);
        }
      });
    }
    .height(344)
    .margin(new BreakpointType<Margin>({
      sm: {
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8'),
      },
      md: {
        left: $r('sys.float.padding_level12'),
        right: $r('sys.float.padding_level12'),
      },
      lg: {
        left: $r('sys.float.padding_level16'),
        right: $r('sys.float.padding_level16'),
      },
    }).getValue(this.globalInfo.currentBreakpoint))
    .backgroundColor($r('sys.color.background_secondary'));
  }

  @Builder
  sheetCard(title: string, data:SortType[] | ShowMethod[], callBack:Function, group: string) {
    Column() {
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({bottom: 16});

      List({ space: 24 }) {
        ForEach(data, (item:SortType | ShowMethod) => {
          ListItem() {
            Row() {
              Text(item.name)
                .fontSize(16)
                .fontColor($r('sys.color.font_primary'))
              Blank();
              Radio({ value: item.type, group: group })
                .checked(this.sortController.sortBy === item.type || this.showListType === item.type)
                .onChange((isChecked: boolean) => {
                  if (isChecked === true) {
                    callBack(item.type)
                  }
                });
            }
            .width('100%')
            .padding({left: 12, right: 12 })
            .onClick(() =>callBack(item.type));
          }
        }, (item:SortType) => JSON.stringify(item))
      }
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(8)
      .padding({
        top:16,
        bottom: 16
      })
      .divider({
        strokeWidth:1,
        startMargin:12,
        endMargin:12
      })
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .width('100%')
    .padding(new BreakpointType<Padding>({
      sm: {
        top:20,
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8'),
      },
      md: {
        top:20,
        left: $r('sys.float.padding_level12'),
        right: $r('sys.float.padding_level12'),
      },
      lg: {
        top:20,
        left: $r('sys.float.padding_level16'),
        right: $r('sys.float.padding_level16'),
      },
    }).getValue(this.globalInfo.currentBreakpoint))
  }

  @Builder
  sortSheet() {
    Column() {
      this.sheetCard('展示形式', showType, this.toggleShowType, 'showType')
      this.sheetCard('排序方式', sortData, this.sort, 'sortGroup')
    }
  }

  build() {
    Navigation(this.appPathStack) {
      Column() {
        this.topArea();
        // 搜索框
        Search({
          placeholder: ('请输入关键字搜索'),
        })
          .placeholderFont({size: 14})
          .placeholderColor('#999999')
          .fontColor($r('sys.color.font_primary'))
          .margin(new BreakpointType<Margin>({
            sm: {
              bottom: 12,
              left: $r('sys.float.padding_level8'),
              right: $r('sys.float.padding_level8'),
            },
            md: {
              bottom: 12,
              left: $r('sys.float.padding_level12'),
              right: $r('sys.float.padding_level12'),
            },
            lg: {
              bottom: 12,
              left: $r('sys.float.padding_level16'),
              right: $r('sys.float.padding_level16'),
            },
          }).getValue(this.globalInfo.currentBreakpoint))
          .onSubmit((value: string) => { // 提交搜索
            this.noteList = this.noteSearchController.onSearch(this.currentCategory.id, value,
              this.sortController.sortBy);
            this.updateDataList();
          })
          .onChange((value: string) => { // 输入变化时
            if (!value) {
              // 清空搜索时恢复列表
              this.noteList =
                this.noteSearchController.onSearch(this.currentCategory.id, '', this.sortController.sortBy);
              this.updateDataList();
            }
          })

        this.editorNoteList()
        this.showNoteList()
        this.toolBarBuilder()
        this.addNoteBuilder()
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
      .backgroundColor($r('sys.color.background_secondary'))
      .width('100%')
      .height('100%');
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .onNavBarStateChange(() => {
      this.noteSearchController.searchKeyword = '';
      this.noteList = this.noteService.getNoteList(
        this.currentCategory.id, this.sortController.sortBy, this.noteSearchController.searchKeyword);
      this.updateDataList();
    });
  }
}

/**
 * 获取列间距
 * @param breakPoint
 * @returns
 */
function obtainGutter(breakPoint: BreakpointTypeEnum, type: string): Dimension{
  switch (breakPoint){
    case BreakpointTypeEnum.SM:
      return type === 'List' ? 0 : $r('sys.float.padding_level8');
    case BreakpointTypeEnum.MD:
      return $r('sys.float.padding_level12');
    default :
      return $r('sys.float.padding_level16');
  }
}

//    "Note/product/ pages/EditNotes",
//    "Note/product/ pages/EditorCategory",
//    "Note/product/ pages/mine/MineView",
//    "Note/product/ pages/mine/Trash",
//    "Note/product/ pages/mine/Setting",
//    "Note/product/ pages/mine/PrivacyAgreement",
//    "Note/product/ pages/mine/SecretSetting",
//
//    "Note/product/ pages/mine/FeedBackChoose",
//    "Note/product/ pages/mine/FeedBackPage",
//    "Note/product/ pages/mine/FeedBackRecordPage",
//    "Note/product/ pages/mine/PrivacySetting",
//    "Note/product/ pages/mine/AboutUs"