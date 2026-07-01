import 'dart:async';

import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:BlueEra/core/services/ads/meta_native_ad_widget.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';

/// Meta (Facebook Audience Network) counterpart of [InterstitialAdManager].
///
/// Same public surface (`initialize()` + `showInterstitial()`) so the Google
/// `InterstitialAdManager` can delegate here transparently when
/// [AdConfig.useMetaInterstitial] is on — call sites stay unchanged.
///
/// The Meta plugin exposes a single static interstitial slot: load one, wait for
/// [InterstitialAdResult.LOADED], show it, then reload on DISMISSED.
class MetaInterstitialManager {
  MetaInterstitialManager._();

  static final MetaInterstitialManager instance = MetaInterstitialManager._();

  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isShowing = false;

  /// Completes when the in-flight [_load] finishes (loaded OR failed) so
  /// [showInterstitial] can wait for a just-started load instead of giving up.
  Completer<void>? _loadCompleter;

  /// Initialise the Meta SDK and preload the first interstitial. Idempotent.
  Future<void> initialize() async {
    final ok = await MetaAds.ensureInitialized();
    print('[META_INTERSTITIAL_AD] initialize — SDK ready=$ok');
    if (!ok) return;
    _load();
  }

  /// Preload an interstitial. MUST be called after the SDK init has resolved —
  /// loading before init means the plugin never fires the load callback.
  void _load() {
    if (_isLoading || _isLoaded) return;
    _isLoading = true;
    _loadCompleter ??= Completer<void>();
    final unit = AdConfig.metaInterstitialUnit;
    print('[META_INTERSTITIAL_AD] loading unit=$unit');

    // Watchdog: if NO listener callback (LOADED/ERROR) arrives, the native side
    // never responded — log it so silence becomes an explicit signal instead of
    // an unexplained hang.
    Timer(const Duration(seconds: 12), () {
      if (_isLoading && !_isLoaded) {
        print('[META_INTERSTITIAL_AD] ⚠️ NO callback within 12s for unit=$unit '
            '— native SDK never responded (check Meta app/placement approval '
            'or plugin channel).');
      }
    });

    FacebookInterstitialAd.loadInterstitialAd(
      placementId: unit,
      listener: (result, value) {
        switch (result) {
          case InterstitialAdResult.LOADED:
            print('[META_INTERSTITIAL_AD] loaded unit=$unit');
            _isLoaded = true;
            _isLoading = false;
            _completeLoad();
            break;
          case InterstitialAdResult.ERROR:
            print('[META_INTERSTITIAL_AD] failed to load: $value');
            _isLoaded = false;
            _isLoading = false;
            _completeLoad();
            break;
          case InterstitialAdResult.DISPLAYED:
            _isShowing = true;
            break;
          case InterstitialAdResult.DISMISSED:
            // Closed by the user — free it and preload the next one.
            _isShowing = false;
            _isLoaded = false;
            FacebookInterstitialAd.destroyInterstitialAd();
            _load();
            break;
          default:
            break;
        }
      },
    ).then((accepted) {
      // The native method-channel call's own result — true means the load
      // request was accepted by the plugin (callbacks should follow).
      print('[META_INTERSTITIAL_AD] loadInterstitialAd() channel returned='
          '$accepted');
    }).catchError((e) {
      print('[META_INTERSTITIAL_AD] loadInterstitialAd() channel threw=$e');
    });
  }

  void _completeLoad() {
    final c = _loadCompleter;
    _loadCompleter = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Show the interstitial. If one isn't preloaded yet, kick off a load and wait
  /// up to [maxWait] for it before giving up. Never throws.
  Future<void> showInterstitial(
      {Duration maxWait = const Duration(seconds: 5)}) async {
    print('[META_INTERSTITIAL_AD] showInterstitial() called — '
        'isShowing=$_isShowing loaded=$_isLoaded');
    if (!AdConfig.adsEnabled) {
      print('[META_INTERSTITIAL_AD] ads disabled for this build — skipped');
      return;
    }
    final ok = await MetaAds.ensureInitialized();
    print('[META_INTERSTITIAL_AD] showInterstitial — SDK ready=$ok');
    if (!ok) return;
    if (_isShowing) {
      print('[META_INTERSTITIAL_AD] already showing — skipped');
      return;
    }

    // No ad ready yet → start a load and wait briefly for it.
    if (!_isLoaded) {
      print('[META_INTERSTITIAL_AD] no ad ready — loading and waiting up to '
          '${maxWait.inMilliseconds}ms');
      _load();
      final completer = _loadCompleter;
      if (completer != null) {
        try {
          await completer.future.timeout(maxWait);
        } catch (_) {
          // timed out — fall through; may still be unloaded
        }
      }
    }

    if (!_isLoaded) {
      print('[META_INTERSTITIAL_AD] no fill within wait — nothing to show '
          '(preloading next)');
      _load();
      return;
    }

    print('[META_INTERSTITIAL_AD] showing interstitial now');
    // _isShowing flips true on the DISPLAYED callback; DISMISSED resets state
    // and preloads the next. Clear _isLoaded now so a concurrent trigger can't
    // request the same instance twice.
    _isLoaded = false;
    try {
      await FacebookInterstitialAd.showInterstitialAd();
    } catch (e) {
      print('[META_INTERSTITIAL_AD] show threw: $e');
      _isShowing = false;
      _load();
    }
  }
}
