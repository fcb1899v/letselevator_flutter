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
  String get thisApp => '这款应用是一个真实的电梯模拟器。';

  @override
  String get openDoor => '开门。';

  @override
  String get closeDoor => '关门。';

  @override
  String get basement => '地下';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER层。';
  }

  @override
  String get ground => '地面层。';

  @override
  String get rooftop => '屋顶。';

  @override
  String get platform => '平台层。　';

  @override
  String get dog => '狗。';

  @override
  String get spa => '温泉。';

  @override
  String get vip => 'VIP层。';

  @override
  String get parking => '停车场。';

  @override
  String get paradise => '乐园。';

  @override
  String get pushNumber => '请按楼层按钮。';

  @override
  String get upFloor => '向上前往。';

  @override
  String get downFloor => '向下前往。';

  @override
  String get notStop => '本层不停车。';

  @override
  String get emergency => '为了检查电梯状态，将进行紧急停车。';

  @override
  String get return1st => '检查完成。返回一层。';

  @override
  String get settings => '设置';

  @override
  String get changeNumber => '更改楼层';

  @override
  String get changeBasementNumber => '更改地下楼层';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get bypass => '经过层';

  @override
  String get stop => '停止层';

  @override
  String get menu => '菜单';

  @override
  String get normalMode => '标准模式';

  @override
  String get elevatorMode => '电梯模式';

  @override
  String get buttonsMode => '1000个\n按钮模式';

  @override
  String get reproButtons => '再现!\n1000个\n按钮';

  @override
  String get aboutShimax => '关于\n岛田电器\n制造所';

  @override
  String get aboutButtons => '关于\n1000个\n按钮';

  @override
  String get aboutLetsElevator => '关于操作乐趣电梯';

  @override
  String get termsAndPrivacyPolicy => '使用条款和隐私政策';

  @override
  String get terms => '使用条款';

  @override
  String get officialPage => '官方页面';

  @override
  String get officialShop => '官方商店';

  @override
  String get start => '开始';

  @override
  String get challenge => '30秒挑战';

  @override
  String get best => '最高 ';

  @override
  String get challengeRanking => '30秒\n挑战\n排名';

  @override
  String get ranking => '排名';

  @override
  String get yourScore => '得分';

  @override
  String get back => '返回';

  @override
  String get newRecord => '最高得分更新！';

  @override
  String get unlock => '解锁';

  @override
  String get unlockTitle => '观看视频解锁新按钮！';

  @override
  String get unlockDesc => '\n看完视频就能使用新按钮。\n请点击「确定」！';

  @override
  String get unlockAllTitle => '解锁条件：1.或2.';

  @override
  String get unlockAll1 => '1. 在30秒挑战中达成100个以上！';

  @override
  String get unlockAll2 => '2. 解锁所有按钮形状!!';
}
