import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { AuthApi } from './AuthApi';

@Entry
@Component
export struct BindCar {
  @State vinCode: string = '';
  @State showErrorToast: boolean = false;
  @State errorMessage: string = '车架号错误，请检查车架号是否正确';
  @State isSubmitting: boolean = false;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          });

        Blank();

        Text('绑定车辆')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
          .textAlign(TextAlign.Center);

        Blank()
          .width(24);
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 });

      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 10 }) {
            Text('添加你的车辆')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
              .width('100%');

            Text('输入车架号后，系统会从服务器绑定对应车辆')
              .fontSize(15)
              .fontColor('#6B7280')
              .width('100%');
          }
          .width('88%')
          .margin({ top: 12 });

          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width('88%')
              .height(190)
              .backgroundColor('#E6F7FF')
              .borderRadius(8);

            Image($r('app.media.bg_owner_car'))
              .width('82%')
              .height(170)
              .objectFit(ImageFit.Contain);
          }
          .width('100%')
          .height(210);

          Column({ space: 12 }) {
            Row() {
              Text('车架号 VIN')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827');

              Blank();

              Text(`${this.vinCode.length} 位`)
                .fontSize(13)
                .fontColor(this.vinCode.length > 0 ? '#0E9F6E' : '#9CA3AF');
            }
            .width('100%');

            TextInput({ placeholder: '请输入车辆识别代码', text: this.vinCode })
              .width('100%')
              .height(54)
              .fontSize(16)
              .fontColor('#111827')
              .placeholderColor('#9CA3AF')
              .backgroundColor('#F9FAFB')
              .borderRadius(8)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.vinCode = value.trim().toUpperCase();
                this.showErrorToast = false;
              });

            Row() {
              Text(this.getVinHint())
                .fontSize(13)
                .fontColor(this.vinCode.length > 0 ? '#6B7280' : '#9CA3AF');

              Blank();

              Text('清空')
                .fontSize(13)
                .fontColor('#2563EB')
                .onClick(() => {
                  this.vinCode = '';
                  this.showErrorToast = false;
                });
            }
            .width('100%');
          }
          .width('88%')
          .padding(18)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 2 });

          Column({ space: 10 }) {
            Row() {
              Text('云端校验')
                .fontSize(14)
                .fontColor('#6B7280');

              Blank();

              Text('绑定成功后自动同步车辆状态')
                .fontSize(14)
                .fontColor('#111827');
            }
            .width('100%');

            Row() {
              Text('数据权限')
                .fontSize(14)
                .fontColor('#6B7280');

              Blank();

              Text('仅保存账号、车辆与 Token')
                .fontSize(14)
                .fontColor('#111827');
            }
            .width('100%');
          }
          .width('88%')
          .padding(18)
          .backgroundColor(Color.White)
          .borderRadius(8);

          if (this.showErrorToast) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#B91C1C')
              .width('88%')
              .padding(12)
              .backgroundColor('#FEF2F2')
              .borderRadius(8);
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 24 });
      }
      .layoutWeight(1);

      Button(this.isSubmitting ? '绑定中...' : '绑定车辆')
        .width('88%')
        .height(52)
        .backgroundColor('#111827')
        .fontColor(Color.White)
        .fontSize(17)
        .borderRadius(8)
        .margin({ bottom: 28 })
        .onClick(() => {
          this.handleBindCar();
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }

  private getVinHint(): string {
    if (this.vinCode.length === 0) {
      return '支持测试车架号，也支持标准 VIN';
    }

    if (this.vinCode.length === 17) {
      return '标准 VIN 长度已满足';
    }

    return '当前长度不会被本地拦截，以服务器校验结果为准';
  }

  private async handleBindCar(): Promise<void> {
    const carVin = this.vinCode.trim();
    if (!carVin) {
      this.showError('请输入车架号');
      return;
    }

    if (this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    try {
      const pref = await preferences.getPreferences(this.context, 'userStore');
      const token = pref.getSync('token', '') as string;
      if (!token) {
        this.showError('登录状态已失效，请重新登录');
        router.replaceUrl({ url: 'pages/Index' });
        return;
      }

      const result = await AuthApi.bindCarVin(token, carVin);
      if (result.code !== 200) {
        this.showError(result.msg ?? '绑定失败，请检查车架号是否正确');
        return;
      }

      const userInfo = await AuthApi.getUserInfo(token);
      const latestCarVin = userInfo.carVin ?? carVin;
      const latestCarId = userInfo.carId ?? '';

      await pref.put('isCarBound', latestCarVin.length > 0);
      await pref.put('carVin', latestCarVin);
      await pref.put('carId', latestCarId);
      await pref.put('userId', userInfo.user?.userId ?? '');
      await pref.put('nickName', userInfo.user?.nickName ?? '');
      await pref.put('phonenumber', userInfo.user?.phonenumber ?? '');
      await pref.put('birthDate', userInfo.user?.birthDate ?? '');
      await pref.flush();

      this.showToast(result.msg ?? '绑定成功');
      router.replaceUrl({
        url: 'pages/BindSuccess'
      });
    } catch (error) {
      this.showError(this.getErrorMessage(error));
    } finally {
      this.isSubmitting = false;
    }
  }

  private showError(message: string) {
    this.errorMessage = message;
    this.showErrorToast = true;
  }

  private showToast(message: string) {
    promptAction.openToast({
      message,
      duration: 2000
    }).catch(() => {
    });
  }

  private getErrorMessage(error: Object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return '操作失败，请稍后重试';
  }
}
