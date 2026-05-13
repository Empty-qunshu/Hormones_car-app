import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { promptAction } from '@kit.ArkUI';
import { AddFeedbackParams, AuthApi } from './AuthApi';

@Component
export struct Feedback_submit {
  navPathStack: NavPathStack = new NavPathStack();
  @State title: string = '';
  @State content: string = '';
  @State contact: string = '';
  @State selectedTag: string = '';
  @State isSubmitting: boolean = false;

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Column({ space: 4 }) {
              Text('提交反馈')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827');

              Text('把问题说清楚，处理会更快')
                .fontSize(13)
                .fontColor('#6B7280');
            }
            .layoutWeight(1);
          }
          .width('88%')
          .margin({ top: 20 });

          Column({ space: 12 }) {
            Text('问题类型')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')
              .width('100%');

            Row({ space: 8 }) {
              this.tagItem('车辆控制');
              this.tagItem('空调');
              this.tagItem('绑定车辆');
            }
            .width('100%');

            Row({ space: 8 }) {
              this.tagItem('页面体验');
              this.tagItem('数据异常');
            }
            .width('100%');
          }
          .width('88%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8);

          Column({ space: 12 }) {
            TextInput({ placeholder: '请输入反馈标题', text: this.title })
              .width('100%')
              .height(52)
              .backgroundColor('#F9FAFB')
              .borderRadius(8)
              .fontColor('#111827')
              .placeholderColor('#9CA3AF')
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.title = value;
              });

            TextArea({ placeholder: '请详细描述你的问题或建议...', text: this.content })
              .width('100%')
              .height(190)
              .backgroundColor('#F9FAFB')
              .borderRadius(8)
              .fontColor('#111827')
              .placeholderColor('#9CA3AF')
              .padding({ top: 16, left: 16, right: 16 })
              .onChange((value: string) => {
                this.content = value;
              });

            Row() {
              Text(`${this.content.length} 字`)
                .fontSize(12)
                .fontColor('#9CA3AF');

              Blank();

              Text(this.selectedTag.length > 0 ? `已选：${this.selectedTag}` : '未选择类型')
                .fontSize(12)
                .fontColor(this.selectedTag.length > 0 ? '#2563EB' : '#9CA3AF');
            }
            .width('100%');

            TextInput({ placeholder: '联系方式（选填）', text: this.contact })
              .width('100%')
              .height(52)
              .backgroundColor('#F9FAFB')
              .borderRadius(8)
              .fontColor('#111827')
              .placeholderColor('#9CA3AF')
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.contact = value;
              });
          }
          .width('88%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 2 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 24 });
      }
      .layoutWeight(1);

      Button(this.isSubmitting ? '提交中...' : '提交反馈')
        .width('88%')
        .height(52)
        .backgroundColor('#111827')
        .fontColor(Color.White)
        .fontSize(17)
        .borderRadius(8)
        .margin({ bottom: 28 })
        .onClick(() => {
          this.submitFeedback();
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }

  @Builder
  tagItem(tag: string) {
    Text(tag)
      .fontSize(13)
      .fontColor(this.selectedTag === tag ? '#062027' : '#6B7280')
      .textAlign(TextAlign.Center)
      .height(36)
      .layoutWeight(1)
      .backgroundColor(this.selectedTag === tag ? '#DDF7F4' : '#F9FAFB')
      .borderRadius(8)
      .onClick(() => {
        this.selectedTag = tag;
        if (this.title.length === 0) {
          this.title = tag;
        }
      });
  }

  private async submitFeedback(): Promise<void> {
    const title = this.title.trim();
    const content = this.content.trim();
    const contact = this.contact.trim();

    if (content.length === 0) {
      this.showToast('请填写反馈内容');
      return;
    }

    if (this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    try {
      const pref = await preferences.getPreferences(getContext(this), 'userStore');
      const token = pref.getSync('token', '') as string;
      const userId = pref.getSync('userId', '') as string;
      const userName = pref.getSync('username', '') as string;
      const nickName = pref.getSync('nickName', '') as string;
      const phonenumber = pref.getSync('phonenumber', '') as string;

      if (token.length === 0) {
        this.showToast('登录状态已失效，请重新登录');
        router.replaceUrl({ url: 'pages/Index' });
        return;
      }

      if (userId.length === 0) {
        this.showToast('用户信息缺失，请重新登录');
        router.replaceUrl({ url: 'pages/Index' });
        return;
      }

      const tagLine = this.selectedTag.length > 0 ? `【${this.selectedTag}】` : '';
      const finalContent = title.length > 0 ? `${tagLine}${title}\n${content}` : `${tagLine}${content}`;
      const params: AddFeedbackParams = {
        userId,
        userName,
        nickName: nickName.length > 0 ? nickName : userName,
        phonenumber: contact.length > 0 ? contact : phonenumber,
        content: finalContent,
        status: '0',
        picUrl: '',
        delFlag: '1',
        searchValue: '',
        createBy: '',
        createTime: '',
        updateBy: '',
        updateTime: '',
        remark: ''
      };

      const result = await AuthApi.addFeedback(token, params);
      if (result.code !== 200) {
        this.showToast(result.msg ?? '提交反馈失败');
        return;
      }

      this.title = '';
      this.content = '';
      this.contact = '';
      this.selectedTag = '';
      this.navPathStack.pop();
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isSubmitting = false;
    }
  }

  private showToast(message: string): void {
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
