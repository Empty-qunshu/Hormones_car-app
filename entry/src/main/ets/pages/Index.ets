import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { promptAction } from '@kit.ArkUI';
import { AuthApi, RegisterParams } from './AuthApi';

@Entry
@Component
struct Index {
  @State isLogin: boolean = true;
  @State phone: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isSubmitting: boolean = false;
  private pref: preferences.Preferences | null = null;

  aboutToAppear() {
    preferences.getPreferences(getContext(this), 'userStore')
      .then((data) => {
        this.pref = data;
        this.checkLoginStatus();
      });
  }

  checkLoginStatus() {
    const loginState = this.pref?.getSync('isLogin', false);
    const carBoundState = this.pref?.getSync('isCarBound', false);

    if (loginState && carBoundState) {
      router.replaceUrl({
        url: 'pages/Home'
      });
    } else if (loginState && !carBoundState) {
      router.replaceUrl({
        url: 'pages/BindCar'
      });
    }
  }

  logout() {
    if (this.pref) {
      this.pref.putSync('isLogin', false);
      this.pref.putSync('isCarBound', false);
      this.pref.putSync('token', '');
      this.pref.putSync('username', '');
      this.pref.flushSync();
      this.phone = '';
      this.password = '';
      this.confirmPassword = '';
      this.isLogin = true;
    }
  }

  clearAllUserInfo() {
    if (this.pref) {
      this.pref.clearSync();
      this.pref.flushSync();
      this.phone = '';
      this.password = '';
      this.confirmPassword = '';
      this.isLogin = true;
      this.showToast('已清除本地账号信息');
    }
  }

