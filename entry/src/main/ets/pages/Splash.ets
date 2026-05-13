import router from '@ohos.router';

@Entry
@Component
struct Splash {
  @State countdown: number = 3;
  private timerId: number = -1;
  private hasNavigated: boolean = false;

  aboutToAppear() {
    this.timerId = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        this.goIndex();
      }
    }, 1000);
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Stack() {
      Image($r('app.media.Advertisement'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover);

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['rgba(8,16,24,0.06)', 0.0], ['rgba(8,16,24,0.78)', 1.0]]
        });

      Text(`跳过 ${this.countdown}`)
        .fontSize(14)
        .fontColor(Color.White)
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .backgroundColor('rgba(17,24,39,0.46)')
        .borderRadius(18)
        .position({ x: '78%', y: 56 })
        .onClick(() => {
          this.goIndex();
        });

      Column({ space: 10 }) {
        Text('鸿蒙智能座舱')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White);

        Text('车辆云控 · 智能反馈 · 安全绑定')
          .fontSize(15)
          .fontColor('rgba(255,255,255,0.82)');
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 28, right: 28, bottom: 64 })
      .position({ x: 0, y: '74%' });
    }
    .width('100%')
    .height('100%');
  }

  private goIndex(): void {
    if (this.hasNavigated) {
      return;
    }

    this.hasNavigated = true;
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }

    router.replaceUrl({
      url: 'pages/Index'
    }).catch(() => {
    });
  }
}
