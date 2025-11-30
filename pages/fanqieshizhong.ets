@Entry
@Component
struct TomatoTimer {
  @State currentTime: string = this.getFormattedTime()
  @State focusMinutes: number = 25
  @State remainingSeconds: number = 25 * 60
  @State isRunning: boolean = false
  @State timerId: number | null = null
  @State showCompletion: boolean = false
  @State progressValue: number = 0
  @State ringColor: Color = Color.Blue

  // 获取格式化时间
  getFormattedTime(): string {
    const now = new Date()
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`
  }

  // 更新当前时间
  updateTime() {
    this.currentTime = this.getFormattedTime()
  }

  // 开始/暂停计时器
  toggleTimer() {
    if (this.isRunning) {
      // 暂停计时器
      if (this.timerId !== null) {
        clearInterval(this.timerId)
        this.timerId = null
      }
      this.isRunning = false
    } else {
      // 开始计时器
      if (this.showCompletion) {
        this.showCompletion = false
        this.remainingSeconds = this.focusMinutes * 60
        this.progressValue = 0
      }

      this.isRunning = true
      this.timerId = setInterval(() => {
        if (this.remainingSeconds > 0) {
          this.remainingSeconds--
          this.progressValue = 1 - (this.remainingSeconds / (this.focusMinutes * 60))

          // 根据剩余时间改变进度条颜色
          if (this.remainingSeconds < this.focusMinutes * 60 * 0.25) {
            this.ringColor = Color.Red
          } else if (this.remainingSeconds < this.focusMinutes * 60 * 0.5) {
            this.ringColor = Color.Orange
          }
        } else {
          // 计时结束
          clearInterval(this.timerId)
          this.timerId = null
          this.isRunning = false
          this.showCompletion = true
          this.ringColor = Color.Green
        }
      }, 1000)
    }
  }

  // 重置计时器
  resetTimer() {
    if (this.timerId !== null) {
      clearInterval(this.timerId)
      this.timerId = null
    }
    this.isRunning = false
    this.showCompletion = false
    this.remainingSeconds = this.focusMinutes * 60
    this.progressValue = 0
    this.ringColor = Color.Blue
  }

  // 设置专注时间
  setFocusTime(minutes: number) {
    this.focusMinutes = minutes
    this.resetTimer()
  }

  // 格式化倒计时显示
  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  aboutToAppear() {
    // 每秒更新一次当前时间
    setInterval(() => {
      this.updateTime()
    }, 1000)
  }

  build() {
    Column() {
      // 顶部当前时间显示
      Text(this.currentTime)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 30 })
        .fontColor("#333")

      // 番茄钟卡片
      Stack() {
        // 卡片背景
        Column() {
          // 留空给进度条
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .padding(20)
        .shadow({ radius: 10, color: Color.Gray, offsetX: 0, offsetY: 5 })

        // 进度条
        Progress({
          value: this.progressValue,
          style: ProgressStyle.Ring
        })
          .width(200)
          .height(200)
          .color(this.ringColor)

        // 倒计时显示
        Text(this.formatTime(this.remainingSeconds))
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor("#333")
          .margin({ top: 20 })
      }
      .width('80%')
      .height(300)
      .margin({ bottom: 30 })

      // 完成提示
      if (this.showCompletion) {
        Text('时间到，可以适当休息')
          .fontSize(20)
          .fontColor(Color.Green)
          .margin({ bottom: 20 })
          .opacity(0.9)
      }

      // 时间设置按钮
      Row() {

        Button('45分钟', { type: ButtonType.Capsule, stateEffect: true })
          .backgroundColor(this.focusMinutes === 45 ? '#5B8FF9' : '#F0F0F0')
          .fontColor(this.focusMinutes === 45 ? Color.White : '#333')
          .onClick(() => this.setFocusTime(45))
          .width(90)
          .margin(5)

        Button('30分钟', { type: ButtonType.Capsule, stateEffect: true })
          .backgroundColor(this.focusMinutes === 30 ? '#5B8FF9' : '#F0F0F0')
          .fontColor(this.focusMinutes === 30 ? Color.White : '#333')
          .onClick(() => this.setFocusTime(30))
          .width(90)
          .margin(5)

        Button('25分钟', { type: ButtonType.Capsule, stateEffect: true })
          .backgroundColor(this.focusMinutes === 25 ? '#5B8FF9' : '#F0F0F0')
          .fontColor(this.focusMinutes === 25 ? Color.White : '#333')
          .onClick(() => this.setFocusTime(25))
          .width(90)
          .margin(5)
      }
      .margin({ bottom: 20 })

        Row() {

        Button('15分钟', { type: ButtonType.Capsule, stateEffect: true })
          .backgroundColor(this.focusMinutes === 15 ? '#5B8FF9' : '#F0F0F0')
          .fontColor(this.focusMinutes === 15 ? Color.White : '#333')
          .onClick(() => this.setFocusTime(15))
          .width(90)
          .margin(5)

          Button('10分钟', { type: ButtonType.Capsule, stateEffect: true })
            .backgroundColor(this.focusMinutes === 10 ? '#5B8FF9' : '#F0F0F0')
            .fontColor(this.focusMinutes === 10 ? Color.White : '#333')
            .onClick(() => this.setFocusTime(10))
            .width(90)
            .margin(5)

        Button('5分钟', { type: ButtonType.Capsule, stateEffect: true })
          .backgroundColor(this.focusMinutes === 5 ? '#5B8FF9' : '#F0F0F0')
          .fontColor(this.focusMinutes === 5 ? Color.White : '#333')
          .onClick(() => this.setFocusTime(5))
          .width(90)
          .margin(5)
      }
      .margin({ bottom: 15 })

      // 操作按钮
      Row() {
        Button(this.isRunning ? '暂停' : '开始', { type: ButtonType.Capsule })
          .backgroundColor(this.isRunning ? '#F67280' : '#34BFA3')
          .fontColor(Color.White)
          .width(120)
          .height(40)
          .onClick(() => this.toggleTimer())
          .margin({ right: 15 })

        Button('重置', { type: ButtonType.Capsule })
          .backgroundColor('#F0F0F0')
          .fontColor('#333')
          .width(120)
          .height(40)
          .onClick(() => this.resetTimer())
      }
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F7FA')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}