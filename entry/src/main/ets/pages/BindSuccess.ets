import router from '@ohos.router';

@Entry
@Component
struct BindSuccessPage {
  build() {
    Column() {
      Row() {
        Blank();

        Text('绑定车辆')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Blank()
          .width(24);
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 });

      Blank();

      Column({ space: 18 }) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(132)
            .height(132)
            .borderRadius(66)
            .backgroundColor('#E6FFFB');

          Image($r('app.media.ic_success'))
            .width(90)
            .height(90)
            .objectFit(ImageFit.Contain);
        }

        Text('绑定成功')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827');

        Text('车辆已加入你的智能座舱账户')
          .fontSize(16)
          .fontColor('#6B7280');
      }
      .alignItems(HorizontalAlign.Center);

      Column({ space: 10 }) {
        Row() {
          Text('下一步')
            .fontSize(14)
            .fontColor('#6B7280');

          Blank();

          Text('进入首页查看车辆状态')
            .fontSize(14)
            .fontColor('#111827');
        }
        .width('88%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8);

        Row() {
          Text('安全状态')
            .fontSize(14)
            .fontColor('#6B7280');

          Blank();

          Text('已开启云端同步')
            .fontSize(14)
            .fontColor('#0E9F6E');
        }
        .width('88%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8);
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 42 });

      Blank();

      Button('完成')
        .width('88%')
        .height(52)
        .backgroundColor('#111827')
        .fontColor(Color.White)
        .fontSize(17)
        .borderRadius(8)
        .margin({ bottom: 40 })
        .onClick(() => {
          router.replaceUrl({ url: 'pages/Home' });
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }
}

export { BindSuccessPage };
