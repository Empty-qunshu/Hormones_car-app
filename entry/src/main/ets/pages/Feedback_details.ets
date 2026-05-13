import preferences from '@ohos.data.preferences';
import { promptAction } from '@kit.ArkUI';
import { AuthApi, FeedbackItem } from './AuthApi';

@Component
export struct Feedback_details {
  @Prop feedbackId: string = '';
  navPathStack: NavPathStack = new NavPathStack();
  onDeleted: (id: string) => void = (id: string) => {};
  @State feedback: FeedbackItem = {};
  @State isLoading: boolean = false;
  @State isDeleting: boolean = false;

  aboutToAppear() {
    this.loadFeedbackDetail();
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Column({ space: 4 }) {
              Text('反馈详情')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111827');

              Text(this.getFeedbackTime())
                .fontSize(13)
                .fontColor('#6B7280');
            }
            .layoutWeight(1);

            Text(this.feedback.status === '1' ? '已读' : '未读')
              .fontSize(12)
              .fontColor(this.feedback.status === '1' ? '#065F46' : '#92400E')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(this.feedback.status === '1' ? '#D1FAE5' : '#FEF3C7')
              .borderRadius(8);
          }
          .width('88%')
          .margin({ top: 20 });

          Row() {
            Image($r('app.media.ic_default_avatar'))
              .width(52)
              .height(52)
              .borderRadius(26)
              .objectFit(ImageFit.Cover);

            Column({ space: 4 }) {
              Text(this.feedback.nickName ?? this.feedback.userName ?? '匿名用户')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827');

              Text(this.feedback.phonenumber ?? '未留下联系方式')
                .fontSize(13)
                .fontColor('#6B7280');
            }
            .layoutWeight(1)
            .margin({ left: 12 });

            Text('车主')
              .fontSize(12)
              .fontColor('#2563EB')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#EFF6FF')
              .borderRadius(8);
          }
          .width('88%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 2 });

          this.detailCard('反馈内容', this.feedback.content ?? (this.isLoading ? '加载中...' : '暂无反馈内容'));

          this.detailCard('处理状态', this.getStatusText());

          if (this.hasReply()) {
            this.detailCard('回复内容', this.feedback.reply ?? '');
          } else {
            this.detailCard('处理建议', '反馈已进入列表，你可以稍后刷新查看处理结果。');
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 24 });
      }
      .layoutWeight(1);

      Row({ space: 10 }) {
        Button(this.isDeleting ? '删除中...' : '删除反馈')
          .layoutWeight(1)
          .height(50)
          .backgroundColor('#FEF2F2')
          .fontColor('#DC2626')
          .fontSize(16)
          .borderRadius(8)
          .onClick(() => {
            this.deleteFeedback();
          });

        Button(this.isLoading ? '刷新中...' : '刷新详情')
          .layoutWeight(1)
          .height(50)
          .backgroundColor('#111827')
          .fontColor(Color.White)
          .fontSize(16)
          .borderRadius(8)
          .onClick(() => {
            this.loadFeedbackDetail();
          });
      }
      .width('88%')
      .margin({ bottom: 28 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }

  @Builder
  detailCard(title: string, content: string) {
    Column({ space: 10 }) {
      Text(title)
        .fontSize(14)
        .fontColor('#6B7280')
        .width('100%');

      Text(content)
        .fontSize(16)
        .fontColor('#111827')
        .lineHeight(24)
        .width('100%');
    }
    .width('88%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 2 });
  }

  private async loadFeedbackDetail(): Promise<void> {
    if (this.feedbackId.length === 0 || this.isLoading) {
      return;
    }

    this.isLoading = true;
    try {
      const pref = await preferences.getPreferences(getContext(this), 'userStore');
      const token = pref.getSync('token', '') as string;
      if (token.length === 0) {
        this.showToast('登录状态已失效，请重新登录');
        return;
      }

      const result = await AuthApi.getFeedbackDetail(token, this.feedbackId);
      if (result.code !== 200 || !result.data) {
        this.showToast(result.msg ?? '获取反馈详情失败');
        return;
      }

      const detail: FeedbackItem = result.data;
      detail.status = '1';
      detail.replyRead = '1';
      this.feedback = detail;
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isLoading = false;
    }
  }

  private async deleteFeedback(): Promise<void> {
    if (this.feedbackId.length === 0) {
      this.showToast('反馈编号为空，无法删除');
      return;
    }

    if (this.isDeleting) {
      return;
    }

    this.isDeleting = true;
    try {
      const pref = await preferences.getPreferences(getContext(this), 'userStore');
      const token = pref.getSync('token', '') as string;
      if (token.length === 0) {
        this.showToast('登录状态已失效，请重新登录');
        return;
      }

      const result = await AuthApi.deleteFeedback(token, this.feedbackId);
      if (result.code !== 200) {
        this.showToast(result.msg ?? '删除反馈失败');
        return;
      }

      this.onDeleted(this.feedbackId);
      this.showToast(result.msg ?? '反馈已删除');
      this.navPathStack.pop();
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isDeleting = false;
    }
  }

  private getFeedbackTime(): string {
    return this.feedback.updateTime ?? this.feedback.createTime ?? '--';
  }

  private getStatusText(): string {
    if (this.feedback.status === '1') {
      return '后台已读取这条反馈，等待进一步处理或回复。';
    }
    return '反馈已提交，当前仍处于未读状态。';
  }

  private hasReply(): boolean {
    return (this.feedback.reply ?? '').length > 0;
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
