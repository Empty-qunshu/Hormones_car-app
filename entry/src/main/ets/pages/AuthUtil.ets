import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export class AuthUtil {

  // 检查登录 + 绑定状态
  static async checkAuth(context: common.UIAbilityContext) {
    const pref = await preferences.getPreferences(context, 'userStore');

    const isLogin = pref.getSync('isLogin', false);
    const isCarBound = pref.getSync('isCarBound', false);

    if (!isLogin) {
      router.replaceUrl({ url: 'pages/Index' });
      return;
    }

    if (!isCarBound) {
      router.replaceUrl({ url: 'pages/BindCar' });
      return;
    }

    router.replaceUrl({ url: 'pages/Home' });
  }

  // 退出登录统一方法
  static async logout(context: common.UIAbilityContext) {
    const pref = await preferences.getPreferences(context, 'userStore');
    pref.putSync('isLogin', false);
    pref.putSync('isCarBound', false);
    pref.putSync('token', '');
    pref.putSync('username', '');
    pref.flushSync();

    router.replaceUrl({ url: 'pages/Index' });
  }
}
