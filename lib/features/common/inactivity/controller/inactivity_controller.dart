import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/features/common/inactivity/model/inactivity_status_model.dart';
import 'package:BlueEra/features/common/inactivity/repo/inactivity_repo.dart';
import 'package:BlueEra/features/common/inactivity/view/data_purged_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Owns everything about the inactive-account DATA PURGE — the 90-day content
/// erase described in docs/backend/FLUTTER_INACTIVE_USER_DATA_PURGE_GUIDE.md.
///
/// Not account deletion. The account, the phone number, the wallet balance and
/// any active subscription all survive a purge; what goes is the *content*
/// (posts, orders, chats, profile details, media). `AccountDeletionController`
/// is the unrelated flow with its own OTP and web page.
///
/// Two things the app has to do, and this controller does both:
///   * a returning user whose data is ALREADY gone gets told why, once, before
///     they stare at a blank profile and file a support ticket ([_onPurged]);
///   * a user who is ABOUT to be purged gets a banner ([showWarning]) — they
///     don't have to act on it, because opening the app has already saved them.
///
/// [ping] is also the "I'm alive" signal: the status endpoint counts as
/// activity server-side, so a user who opens the app is taken out of the purge
/// cohort by that call alone even if every other signal fails. That is why it
/// runs on launch AND on resume, and why a failure here is only ever logged —
/// there is nothing to show the user about a background heartbeat.
class InactivityController extends GetxController {
  static InactivityController get to =>
      getOrPut(() => InactivityController(), permanent: true);

  final InactivityRepo _repo = InactivityRepo();

  /// Null until the first successful read. Everything that renders off this
  /// treats null as "nothing to show".
  final Rxn<InactivityStatusModel> status = Rxn<InactivityStatusModel>();

  /// Session-scoped banner dismissal — the banner returns on the next launch
  /// if the account is somehow still in the warning window. (It normally is
  /// not: [ping] itself reset the clock.)
  final RxBool warningDismissed = false.obs;

  /// True while `/acknowledge` is in flight, so the screen's button can show
  /// its inline loader.
  final RxBool isAcknowledging = false.obs;

  /// The "your data was removed" screen is a once-per-process event. Without
  /// this a resume ping would re-push it on top of itself while the user is
  /// still reading the first copy.
  bool _purgedScreenShown = false;

  DateTime? _lastPingAt;
  bool _pingInFlight = false;

  /// Resume fires for every trip through the app switcher. The backend only
  /// needs one "I'm alive" per session to take the user out of the cohort, so
  /// anything closer together than this is wasted work on a cold radio.
  static const Duration _minPingGap = Duration(minutes: 5);

  /// Whether the home banner should be up right now.
  bool get showWarning =>
      (status.value?.showWarning ?? false) && !warningDismissed.value;

  /// Days the banner counts down to. Null when the server didn't say — the
  /// banner then drops the number rather than inventing one.
  int? get daysUntilPurge => status.value?.daysUntilPurge;

  /// Reads the purge state and reacts to it.
  ///
  /// [force] skips the [_minPingGap] throttle — pass it for the events that
  /// genuinely want a fresh answer (a tapped warning notification, the
  /// inactivity deep link) rather than the periodic resume heartbeat.
  Future<void> ping({bool force = false}) async {
    // No token means no account to be inactive on. Guests are included on
    // purpose: a guest account is a real account with real content, and the
    // backend purges it on the same clock.
    if (!isLoggedIn()) return;
    if (_pingInFlight) return;

    final last = _lastPingAt;
    if (!force && last != null && DateTime.now().difference(last) < _minPingGap) {
      return;
    }

    _pingInFlight = true;
    try {
      final ResponseModel response = await _repo.getInactivityStatus();
      if (!response.isSuccess) {
        log('InactivityController: status ${response.statusCode} — ${response.message}');
        return;
      }
      _lastPingAt = DateTime.now();

      final body = response.response?.data;
      final parsed = InactivityStatusModel.fromJson(
        body is String ? jsonDecode(body) : body,
      );
      status.value = parsed;

      if (parsed.dataPurged) {
        await _onPurged();
      }
    } catch (e, s) {
      // A heartbeat that fails is not something to interrupt anyone over; the
      // next resume tries again.
      log('InactivityController.ping error: $e\n$s');
    } finally {
      _pingInFlight = false;
    }
  }

