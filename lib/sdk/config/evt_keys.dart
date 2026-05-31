import '../../core/mask_util.dart';

String analyticsKey() {
  const v = [21, 153, 75, 7, 216, 173, 170, 123, 245, 63, 32, 197, 47, 24, 146, 185, 251, 100, 235, 144, 160, 199];
  return unmask(v);
}

String cloudMsgId() {
  const v = [94, 195, 30, 93, 167, 252, 204, 63, 164, 77, 36, 182];
  return unmask(v);
}
