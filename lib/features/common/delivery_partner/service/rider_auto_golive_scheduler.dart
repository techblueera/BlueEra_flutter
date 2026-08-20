import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';

import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../permissionCentralize/go_live_permission_service.dart';
import '../../../account_plan/controller/account_plan_entitlement.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../controller/delivery_partner_controller.dart';
import '../repo/delivery_partner_repo.dart';

/// Best-effort **client-side** daily auto go-live for riders.
///
/// Once a rider goes live manually for the first time (after clearing the two
/// gates — document verification + security-deposit payment), we opt them into
/// a recurring daily window: each day **08:00–22:00** (8 AM until 10 PM) the
/// app auto-opens go-live and auto-closes afterwards.
///
/// IMPORTANT — this is BEST-EFFORT only. A Dart [Timer] runs solely while the
/// app is alive (foreground / short background); if the rider's app is killed at
/// 08:00 nothing fires here. The **authoritative** daily open/close must be a
/// backend cron — see `docs/backend/RIDER_GO_LIVE_GUIDE.md`. The app
/// merely reflects the server status on launch/resume
/// (`ViewPersonalDetailsController.restoreProviderLiveState`); this scheduler
/// just reinforces it while the app happens to be open.
///
/// Guards baked in:
///  • never opens an unverified / unpaid rider (re-checks the same two gates);
///  • never auto-opens without the required permissions already granted (it
///    can't prompt in the background);
///  • respects a manual opt-out — if the rider taps offline during the window,
///    it won't re-open until the next day;
///  • only auto-closes a session **it** opened — a manual or mid-delivery
///    session is never force-closed;
///  • auto-closes its own session the moment a go-live gate stops holding
///    (deposit/payment expiry, verification loss, window end, manual-off), so a
///    rider is never left auto-live once they'd fail the manual go-live check.
class RiderAutoGoLiveScheduler {
  RiderAutoGoLiveScheduler._();
  static final RiderAutoGoLiveScheduler _instance =
      RiderAutoGoLiveScheduler._();
  factory RiderAutoGoLiveScheduler() => _instance;

  /// Window bounds as minutes-from-midnight in DEVICE LOCAL time. The backend
  /// cron should use IST (Asia/Kolkata) to match this.
  static const int _windowStartMin = 8 * 60; //  08:00
  static const int _windowEndMin = 22 * 60; //   22:00 (10 PM, end-exclusive)

  static const Duration _tickInterval = Duration(minutes: 1);

  Timer? _timer;
  bool _started = false;

  /// Guards the launch reconcile so the schedule GET runs at most once per app
  /// session, not on every rider-screen mount that calls
  /// [ensureStartedIfEnabled].
  bool _reconciledThisSession = false;

  /// True while the CURRENT live session was opened by this scheduler — so we
  /// only auto-close what we auto-opened (in-memory; a restart mid-window loses
  /// it, and the backend cron is the authoritative closer — by design).
  bool _autoOpenedThisSession = false;

  // Persistence keys scoped per user so accounts don't cross-contaminate.
  String get _enabledKey => 'rider_auto_golive_enabled_$userId';
  String get _manualOffKey => 'rider_auto_golive_manual_off_$userId';

  // ── In-memory cache of the two persisted flags ─────────────────────────────
  // Secure storage stays the source of truth (every change is still written to
  // it), but reads hit the Keystore/Keychain over a platform channel — far too
  // expensive to do on every evaluator tick. We load both flags into memory once
  // per session and keep the copies in sync on each write, so the per-tick hot
  // path never touches secure storage.
  bool? _enabledCache; // null until first load
  String? _manualOffCache; // day-key ('yyyy-MM-dd') the rider opted out on, or null
  bool _cacheLoaded = false;

  /// Lazily hydrate the in-memory flags from secure storage — runs its reads at
  /// most once per session (subsequent calls are a no-op).
  Future<void> _ensureCacheLoaded() async {
    if (_cacheLoaded) return;
    _enabledCache =
        (await SharedPreferenceUtils.getSecureValue(_enabledKey)) == 'true';
    _manualOffCache = await SharedPreferenceUtils.getSecureValue(_manualOffKey);
    _cacheLoaded = true;
  }

  /// Whether the rider has opted into the daily auto window (in-memory copy).
  Future<bool> isEnabled() async {
    await _ensureCacheLoaded();
    return _enabledCache ?? false;
  }

