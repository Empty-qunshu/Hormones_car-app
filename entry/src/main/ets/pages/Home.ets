import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { AppRoutes, PreferenceKeys, USER_STORE_NAME } from './AppConstants';
import { AppPrompt } from './AppPrompt';
import { Feedback_submit } from './Feedback_submit';
import { Feedback_details } from './Feedback_details';
import {
  AuthApi,
  BaseResult,
  ControlLogItem,
  FeedbackItem,
  UpdateVehicleStateParams,
  VehicleDetail,
  VehicleState
} from './AuthApi';

interface SceneSnapshot {
  carLocked: boolean;
  lightOn: boolean;
  temperature: number;
  windLevel: string;
  acOn: boolean;
  airCirculationOn: boolean;
  defrostOn: boolean;
  nightMode: boolean;
}

const DIRECTION_REPEAT_INTERVAL_MS: number = 300;

@Entry
@Component
struct Home {
  @State currentIndex: number = 0;
  @State token: string = '';
  @State userId: string = '';
  @State userName: string = '';
  @State nickName: string = '';
  @State phonenumber: string = '';
  @State birthDate: string = '';
  @State carId: string = '';
  @State carVin: string = '';
  @State carName: string = '我的车辆';
  @State enduranceMileage: string = '--';
  @State batteryPower: number = 0;
  @State updateTime: string = '--';
  @State stateSyncedAt: string = '--';
  @State isVehicleStateLoading: boolean = false;
  @State isAirUpdating: boolean = false;
  @State carLocked: boolean = true;
  @State lightOn: boolean = false;
  @State directionState: string = 'stop';
  @State temperature: number = 24;
  @State windLevel: string = '1';
  @State acOn: boolean = true;
  @State airCirculationOn: boolean = false;
  @State defrostOn: boolean = false;
  @State nightMode: boolean = false;
  @State fanState: string = '';
  @State playMode: string = '';
  @State processMp3: string = '0';
  @State mp3Playing: string = '0';
  @State processMp4: string = '0';
  @State mp4Playing: string = '0';
  @State feedbackList: FeedbackItem[] = [];
  @State controlLogs: ControlLogItem[] = [];
  @State selectedFeedbackId: string = '';
  @State showProfileEditor: boolean = false;
  @State profileNickName: string = '';
  @State profilePhone: string = '';
  @State profileBirthDate: string = '';
  @State showDeleteDialog: boolean = false;
  @State deleteTargetType: string = '';
  @State deleteTargetId: string = '';
  @State deleteTargetTitle: string = '';
  @State isDeleting: boolean = false;
  @State activeSceneKey: string = '';
  @State activeSceneTitle: string = '';
  @State sceneProgress: number = 0;
  @State sceneRunning: boolean = false;
  @State sceneStatus: string = '等待执行';
  @State sceneEffect: string = '点击场景卡片，一键联动车门、车灯与空调';
  private localLogSeed: number = 0;
  private stateRefreshTimerId: number = -1;
  private directionHoldTimerId: number = -1;
  private activeDirection: string = '';
  private directionCommandInFlight: Promise<void> | null = null;
  navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    preferences.getPreferences(getContext(this), USER_STORE_NAME)
      .then((pref) => {
        const isLogin = pref.getSync(PreferenceKeys.IS_LOGIN, false) as boolean;
        const isCarBound = pref.getSync(PreferenceKeys.IS_CAR_BOUND, false) as boolean;

        if (!isLogin) {
          router.replaceUrl({ url: AppRoutes.INDEX });
          return;
        }

        if (!isCarBound) {
          router.replaceUrl({ url: AppRoutes.BIND_CAR });
          return;
        }

        this.token = pref.getSync(PreferenceKeys.TOKEN, '') as string;
        this.userId = pref.getSync(PreferenceKeys.USER_ID, '') as string;
        this.userName = pref.getSync(PreferenceKeys.USERNAME, '') as string;
        this.nickName = pref.getSync(PreferenceKeys.NICK_NAME, '') as string;
        this.phonenumber = pref.getSync(PreferenceKeys.PHONE_NUMBER, '') as string;
        this.birthDate = pref.getSync(PreferenceKeys.BIRTH_DATE, '') as string;
        this.carId = pref.getSync(PreferenceKeys.CAR_ID, '') as string;
        this.carVin = pref.getSync(PreferenceKeys.CAR_VIN, '') as string;

        this.refreshAll();
        this.startVehicleStatePolling();
      });
  }

  aboutToDisappear() {
    this.stopVehicleStatePolling();
    this.stopDirectionHold();
  }

  build() {
    Stack() {
      Navigation(this.navPathStack) {
        Tabs({
          index: this.currentIndex,
          barPosition: BarPosition.End
        }) {
          TabContent() {
            this.homePage();
          }
          .tabBar(this.tabBarItem('首页', 0, $r('app.media.ic_home'), $r('app.media.ic_home_active')))

          TabContent() {
            this.carPage();
          }
          .tabBar(this.tabBarItem('控车', 1, $r('app.media.ic_car'), $r('app.media.ic_car_active')))

          TabContent() {
            this.feedPage();
          }
          .tabBar(this.tabBarItem('反馈', 2, $r('app.media.ic_feedback'), $r('app.media.ic_feedback_active')))

          TabContent() {
            this.minePage();
          }
          .tabBar(this.tabBarItem('我的', 3, $r('app.media.ic_mine'), $r('app.media.ic_mine_active')))
        }
        .onChange((index: number) => {
          this.currentIndex = index;
          if (index === 0) {
            this.refreshHomeState();
          }
          if (index === 1) {
            this.loadVehicleState();
            this.loadControlLogs();
          }
          if (index === 2) {
            this.loadFeedbackList();
          }
        })
      }
      .navDestination(this.pageMap)

      if (this.showDeleteDialog) {
        this.deleteConfirmDialog();
      }
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  tabBarItem(title: string, index: number, normalIcon: Resource, activeIcon: Resource) {
    Column({ space: 4 }) {
      Image(this.currentIndex === index ? activeIcon : normalIcon)
        .width(23)
        .height(23);

      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#111827' : '#9CA3AF');
    }
  }

  @Builder
  homePage() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          this.appHeader('早上好，' + this.getDisplayName(), this.getHomeStatusSubtitle(), true);

          Column({ space: 14 }) {
            Row() {
              Column({ space: 6 }) {
                Text(this.carName)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#111827');

                Text(`VIN ${this.carVin.length > 0 ? this.carVin : '--'}`)
                  .fontSize(12)
                  .fontColor('#6B7280')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis });
              }
              .layoutWeight(1);

              Text(this.getSafetyLabel())
                .fontSize(12)
                .fontColor(this.carLocked ? '#0E9F6E' : '#B45309')
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor(this.carLocked ? '#ECFDF5' : '#FFFBEB')
                .borderRadius(8);
            }
            .width('100%');

            Image(this.getCarImage())
              .width('100%')
              .height(190)
              .objectFit(ImageFit.Contain);

            Row({ space: 10 }) {
              this.metricTile(this.enduranceMileage, '续航 km', '#111827');
              this.metricTile(`${this.batteryPower}%`, '电量', this.getEnergyColor());
              this.metricTile(`${this.temperature}℃`, '座舱温度', '#2563EB');
            }

            Progress({ value: this.batteryPower, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(8)
              .color(this.getEnergyColor())
              .backgroundColor('#E5E7EB');

            Text(`更新于 ${this.updateTime}`)
              .fontSize(12)
              .fontColor('#9CA3AF')
              .width('100%')
              .textAlign(TextAlign.End);
          }
          .width('88%')
          .padding(18)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 2 });

          Row({ space: 10 }) {
            this.statusPill('车门', this.carLocked ? '已锁定' : '已解锁', this.carLocked);
            this.statusPill('车灯', this.lightOn ? '开启' : '关闭', this.lightOn);
            this.statusPill('空调', this.acOn ? '运行中' : '已关闭', this.acOn);
          }
          .width('88%');

          this.sceneModePanel();
          this.airPanel();
          this.dataCenterPanel();
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 24 });
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.nightMode ? '#0B1120' : '#F5F7FA');
  }

  @Builder
  sceneModePanel() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text('一键场景模式')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.nightMode ? Color.White : '#111827');

          Text('一次点击，联动车门、车灯、空调与座舱氛围')
            .fontSize(13)
            .fontColor(this.nightMode ? 'rgba(255,255,255,0.68)' : '#6B7280');
        }
        .layoutWeight(1);

        Text(this.sceneRunning ? '执行中' : '智能联动')
          .fontSize(12)
          .fontColor(this.sceneRunning ? '#92400E' : '#2563EB')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.sceneRunning ? '#FEF3C7' : '#EFF6FF')
          .borderRadius(8);
      }
      .width('100%');

      Row({ space: 10 }) {
        this.sceneModeCard('offWork', '下班模式', '空调22℃ · 解锁 · 开灯', '准备完成动画', '#2563EB');
        this.sceneModeCard('camping', '露营模式', '循环空调 · 关闭车灯 · 低能耗', '露营氛围卡片', '#0E9F6E');
      }
      .width('100%');

      Row({ space: 10 }) {
        this.sceneModeCard('rainy', '雨天模式', '除雾 · 开灯 · 稳定视野', '天气联动动画', '#0891B2');
        this.sceneModeCard('night', '夜间模式', '深色主题 · 降低亮度 · 氛围灯', '夜间动态界面', '#7C3AED');
      }
      .width('100%');

      this.sceneExecutionCard();
    }
    .width('88%')
    .padding(18)
    .backgroundColor(this.nightMode ? '#111827' : Color.White)
    .borderRadius(8)
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 2 });
  }

  @Builder
  sceneModeCard(key: string, title: string, summary: string, effect: string, accent: string) {
    Column({ space: 8 }) {
      Row() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.activeSceneKey === key ? Color.White : (this.nightMode ? Color.White : '#111827'))
          .layoutWeight(1);

        Text(this.activeSceneKey === key ? 'ON' : '+')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.activeSceneKey === key ? Color.White : accent)
          .textAlign(TextAlign.Center)
          .width(30)
          .height(24)
          .backgroundColor(this.activeSceneKey === key ? 'rgba(255,255,255,0.18)' : '#F3F4F6')
          .borderRadius(8);
      }
      .width('100%');

      Text(summary)
        .fontSize(12)
        .fontColor(this.activeSceneKey === key ? 'rgba(255,255,255,0.82)' : (this.nightMode ? 'rgba(255,255,255,0.62)' : '#6B7280'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .height(34);

      Text(effect)
        .fontSize(11)
        .fontColor(this.activeSceneKey === key ? Color.White : accent)
        .padding({ left: 8, right: 8, top: 5, bottom: 5 })
        .backgroundColor(this.activeSceneKey === key ? 'rgba(255,255,255,0.18)' : '#F9FAFB')
        .borderRadius(8);
    }
    .layoutWeight(1)
    .height(126)
    .padding(12)
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor(this.activeSceneKey === key ? accent : (this.nightMode ? '#1F2937' : '#F9FAFB'))
    .borderRadius(8)
    .onClick(() => {
      this.runSceneMode(key);
    });
  }

  @Builder
  sceneExecutionCard() {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 3 }) {
          Text(this.activeSceneTitle.length > 0 ? this.activeSceneTitle : '场景待命')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.nightMode ? Color.White : '#111827');

          Text(this.sceneStatus)
            .fontSize(12)
            .fontColor(this.nightMode ? 'rgba(255,255,255,0.66)' : '#6B7280');
        }
        .layoutWeight(1);

        Text(`${this.sceneProgress}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sceneRunning ? '#2563EB' : '#0E9F6E');
      }
      .width('100%');

      Progress({ value: this.sceneProgress, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(8)
        .color(this.sceneRunning ? '#2563EB' : '#0E9F6E')
        .backgroundColor(this.nightMode ? '#374151' : '#E5E7EB');

      Text(this.sceneEffect)
        .fontSize(13)
        .fontColor(this.nightMode ? 'rgba(255,255,255,0.70)' : '#374151')
        .width('100%')
        .lineHeight(20);
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.nightMode ? '#0F172A' : '#F8FAFC')
    .borderRadius(8);
  }

  @Builder
  airPanel() {
    Column({ space: 16 }) {
      Row() {
        Column({ space: 4 }) {
          Text('智能空调')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827');

          Text(this.getAcSummary())
            .fontSize(13)
            .fontColor('#6B7280');
        }
        .layoutWeight(1);

        Text(this.acOn ? 'ON' : 'OFF')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.acOn ? '#065F46' : '#6B7280')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.acOn ? '#D1FAE5' : '#F3F4F6')
          .borderRadius(8);
      }
      .width('100%');

      Row() {
        Button('-')
          .width(50)
          .height(50)
          .borderRadius(8)
          .backgroundColor('#F3F4F6')
          .fontColor('#111827')
          .onClick(() => {
            this.setTemperature(this.temperature - 1);
          });

        Blank();

        Column({ space: 2 }) {
          Text(`${this.temperature}℃`)
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827');

          Text('设定温度')
            .fontSize(12)
            .fontColor('#9CA3AF');
        }
        .alignItems(HorizontalAlign.Center);

        Blank();

        Button('+')
          .width(50)
          .height(50)
          .borderRadius(8)
          .backgroundColor('#111827')
          .fontColor(Color.White)
          .onClick(() => {
            this.setTemperature(this.temperature + 1);
          });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Row({ space: 10 }) {
        this.airToggle('循环', 'cycle', $r('app.media.ic_air_cycle'), () => {
          this.toggleAirCirculation();
        });
        this.airToggle('A/C', 'ac', $r('app.media.ic_ac'), () => {
          this.toggleAcPower();
        });
        this.airToggle('除雾', 'defrost', $r('app.media.ic_defrost'), () => {
          this.toggleDefrost();
        });
      }
      .width('100%');
    }
    .width('88%')
    .padding(18)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 2 });
  }

  @Builder
  airToggle(title: string, mode: string, icon: Resource, action: () => void) {
    Column({ space: 8 }) {
      Image(icon)
        .width(24)
        .height(24);

      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isAirToggleActive(mode) ? '#062027' : '#6B7280');
    }
    .layoutWeight(1)
    .height(74)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.isAirToggleActive(mode) ? '#DDF7F4' : '#F9FAFB')
    .borderRadius(8)
    .onClick(action);
  }

  @Builder
  dataCenterPanel() {
    Column({ space: 16 }) {
      Row() {
        Column({ space: 4 }) {
          Text('车辆数据可视化中心')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.nightMode ? Color.White : '#111827');

          Text('周统计 · 能耗趋势 · 行为时间轴')
            .fontSize(13)
            .fontColor(this.nightMode ? 'rgba(255,255,255,0.68)' : '#6B7280');
        }
        .layoutWeight(1);

        Text('刷新')
          .fontSize(13)
          .fontColor('#2563EB')
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .backgroundColor(this.nightMode ? '#1E3A8A' : '#EFF6FF')
          .borderRadius(8)
          .onClick(() => {
            this.refreshHomeState();
            this.loadControlLogs();
          });
      }
      .width('100%');

      Row({ space: 10 }) {
        this.dataMetricTile('本周使用', `${this.getWeeklyUsageCount()}`, '次', '#2563EB');
        this.dataMetricTile('空调开启', `${this.getAirConditionCount()}`, '次', '#0E9F6E');
      }
      .width('100%');

      Row({ space: 10 }) {
        this.dataMetricTile('夜间占比', `${this.getNightUsagePercent()}`, '%', '#7C3AED');
        this.dataMetricTile('平均时长', `${this.getAverageUseMinutes()}`, '分钟', '#B45309');
      }
      .width('100%');

      this.energyTrendCard();
      this.behaviorTimelineCard();
    }
    .width('88%')
    .padding(18)
    .backgroundColor(this.nightMode ? '#111827' : Color.White)
    .borderRadius(8)
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 2 });
  }

  @Builder
  dataMetricTile(label: string, value: string, unit: string, color: string) {
    Column({ space: 4 }) {
      Row({ space: 3 }) {
        Text(value)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(color);

        Text(unit)
          .fontSize(12)
          .fontColor(this.nightMode ? 'rgba(255,255,255,0.62)' : '#6B7280')
          .margin({ top: 8 });
      }
      .justifyContent(FlexAlign.Center)
      .width('100%');

      Text(label)
        .fontSize(12)
        .fontColor(this.nightMode ? 'rgba(255,255,255,0.70)' : '#6B7280');
    }
    .layoutWeight(1)
    .height(82)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.nightMode ? '#1F2937' : '#F9FAFB')
    .borderRadius(8);
  }

  @Builder
  energyTrendCard() {
    Column({ space: 12 }) {
      Row() {
        Text('能耗趋势')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.nightMode ? Color.White : '#111827');

        Blank();

        Text(`电量 ${this.batteryPower}%`)
          .fontSize(12)
          .fontColor(this.getEnergyColor())
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.nightMode ? '#064E3B' : '#ECFDF5')
          .borderRadius(8);
      }
      .width('100%');

      Row({ space: 8 }) {
        this.energyBar('一', this.getEnergyTrendValue(0), '#93C5FD');
        this.energyBar('二', this.getEnergyTrendValue(1), '#60A5FA');
        this.energyBar('三', this.getEnergyTrendValue(2), '#3B82F6');
        this.energyBar('四', this.getEnergyTrendValue(3), '#2563EB');
        this.energyBar('五', this.getEnergyTrendValue(4), '#1D4ED8');
        this.energyBar('六', this.getEnergyTrendValue(5), '#0E9F6E');
        this.energyBar('日', this.getEnergyTrendValue(6), '#10B981');
      }
      .width('100%')
      .height(132)
      .alignItems(VerticalAlign.Bottom);

      Row() {
        Text('电池电量变化趋势')
          .fontSize(12)
          .fontColor(this.nightMode ? 'rgba(255,255,255,0.60)' : '#6B7280');

        Blank();

        Text(`座舱 ${this.temperature}℃`)
          .fontSize(12)
          .fontColor('#2563EB');
      }
      .width('100%');
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.nightMode ? '#0F172A' : '#F8FAFC')
    .borderRadius(8);
  }

  @Builder
  energyBar(label: string, value: number, color: string) {
    Column({ space: 6 }) {
      Blank();

      Column()
        .width('100%')
        .height(value)
        .backgroundColor(color)
        .borderRadius(6);

      Text(label)
        .fontSize(11)
        .fontColor(this.nightMode ? 'rgba(255,255,255,0.62)' : '#6B7280');
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  behaviorTimelineCard() {
    Column({ space: 12 }) {
      Row() {
        Text('行为时间轴')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.nightMode ? Color.White : '#111827');

        Blank();

        Text(`${this.controlLogs.length} 条`)
          .fontSize(12)
          .fontColor(this.nightMode ? 'rgba(255,255,255,0.62)' : '#6B7280');
      }
      .width('100%');

      this.timelineRow(this.getTimelineTime(0), this.getTimelineTitle(0), this.getTimelineDesc(0), '#2563EB');
      this.timelineRow(this.getTimelineTime(1), this.getTimelineTitle(1), this.getTimelineDesc(1), '#0E9F6E');
      this.timelineRow(this.getTimelineTime(2), this.getTimelineTitle(2), this.getTimelineDesc(2), '#7C3AED');
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.nightMode ? '#0F172A' : '#F8FAFC')
    .borderRadius(8);
  }

  @Builder
  timelineRow(time: string, title: string, desc: string, color: string) {
    Row({ space: 10 }) {
      Column() {
        Text('')
          .width(10)
          .height(10)
          .backgroundColor(color)
          .borderRadius(5);
      }
      .width(20)
      .alignItems(HorizontalAlign.Center);

      Column({ space: 3 }) {
        Row() {
          Text(title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.nightMode ? Color.White : '#111827')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(time)
            .fontSize(11)
            .fontColor(this.nightMode ? 'rgba(255,255,255,0.52)' : '#9CA3AF');
        }
        .width('100%');

        Text(desc)
          .fontSize(12)
          .fontColor(this.nightMode ? 'rgba(255,255,255,0.62)' : '#6B7280')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .layoutWeight(1);
    }
    .width('100%');
  }

  @Builder
  carPage() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          this.appHeader('车辆控制', '远程指令中心', true);

          this.carControlStage();
          this.controlLogPanel();
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 24 });
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }

  @Builder
  carControlStage() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#FFFFFF', 0.0], ['#F4F6F8', 1.0]]
        });

      Column({ space: 0 }) {
        Image(this.getCarImage())
          .width(248)
          .height(392)
          .objectFit(ImageFit.Contain)
          .margin({ top: 6 });

        this.directionPanel();
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center);

      this.vehicleControlButton(this.carLocked ? $r('app.media.ic_door_lock') : $r('app.media.ic_door_lock_active'),
        !this.carLocked, '7%', 210, () => {
          this.toggleDoor();
        });

      this.vehicleControlButton(this.lightOn ? $r('app.media.ic_light_open_active') : $r('app.media.ic_light_open'),
        this.lightOn, '78%', 210, () => {
          this.toggleLight();
        });
    }
    .width('88%')
    .height(558)
    .backgroundColor('#F4F6F8')
    .borderRadius(8)
    .shadow({ radius: 12, color: '#0000000D', offsetX: 0, offsetY: 4 });
  }

  @Builder
  vehicleControlButton(icon: Resource, active: boolean, x: string, y: number, action: () => void) {
    Column() {
      Image(icon)
        .width(36)
        .height(36)
        .objectFit(ImageFit.Contain);
    }
    .width(46)
    .height(46)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(active ? '#DDFCF7' : 'rgba(255,255,255,0.88)')
    .border({ width: 1, color: active ? '#A8F3EA' : '#E5E7EB' })
    .borderRadius(23)
    .shadow({ radius: 6, color: '#00000012', offsetX: 0, offsetY: 2 })
    .position({ x: x, y: y })
    .onClick(action);
  }

  @Builder
  directionPanel() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.getDirectionImage())
        .width(128)
        .height(128)
        .objectFit(ImageFit.Contain)
        .shadow({ radius: 10, color: '#0000000A', offsetX: 0, offsetY: 4 });

      this.directionPadButton('up', 42, 0, 44, 46);
      this.directionPadButton('left', 0, 42, 46, 44);
      this.directionPadButton('right', 82, 42, 46, 44);
      this.directionPadButton('down', 42, 82, 44, 46);
      this.stopDirectionButton();
    }
    .width(128)
    .height(128)
    .margin({ top: 8 });
  }

  @Builder
  directionPadButton(direction: string, x: number, y: number, width: number, height: number) {
    Column()
      .width(width)
      .height(height)
      .backgroundColor('rgba(255,255,255,0.01)')
      .position({ x: x, y: y })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.startDirectionHold(direction);
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.stopDirectionHold();
        }
      });
  }

  @Builder
  stopDirectionButton() {
    Column()
    .width(42)
    .height(42)
    .backgroundColor('rgba(255,255,255,0.01)')
    .borderRadius(21)
    .position({ x: 43, y: 43 })
    .onClick(() => {
      this.stopDirectionHold(false);
      this.stopCar();
    });
  }

  @Builder
  controlLogPanel() {
    Column({ space: 12 }) {
      Row() {
        Text('最近指令')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827');

        Blank();

        Text('刷新')
          .fontSize(13)
          .fontColor('#2563EB')
          .onClick(() => {
            this.loadControlLogs();
          });
      }
      .width('100%');

      if (this.controlLogs.length === 0) {
        Text('暂无控制日志')
          .fontSize(14)
          .fontColor('#9CA3AF')
          .width('100%')
          .padding({ top: 10, bottom: 10 });
      }

      ForEach(this.controlLogs, (item: ControlLogItem) => {
        Column({ space: 6 }) {
          Row() {
            Text(item.operaType ?? '车辆操作')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827');

            Blank();

            Text(item.createTime ?? '--')
              .fontSize(12)
              .fontColor('#9CA3AF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ right: 10 });

            Text('删除')
              .fontSize(12)
              .fontColor('#DC2626')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#FEF2F2')
              .borderRadius(8)
              .onClick(() => {
                this.openDeleteDialog('controlLog', item.id ?? '', item.operaContent ?? item.operaType ?? '这条控制日志');
              });
          }
          .width('100%');

          Text(item.operaContent ?? '')
            .fontSize(13)
            .fontColor('#6B7280')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F9FAFB')
        .borderRadius(8);
      }, (item: ControlLogItem) => item.id ?? item.createTime ?? '');
    }
    .width('88%')
    .padding(18)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 2 });
  }

  @Builder
  feedPage() {
    Column() {
      Scroll() {
        Column({ space: 14 }) {
          this.appHeader('反馈中心', '问题、建议与处理进度', true);

          Row() {
            Text(`${this.feedbackList.length}`)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827');

            Text(' 条反馈')
              .fontSize(15)
              .fontColor('#6B7280')
              .margin({ left: 4, top: 10 });

            Blank();

            Button('新增')
              .width(84)
              .height(40)
              .borderRadius(8)
              .backgroundColor('#111827')
              .fontColor(Color.White)
              .onClick(() => {
                this.navPathStack.pushPath({
                  name: 'Feedback_submit'
                });
              });
          }
          .width('88%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8);

          if (this.feedbackList.length === 0) {
            Column({ space: 10 }) {
              Image($r('app.media.ic_msg'))
                .width(48)
                .height(48);

              Text('暂无反馈记录')
                .fontSize(16)
                .fontColor('#6B7280');
            }
            .width('88%')
            .height(180)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(8);
          }

          ForEach(this.feedbackList, (item: FeedbackItem) => {
            Column({ space: 12 }) {
              Row() {
                Text(this.getFeedbackStatus(item))
                  .fontSize(12)
                  .fontColor(item.status === '1' ? '#065F46' : '#92400E')
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                  .backgroundColor(item.status === '1' ? '#D1FAE5' : '#FEF3C7')
                  .borderRadius(8);

                Blank();

                Text(this.getFeedbackTime(item))
                  .fontSize(12)
                  .fontColor('#9CA3AF');
              }
              .width('100%');

              Text(item.content ?? '')
                .fontSize(16)
                .fontColor('#111827')
                .lineHeight(23)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis });

              Row() {
                Text(item.nickName ?? item.userName ?? '车主用户')
                  .fontSize(13)
                  .fontColor('#6B7280')
                  .layoutWeight(1);

                Text('删除')
                  .fontSize(13)
                  .fontColor('#DC2626')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor('#FEF2F2')
                  .borderRadius(8)
                  .onClick(() => {
                    this.openDeleteDialog('feedback', item.id ?? '', item.content ?? '这条反馈记录');
                  });

                Text('详情')
                  .fontSize(13)
                  .fontColor('#2563EB')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor('#EFF6FF')
                  .borderRadius(8)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.openFeedbackDetail(item.id ?? '');
                  });
              }
              .width('100%');
            }
            .width('88%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 2 });
          }, (item: FeedbackItem) => item.id ?? item.createTime ?? item.content ?? '');
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 24 });
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }

  @Builder
  minePage() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 16 }) {
            Row() {
              Image($r('app.media.avatar'))
                .width(72)
                .height(72)
                .borderRadius(36)
                .objectFit(ImageFit.Cover);

              Column({ space: 6 }) {
                Text(this.getDisplayName())
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White);

                Text(this.phonenumber.length > 0 ? this.phonenumber : this.userName)
                  .fontSize(14)
                  .fontColor('rgba(255,255,255,0.76)');
              }
              .layoutWeight(1)
              .margin({ left: 14 });

              Image($r('app.media.ic_edit'))
                .width(22)
                .height(22);
            }
            .width('100%');

            Row({ space: 10 }) {
              this.profileMetric('车辆', this.carName);
              this.profileMetric('反馈', `${this.feedbackList.length}`);
            }
            .width('100%');
          }
          .width('88%')
          .padding(18)
          .backgroundColor('#111827')
          .borderRadius(8)
          .margin({ top: 20 });

          this.mineRow($r('app.media.ic_car_active'), '绑定车辆', this.carVin.length > 0 ? this.carVin : '未绑定', () => {
            router.replaceUrl({ url: AppRoutes.BIND_CAR });
          });

          this.mineRow($r('app.media.ic_feedback_active'), '我的反馈', `${this.feedbackList.length} 条记录`, () => {
            this.currentIndex = 2;
            this.loadFeedbackList();
          });

          this.mineRow($r('app.media.ic_settings'), '账号资料', this.getProfileSummary(), () => {
            this.openProfileEditor();
          });

          if (this.showProfileEditor) {
            this.profileEditor();
          }

          Button('退出登录')
            .width('88%')
            .height(52)
            .backgroundColor('#40E0D0')
            .fontColor('#062027')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .borderRadius(8)
            .margin({ top: 12, bottom: 26 })
            .onClick(() => {
              this.logout();
            });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }

  @Builder
  appHeader(title: string, subtitle: string, showRefresh: boolean) {
    Row() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.nightMode ? Color.White : '#111827');

        Text(subtitle)
          .fontSize(13)
          .fontColor(this.nightMode ? 'rgba(255,255,255,0.70)' : '#6B7280');
      }
      .layoutWeight(1);

      if (showRefresh) {
        Text('刷新')
          .fontSize(13)
          .fontColor(this.nightMode ? Color.White : '#2563EB')
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .backgroundColor(this.nightMode ? '#1E3A8A' : '#EFF6FF')
          .borderRadius(8)
          .onClick(() => {
            this.refreshAll();
          });
      }
    }
    .width('88%');
  }

  @Builder
  metricTile(value: string, label: string, color: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Text(label)
        .fontSize(12)
        .fontColor('#6B7280');
    }
    .layoutWeight(1)
    .height(70)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F9FAFB')
    .borderRadius(8);
  }

  @Builder
  statusPill(title: string, value: string, active: boolean) {
    Column({ space: 5 }) {
      Text(title)
        .fontSize(12)
        .fontColor('#6B7280');

      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(active ? '#065F46' : '#111827');
    }
    .layoutWeight(1)
    .height(68)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(active ? '#ECFDF5' : Color.White)
    .borderRadius(8);
  }

  @Builder
  controlTile(title: string, value: string, bgColor: string, action: () => void) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(13)
        .fontColor('#6B7280');

      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827');
    }
    .layoutWeight(1)
    .height(74)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(bgColor)
    .borderRadius(8)
    .onClick(action);
  }

  @Builder
  profileMetric(label: string, value: string) {
    Column({ space: 3 }) {
      Text(value)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Text(label)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.65)');
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('rgba(255,255,255,0.10)')
    .borderRadius(8);
  }

  @Builder
  mineRow(icon: Resource, title: string, desc: string, action: () => void) {
    Row() {
      Image(icon)
        .width(28)
        .height(28);

      Column({ space: 4 }) {
        Text(title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827');

        Text(desc)
          .fontSize(13)
          .fontColor('#6B7280')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .layoutWeight(1)
      .margin({ left: 14 });

      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16);
    }
    .width('88%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .onClick(action);
  }

  @Builder
  profileEditor() {
    Column({ space: 12 }) {
      Row() {
        Text('完善账号资料')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827');

        Blank();

        Text('收起')
          .fontSize(13)
          .fontColor('#6B7280')
          .onClick(() => {
            this.showProfileEditor = false;
          });
      }
      .width('100%');

      TextInput({ placeholder: '昵称', text: this.profileNickName })
        .width('100%')
        .height(48)
        .fontColor('#111827')
        .placeholderColor('#9CA3AF')
        .backgroundColor('#F9FAFB')
        .borderRadius(8)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.profileNickName = value;
        });

      TextInput({ placeholder: '手机号', text: this.profilePhone })
        .width('100%')
        .height(48)
        .fontColor('#111827')
        .placeholderColor('#9CA3AF')
        .backgroundColor('#F9FAFB')
        .borderRadius(8)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.profilePhone = value;
        });

      TextInput({ placeholder: '生日，例如 2000-01-01', text: this.profileBirthDate })
        .width('100%')
        .height(48)
        .fontColor('#111827')
        .placeholderColor('#9CA3AF')
        .backgroundColor('#F9FAFB')
        .borderRadius(8)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.profileBirthDate = value;
        });

      Row({ space: 10 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .borderRadius(8)
          .backgroundColor('#F3F4F6')
          .fontColor('#111827')
          .onClick(() => {
            this.showProfileEditor = false;
          });

        Button('保存')
          .layoutWeight(1)
          .height(44)
          .borderRadius(8)
          .backgroundColor('#111827')
          .fontColor(Color.White)
          .onClick(() => {
            this.saveProfile();
          });
      }
      .width('100%');
    }
    .width('88%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 2 });
  }

  @Builder
  deleteConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(17,24,39,0.46)')
        .onClick(() => {
          this.closeDeleteDialog();
        });

      Column({ space: 16 }) {
        Row() {
          Column({ space: 4 }) {
            Text('确认删除')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827');

            Text(this.getDeleteTargetName())
              .fontSize(13)
              .fontColor('#6B7280');
          }
          .layoutWeight(1);

          Text('取消')
            .fontSize(13)
            .fontColor('#6B7280')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .onClick(() => {
              this.closeDeleteDialog();
            });
        }
        .width('100%');

        Text('删除后将无法恢复，确定继续吗？')
          .fontSize(15)
          .fontColor('#374151')
          .width('100%')
          .lineHeight(22);

        Text(this.deleteTargetTitle)
          .fontSize(13)
          .fontColor('#6B7280')
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding(12)
          .backgroundColor('#F9FAFB')
          .borderRadius(8);

        Row({ space: 10 }) {
          Button('再想想')
            .layoutWeight(1)
            .height(46)
            .borderRadius(8)
            .backgroundColor('#F3F4F6')
            .fontColor('#111827')
            .onClick(() => {
              this.closeDeleteDialog();
            });

          Button(this.isDeleting ? '删除中...' : '确认删除')
            .layoutWeight(1)
            .height(46)
            .borderRadius(8)
            .backgroundColor('#DC2626')
            .fontColor(Color.White)
            .onClick(() => {
              this.confirmDelete();
            });
        }
        .width('100%');
      }
      .width('82%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .shadow({ radius: 18, color: '#00000030', offsetX: 0, offsetY: 6 });
    }
    .width('100%')
    .height('100%');
  }

  private openProfileEditor(): void {
    this.profileNickName = this.nickName.length > 0 ? this.nickName : this.userName;
    this.profilePhone = this.phonenumber;
    this.profileBirthDate = this.birthDate;
    this.showProfileEditor = true;
  }

  private saveProfile(): void {
    const nextNickName = this.profileNickName.trim();
    const nextPhone = this.profilePhone.trim();
    const nextBirthDate = this.profileBirthDate.trim();

    if (nextNickName.length === 0) {
      this.showToast('昵称不能为空');
      return;
    }

    preferences.getPreferences(getContext(this), USER_STORE_NAME).then(pref => {
      pref.putSync(PreferenceKeys.NICK_NAME, nextNickName);
      pref.putSync(PreferenceKeys.PHONE_NUMBER, nextPhone);
      pref.putSync(PreferenceKeys.BIRTH_DATE, nextBirthDate);
      pref.flushSync();
      this.nickName = nextNickName;
      this.phonenumber = nextPhone;
      this.birthDate = nextBirthDate;
      this.showProfileEditor = false;
    }).catch(() => {
      this.showToast('保存资料失败，请稍后重试');
    });
  }

  private openDeleteDialog(targetType: string, id: string, title: string): void {
    if (id.length === 0) {
      this.showToast('记录编号为空，无法删除');
      return;
    }

    this.deleteTargetType = targetType;
    this.deleteTargetId = id;
    this.deleteTargetTitle = title.length > 0 ? title : this.getDeleteTargetName();
    this.showDeleteDialog = true;
  }

  private closeDeleteDialog(): void {
    if (this.isDeleting) {
      return;
    }

    this.resetDeleteDialog();
  }

  private resetDeleteDialog(): void {
    this.showDeleteDialog = false;
    this.deleteTargetType = '';
    this.deleteTargetId = '';
    this.deleteTargetTitle = '';
  }

  private async confirmDelete(): Promise<void> {
    if (this.isDeleting) {
      return;
    }

    if (this.deleteTargetType === 'feedback') {
      await this.deleteFeedbackRecord(this.deleteTargetId);
      return;
    }

    if (this.deleteTargetType === 'controlLog') {
      await this.deleteControlLogRecord(this.deleteTargetId);
    }
  }

  private async deleteFeedbackRecord(id: string): Promise<void> {
    if (this.token.length === 0) {
      this.showToast('登录状态已失效，请重新登录');
      return;
    }

    this.isDeleting = true;
    try {
      const result = await AuthApi.deleteFeedback(this.token, id);
      if (result.code !== 200) {
        this.showToast(result.msg ?? '删除反馈失败');
        return;
      }

      this.removeFeedbackFromList(id);
      this.resetDeleteDialog();
      this.showToast(result.msg ?? '反馈已删除');
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isDeleting = false;
    }
  }

  private async deleteControlLogRecord(id: string): Promise<void> {
    this.isDeleting = true;
    try {
      if (id.startsWith('local-')) {
        this.removeControlLogFromList(id);
        this.resetDeleteDialog();
        this.showToast('控制日志已删除');
        return;
      }

      if (this.token.length === 0) {
        this.showToast('登录状态已失效，请重新登录');
        return;
      }

      const result = await AuthApi.deleteControlLog(this.token, id);
      if (result.code !== 200) {
        this.showToast(result.msg ?? '删除控制日志失败');
        return;
      }

      this.removeControlLogFromList(id);
      this.resetDeleteDialog();
      this.showToast(result.msg ?? '控制日志已删除');
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isDeleting = false;
    }
  }

  private removeFeedbackFromList(id: string): void {
    let nextList: FeedbackItem[] = [];
    this.feedbackList.forEach((item: FeedbackItem) => {
      if (item.id !== id) {
        nextList.push(item);
      }
    });
    this.feedbackList = nextList;
  }

  private removeControlLogFromList(id: string): void {
    let nextLogs: ControlLogItem[] = [];
    this.controlLogs.forEach((item: ControlLogItem) => {
      if (item.id !== id) {
        nextLogs.push(item);
      }
    });
    this.controlLogs = nextLogs;
  }

  private getProfileSummary(): string {
    let completed = 0;
    if (this.getDisplayName().length > 0) {
      completed += 1;
    }
    if (this.phonenumber.length > 0) {
      completed += 1;
    }
    if (this.birthDate.length > 0) {
      completed += 1;
    }

    if (completed === 3) {
      return '资料已完善';
    }

    return `已完善 ${completed}/3`;
  }

  private refreshAll(): void {
    this.loadVehicleInfo();
    this.loadVehicleState();
    this.loadFeedbackList();
    this.loadControlLogs();
  }

  private refreshHomeState(): void {
    this.loadVehicleInfo();
    this.loadVehicleState();
  }

  private startVehicleStatePolling(): void {
    this.stopVehicleStatePolling();
    this.stateRefreshTimerId = setInterval(() => {
      if (this.currentIndex === 0 || this.currentIndex === 1) {
        this.loadVehicleState();
      }
    }, 5000);
  }

  private stopVehicleStatePolling(): void {
    if (this.stateRefreshTimerId !== -1) {
      clearInterval(this.stateRefreshTimerId);
      this.stateRefreshTimerId = -1;
    }
  }

  private async loadVehicleInfo(): Promise<void> {
    if (this.token.length === 0 || this.carId.length === 0) {
      return;
    }

    try {
      const result = await AuthApi.getVehicleInfo(this.token, this.carId);
      if (result.code === 200 && result.data) {
        this.applyVehicleDetail(result.data);
      } else {
        this.showToast(result.msg ?? '获取车辆信息失败');
      }
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    }
  }

  private async loadVehicleState(): Promise<void> {
    if (this.token.length === 0 || this.carVin.length === 0) {
      return;
    }

    if (this.isVehicleStateLoading) {
      return;
    }

    this.isVehicleStateLoading = true;
    try {
      const result = await AuthApi.getVehicleState(this.token, this.carVin);
      if (result.code === 200 && result.data) {
        this.applyVehicleState(result.data);
        this.stateSyncedAt = this.getCurrentTimeLabel();
      } else {
        this.showToast(result.msg ?? '获取车辆状态失败');
      }
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isVehicleStateLoading = false;
    }
  }

  private async loadFeedbackList(): Promise<void> {
    if (this.token.length === 0) {
      return;
    }

    try {
      const result = await AuthApi.getFeedbackList(this.token);
      if (result.code === 200) {
        this.feedbackList = result.data ?? [];
      } else {
        this.showToast(result.msg ?? '获取反馈列表失败');
      }
    } catch (error) {
      this.showToast(this.getErrorMessage(error));
    }
  }

  private async loadControlLogs(): Promise<void> {
    if (this.token.length === 0) {
      return;
    }

    try {
      const result = await AuthApi.getControlLogList(this.token, 1, 3, '');
      if (result.code === 200) {
        this.mergeControlLogs(result.rows ?? []);
      }
    } catch (error) {
    }
  }

  private mergeControlLogs(remoteLogs: ControlLogItem[]): void {
    let nextLogs: ControlLogItem[] = [];
    this.controlLogs.forEach((item: ControlLogItem) => {
      if ((item.id ?? '').startsWith('local-')) {
        nextLogs.push(item);
      }
    });
    nextLogs = nextLogs.concat(remoteLogs);
    this.controlLogs = nextLogs.slice(0, 5);
  }

  private addLocalControlLog(operaType: string, operaContent: string): void {
    this.localLogSeed += 1;
    const item: ControlLogItem = {
      id: `local-${this.localLogSeed}`,
      userId: this.userId,
      userName: this.getDisplayName(),
      carId: this.carId,
      carName: this.carName,
      operaType,
      operaContent,
      createTime: '刚刚'
    };
    let nextLogs: ControlLogItem[] = [item];
    nextLogs = nextLogs.concat(this.controlLogs);
    this.controlLogs = nextLogs.slice(0, 5);
  }

  private restoreSceneState(snapshot: SceneSnapshot): void {
    this.carLocked = snapshot.carLocked;
    this.lightOn = snapshot.lightOn;
    this.temperature = snapshot.temperature;
    this.windLevel = snapshot.windLevel;
    this.acOn = snapshot.acOn;
    this.airCirculationOn = snapshot.airCirculationOn;
    this.defrostOn = snapshot.defrostOn;
    this.nightMode = snapshot.nightMode;
  }

  private refreshControlLogsSoon(): void {
    setTimeout(() => {
      this.loadControlLogs();
    }, 600);
    setTimeout(() => {
      this.loadControlLogs();
    }, 1800);
  }

  private refreshVehicleStateSoon(): void {
    setTimeout(() => {
      this.loadVehicleState();
    }, 700);
    setTimeout(() => {
      this.loadVehicleState();
    }, 1800);
  }

  private async runSceneMode(sceneKey: string): Promise<void> {
    if (this.sceneRunning) {
      this.showToast('场景正在执行，请稍候');
      return;
    }

    if (!this.ensureVehicleReady()) {
      return;
    }

    const previous = this.snapshotSceneState();
    const title = this.getSceneTitle(sceneKey);

    if (this.activeSceneKey === sceneKey && this.sceneProgress === 100) {
      this.activeSceneKey = '';
      this.activeSceneTitle = '场景待命';
      this.sceneProgress = 0;
      this.sceneStatus = '场景已关闭';
      this.sceneEffect = '点击场景卡片，一键联动车门、车灯与空调';
      this.addLocalControlLog('场景模式', `关闭${title}`);
      this.refreshControlLogsSoon();
      return;
    }

    this.activeSceneKey = sceneKey;
    this.activeSceneTitle = title;
    this.sceneRunning = true;
    this.sceneProgress = 12;
    this.sceneStatus = '正在唤醒智能座舱';
    this.sceneEffect = this.getSceneRunningText(sceneKey);

    setTimeout(() => {
      if (this.activeSceneKey === sceneKey) {
        this.sceneProgress = 38;
        this.sceneStatus = '正在联动车门、车灯与空调';
      }
    }, 300);

    this.applySceneLocalState(sceneKey);
    this.addLocalControlLog('场景模式', `${title}：${this.getSceneSummary(sceneKey)}`);
    this.refreshControlLogsSoon();

    try {
      await this.syncSceneCommands(previous);
      this.sceneProgress = 86;
      this.sceneStatus = '正在校准车辆状态';
      this.refreshVehicleStateSoon();

      setTimeout(() => {
        if (this.activeSceneKey === sceneKey) {
          this.sceneProgress = 100;
          this.sceneRunning = false;
          this.sceneStatus = '场景执行完成';
          this.sceneEffect = this.getSceneFinishedText(sceneKey);
        }
      }, 650);
    } catch (error) {
      this.restoreSceneState(previous);
      this.sceneRunning = false;
      this.sceneProgress = 0;
      this.activeSceneKey = '';
      this.activeSceneTitle = '场景待命';
      this.sceneStatus = '场景执行失败';
      this.sceneEffect = '已恢复执行前页面状态，稍后会以服务器车况为准。';
      this.refreshVehicleStateSoon();
      this.showToast(this.getErrorMessage(error));
    }
  }

  private snapshotSceneState(): SceneSnapshot {
    return {
      carLocked: this.carLocked,
      lightOn: this.lightOn,
      temperature: this.temperature,
      windLevel: this.windLevel,
      acOn: this.acOn,
      airCirculationOn: this.airCirculationOn,
      defrostOn: this.defrostOn,
      nightMode: this.nightMode
    };
  }

  private applySceneLocalState(sceneKey: string): void {
    if (sceneKey === 'offWork') {
      this.acOn = true;
      this.temperature = 22;
      this.carLocked = false;
      this.lightOn = true;
      this.airCirculationOn = false;
      this.defrostOn = false;
      this.windLevel = '2';
      this.nightMode = false;
      return;
    }

    if (sceneKey === 'camping') {
      this.acOn = true;
      this.temperature = 24;
      this.carLocked = true;
      this.lightOn = false;
      this.airCirculationOn = true;
      this.defrostOn = false;
      this.windLevel = '1';
      this.nightMode = false;
      return;
    }

    if (sceneKey === 'rainy') {
      this.acOn = true;
      this.temperature = 23;
      this.lightOn = true;
      this.airCirculationOn = false;
      this.defrostOn = true;
      this.windLevel = '3';
      this.nightMode = false;
      return;
    }

    if (sceneKey === 'night') {
      this.lightOn = true;
      this.acOn = true;
      this.temperature = 24;
      this.airCirculationOn = false;
      this.defrostOn = false;
      this.windLevel = '1';
      this.nightMode = true;
    }
  }

  private async syncSceneCommands(previous: SceneSnapshot): Promise<void> {
    if (previous.carLocked !== this.carLocked) {
      const doorResult = await AuthApi.controlDoor(this.token, this.carId, this.carLocked ? '0' : '1');
      this.ensureSceneResult(doorResult, '车门联动失败');
    }

    if (previous.lightOn !== this.lightOn) {
      const lightResult = await AuthApi.controlLight(this.token, this.carId, this.lightOn ? '1' : '0');
      this.ensureSceneResult(lightResult, '车灯联动失败');
    }

    const stateResult = await AuthApi.updateVehicleState(this.token, this.buildVehicleStateParams());
    this.ensureSceneResult(stateResult, '座舱状态联动失败');
  }

  private buildVehicleStateParams(): UpdateVehicleStateParams {
    return {
      auto: this.acOn ? '1' : '0',
      door: this.carLocked ? '0' : '1',
      light: this.lightOn ? '1' : '0',
      temperature: `${this.temperature}`,
      windLevel: this.windLevel,
      circulate: this.airCirculationOn ? '1' : '0',
      setTemp: `${this.temperature}`,
      acBtn: this.acOn ? '1' : '0',
      clearFog: this.defrostOn ? '1' : '0',
      fanState: this.fanState,
      playMode: this.playMode,
      processMp3: this.processMp3,
      mp3Playing: this.mp3Playing,
      processMp4: this.processMp4,
      mp4Playing: this.mp4Playing,
      carVin: this.carVin
    };
  }

  private ensureSceneResult(result: BaseResult, fallbackMessage: string): void {
    if (result.code !== 200) {
      throw new Error(result.msg ?? fallbackMessage);
    }
  }

  private applyVehicleDetail(data: VehicleDetail): void {
    this.carName = data.carName ?? data.brand ?? '我的车辆';
    this.enduranceMileage = data.enduranceMileage ?? '--';
    this.batteryPower = this.parsePercent(data.batteryPower);
    this.updateTime = data.updateTime ?? data.createYm ?? '--';
    this.carVin = data.carVin ?? this.carVin;
  }

  private applyVehicleState(data: VehicleState): void {
    if (data.door !== undefined) {
      this.carLocked = data.door !== '1';
    }
    if (data.light !== undefined) {
      this.lightOn = data.light === '1';
    }
    if (data.setTemp !== undefined || data.temperature !== undefined) {
      this.temperature = this.toNumber(data.setTemp ?? data.temperature ?? `${this.temperature}`, this.temperature);
    }
    this.windLevel = data.windLevel ?? this.windLevel;
    this.acOn = data.acBtn === undefined ? this.acOn : data.acBtn === '1';
    this.airCirculationOn = data.circulate === undefined ? this.airCirculationOn : data.circulate === '1';
    this.defrostOn = data.clearFog === undefined ? this.defrostOn : data.clearFog === '1';
    this.fanState = data.fanState ?? this.fanState;
    this.playMode = data.playMode ?? this.playMode;
    this.processMp3 = data.processMp3 ?? this.processMp3;
    this.mp3Playing = data.mp3Playing ?? this.mp3Playing;
    this.processMp4 = data.processMp4 ?? this.processMp4;
    this.mp4Playing = data.mp4Playing ?? this.mp4Playing;
  }

  private setTemperature(nextTemperature: number): void {
    if (this.isAirUpdating) {
      this.showToast('空调状态同步中，请稍候');
      return;
    }

    const next = Math.max(16, Math.min(30, nextTemperature));
    if (next === this.temperature) {
      return;
    }

    const previous = this.snapshotSceneState();
    this.temperature = next;
    this.updateAirConditionState(previous);
  }

  private toggleAirCirculation(): void {
    if (this.isAirUpdating) {
      this.showToast('空调状态同步中，请稍候');
      return;
    }

    const previous = this.snapshotSceneState();
    this.airCirculationOn = !this.airCirculationOn;
    this.updateAirConditionState(previous);
  }

  private toggleAcPower(): void {
    if (this.isAirUpdating) {
      this.showToast('空调状态同步中，请稍候');
      return;
    }

    const previous = this.snapshotSceneState();
    this.acOn = !this.acOn;
    if (!this.acOn) {
      this.airCirculationOn = false;
      this.defrostOn = false;
    }
    this.updateAirConditionState(previous);
  }

  private toggleDefrost(): void {
    if (this.isAirUpdating) {
      this.showToast('空调状态同步中，请稍候');
      return;
    }

    const previous = this.snapshotSceneState();
    this.defrostOn = !this.defrostOn;
    if (this.defrostOn) {
      this.acOn = true;
    }
    this.updateAirConditionState(previous);
  }

  private async updateAirConditionState(previous: SceneSnapshot): Promise<void> {
    if (!this.ensureVehicleReady()) {
      this.restoreSceneState(previous);
      return;
    }

    if (this.isAirUpdating) {
      return;
    }

    const params: UpdateVehicleStateParams = this.buildVehicleStateParams();

    this.addLocalControlLog('空调控制', this.getAcSummary());
    this.refreshControlLogsSoon();

    this.isAirUpdating = true;
    try {
      const result = await AuthApi.updateVehicleState(this.token, params);
      if (this.handleApiResult(result, '空调状态已更新')) {
        this.refreshVehicleStateSoon();
      } else {
        this.restoreSceneState(previous);
      }
    } catch (error) {
      this.restoreSceneState(previous);
      this.refreshVehicleStateSoon();
      this.showToast(this.getErrorMessage(error));
    } finally {
      this.isAirUpdating = false;
    }
  }

  private async toggleDoor(): Promise<void> {
    if (!this.ensureVehicleReady()) {
      return;
    }

    const previousLocked = this.carLocked;
    const nextLocked = !this.carLocked;
    this.carLocked = nextLocked;
    this.addLocalControlLog('车门控制', nextLocked ? '锁定车门' : '解锁车门');
    this.refreshControlLogsSoon();

    try {
      const result = await AuthApi.controlDoor(this.token, this.carId, nextLocked ? '0' : '1');
      if (!this.handleApiResult(result, '车门状态已更新')) {
        this.carLocked = previousLocked;
      } else {
        this.refreshVehicleStateSoon();
      }
    } catch (error) {
      this.carLocked = previousLocked;
      this.showToast(this.getErrorMessage(error));
    }
  }

  private async toggleLight(): Promise<void> {
    if (!this.ensureVehicleReady()) {
      return;
    }

    const previousLightOn = this.lightOn;
    const nextLightOn = !this.lightOn;
    this.lightOn = nextLightOn;
    this.addLocalControlLog('车灯控制', nextLightOn ? '开启车灯' : '关闭车灯');
    this.refreshControlLogsSoon();

    try {
      const result = await AuthApi.controlLight(this.token, this.carId, nextLightOn ? '1' : '0');
      if (!this.handleApiResult(result, '车灯状态已更新')) {
        this.lightOn = previousLightOn;
      } else {
        this.refreshVehicleStateSoon();
      }
    } catch (error) {
      this.lightOn = previousLightOn;
      this.showToast(this.getErrorMessage(error));
    }
  }

  changeDirection(direction: string): void {
    const previousDirection = this.directionState;
    this.directionState = direction;
    this.sendDirectionCommand(direction, previousDirection);
  }

  private startDirectionHold(direction: string): void {
    if (this.activeDirection === direction && this.directionHoldTimerId !== -1) {
      return;
    }

    this.stopDirectionHold(false);
    const previousDirection = this.directionState;
    this.activeDirection = direction;
    this.directionState = direction;
    this.sendDirectionCommand(direction, previousDirection, true);

    this.directionHoldTimerId = setInterval(() => {
      this.sendDirectionCommand(direction, previousDirection, false);
    }, DIRECTION_REPEAT_INTERVAL_MS);
  }

  private stopDirectionHold(shouldSendStop: boolean = true): void {
    const hadActiveDirection = this.activeDirection.length > 0 || this.directionHoldTimerId !== -1;
    this.clearDirectionHoldTimer();
    this.activeDirection = '';

    if (shouldSendStop && hadActiveDirection) {
      this.stopCar(true, false);
    }
  }

  private clearDirectionHoldTimer(): void {
    if (this.directionHoldTimerId !== -1) {
      clearInterval(this.directionHoldTimerId);
      this.directionHoldTimerId = -1;
    }
  }

  private async sendDirectionCommand(direction: string, previousDirection: string,
    shouldRecordLog: boolean = true): Promise<void> {
    if (!this.ensureVehicleReady()) {
      this.directionState = previousDirection;
      this.stopDirectionHold(false);
      return;
    }

    if (this.directionCommandInFlight) {
      return;
    }

    if (shouldRecordLog) {
      this.addLocalControlLog('车辆移动', this.getDirectionCommandLabel(direction));
      this.refreshControlLogsSoon();
    }

    const commandTask = this.executeDirectionCommand(direction, previousDirection);
    this.directionCommandInFlight = commandTask;
    try {
      await commandTask;
    } catch (error) {
      this.restoreDirectionAfterFailure(direction, previousDirection);
      this.stopDirectionHold(false);
      this.showToast(this.getErrorMessage(error));
    } finally {
      if (this.directionCommandInFlight === commandTask) {
        this.directionCommandInFlight = null;
      }
    }
  }

  private async executeDirectionCommand(direction: string, previousDirection: string): Promise<void> {
    if (direction === 'up') {
      const result = await AuthApi.controlMove(this.token, this.carId);
      if (!this.handleApiResult(result, '车辆前进指令已发送')) {
        this.restoreDirectionAfterFailure(direction, previousDirection);
      }
      return;
    }
    if (direction === 'down') {
      const result = await AuthApi.controlBack(this.token, this.carId);
      if (!this.handleApiResult(result, '车辆后退指令已发送')) {
        this.restoreDirectionAfterFailure(direction, previousDirection);
      }
      return;
    }
    if (direction === 'left') {
      const result = await AuthApi.controlLeft(this.token, this.carId);
      if (!this.handleApiResult(result, '车辆左转指令已发送')) {
        this.restoreDirectionAfterFailure(direction, previousDirection);
      }
      return;
    }
    if (direction === 'right') {
      const result = await AuthApi.controlRight(this.token, this.carId);
      if (!this.handleApiResult(result, '车辆右转指令已发送')) {
        this.restoreDirectionAfterFailure(direction, previousDirection);
      }
    }
  }

  private restoreDirectionAfterFailure(direction: string, previousDirection: string): void {
    if (this.activeDirection === direction || this.directionState === direction) {
      this.directionState = previousDirection;
    }
  }

  private async stopCar(waitForDirectionCommand: boolean = false, restoreOnFailure: boolean = true): Promise<void> {
    const previousDirection = this.directionState;
    this.directionState = 'stop';
    if (!this.ensureVehicleReady()) {
      this.directionState = previousDirection;
      return;
    }

    this.addLocalControlLog('车辆移动', '停车');
    this.refreshControlLogsSoon();

    try {
      if (waitForDirectionCommand && this.directionCommandInFlight) {
        await this.directionCommandInFlight;
      }

      const result = await AuthApi.controlStop(this.token, this.carId);
      if (!this.handleApiResult(result, '停车指令已发送') && restoreOnFailure) {
        this.directionState = previousDirection;
      }
    } catch (error) {
      if (restoreOnFailure) {
        this.directionState = previousDirection;
      }
      this.showToast(this.getErrorMessage(error));
    }
  }

  private openFeedbackDetail(id: string): void {
    if (id.length === 0) {
      this.showToast('反馈编号为空，无法查看详情');
      return;
    }

    this.selectedFeedbackId = id;
    this.markFeedbackAsRead(id);
    this.navPathStack.pushPath({
      name: 'Feedback_details'
    });
  }

  private markFeedbackAsRead(id: string): void {
    let nextList: FeedbackItem[] = [];
    this.feedbackList.forEach((item: FeedbackItem) => {
      if (item.id === id) {
        const updated: FeedbackItem = {
          id: item.id,
          userId: item.userId,
          userName: item.userName,
          nickName: item.nickName,
          phonenumber: item.phonenumber,
          content: item.content,
          status: '1',
          picUrl: item.picUrl,
          delFlag: item.delFlag,
          replyRead: '1',
          reply: item.reply,
          createBy: item.createBy,
          createTime: item.createTime,
          updateBy: item.updateBy,
          updateTime: item.updateTime,
          remark: item.remark
        };
        nextList.push(updated);
      } else {
        nextList.push(item);
      }
    });
    this.feedbackList = nextList;
  }

  private logout(): void {
    preferences.getPreferences(getContext(this), USER_STORE_NAME).then(pref => {
      pref.putSync(PreferenceKeys.IS_LOGIN, false);
      pref.putSync(PreferenceKeys.IS_CAR_BOUND, false);
      pref.putSync(PreferenceKeys.TOKEN, '');
      pref.putSync(PreferenceKeys.USERNAME, '');
      pref.putSync(PreferenceKeys.USER_ID, '');
      pref.putSync(PreferenceKeys.CAR_VIN, '');
      pref.putSync(PreferenceKeys.CAR_ID, '');
      pref.putSync(PreferenceKeys.NICK_NAME, '');
      pref.putSync(PreferenceKeys.PHONE_NUMBER, '');
      pref.putSync(PreferenceKeys.BIRTH_DATE, '');
      pref.flushSync();
      router.replaceUrl({ url: AppRoutes.INDEX });
    });
  }

  private ensureVehicleReady(): boolean {
    if (this.token.length === 0) {
      this.showToast('登录状态已失效，请重新登录');
      router.replaceUrl({ url: AppRoutes.INDEX });
      return false;
    }

    if (this.carId.length === 0 || this.carVin.length === 0) {
      this.showToast('车辆信息不完整，请重新绑定车辆');
      router.replaceUrl({ url: AppRoutes.BIND_CAR });
      return false;
    }

    return true;
  }

  private handleApiResult(result: BaseResult, successMessage: string): boolean {
    if (result.code !== 200) {
      this.showToast(result.msg ?? '操作失败');
      return false;
    }

    return true;
  }

  getCarImage(): Resource {
    if (this.lightOn && !this.carLocked) {
      return $r('app.media.bg_owner_all_open');
    }

    if (this.lightOn) {
      return $r('app.media.bg_owner_open_light');
    }

    if (!this.carLocked) {
      return $r('app.media.bg_owner_open_door');
    }

    return $r('app.media.bg_owner_normal');
  }

  getDirectionImage(): Resource {
    switch (this.directionState) {
      case 'up':
        return $r('app.media.ic_direction_up');
      case 'down':
        return $r('app.media.ic_direction_down');
      case 'left':
        return $r('app.media.ic_direction_left');
      case 'right':
        return $r('app.media.ic_direction_right');
      default:
        return $r('app.media.ic_direction');
    }
  }

  private getDirectionLabel(): string {
    return this.getDirectionCommandLabel(this.directionState);
  }

  private getDirectionCommandLabel(direction: string): string {
    switch (direction) {
      case 'up':
        return '前进';
      case 'down':
        return '后退';
      case 'left':
        return '左转';
      case 'right':
        return '右转';
      case 'stop':
        return '停车';
      default:
        return '停车';
    }
  }

  private getSceneTitle(sceneKey: string): string {
    if (sceneKey === 'offWork') {
      return '下班模式';
    }
    if (sceneKey === 'camping') {
      return '露营模式';
    }
    if (sceneKey === 'rainy') {
      return '雨天模式';
    }
    if (sceneKey === 'night') {
      return '夜间模式';
    }
    return '智能场景';
  }

  private getSceneSummary(sceneKey: string): string {
    if (sceneKey === 'offWork') {
      return '开启空调、温度22℃、解锁车门、开启车灯';
    }
    if (sceneKey === 'camping') {
      return '开启循环空调、关闭车灯、低能耗运行';
    }
    if (sceneKey === 'rainy') {
      return '开启除雾、开启车灯，提升雨天视野';
    }
    if (sceneKey === 'night') {
      return '切换深色主题、降低界面亮度、开启夜间氛围';
    }
    return '联动座舱状态';
  }

  private getSceneRunningText(sceneKey: string): string {
    if (sceneKey === 'offWork') {
      return '正在为返程准备车辆：座舱预冷、车门解锁、车灯点亮。';
    }
    if (sceneKey === 'camping') {
      return '正在进入轻能耗驻车状态：循环空调开启，外部车灯关闭。';
    }
    if (sceneKey === 'rainy') {
      return '正在处理雨天视野：除雾与车灯同步开启。';
    }
    if (sceneKey === 'night') {
      return '正在切换夜间界面：深色座舱与氛围灯 UI 已激活。';
    }
    return '正在执行场景联动。';
  }

  private getSceneFinishedText(sceneKey: string): string {
    if (sceneKey === 'offWork') {
      return '车辆准备完成，可以直接上车出发。';
    }
    if (sceneKey === 'camping') {
      return '露营氛围已就绪，座舱保持舒适低能耗。';
    }
    if (sceneKey === 'rainy') {
      return '雨天辅助已开启，车灯与除雾正在工作。';
    }
    if (sceneKey === 'night') {
      return '夜间动态界面已启用，亮度更柔和。';
    }
    return '场景执行完成。';
  }

  private getWeeklyUsageCount(): number {
    return 18 + Math.min(12, this.controlLogs.length + this.feedbackList.length);
  }

  private getAirConditionCount(): number {
    return 42 + this.countControlLogsByKeyword('空调') + (this.acOn ? 1 : 0);
  }

  private getNightUsagePercent(): number {
    return this.nightMode ? 68 : 63;
  }

  private getAverageUseMinutes(): number {
    return 26 + Math.min(8, this.controlLogs.length);
  }

  private countControlLogsByKeyword(keyword: string): number {
    let count = 0;
    this.controlLogs.forEach((item: ControlLogItem) => {
      const content = `${item.operaType ?? ''}${item.operaContent ?? ''}`;
      if (content.indexOf(keyword) >= 0) {
        count += 1;
      }
    });
    return count;
  }

  private getEnergyTrendValue(index: number): number {
    const base = this.batteryPower > 0 ? this.batteryPower : 78;
    const offset = this.getTrendOffset(index);
    return Math.max(28, Math.min(110, base + offset));
  }

  private getTrendOffset(index: number): number {
    if (index === 0) {
      return -14;
    }
    if (index === 1) {
      return -9;
    }
    if (index === 2) {
      return -6;
    }
    if (index === 3) {
      return -3;
    }
    if (index === 4) {
      return 0;
    }
    if (index === 5) {
      return 4;
    }
    return 7;
  }

  private getTimelineTime(index: number): string {
    if (this.controlLogs.length > index) {
      return this.controlLogs[index].createTime ?? '刚刚';
    }
    if (index === 0) {
      return '08:20';
    }
    if (index === 1) {
      return '12:40';
    }
    return '20:15';
  }

  private getTimelineTitle(index: number): string {
    if (this.controlLogs.length > index) {
      return this.controlLogs[index].operaType ?? '车辆操作';
    }
    if (index === 0) {
      return '下班模式';
    }
    if (index === 1) {
      return '空调控制';
    }
    return '夜间模式';
  }

  private getTimelineDesc(index: number): string {
    if (this.controlLogs.length > index) {
      return this.controlLogs[index].operaContent ?? '车辆状态已更新';
    }
    if (index === 0) {
      return '自动开启空调、解锁车门并点亮车灯';
    }
    if (index === 1) {
      return '温度维持在舒适区间，能耗保持稳定';
    }
    return '深色座舱与夜间氛围 UI 已启用';
  }

  private getSafetyLabel(): string {
    if (!this.carLocked) {
      return '车门未锁';
    }
    if (this.lightOn) {
      return '车灯开启';
    }
    return '安全停放';
  }

  private getHomeStatusSubtitle(): string {
    if (this.isVehicleStateLoading) {
      return '车辆状态同步中...';
    }

    if (this.stateSyncedAt !== '--') {
      return `车辆状态更新于 ${this.stateSyncedAt}`;
    }

    return '车辆状态待同步';
  }

  private getCurrentTimeLabel(): string {
    const date = new Date();
    return `${this.padTime(date.getHours())}:${this.padTime(date.getMinutes())}:${this.padTime(date.getSeconds())}`;
  }

  private padTime(value: number): string {
    if (value < 10) {
      return `0${value}`;
    }

    return `${value}`;
  }

  private getAcSummary(): string {
    if (!this.acOn) {
      return '空调关闭，座舱保持待机';
    }

    if (this.defrostOn) {
      return '除雾已开启，保持视野清晰';
    }

    if (this.airCirculationOn) {
      return '内循环开启，快速稳定温度';
    }

    return '自动维持舒适温度';
  }

  private isAirToggleActive(mode: string): boolean {
    if (mode === 'cycle') {
      return this.airCirculationOn;
    }
    if (mode === 'ac') {
      return this.acOn;
    }
    if (mode === 'defrost') {
      return this.defrostOn;
    }
    return false;
  }

  private getFeedbackStatus(item: FeedbackItem): string {
    return item.status === '1' ? '已读' : '未读';
  }

  private getDeleteTargetName(): string {
    if (this.deleteTargetType === 'feedback') {
      return '反馈记录';
    }
    if (this.deleteTargetType === 'controlLog') {
      return '控制日志';
    }
    return '记录';
  }

  private getFeedbackTime(item: FeedbackItem): string {
    return item.updateTime ?? item.createTime ?? '--';
  }

  private getDisplayName(): string {
    if (this.nickName.length > 0) {
      return this.nickName;
    }
    if (this.userName.length > 0) {
      return this.userName;
    }
    return '车主用户';
  }

  private getEnergyColor(): string {
    if (this.batteryPower <= 20) {
      return '#DC2626';
    }
    if (this.batteryPower <= 50) {
      return '#B45309';
    }
    return '#0E9F6E';
  }

  private parsePercent(value?: string): number {
    if (!value) {
      return 0;
    }

    const parsed = Number(value);
    if (parsed !== parsed) {
      return 0;
    }

    return Math.max(0, Math.min(100, Math.round(parsed)));
  }

  private toNumber(value: string, fallback: number): number {
    const parsed = Number(value);
    if (parsed !== parsed) {
      return fallback;
    }
    return Math.round(parsed);
  }

  private showToast(message: string): void {
    AppPrompt.showToast(message);
  }

  private getErrorMessage(error: Object): string {
    return AppPrompt.getErrorMessage(error);
  }

  @Builder
  pageMap(name: string) {
    if (name === 'Feedback_submit') {
      NavDestination() {
        Feedback_submit({
          navPathStack: this.navPathStack
        });
      }
    } else if (name === 'Feedback_details') {
      NavDestination() {
        Feedback_details({
          feedbackId: this.selectedFeedbackId,
          navPathStack: this.navPathStack,
          onDeleted: (id: string) => {
            this.removeFeedbackFromList(id);
          }
        });
      }
    }
  }
}
