import 'dart:developer';

import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/check_internet_connectivity.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_track_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_vertical_capabilities.dart';
import 'package:BlueEra/features/chat/auth/repo/order_lifecycle_repo.dart';
import 'package:get/get.dart';

/// Why the last `/track` fetch produced no order.
enum OrderTrackFailure {
  /// Never fetched, or fetched successfully.
  none,

  /// `404` about the ORDER. "This order no longer exists." + pop (S14).
  gone,

  /// The viewer is not the customer and not the shop (B7).
  forbidden,

  /// The request never reached the server. Pull to refresh (B10, T8).
  offline,

  /// Anything else, including a route that is not deployed for this vertical.
  generic,
}

/// **The order steps screen's brain.**
///
/// One instance per open order — created with a tag so two tracker screens on
/// the navigation stack never fight over the same state.
///
/// It owns exactly one server truth: the latest `/track` answer. Nothing in
/// this class advances an order locally. Every control re-fetches after it
/// succeeds (B11), because the server is the only thing that knows whether the
/// other party moved first.
class OrderTrackController extends GetxController {
  OrderTrackController({
    required this.orderId,
    this.service = OrderServiceApi.defaultOrderService,
    bool? isOwner,
  }) : _isOwnerGuess = isOwner ?? false;

  final String orderId;
  final String service;

  /// The caller's guess at the viewer's role, used only until `/track` says
  /// `actor` (B3).
  final bool _isOwnerGuess;

  final OrderLifecycleRepo _repo = OrderLifecycleRepo();

  /// GetX tag so several tracker screens can coexist.
  static String tagFor(String orderId, String service) =>
      'track:$service:$orderId';

  /// Live instances, ref-counted by tag.
  ///
  /// A chat thread can hold the card for an order and, a tap later, the steps
  /// screen for the same order. Both want the same `/track` answer, and two
  /// controllers would mean two fetches and two truths that drift apart the
  /// moment one of them refreshes. [attach] hands both the same instance and
  /// counts the holders; [detach] disposes it when the last one lets go.
  static final Map<String, int> _refCounts = <String, int>{};

  static OrderTrackController attach({
    required String orderId,
    required String service,
    bool isOwner = false,
  }) {
    final tag = tagFor(orderId, service);
    _refCounts[tag] = (_refCounts[tag] ?? 0) + 1;
    if (Get.isRegistered<OrderTrackController>(tag: tag)) {
      return Get.find<OrderTrackController>(tag: tag);
    }
    return Get.put(
      OrderTrackController(
          orderId: orderId, service: service, isOwner: isOwner),
      tag: tag,
    );
  }

  /// **The socket's only job: "something changed, go re-read"** (guide §13).
  ///
  /// A realtime event never patches state from its own body — it asks whoever
  /// is showing this order to fetch `/track` again. When nothing is showing
  /// it, there is nothing to refresh and the next mount loads fresh anyway, so
  /// this deliberately does **not** create a controller.
  static Future<void> refreshIfAttached({
    required String orderId,
    required String service,
  }) async {
    if (orderId.isEmpty) return;
    final tag = tagFor(orderId, service);
    if (!Get.isRegistered<OrderTrackController>(tag: tag)) return;
    await Get.find<OrderTrackController>(tag: tag).silentRefresh();
  }

  static void detach({required String orderId, required String service}) {
    final tag = tagFor(orderId, service);
    final left = (_refCounts[tag] ?? 1) - 1;
    if (left > 0) {
      _refCounts[tag] = left;
      return;
    }
    _refCounts.remove(tag);
    if (Get.isRegistered<OrderTrackController>(tag: tag)) {
      Get.delete<OrderTrackController>(tag: tag);
    }
  }

  // ── State ────────────────────────────────────────────────────────────

  final Rxn<OrderTrackModel> track = Rxn<OrderTrackModel>();

  /// True only on the **cold** load, when there is nothing to show yet. A
  /// refresh over existing content never blanks the screen (T9).
  final RxBool isLoading = false.obs;

  final RxBool isRefreshing = false.obs;

  final Rx<OrderTrackFailure> failure = OrderTrackFailure.none.obs;

  /// Busy keys, one per control, so a double-tap sends one request (B9).
  final RxSet<String> busy = <String>{}.obs;

  /// The screen shows this and disables its controls. Never an optimistic
  /// advance (B10).
  final RxBool isOffline = false.obs;

  /// Set once, when `/track` 404s about the order. The screen pops on it.
  final RxBool isGone = false.obs;

  bool _fetchInFlight = false;

  /// Server-first role. Falls back to the caller's guess until `/track`
  /// answers with `actor`.
  bool get isOwner => track.value?.actorIsOwner ?? _isOwnerGuess;

  /// **Never cached.** Read straight off the latest payload every time, so an
  /// order that reopens stops looking terminal (S6).
  bool get isTerminal => track.value?.isTerminal ?? false;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  // ── Fetch ────────────────────────────────────────────────────────────

