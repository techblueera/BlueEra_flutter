import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/ad_config.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/material.dart';

/// Renders a Meta (Facebook Audience Network) native ad.
///
/// Same public shape (height + card chrome) as `NativeAdWidget`, which delegates
/// to it — so every native slot in the app (feed + grocery) renders a Meta
/// native ad with no changes at the call sites.
///
/// Shows nothing while loading, and collapses to zero
/// height if the ad fails so the surrounding list looks unaffected.
class MetaNativeAdWidget extends StatefulWidget {
  const MetaNativeAdWidget({
    super.key,
    this.height = 140,
    this.borderRadius = 12,
    this.bottomGap,
    this.margin,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  final double height;
  final double borderRadius;
  final double? bottomGap;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;

  @override
  State<MetaNativeAdWidget> createState() => _MetaNativeAdWidgetState();
}

class _MetaNativeAdWidgetState extends State<MetaNativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  bool _failed = false;

  /// True once the Meta SDK init has resolved — we only build the
  /// [FacebookNativeAd] after this, otherwise the plugin loads before init and
  /// the ad silently never calls back.
  bool _sdkReady = false;

  /// True once ANY listener callback (LOADED/ERROR/…) has fired. Used by the
  /// watchdog to detect the "native SDK never responded" case.
  bool _gotCallback = false;
  Timer? _watchdog;

  /// Gated mount: every native slot shares the SAME placement id, so mounting
  /// several at once (or rapidly re-entering a screen) reloads that placement
  /// back-to-back → Meta error 1002 "Ad was re-loaded too frequently". We only
  /// build the [FacebookNativeAd] once this slot's turn in the load gate is up.
  bool _mountAd = false;

  /// This slot's spot in the shared load queue. Cancelled on dispose so a slot
  /// scrolled past before its turn frees the queue instead of wasting a slot.
  _GateHandle? _gateHandle;

  // Keep the loaded ad alive across scroll recycling (mirrors the Google slot)
  // so we don't reload and burn impressions each time it scrolls back in.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Master kill-switch — collapse if ads are disabled for this build.
    if (!AdConfig.adsEnabled) {
      print('[META_NATIVE_AD] ads disabled for this build — collapsing slot');
      _failed = true;
      return;
    }
    print('[META_NATIVE_AD] initState — awaiting SDK init, '
        'unit=${AdConfig.metaNativeUnit}');
    MetaAds.ensureInitialized().then((ok) {
      print('[META_NATIVE_AD] SDK ready=$ok — building native ad '
          'unit=${AdConfig.metaNativeUnit}');
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _sdkReady = true;
          _failed = true; // init failed → nothing to show
        });
        return;
      }
      setState(() => _sdkReady = true);

      // Queue this slot's load behind any others for the same placement so two
      // loads never start too close together (Meta 1002). The handle is
      // cancelled in dispose(), so a slot the user scrolls past before its turn
      // is dropped from the queue and costs no spacing time.
      _gateHandle = _MetaNativeLoadGate.request(() {
        if (!mounted) return;
        _startWatchdog();
        setState(() => _mountAd = true);
      });
    });
  }

  void _startWatchdog() {
    // Watchdog: if the FacebookNativeAd never fires a listener callback, the
    // native side never responded — log it so silence is explicit.
    _watchdog = Timer(const Duration(seconds: 12), () {
      if (!_gotCallback) {
        print('[META_NATIVE_AD] ⚠️ NO callback within 12s for '
            'unit=${AdConfig.metaNativeUnit} — native SDK never responded '
            '(check Meta app/placement approval or plugin channel).');
      }
    });
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _gateHandle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    if (_failed) return const SizedBox.shrink();

    return Padding(
      padding: widget.margin ??
          EdgeInsets.only(bottom: widget.bottomGap ?? SizeConfig.size10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
          boxShadow: widget.boxShadow,
        ),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          // Only mount the ad once the SDK is initialised AND the load gate
          // has cleared this slot (staggered to avoid Meta 1002).
          child: (!_sdkReady || !_mountAd)
              ? null
              : FacebookNativeAd(
                  placementId: AdConfig.metaNativeUnit,
                  adType: NativeAdType.NATIVE_AD,
                  width: double.infinity,
                  height: widget.height,
                  backgroundColor: widget.backgroundColor ?? AppColors.white,
                  titleColor: AppColors.mainTextColor,
                  descriptionColor: AppColors.secondaryTextColor,
                  buttonColor: AppColors.primaryColor,
                  buttonTitleColor: AppColors.white,
                  buttonBorderColor: AppColors.primaryColor,
                  // Keep the reserved box while loading so the list doesn't
                  // jump; the listener collapses it only on a hard error.
                  // keepAlive keeps the loaded ad across scroll recycling.
                  keepExpandedWhileLoading: true,
                  keepAlive: true,
                  listener: (result, value) {
                    _gotCallback = true;
                    print('[META_NATIVE_AD] $result '
                        'unit=${AdConfig.metaNativeUnit} value=$value');
                    if (result == NativeAdResult.ERROR && mounted) {
                      setState(() => _failed = true);
                    }
                  },
                ),
        ),
      ),
    );
  }
}

