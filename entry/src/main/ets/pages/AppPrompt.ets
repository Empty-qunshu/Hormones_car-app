import { promptAction } from '@kit.ArkUI';

export class AppPrompt {
  static showToast(message: string, duration: number = 2000): void {
    promptAction.openToast({
      message,
      duration
    }).catch(() => {
    });
  }

  static getErrorMessage(error: Object, fallbackMessage: string = '操作失败，请稍后重试'): string {
    if (error instanceof Error) {
      return error.message;
    }

    return fallbackMessage;
  }
}
