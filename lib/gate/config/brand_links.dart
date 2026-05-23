import '../../core/mask_util.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TODO: run tool/encode_creds.dart and paste byte arrays here
/// ════════════════════════════════════════════════════════════

// TODO: paste encoded privacy URL bytes here
const List<int> _privacyMask = [];
// TODO: paste encoded support URL bytes here
const List<int> _supportMask = [];

String get brandPrivacyPageUrl => unmask(_privacyMask);
String get brandSupportPageUrl  => unmask(_supportMask);
