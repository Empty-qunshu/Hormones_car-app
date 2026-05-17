import router from '@ohos.router';
import { AppRoutes } from './AppConstants';
import { AppTopBar, InfoCardRow } from './CommonWidgets';

@Entry
@Component
struct BindSuccessPage {
  build() {
    Column() {
      AppTopBar({
        title: '绑定车辆'
      });

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
        InfoCardRow({
          label: '下一步',
          value: '进入首页查看车辆状态'
        });

        InfoCardRow({
          label: '安全状态',
          value: '已开启云端同步',
          valueColor: '#0E9F6E'
        });
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
          router.replaceUrl({ url: AppRoutes.HOME });
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }
}

export { BindSuccessPage };
