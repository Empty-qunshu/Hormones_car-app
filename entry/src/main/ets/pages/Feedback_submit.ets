import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { AppRoutes, PreferenceKeys, USER_STORE_NAME } from './AppConstants';
import { AppPrompt } from './AppPrompt';
import { AddFeedbackParams, AuthApi } from './AuthApi';
import { FeedbackTag } from './CommonWidgets';

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
              FeedbackTag({
                tag: '车辆控制',
                selected: this.selectedTag === '车辆控制',
                onSelect: (tag: string) => {
                  this.selectTag(tag);
                }
              });
              FeedbackTag({
                tag: '空调',
                selected: this.selectedTag === '空调',
                onSelect: (tag: string) => {
                  this.selectTag(tag);
                }
              });
              FeedbackTag({
                tag: '绑定车辆',
                selected: this.selectedTag === '绑定车辆',
                onSelect: (tag: string) => {
                  this.selectTag(tag);
                }
              });
            }
            .width('100%');

            Row({ space: 8 }) {
              FeedbackTag({
                tag: '页面体验',
                selected: this.selectedTag === '页面体验',
                onSelect: (tag: string) => {
                  this.selectTag(tag);
                }
              });
              FeedbackTag({
                tag: '数据异常',
                selected: this.selectedTag === '数据异常',
                onSelect: (tag: string) => {
                  this.selectTag(tag);
                }
              });
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
      const pref = await preferences.getPreferences(getContext(this), USER_STORE_NAME);
      const token = pref.getSync(PreferenceKeys.TOKEN, '') as string;
      const userId = pref.getSync(PreferenceKeys.USER_ID, '') as string;
      const userName = pref.getSync(PreferenceKeys.USERNAME, '') as string;
      const nickName = pref.getSync(PreferenceKeys.NICK_NAME, '') as string;
      const phonenumber = pref.getSync(PreferenceKeys.PHONE_NUMBER, '') as string;

      if (token.length === 0) {
        this.showToast('登录状态已失效，请重新登录');
        router.replaceUrl({ url: AppRoutes.INDEX });
        return;
      }

      if (userId.length === 0) {
        this.showToast('用户信息缺失，请重新登录');
        router.replaceUrl({ url: AppRoutes.INDEX });
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

  private selectTag(tag: string): void {
    this.selectedTag = tag;
    if (this.title.length === 0) {
      this.title = tag;
    }
  }

  private showToast(message: string): void {
    AppPrompt.showToast(message);
  }

  private getErrorMessage(error: Object): string {
    return AppPrompt.getErrorMessage(error);
  }
}
