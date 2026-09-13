// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get letsElevator => '操作乐趣电梯';

  @override
  String get menu => '菜单';

  @override
  String get settings => '设置';

  @override
  String get start => '开始';

  @override
  String get back => '返回';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get basement => '地下';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER层。';
  }

  @override
  String get ground => '首层。';

  @override
  String get openDoor => '开门。';

  @override
  String get closeDoor => '关门。';

  @override
  String get pushNumber => '选择楼层。';

  @override
  String get upFloor => '上行。';

  @override
  String get downFloor => '下行。';

  @override
  String get notStop => '本层不停。';

  @override
  String get emergency => '检查电梯状态，紧急停车。';

  @override
  String get return1st => '检查已完成。返回一楼。';

  @override
  String get bypass => '跳过层';

  @override
  String get stop => '停靠层';

  @override
  String get changeNumber => '更改楼层';

  @override
  String get changeBasementNumber => '更改地下楼层';

  @override
  String get rooftop => '屋顶层。';

  @override
  String get vip => 'VIP层。';

  @override
  String get spa => '温泉层。';

  @override
  String get parking => '停车场层。';

  @override
  String get platform => '平台层。';

  @override
  String get paradise => '乐园层。';

  @override
  String get dog => '狗层。';

  @override
  String get unlock => '解锁';

  @override
  String get unlockTitle => '观看视频解锁新按钮！';

  @override
  String get unlockDesc => '\n看完视频就能使用新按钮。\n请点击「确定」！';

  @override
  String get rewardAdUnavailable => '\n现在无法播放视频。\n请检查广告同意设置，\n或稍后再试。';

  @override
  String get unlockByScore => '在30秒挑战中达成100分以上';

  @override
  String get challenge => '30秒挑战';

  @override
  String get best => '最高';

  @override
  String get yourScore => '得分';

  @override
  String get newRecord => '最高得分更新！';

  @override
  String get termsAndPrivacyPolicy => '使用条款和隐私政策';

  @override
  String get terms => '使用条款';

  @override
  String get officialPage => '官方页面';

  @override
  String get officialShop => '官方商店';

  @override
  String get ranking => '排名';

  @override
  String get premiumTitle => '高级版';

  @override
  String get premiumNoAds => '不再显示广告';

  @override
  String get premiumUnlockAll => '无需在30秒挑战中达成100个以上，\n也无需观看广告视频，\n即可使用所有设计和功能';

  @override
  String get premiumOneTime => '一次性购买';

  @override
  String premiumPrice(Object PRICE) {
    return '以$PRICE购买';
  }

  @override
  String get premiumBuy => '购买';

  @override
  String get premiumRestore => '恢复购买';

  @override
  String get premiumThanks => '感谢您！已全部解锁。';

  @override
  String get premiumFailed => '购买未能完成。';

  @override
  String get premiumRestoreFailed => '未找到可恢复的购买记录。';

  @override
  String get premiumUnavailable => '目前无法进行购买。\n请稍后再试。';
}