  /// The account came back with its content already erased.
  ///
  /// The local wipe and the FCM re-registration happen HERE rather than on the
  /// screen's button, even though the guide lists them under "on tap": stale
  /// local data sitting over a purged server account is the one thing that
  /// makes this genuinely confusing, and the user can background the app
  /// without ever tapping anything. Doing it at detection means there is no
  /// window where the home shell can paint the previous life's feed.
  ///
  /// The in-memory half — the GetX controllers holding their own copy of that
  /// same data — is deliberately NOT dropped here; it waits for
  /// [acknowledgeAndContinue], which can drop and re-create in one turn. A
  /// purged user is still signed in, and an empty registry is only safe for as
  /// long as nothing can look in it.
  Future<void> _onPurged() async {
    if (_purgedScreenShown) return;
    _purgedScreenShown = true;

    // Hive boxes, per-feature caches, chat history, the app docs dir — the
    // same account-half wipe a logout performs, minus the secure storage:
    // the session is still valid and the user stays signed in.
    try {
      await LogoutHelper.clearAllLocalData();
    } catch (e) {
      log('InactivityController: local wipe failed — $e');
    }

    // `device_token` and `voip_token` are cleared server-side by the purge, so
    // until this lands the user receives no notifications at all.
    unawaited(AppNotificationHandler.flushPendingTokenSync());
    unawaited(AppNotificationHandler.syncVoipToken(force: true));

    // `offAll`, not `to`: every screen behind this one is now showing the
    // previous life's data out of caches that no longer exist, and leaving
    // them mounted underneath is also what would make the controller reset in
    // [acknowledgeAndContinue] unsafe — that reset needs the same "no screen
    // still holds one of these" precondition a logout gets from its own
    // `offAllNamed`. Waiting for the frame first because this can be reached
    // from the home shell's own post-frame callback, and navigating out of a
    // widget mid-build is how "setState() called during build" happens.
    await WidgetsBinding.instance.endOfFrame;
    await Get.offAll(() => const DataPurgedScreen());
  }

  /// Button on the "your data was removed" screen: tell the backend it was
  /// seen, then hand the user to their (now empty) profile to fill in again.
  ///
  /// Deliberately NOT the guest/registration flow — they already have an
  /// account and `account_type` is intact. Index 0 is the Me tab, which is the
  /// profile-setup screen for an individual and the own-profile screen for a
  /// business, so one destination serves both.
  Future<void> acknowledgeAndContinue() async {
    if (isAcknowledging.value) return;
    isAcknowledging.value = true;
    try {
      await _repo.acknowledgePurge();
    } catch (e) {
      // The screen must never trap the user because a best-effort flag write
      // failed. Worst case it reappears on the next launch.
      log('InactivityController.acknowledge error: $e');
    } finally {
      isAcknowledging.value = false;
    }

    // Locally forget the purge either way, so nothing re-triggers this session.
    status.value = const InactivityStatusModel();

    // Throw away the in-memory half of the account's data, then immediately
    // re-mount the shell that re-creates it.
    //
    // The Hive wipe in [_onPurged] only cleared the disk. These controllers
    // hold their own copy of the same posts, chats, profile and merchant
    // catalogues — several are `permanent: true`, so GetX will never reclaim
    // them — and each carries the "already fetched, don't refetch" stamp that
    // would keep the empty account showing the full one.
    //
    // The two lines are deliberately adjacent and in this order. Dropping
    // earlier (at detection, or on this screen's first frame) would leave the
    // registry empty for as long as the user takes to read the screen, and a
    // purged user is still SIGNED IN — a socket event or an arriving push in
    // that window hits one of the ~185 bare `Get.find<T>()` call sites and
    // throws. Dropping later, after the shell is up, would be worse: its
    // `getOrPut` would have already adopted the stale instances and we would
    // delete the ones it is holding. Between these two statements nothing but
    // this screen is mounted and the shell's `initState` re-creates every one
    // of them, so the gap is a single frame with no UI in it.
    LogoutHelper.resetAccountControllers();
    Get.offAllNamed(
      RouteHelper.getBottomNavigationBarScreenRoute(),
      arguments: {'initialIndex': 0},
    );
  }

  void dismissWarning() => warningDismissed.value = true;
}