  async login() {
    if (!this.phone || !this.password) {
      this.showToast('请填写用户名及密码');
      return;
    }

    if (this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    try {
      const result = await AuthApi.login(this.phone, this.password);
      if (result.code !== 200 || !result.token) {
        this.showToast(result.msg ?? '登录失败，请检查账号或密码');
        return;
      }

      const userInfo = await AuthApi.getUserInfo(result.token);
      if (userInfo.code !== 200) {
        this.showToast(userInfo.msg ?? '获取用户信息失败');
        return;
      }

      const carVin = userInfo.carVin ?? '';
      const carId = userInfo.carId ?? '';

      this.pref?.putSync('isLogin', true);
      this.pref?.putSync('token', result.token);
      this.pref?.putSync('username', this.phone);
      this.pref?.putSync('isCarBound', carVin.length > 0);
      this.pref?.putSync('carVin', carVin);
      this.pref?.putSync('carId', carId);
      this.pref?.putSync('userId', userInfo.user?.userId ?? '');
      this.pref?.putSync('nickName', userInfo.user?.nickName ?? '');
      this.pref?.putSync('phonenumber', userInfo.user?.phonenumber ?? '');
      this.pref?.putSync('birthDate', userInfo.user?.birthDate ?? '');
      this.pref?.flushSync();

      this.showToast(result.msg ?? '登录成功');
      router.replaceUrl({
        url: carVin.length > 0 ? 'pages/Home' : 'pages/BindCar'
      });
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isSubmitting = false;
    }
  }

  async register() {
    if (!this.phone || !this.password || !this.confirmPassword) {
      this.showToast('请填写账号、密码和确认密码');
      return;
    }

    if (this.password !== this.confirmPassword) {
      this.showToast('两次输入的密码不一致');
      return;
    }

    if (this.isSubmitting) {
      return;
    }

    const params: RegisterParams = {
      nickName: this.phone,
      userName: this.phone,
      phonenumber: this.phone,
      sex: '1',
      avatar: '',
      password: this.password,
      roleIds: ['9'],
      birthDate: '',
      state: '1'
    };

    this.isSubmitting = true;
    try {
      const result = await AuthApi.register(params);
      if (result.code !== 200) {
        this.showToast(result.msg ?? '注册失败');
        return;
      }

      this.showToast(result.msg ?? '注册成功');
      this.isLogin = true;
      this.password = '';
      this.confirmPassword = '';
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Stack() {
      Image($r('app.media.bg_start'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover);

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(6,16,27,0.72)');

      Column() {
        Row() {
          Image($r('app.media.startIcon'))
            .width(42)
            .height(42)
            .borderRadius(8);

          Column({ space: 4 }) {
            Text('鸿蒙智能座舱')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White);

            Text('车主端云控中心')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.68)');
          }
          .margin({ left: 12 });

          Blank();
        }
        .width('88%')
        .margin({ top: 72 });

        Blank();

        Column({ space: 18 }) {
          Row() {
            Text('登录')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isLogin ? Color.White : 'rgba(255,255,255,0.58)')
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(42)
              .backgroundColor(this.isLogin ? '#111827' : 'rgba(255,255,255,0.08)')
              .borderRadius(8)
              .onClick(() => {
                this.isLogin = true;
              });

            Text('注册')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(!this.isLogin ? Color.White : 'rgba(255,255,255,0.58)')
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(42)
              .backgroundColor(!this.isLogin ? '#111827' : 'rgba(255,255,255,0.08)')
              .borderRadius(8)
              .margin({ left: 8 })
              .onClick(() => {
                this.isLogin = false;
              });
          }
          .width('100%');

          Text(this.isLogin ? '欢迎回来' : '创建车主账户')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .width('100%');

          TextInput({ placeholder: '请输入账号 / 手机号', text: this.phone })
            .onChange((value: string) => {
              this.phone = value;
            })
            .width('100%')
            .height(54)
            .borderRadius(8)
            .backgroundColor('rgba(255,255,255,0.12)')
            .fontColor(Color.White)
            .placeholderColor('rgba(255,255,255,0.54)')
            .padding({ left: 16, right: 16 });

          TextInput({
            placeholder: this.isLogin ? '请输入登录密码' : '设置 6-20 位新密码',
            text: this.password
          })
            .onChange((value: string) => {
              this.password = value;
            })
            .width('100%')
            .height(54)
            .borderRadius(8)
            .backgroundColor('rgba(255,255,255,0.12)')
            .fontColor(Color.White)
            .placeholderColor('rgba(255,255,255,0.54)')
            .padding({ left: 16, right: 16 });

          if (!this.isLogin) {
            TextInput({ placeholder: '请再次确认密码', text: this.confirmPassword })
              .onChange((value: string) => {
                this.confirmPassword = value;
              })
              .width('100%')
              .height(54)
              .borderRadius(8)
              .backgroundColor('rgba(255,255,255,0.12)')
              .fontColor(Color.White)
              .placeholderColor('rgba(255,255,255,0.54)')
              .padding({ left: 16, right: 16 });
          }

          Button(this.isSubmitting ? '处理中...' : (this.isLogin ? '立即登录' : '完成注册'))
            .onClick(() => {
              if (this.isLogin) {
                this.login();
              } else {
                this.register();
              }
            })
            .width('100%')
            .height(52)
            .borderRadius(8)
            .backgroundColor('#40E0D0')
            .fontColor('#062027')
            .fontSize(17)
            .fontWeight(FontWeight.Bold);

          Row() {
            Text('退出登录')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.58)')
              .onClick(() => {
                this.logout();
              });

            Blank();

            Text('清除本地账号')
              .fontSize(13)
              .fontColor('#F8C35C')
              .onClick(() => {
                this.clearAllUserInfo();
              });
          }
          .width('100%');
        }
        .width('88%')
        .padding(22)
        .backgroundColor('rgba(255,255,255,0.10)')
        .borderRadius(8)
        .border({ width: 1, color: 'rgba(255,255,255,0.12)' });

        Text('© 2026 Harmony Cockpit')
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.4)')
          .margin({ top: 18, bottom: 28 });
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .height('100%');
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
