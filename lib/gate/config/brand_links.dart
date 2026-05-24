import '../../core/mask_util.dart';

const List<int> _privacyMask = [14, 128, 91, 25, 227, 242, 212, 39, 238, 12, 118, 227, 45, 48, 143, 133, 181, 54, 236, 240, 169, 195, 21, 92, 229, 49, 235, 52, 186, 12, 77, 79, 166, 102, 233, 2, 88, 17, 195, 31, 49, 8, 9];
const List<int> _supportMask  = [14, 128, 91, 25, 227, 242, 212, 39, 238, 12, 118, 227, 45, 48, 143, 133, 181, 54, 236, 240, 169, 195, 21, 92, 230, 54, 242, 50, 180, 29, 64, 76, 190, 125, 232, 7];

String get brandPrivacyPageUrl => unmask(_privacyMask);
String get brandSupportPageUrl  => unmask(_supportMask);
