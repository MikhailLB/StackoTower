class StackoAssets {
  static const _gameplay = 'assets/gameplay';
  static const _splash = 'assets/splash';
  static const _noWifi = 'assets/additional_assets/no_wifi';

  static const noWifiPortrait = '$_noWifi/9x16_no_wifi_screen.webp';
  static const noWifiLandscape = '$_noWifi/16x9_no_wifi_screen.webp';

  static const sky = '$_gameplay/sky_bg.webp';
  static const ground = '$_gameplay/ground_bg.webp';
  static const cloud = '$_gameplay/cloud_01.webp';
  static const hook = '$_gameplay/crane_hook.webp';
  static const startBg = '$_gameplay/city_bg.webp';
  static const startBuilding = '$_gameplay/base_platform.webp';

  static const icon = 'assets/stacko_icon.webp';
  static const gameName = 'assets/stacko_name.webp';

  static String block(int n) =>
      '$_gameplay/block_0${n.toString().padLeft(1, '0')}.webp';

  static const allBlocks = <String>[
    '$_gameplay/block_01.webp',
    '$_gameplay/block_02.webp',
    '$_gameplay/block_03.webp',
    '$_gameplay/block_04.webp',
    '$_gameplay/block_05.webp',
    '$_gameplay/block_06.webp',
  ];

  static const splashPortrait = '$_splash/9x16_loading_screen.mp4';
  static const splashLandscape = '$_splash/16x9_loading_screen.mp4';

  static String loadingBar(int state) => '$_splash/bar_0$state.webp';
}
