import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';

import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../permissionCentralize/go_live_permission_service.dart';
import '../../auth/controller/view_personal_details_controller.dart';

/// Best-effort **client-side** daily auto go-live for self-employed / selfWork
/// providers — the individual analogue of [RiderAutoGoLiveScheduler].
///
/// Once a provider goes live manually for the first time (after clearing the
/// security-deposit gate — or while their first service is still free), we opt
/// them into a recurring daily window: each day **08:00–22:00** (8 AM until
/// 10 PM) the app auto-opens go-live and auto-closes afterwards.
///
/// IMPORTANT — this is BEST-EFFORT only. A Dart [Timer] runs solely while the
/// app is alive (foreground / short background); if the app is killed at 08:00
/// nothing fires here. Unlike the rider scheduler there is no backend cron for
/// self-work yet, so this is purely a while-the-app-is-open convenience.
///
/// Guards baked in (mirror the MANUAL go-live gate in SelfEmployeeScreen):
///  • never opens a provider whose deposit is required-but-unpaid AND whose
///    first-service-free waiver is used up (re-checks `canGoLive` /
///    `isFirstServiceFree` every tick);
///  • never auto-opens without the required permissions already granted (it
///    can't prompt in the background);
///  • respects a manual opt-out — if the provider taps offline during the
///    window, it won't re-open until the next day;
///  • only auto-closes a session **it** opened — a manual session is never
///    force-closed;
///  • auto-closes its own session the moment the go-live gate stops holding
///    (deposit/payment expiry, window end, manual-off), so a provider is never
///    left auto-live once they'd fail the manual go-live check.
class SelfWorkAutoGoLiveScheduler {
  SelfWorkAutoGoLiveScheduler._();
  static final SelfWorkAutoGoLiveScheduler _instance =
      SelfWorkAutoGoLiveScheduler._();
  factory SelfWorkAutoGoLiveScheduler() => _instance;

  /// Window bounds as minutes-from-midnight in DEVICE LOCAL time.
  static const int _windowStartMin = 8 * 60; //  08:00
  static const int _windowEndMin = 22 * 60; //   22:00 (10 PM, end-exclusive)

  static const Duration _tickInterval = Duration(minutes: 1);

  Timer? _timer;
  bool _started = false;

  /// True while the CURRENT live session was opened by this scheduler — so we
  /// only auto-close what we auto-opened (in-memory; a restart mid-window loses
  /// it, by design).
  bool _autoOpenedThisSession = false;

  // Persistence keys scoped per user so accounts don't cross-contaminate.
  String get _enabledKey => 'selfwork_auto_golive_enabled_$userId';
  String get _manualOffKey => 'selfwork_auto_golive_manual_off_$userId';

  // ── In-memory cache of the two persisted flags (see the rider scheduler for
  // the rationale — avoids a Keystore/Keychain read on every evaluator tick).
  bool? _enabledCache; // null until first load
  String? _manualOffCache; // day-key ('yyyy-MM-dd') opted out on, or null
  bool _cacheLoaded = false;

  Future<void> _ensureCacheLoaded() async {
    if (_cacheLoaded) return;
    _enabledCache =
        (await SharedPreferenceUtils.getSecureValue(_enabledKey)) == 'true';
    _manualOffCache = await SharedPreferenceUtils.getSecureValue(_manualOffKey);
    _cacheLoaded = true;
  }

  /// Whether the provider has opted into the daily auto window (in-memory copy).
  Future<bool> isEnabled() async {
    await _ensureCacheLoaded();
    return _enabledCache ?? false;
  }

  /// Start the evaluator only if the provider is already opted in. Safe to call
  /// from any self-work surface's initState (idempotent).
  Future<void> ensureStartedIfEnabled() async {
    if (_started) {
      log('[SelfWorkAutoGoLive] ensureStartedIfEnabled: already started this '
          'session — skip');
      return;
    }
    final enabled = await isEnabled();
    log('[SelfWorkAutoGoLive] ensureStartedIfEnabled: enabled=$enabled '
        '(window ${_windowStartMin ~/ 60}:00–${_windowEndMin ~/ 60}:00, '
        'now=${_nowLabel()})');
    if (!enabled) {
      log('[SelfWorkAutoGoLive] not opted in → scheduler NOT started');
      return;
    }
    _start();
  }

  /// Called after the provider's FIRST successful manual go-live — opts them
  /// into the daily auto window from the next day on and starts the evaluator.
  Future<void> enableAfterManualGoLive() async {
    log('[SelfWorkAutoGoLive] enableAfterManualGoLive: opting provider in for '
        'daily auto window (from tomorrow), now=${_nowLabel()}');
    _enabledCache = true; // keep the in-memory copy in sync
    _cacheLoaded = true;
    await SharedPreferenceUtils.setSecureValue(_enabledKey, 'true');
    _start();
  }