  /// Start the 1-minute evaluator only if the rider is already opted in. Safe to
  /// call from any rider surface's initState (idempotent).
  Future<void> ensureStartedIfEnabled() async {
    if (_started) {
      log('[RiderAutoGoLive] ensureStartedIfEnabled: already started this session — skip');
      return;
    }
    // Reconcile the opt-in with the server before deciding — covers reinstall /
    // second device where the local flag is missing but the server has the
    // rider opted in (or vice-versa). Server `enabled` is authoritative.
    await _reconcileEnabledFromServer();
    final enabled = await isEnabled();
    log('[RiderAutoGoLive] ensureStartedIfEnabled: enabled=$enabled '
        '(window ${_windowStartMin ~/ 60}:00–${_windowEndMin ~/ 60}:00, now=${_nowLabel()})');
    if (!enabled) {
      log('[RiderAutoGoLive] not opted in → scheduler NOT started');
      return;
    }
    _start();
  }

  /// Called after the rider's FIRST successful manual go-live — opts them into
  /// the daily auto window from the next day on and starts the evaluator.
  Future<void> enableAfterManualGoLive() async {
    log('[RiderAutoGoLive] enableAfterManualGoLive: opting rider in for daily '
        'auto window (from tomorrow), now=${_nowLabel()}');
    _enabledCache = true; // keep the in-memory copy in sync
    _cacheLoaded = true;
    await SharedPreferenceUtils.setSecureValue(_enabledKey, 'true');
    // Tell the backend cron the rider opted in. Fire-and-forget: until the PUT
    // lands the cron simply doesn't know about the rider (behaves like today);
    // the next launch's reconcile heals a missed sync.
    _syncToServer({'enabled': true});
    _start();
  }