  /// `/track` is the only route grocery has. A vertical that does not serve it
  /// at all is caught here rather than by a 404 the user has to look at.
  bool get canTrack => OrderVerticalCapabilities.hasTrack(service);

  Future<void> load({bool silent = false}) async {
    if (orderId.isEmpty) {
      failure.value = OrderTrackFailure.gone;
      isGone.value = true;
      return;
    }
    if (!canTrack) {
      failure.value = OrderTrackFailure.generic;
      return;
    }
    if (_fetchInFlight) return;
    _fetchInFlight = true;

    if (track.value == null && !silent) {
      isLoading.value = true;
    } else if (!silent) {
      isRefreshing.value = true;
    }

    try {
      final res = await _repo.track(orderId, service: service);
      final body = res.response?.data;

      if (res.isSuccess && body is Map) {
        final parsed = OrderTrackModel.fromJson(Map<String, dynamic>.from(body),
            fallbackOrderId: orderId);
        track.value = parsed;
        failure.value = OrderTrackFailure.none;
        isOffline.value = false;
        isGone.value = false;
        return;
      }

      final status = res.response?.statusCode;
      final json = body is Map ? Map<String, dynamic>.from(body) : null;
      final code = _codeOf(json);

      if (OrderVerticalCapabilities.isRouteMissingResponse(status, body)) {
        // The route is not deployed for this vertical. Nothing the user can do
        // about it, and nothing about their order is actually wrong.
        failure.value = OrderTrackFailure.generic;
        return;
      }
      if (status == 404 ||
          code == OrderErrorCode.orderNotFound ||
          code == OrderErrorCode.invalidOrderId) {
        failure.value = OrderTrackFailure.gone;
        isGone.value = true;
        return;
      }
      if (code == OrderErrorCode.notAPartyToOrder ||
          code == OrderErrorCode.notOrderCustomer ||
          status == 403) {
        failure.value = OrderTrackFailure.forbidden;
        return;
      }
      failure.value = OrderTrackFailure.generic;
    } catch (e) {
      // `ApiBaseHelper` throws a plain String on a transport failure. The
      // order is fine; the phone is not.
      log('order track failed for $orderId: $e');
      isOffline.value = !(await checkInternetStatus());
      failure.value = OrderTrackFailure.offline;
    } finally {
      _fetchInFlight = false;
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Pull-to-refresh and on-focus refresh. Grocery has no socket, so this is
  /// the only way a card ever changes (T7, S13).
  Future<void> refresh() => load(silent: false);

  /// Same fetch with no spinner — used after an action and on app resume, so
  /// the screen updates without flashing (B11, T8).
  Future<void> silentRefresh() => load(silent: true);

  // ── Controls ─────────────────────────────────────────────────────────

  bool isBusy(String key) => busy.contains(key);

  /// The two controls that exist for a legacy vertical, plus whatever a ported
  /// one lists. A key this build does not know is never rendered (B1), and a
  /// key whose route 404'd once is never rendered again (B8).
  List<String> get availableControls {
    final model = track.value;
    if (model == null) return const [];

    final fromServer = model.actionsFor(isOwner: isOwner);
    if (fromServer.isNotEmpty) {
      return fromServer
          .where((a) => OrderVerticalCapabilities.allowsAction(service, a))
          .toList(growable: false);
    }

    // No lifecycle, no `availableActions` — grocery, today and always. The two
    // verified routes are offered from the stage the order is standing on
    // (§7), and only to the shop.
    if (!isOwner || model.isTerminal) return const [];
    final stageKey = _currentStageKey(model);
    final controls = <String>[];
    if (_looksPlaced(model, stageKey) &&
        OrderVerticalCapabilities.allowsAction(
            service, OrderAction.markReady)) {
      controls.add(OrderAction.markReady);
    }
    if (_looksReady(model, stageKey) &&
        OrderVerticalCapabilities.allowsAction(
            service, kOrderActionMarkCollected)) {
      controls.add(kOrderActionMarkCollected);
    }
    return controls;
  }

  String _currentStageKey(OrderTrackModel model) {
    final index = model.currentIndex;
    if (index >= 0 && index < model.stages.length) {
      return model.stages[index].key.toLowerCase();
    }
    return (model.currentStage ?? '').toLowerCase();
  }

  /// The stepper drives this, not `orderStatus` — the two are allowed to
  /// disagree and the stage is the one that is right (S5).
  bool _looksPlaced(OrderTrackModel model, String stageKey) {
    if (stageKey.isNotEmpty) {
      return stageKey.contains('placed') ||
          stageKey.contains('pending') ||
          stageKey.contains('accepted') ||
          stageKey.contains('progress') ||
          stageKey.contains('preparing');
    }
    return model.orderStatus == OrderStatusValue.placed ||
        model.orderStatus == OrderStatusValue.accepted ||
        model.orderStatus == OrderStatusValue.inProgress;
  }

  bool _looksReady(OrderTrackModel model, String stageKey) {
    if (stageKey.isNotEmpty) {
      return stageKey.contains('ready') ||
          stageKey.contains('pickup') ||
          stageKey.contains('collect');
    }
    return model.orderStatus == OrderStatusValue.ready;
  }

  /// `PUT /ready`. Verified working for grocery (§7).
  Future<OrderControlOutcome> markReady() => _run(
        OrderAction.markReady,
        () => _repo.markReady(orderId, service: service),
        successCopy: AppStrings.orderMarkedReadyToast,
      );

  /// `PUT /:id { orderStatus: 'completed' }`. The only way to close a grocery
  /// order; the caller gates it behind a confirm (§7).
  Future<OrderControlOutcome> markCollected() => _run(
        kOrderActionMarkCollected,
        () => _repo.updateOrderStatus(orderId,
            orderStatus: OrderStatusValue.completed, service: service),
        successCopy: AppStrings.orderMarkedCollectedToast,
      );

  Future<OrderControlOutcome> _run(
    String key,
    Future<ResponseModel> Function() call, {
    required String successCopy,
  }) async {
    // B9 — the server does not dedupe, so the button does.
    if (busy.contains(key)) {
      return const OrderControlOutcome(ok: false, silent: true);
    }
    if (isOffline.value) {
      return OrderControlOutcome(ok: false, copy: AppStrings.orderOfflineCopy);
    }
    busy.add(key);
    busy.refresh();
    try {
      final res = await call();
      final body = res.response?.data;
      final status = res.response?.statusCode;

      if (res.isSuccess) {
        // B11 — never advance the card locally, always re-read.
        await silentRefresh();
        return OrderControlOutcome(ok: true, copy: successCopy);
      }

      final json = body is Map ? Map<String, dynamic>.from(body) : null;
      final code = _codeOf(json);

      if (OrderVerticalCapabilities.isRouteMissingResponse(status, body)) {
        // B8 — not deployed for this vertical. Hide the control from now on
        // rather than offering a button that can only fail.
        OrderVerticalCapabilities.markRouteMissing(service, key);
        track.refresh();
        return OrderControlOutcome(
            ok: false, copy: AppStrings.orderGenericError);
      }

      if (OrderErrorCode.isStaleState(code)) {
        // B4 / B5 — the other party moved first. Normal. Refresh, say nothing.
        await silentRefresh();
        if (code == OrderErrorCode.orderTerminal) {
          // B6 — this one earns a sentence, because the order really is done.
          return OrderControlOutcome(
              ok: false, copy: AppStrings.orderAlreadyClosed);
        }
        return const OrderControlOutcome(ok: false, silent: true);
      }

      if (code == OrderErrorCode.notAPartyToOrder ||
          code == OrderErrorCode.notOrderCustomer) {
        // B7 — and the controls go away with it.
        failure.value = OrderTrackFailure.forbidden;
        return OrderControlOutcome(ok: false, copy: AppStrings.orderNotAParty);
      }

      if (code == OrderErrorCode.orderNotFound ||
          code == OrderErrorCode.invalidOrderId ||
          status == 404) {
        isGone.value = true;
        failure.value = OrderTrackFailure.gone;
        return OrderControlOutcome(
            ok: false, copy: AppStrings.orderNoLongerExists);
      }

      // Never the server's own `message` — it is Mongoose text as often as it
      // is a sentence (§8).
      return OrderControlOutcome(ok: false, copy: AppStrings.orderGenericError);
    } catch (e) {
      log('order control $key failed for $orderId: $e');
      isOffline.value = !(await checkInternetStatus());
      return OrderControlOutcome(
        ok: false,
        copy: isOffline.value
            ? AppStrings.orderOfflineCopy
            : AppStrings.orderGenericError,
      );
    } finally {
      busy.remove(key);
      busy.refresh();
    }
  }

  String? _codeOf(Map<String, dynamic>? json) {
    if (json == null) return null;
    final direct = json['code'] ?? json['errorCode'] ?? json['error_code'];
    if (direct != null) return direct.toString();
    final err = json['error'];
    if (err is Map) {
      final nested = err['code'] ?? err['errorCode'];
      if (nested != null) return nested.toString();
    }
    return null;
  }
}

/// What one control did. `silent` means the UI shows nothing at all — a stale
/// 409 is normal, and a red toast for it is a lie (B4).
class OrderControlOutcome {
  final bool ok;

  /// An `AppStrings` key, already chosen from the §8 table. Resolve with
  /// `.tr` at the call site.
  final String? copy;

  final bool silent;

  const OrderControlOutcome({required this.ok, this.copy, this.silent = false});
}