/// One-time initialiser for the Meta Audience Network SDK. Idempotent — the
/// first native/interstitial slot awaits it; the init runs exactly once and
/// every caller shares the same Future.
///
/// IMPORTANT: ad loads MUST await this. Calling `loadInterstitialAd` /
/// building `FacebookNativeAd` before `init()` resolves means the plugin's
/// method channel never calls back (you see "loading" but no LOADED/ERROR).
class MetaAds {
  MetaAds._();

  static Future<bool>? _initFuture;

  static Future<bool> ensureInitialized() =>
      _initFuture ??= _init();

  static Future<bool> _init() async {
    print('[META_ADS] init start (testMode=${AdConfig.metaTestMode})');
    try {
      // No testingId: test ads come from the reserved magic placement tokens
      // (see AdConfig.metaNativeUnit), which work on any device without
      // registering a device hash. Passing a bogus hash here does nothing.
      final res = await FacebookAudienceNetwork.init(
        iOSAdvertiserTrackingEnabled: true,
      );
      print('[META_ADS] init result=$res');
      return res ?? false;
    } catch (e, st) {
      print('[META_ADS] init FAILED: $e\n$st');
      return false;
    }
  }
}

/// App-wide load gate for the (single) Meta native placement.
///
/// Every native slot uses the same `AdConfig.metaNativeUnit`, so loading several
/// at once — or rapidly re-entering/scrolling a screen — reloads that placement
/// back-to-back and Meta returns error 1002 ("Ad was re-loaded too frequently").
///
/// This is a CANCELLABLE QUEUE, not a fire-and-forget reservation. Slots are
/// granted their load in FIFO order, never less than [_minInterval] apart. A
/// slot disposed before its turn ([_GateHandle.cancel]) is dropped and costs no
/// spacing time — critical under fast scrolling, where an absolute-time
/// reservation would let every flung-past slot burn a 15s window and push the
/// next on-screen ad minutes into the future.
class _MetaNativeLoadGate {
  _MetaNativeLoadGate._();

  /// Minimum spacing between the START of two loads of the same placement.
  static const Duration _minInterval = Duration(seconds: 15);

  /// When the most recent load was actually granted (null until the first).
  static DateTime? _lastGrant;

  /// FIFO of slots still waiting for their turn to load.
  static final List<_GateWaiter> _queue = [];

  /// Timer that will dispatch the next waiter; null when idle.
  static Timer? _pump;

  /// Enqueue a load request. [onGranted] fires once when this slot may load.
  /// Cancel via the returned handle if the slot is disposed first.
  static _GateHandle request(VoidCallback onGranted) {
    final waiter = _GateWaiter(onGranted);
    _queue.add(waiter);
    _schedulePump();
    return _GateHandle._(waiter);
  }

  static void _schedulePump() {
    if (_pump != null || _queue.isEmpty) return;
    final now = DateTime.now();
    final earliest = _lastGrant?.add(_minInterval) ?? now;
    final wait = earliest.isAfter(now) ? earliest.difference(now) : Duration.zero;
    _pump = Timer(wait, _dispatch);
  }

  static void _dispatch() {
    _pump = null;
    // Skip slots disposed while waiting — they cost no spacing time.
    while (_queue.isNotEmpty && _queue.first.cancelled) {
      _queue.removeAt(0);
    }
    if (_queue.isEmpty) return;
    final waiter = _queue.removeAt(0);
    _lastGrant = DateTime.now();
    waiter.onGranted();
    _schedulePump(); // arm the next one, if any remain
  }
}

/// A single queued load request. [cancelled] is flipped when its slot is
/// disposed before being granted, so [_MetaNativeLoadGate._dispatch] skips it.
class _GateWaiter {
  _GateWaiter(this.onGranted);
  final VoidCallback onGranted;
  bool cancelled = false;
}

/// Handle returned by [_MetaNativeLoadGate.request] so a slot can withdraw its
/// pending load on dispose.
class _GateHandle {
  _GateHandle._(this._waiter);
  final _GateWaiter _waiter;
  void cancel() => _waiter.cancelled = true;
}
