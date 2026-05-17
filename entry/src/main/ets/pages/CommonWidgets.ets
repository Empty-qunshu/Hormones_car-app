@Component
export struct AppTopBar {
  title: string = '';
  showBack: boolean = false;
  onBack: () => void = () => {
  };

  build() {
    Row() {
      if (this.showBack) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.onBack();
          });
      } else {
        Blank()
          .width(24);
      }

      Text(this.title)
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
  }
}

@Component
export struct PlainInfoRow {
  label: string = '';
  value: string = '';
  valueColor: string = '#111827';

  build() {
    Row() {
      Text(this.label)
        .fontSize(14)
        .fontColor('#6B7280');

      Blank();

      Text(this.value)
        .fontSize(14)
        .fontColor(this.valueColor);
    }
    .width('100%');
  }
}

@Component
export struct InfoCardRow {
  label: string = '';
  value: string = '';
  valueColor: string = '#111827';

  build() {
    Row() {
      Text(this.label)
        .fontSize(14)
        .fontColor('#6B7280');

      Blank();

      Text(this.value)
        .fontSize(14)
        .fontColor(this.valueColor);
    }
    .width('88%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8);
  }
}

@Component
export struct DetailCard {
  title: string = '';
  content: string = '';

  build() {
    Column({ space: 10 }) {
      Text(this.title)
        .fontSize(14)
        .fontColor('#6B7280')
        .width('100%');

      Text(this.content)
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
}

@Component
export struct FeedbackTag {
  tag: string = '';
  selected: boolean = false;
  onSelect: (tag: string) => void = (tag: string) => {
  };

  build() {
    Text(this.tag)
      .fontSize(13)
      .fontColor(this.selected ? '#062027' : '#6B7280')
      .textAlign(TextAlign.Center)
      .height(36)
      .layoutWeight(1)
      .backgroundColor(this.selected ? '#DDF7F4' : '#F9FAFB')
      .borderRadius(8)
      .onClick(() => {
        this.onSelect(this.tag);
      });
  }
}
