/// AdMob unit IDs. Development uses Google's official test IDs.
///
/// TODO(production): Replace [androidAppId] and [androidInterstitialUnitId]
/// with real AdMob console values before a Play Store release. Keep the
/// test IDs for debug/profile builds if you prefer a flavor split later.
class AdConfig {
  const AdConfig._();

  /// Google sample Android App ID (safe for local/dev).
  /// Paste your real App ID in AndroidManifest `APPLICATION_ID` when ready.
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Google sample Android interstitial unit.
  static const String androidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Active interstitial unit for the running build.
  static const String interstitialAdUnitId = androidInterstitialUnitId;
}
