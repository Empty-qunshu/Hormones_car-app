import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { AppRoutes, PreferenceKeys, USER_STORE_NAME } from './AppConstants';

export class AuthUtil {

  // 检查登录 + 绑定状态
  static async checkAuth(context: common.UIAbilityContext) {
    const pref = await preferences.getPreferences(context, USER_STORE_NAME);

    const isLogin = pref.getSync(PreferenceKeys.IS_LOGIN, false);
    const isCarBound = pref.getSync(PreferenceKeys.IS_CAR_BOUND, false);

    if (!isLogin) {
      router.replaceUrl({ url: AppRoutes.INDEX });
      return;
    }

    if (!isCarBound) {
      router.replaceUrl({ url: AppRoutes.BIND_CAR });
      return;
    }

    router.replaceUrl({ url: AppRoutes.HOME });
  }

  // 退出登录统一方法
  static async logout(context: common.UIAbilityContext) {
    const pref = await preferences.getPreferences(context, USER_STORE_NAME);
    pref.putSync(PreferenceKeys.IS_LOGIN, false);
    pref.putSync(PreferenceKeys.IS_CAR_BOUND, false);
    pref.putSync(PreferenceKeys.TOKEN, '');
    pref.putSync(PreferenceKeys.USERNAME, '');
    pref.flushSync();

    router.replaceUrl({ url: AppRoutes.INDEX });
  }
}
