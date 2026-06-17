class AdConfig {
  AdConfig._();

  /// When `true` (default), release builds use the LIVE ad units.
  /// When `false`, release builds fall back to the Google TEST units.
  static const bool useLiveAdsInRelease = true;
}