  /// Stop the evaluator (e.g. on logout). The opt-in flag persists, so the
  /// scheduler resumes for the same provider on the next session.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
    _autoOpenedThisSession = false;
    // Drop the cached flags so the next session (possibly a DIFFERENT user —
    // the keys are per-userId) reloads them fresh from secure storage.
    _cacheLoaded = false;
    _enabledCache = null;
    _manualOffCache = null;
  }

  /// Record that the provider manually went offline during the window, so the
  /// evaluator won't fight them by re-opening for the rest of today.
  Future<void> noteManualOffDuringWindow() async {
    if (!_inWindow(DateTime.now())) {
      log('[SelfWorkAutoGoLive] manual offline outside window '
          '(now=${_nowLabel()}) — no opt-out recorded');
      return;
    }
    _autoOpenedThisSession = false;
    log('[SelfWorkAutoGoLive] manual offline INSIDE window (now=${_nowLabel()}) '
        '— suppressing auto-open for the rest of ${_todayKey()}');
    _manualOffCache = _todayKey(); // keep the in-memory copy in sync
    await SharedPreferenceUtils.setSecureValue(_manualOffKey, _todayKey());
  }

  // ── internals ──────────────────────────────────────────────
  void _start() {
    if (_started) return;
    _started = true;
    log('[SelfWorkAutoGoLive] scheduler STARTED — evaluating every '
        '${_tickInterval.inMinutes} min, now=${_nowLabel()}');
    _evaluate();
    _timer = Timer.periodic(_tickInterval, (_) => _evaluate());
  }

  bool _inWindow(DateTime now) {
    final m = now.hour * 60 + now.minute;
    return m >= _windowStartMin && m < _windowEndMin;
  }

  String _todayKey() {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  /// Human-readable local timestamp for logs, e.g. `2026-07-16 09:07`.
  String _nowLabel() {
    final n = DateTime.now();
    final hh = n.hour.toString().padLeft(2, '0');
    final min = n.minute.toString().padLeft(2, '0');
    return '${_todayKey()} $hh:$min';
  }

  Future<void> _evaluate() async {
    try {
      if (!await isEnabled()) {
        log('[SelfWorkAutoGoLive] tick@${_nowLabel()}: not enabled → skip');
        return;
      }
      if (!Get.isRegistered<ViewPersonalDetailsController>()) {
        log('[SelfWorkAutoGoLive] tick@${_nowLabel()}: '
            'ViewPersonalDetailsController not registered → skip');
        return;
      }

      final viewCtrl = Get.find<ViewPersonalDetailsController>();

      // ── Evaluate the SAME go-live gate as the manual tap (_handleGoLiveTap):
      //    the security deposit must be paid (canGoLive) OR the first-service-
      //    free waiver still applies (isFirstServiceFree).
      final eligible = viewCtrl.canGoLive || viewCtrl.isFirstServiceFree;

      final inWindow = _inWindow(DateTime.now());
      final isOpen = viewCtrl.shopStatusOpenClose.value;
      final manualOffToday = _manualOffCache == _todayKey();
      log('[SelfWorkAutoGoLive] tick@${_nowLabel()}: eligible=$eligible '
          '(canGoLive=${viewCtrl.canGoLive} '
          'firstServiceFree=${viewCtrl.isFirstServiceFree}) inWindow=$inWindow '
          'isOpen=$isOpen autoOpened=$_autoOpenedThisSession '
          'manualOffToday=$manualOffToday');

      // ── CASE 1: a session WE auto-opened is currently live. Keep it live only
      //    while it should be (gate still passes, still in window, not manually
      //    turned off). Otherwise force it offline — covers payment expiry /
      //    window end / mid-window manual-off. We only ever touch a session THIS
      //    scheduler opened, never a manual one.
      if (isOpen && _autoOpenedThisSession) {
        final shouldStayLive = eligible && inWindow && !manualOffToday;
        if (shouldStayLive) return; // all good — leave it live
        _autoOpenedThisSession = false;
        final why = !eligible
            ? 'deposit/payment no longer valid'
            : (!inWindow ? 'window ended' : 'manually turned off today');
        log('[SelfWorkAutoGoLive] auto-session no longer valid ($why) → '
            'GOING OFFLINE (auto-close)');
        await viewCtrl.toggleShopOnlyStatus(isActive: false);
        return;
      }

      // ── CASE 2: already live but WE did not open it (manual). Never touch it.
      if (isOpen) {
        log('[SelfWorkAutoGoLive] live session not auto-opened → leaving '
            'untouched');
        return;
      }

      // ── CASE 3: currently offline → decide whether to auto-OPEN.
      //
      // Idempotency guard: if we ALREADY auto-opened this session, never fire
      // the go-live API again — even if the local status flag momentarily reads
      // closed. Sent exactly ONCE per auto-session; cleared only on close.
      if (_autoOpenedThisSession) {
        log('[SelfWorkAutoGoLive] already auto-opened this session → skip '
            'duplicate open API');
        return;
      }
      if (!eligible) {
        log('[SelfWorkAutoGoLive] not eligible (canGoLive=${viewCtrl.canGoLive} '
            'firstServiceFree=${viewCtrl.isFirstServiceFree}) → skip open');
        return;
      }
      if (!inWindow) return; // outside 08:00–22:00 — nothing to open
      if (manualOffToday) {
        log('[SelfWorkAutoGoLive] manual opt-out active for ${_todayKey()} → '
            'skip auto-open');
        return;
      }
      // Can't prompt for permissions in the background — only auto-open when
      // everything is already granted.
      if (!await GoLivePermissionService.areRequiredGranted()) {
        log('[SelfWorkAutoGoLive] required permissions NOT granted → skip '
            'auto-open (cannot prompt in background)');
        return;
      }
      _autoOpenedThisSession = true;
      log('[SelfWorkAutoGoLive] window open + gate passes → GOING LIVE (auto)');
      await viewCtrl.toggleShopOnlyStatus(isActive: true);
    } catch (e) {
      // Best-effort — never let a tick throw.
      log('[SelfWorkAutoGoLive] evaluate error: $e');
    }
  }
}