  /// Stop the evaluator (e.g. on logout). The opt-in flag persists, so the
  /// scheduler resumes for the same rider on the next session.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
    _autoOpenedThisSession = false;
    // Allow the next session (e.g. after re-login) to reconcile with the
    // server again.
    _reconciledThisSession = false;
    // Drop the cached flags so the next session (possibly a DIFFERENT user —
    // the keys are per-userId) reloads them fresh from secure storage.
    _cacheLoaded = false;
    _enabledCache = null;
    _manualOffCache = null;
  }

  /// Record that the rider manually went offline during the window, so the
  /// evaluator won't fight them by re-opening for the rest of today.
  Future<void> noteManualOffDuringWindow() async {
    if (!_inWindow(DateTime.now())) {
      log('[RiderAutoGoLive] manual offline outside window (now=${_nowLabel()}) '
          '— no opt-out recorded');
      return;
    }
    _autoOpenedThisSession = false;
    log('[RiderAutoGoLive] manual offline INSIDE window (now=${_nowLabel()}) '
        '— suppressing auto-open for the rest of ${_todayKey()}');
    _manualOffCache = _todayKey(); // keep the in-memory copy in sync
    await SharedPreferenceUtils.setSecureValue(_manualOffKey, _todayKey());
    // Mirror the opt-out to the server so the cron won't re-open the rider for
    // the rest of today (IST). Fire-and-forget — the local flag already blocks
    // this client; the PUT keeps the authoritative cron in sync.
    _syncToServer({'manualOffToday': true});
  }

  /// PUT an auto-go-live change to the backend. Fire-and-forget: never blocks
  /// the caller and never throws — the local flags are the source of truth for
  /// THIS client, and the server sync is best-effort (retried on next launch).
  Future<void> _syncToServer(Map<String, dynamic> params) async {
    try {
      await DeliveryPartnerRepo().updateRiderAutoGoLiveRepo(params: params);
    } catch (e) {
      log('[RiderAutoGoLive] server sync failed for $params: $e');
    }
  }

  /// GET the server schedule and let its `enabled` win over the local flag.
  /// Best-effort — on any failure we keep the local flag as-is. Runs at most
  /// once per session (see [_reconciledThisSession]).
  Future<void> _reconcileEnabledFromServer() async {
    if (_reconciledThisSession) return;
    _reconciledThisSession = true;
    try {
      final res = await DeliveryPartnerRepo().getRiderAutoGoLiveRepo();
      if (!res.isSuccess) return;
      final body = res.response?.data;
      final schedule = (body is Map) ? body['data'] : null;
      if (schedule is Map && schedule['enabled'] != null) {
        final serverEnabled = schedule['enabled'] == true;
        log('[RiderAutoGoLive] reconcile: server enabled=$serverEnabled '
            '(overwriting local flag)');
        _enabledCache = serverEnabled; // keep the in-memory copy in sync
        _cacheLoaded = true;
        await SharedPreferenceUtils.setSecureValue(
            _enabledKey, serverEnabled ? 'true' : 'false');
      } else {
        log('[RiderAutoGoLive] reconcile: server returned no `enabled` — '
            'keeping local flag as-is');
      }
    } catch (e) {
      log('[RiderAutoGoLive] enabled reconcile failed: $e');
    }
  }

  // ── internals ──────────────────────────────────────────────
  void _start() {
    if (_started) return;
    _started = true;
    log('[RiderAutoGoLive] scheduler STARTED — evaluating every '
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
        log('[RiderAutoGoLive] tick@${_nowLabel()}: not enabled → skip');
        return;
      }
      if (!Get.isRegistered<ViewPersonalDetailsController>()) {
        log('[RiderAutoGoLive] tick@${_nowLabel()}: ViewPersonalDetailsController '
            'not registered → skip');
        return;
      }
      if (!Get.isRegistered<DeliveryPartnerController>()) {
        log('[RiderAutoGoLive] tick@${_nowLabel()}: DeliveryPartnerController '
            'not registered → skip');
        return;
      }

      final viewCtrl = Get.find<ViewPersonalDetailsController>();
      final riderCtrl = Get.find<DeliveryPartnerController>();

      // ── Evaluate the SAME go-live gates as the manual tap (handleGoLiveTap):
      //    verification (onboarding) + security deposit. These decide
      //    eligibility both for auto-OPENing and for keeping an auto-opened
      //    session alive.
      final verified =
          riderCtrl.riderVerificationState == RiderVerificationState.completed;
      // Payment terms, identical to the manual tap (handleGoLiveTap) — no
      // profession check there and none here, since only GIG_WORKER accounts
      // ever opt into this scheduler. Waived while the worker's FIRST JOB is
      // still free, so the scheduler never auto-closes someone who would pass
      // the manual gate.
      final depositBlocked = !AccountPlanEntitlement.to.hasActivePlan.value &&
          !riderCtrl.isFirstRideFree &&
          !riderCtrl.isSecurityDepositPaid;
      final eligible = verified && !depositBlocked;

      final inWindow = _inWindow(DateTime.now());
      final isOpen = viewCtrl.shopStatusOpenClose.value;
      final manualOffToday = _manualOffCache == _todayKey();
      log('[RiderAutoGoLive] tick@${_nowLabel()}: eligible=$eligible '
          '(verified=$verified depositBlocked=$depositBlocked) inWindow=$inWindow '
          'isOpen=$isOpen autoOpened=$_autoOpenedThisSession '
          'manualOffToday=$manualOffToday');

      // ── CASE 1: a session WE auto-opened is currently live. Keep it live only
      //    while it should be (gates still pass, still in window, not manually
      //    turned off). Otherwise force it offline — this covers payment expiry
      //    / verification loss / window end / mid-window manual-off. We only ever
      //    touch a session THIS scheduler opened, never a manual/mid-delivery one.
      if (isOpen && _autoOpenedThisSession) {
        final shouldStayLive = eligible && inWindow && !manualOffToday;
        if (shouldStayLive) return; // all good — leave it live
        _autoOpenedThisSession = false;
        final why = !eligible
            ? (verified ? 'deposit/payment no longer valid' : 'not verified')
            : (!inWindow ? 'window ended' : 'manually turned off today');
        log('[RiderAutoGoLive] auto-session no longer valid ($why) → '
            'GOING OFFLINE (auto-close)');
        await viewCtrl.toggleShopOnlyStatus(isActive: false);
        return;
      }

      // ── CASE 2: already live but WE did not open it (manual / mid-delivery).
      //    Never force-close a session the rider owns.
      if (isOpen) {
        log('[RiderAutoGoLive] live session not auto-opened → leaving untouched');
        return;
      }

      // ── CASE 3: currently offline → decide whether to auto-OPEN. Requires all
      //    the same gates as a manual go-live to hold.
      //
      // Idempotency guard: if we ALREADY auto-opened this session, never fire the
      // go-live API again — even if the local status flag momentarily reads
      // closed (a transient status refresh, screen re-entry, etc.). The open API
      // is sent exactly ONCE per auto-session; the flag is cleared only when we
      // close it (Case 1) or the rider manually turns off.
      if (_autoOpenedThisSession) {
        log('[RiderAutoGoLive] already auto-opened this session → skip duplicate '
            'open API');
        return;
      }
      if (!eligible) {
        log('[RiderAutoGoLive] not eligible '
            '(verified=$verified depositBlocked=$depositBlocked) → skip open');
        return;
      }
      if (!inWindow) return; // outside 08:00–22:00 — nothing to open
      if (manualOffToday) {
        log('[RiderAutoGoLive] manual opt-out active for ${_todayKey()} → '
            'skip auto-open');
        return;
      }
      // Can't prompt for permissions in the background — only auto-open when
      // everything is already granted.
      if (!await GoLivePermissionService.areRequiredGranted()) {
        log('[RiderAutoGoLive] required permissions NOT granted → skip '
            'auto-open (cannot prompt in background)');
        return;
      }
      _autoOpenedThisSession = true;
      log('[RiderAutoGoLive] window open + gates pass → GOING LIVE (auto)');
      await viewCtrl.toggleShopOnlyStatus(isActive: true);
    } catch (e) {
      // Best-effort — never let a tick throw. Backend cron is the safety net.
      log('[RiderAutoGoLive] evaluate error: $e');
    }
  }
}
