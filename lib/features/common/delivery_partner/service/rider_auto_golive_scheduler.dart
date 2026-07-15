import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../permissionCentralize/go_live_permission_service.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../controller/delivery_partner_controller.dart';
import '../repo/delivery_partner_repo.dart';

/// Best-effort **client-side** daily auto go-live for riders.
///
/// Once a rider goes live manually for the first time (after clearing the two
/// gates — document verification + security-deposit payment), we opt them into
/// a recurring daily window: each day **10:00–12:00** the app auto-opens go-live
/// and auto-closes afterwards.
///
/// IMPORTANT — this is BEST-EFFORT only. A Dart [Timer] runs solely while the
/// app is alive (foreground / short background); if the rider's app is killed at
/// 10:00 nothing fires here. The **authoritative** daily open/close must be a
/// backend cron — see `docs/backend/RIDER_AUTO_GOLIVE_SCHEDULE_GUIDE.md`. The app
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
///  • only auto-closes a session **it** opened, so a manual or mid-delivery
///    session is never force-closed at 12:00.
class RiderAutoGoLiveScheduler {
  RiderAutoGoLiveScheduler._();
  static final RiderAutoGoLiveScheduler _instance =
      RiderAutoGoLiveScheduler._();
  factory RiderAutoGoLiveScheduler() => _instance;

  /// Window bounds as minutes-from-midnight in DEVICE LOCAL time. The backend
  /// cron should use IST (Asia/Kolkata) to match this.
  static const int _windowStartMin = 10 * 60; // 10:00
  static const int _windowEndMin = 12 * 60; //   12:00

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

  /// Whether the rider has opted into the daily auto window.
  Future<bool> isEnabled() async {
    final v = await SharedPreferenceUtils.getSecureValue(_enabledKey);
    return v == 'true';
  }

  /// Start the 1-minute evaluator only if the rider is already opted in. Safe to
  /// call from any rider surface's initState (idempotent).
  Future<void> ensureStartedIfEnabled() async {
    if (_started) return;
    // Reconcile the opt-in with the server before deciding — covers reinstall /
    // second device where the local flag is missing but the server has the
    // rider opted in (or vice-versa). Server `enabled` is authoritative.
    await _reconcileEnabledFromServer();
    if (!await isEnabled()) return;
    _start();
  }

  /// Called after the rider's FIRST successful manual go-live — opts them into
  /// the daily auto window from the next day on and starts the evaluator.
  Future<void> enableAfterManualGoLive() async {
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
  }

  /// Record that the rider manually went offline during the window, so the
  /// evaluator won't fight them by re-opening for the rest of today.
  Future<void> noteManualOffDuringWindow() async {
    if (!_inWindow(DateTime.now())) return;
    _autoOpenedThisSession = false;
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
        await SharedPreferenceUtils.setSecureValue(
            _enabledKey, serverEnabled ? 'true' : 'false');
      }
    } catch (e) {
      log('[RiderAutoGoLive] enabled reconcile failed: $e');
    }
  }

  // ── internals ──────────────────────────────────────────────
  void _start() {
    if (_started) return;
    _started = true;
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

  Future<void> _evaluate() async {
    try {
      if (!await isEnabled()) return;
      if (!Get.isRegistered<ViewPersonalDetailsController>()) return;
      if (!Get.isRegistered<DeliveryPartnerController>()) return;

      final viewCtrl = Get.find<ViewPersonalDetailsController>();
      final riderCtrl = Get.find<DeliveryPartnerController>();

      // Thresholds must STILL hold — never auto-open an unverified/unpaid rider.
      if (riderCtrl.riderVerificationState !=
          RiderVerificationState.completed) {
        return;
      }
      final isRiderRole = userProfessionGlobal == BIKE_RIDER ||
          userProfessionGlobal == CAR_TAXI_DRIVER;
      if (isRiderRole && !riderCtrl.isSecurityDepositPaid) return;

      final now = DateTime.now();
      final inWindow = _inWindow(now);
      final isOpen = viewCtrl.shopStatusOpenClose.value;

      if (inWindow) {
        if (isOpen) return; // already live — nothing to do
        // Respect a manual opt-out for today's window.
        final manualOff =
            await SharedPreferenceUtils.getSecureValue(_manualOffKey);
        if (manualOff == _todayKey()) return;
        // Can't prompt for permissions in the background — only auto-open when
        // everything is already granted.
        if (!await GoLivePermissionService.areRequiredGranted()) return;
        _autoOpenedThisSession = true;
        log('[RiderAutoGoLive] window open → going live');
        await viewCtrl.toggleShopOnlyStatus(isActive: true);
      } else {
        // Outside the window: auto-close ONLY what we auto-opened.
        if (isOpen && _autoOpenedThisSession) {
          _autoOpenedThisSession = false;
          log('[RiderAutoGoLive] window closed → going offline');
          await viewCtrl.toggleShopOnlyStatus(isActive: false);
        }
      }
    } catch (e) {
      // Best-effort — never let a tick throw. Backend cron is the safety net.
      log('[RiderAutoGoLive] evaluate error: $e');
    }
  }
}
