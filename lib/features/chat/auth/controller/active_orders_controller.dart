import 'dart:developer';

import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/features/chat/auth/model/active_order_summary.dart';
import 'package:BlueEra/features/chat/auth/model/order_vertical_capabilities.dart';
import 'package:BlueEra/features/chat/auth/repo/order_lifecycle_repo.dart';
import 'package:get/get.dart';

/// The customer's own in-flight orders, for surfaces that are **not** the order
/// screen — today, the Discover rail.
///
/// ## The problem it solves
///
/// Every clock in this app was already correct and already server-authored. The
/// gap was never the countdown; it was that the countdown was only ever drawn
/// inside a chat thread. A customer who placed a grocery order and closed the
/// conversation had no way to learn it was ready, and the order expired at the
/// one-hour sweep with nobody having seen a single tick of the clock (§12).
///
/// ## Deliberately not a cache of orders
///
/// This holds **summaries** and nothing else. It never merges into
/// [OrderLifecycleController.orders], never seeds a card, and never decides
/// what anyone may do: `/orders/me` carries no `availableActions` and no
/// `actor`, so anything derived from it about legality would be a guess. The
/// rail shows state and hands off (§0, §11).
///
/// ## Undeployed verticals
///
/// `/orders/me` is verified in guide §12 fact 3 — but verified **for grocery**.
/// Rather than assume parity, every vertical is asked once and a route-missing
/// 404 (an Express `Cannot GET /…` page, not a typed error) is recorded through
/// the app's existing learned-404 gate. A vertical without the route costs one
/// failed request per process and then disappears — the rail simply has less to
/// show, which is exactly today's behaviour.
class ActiveOrdersController extends GetxController {
  ActiveOrdersController({OrderLifecycleRepo? repo})
      : _repo = repo ?? OrderLifecycleRepo();

  final OrderLifecycleRepo _repo;

  static ActiveOrdersController get instance =>
      Get.isRegistered<ActiveOrdersController>()
          ? Get.find<ActiveOrdersController>()
          : Get.put(ActiveOrdersController(), permanent: true);

  /// The action key the learned-404 gate records a missing list route under.
  /// Not an `OrderAction` — nothing renders a button for it — but the gate is
  /// keyed by string and this is the string.
  static const String routeKey = 'LIST_MY_ORDERS';

  /// Verticals worth asking. Product runs the full state machine; grocery is
  /// the one §12 verifies the route on, and the one whose orders actually
  /// expire in bulk. Food and medical are omitted until someone verifies them
  /// — an unasked route is cheaper than a learned 404.
  static const List<String> services = [
    OrderServiceApi.productOrderService,
    OrderServiceApi.groceryOrderService,
  ];

  /// Live orders, most urgent first. Empty is the common case and must cost
  /// nothing to render.
  final RxList<ActiveOrderSummary> orders = <ActiveOrderSummary>[].obs;

  final RxBool isLoading = false.obs;

  /// True once a load has completed, however it went. Lets the rail tell
  /// "nothing yet" from "nothing at all" without flashing an empty state.
  final RxBool hasLoaded = false.obs;

  bool _inFlight = false;

  /// Fetch every vertical that still has the route, and replace the list.
  ///
  /// Concurrent calls collapse into the one in flight: Discover can ask on
  /// mount, on focus and on a socket cue within the same frame, and three
  /// identical requests would be three chances to render three different
  /// answers.
  Future<void> refreshOrders({bool silent = true}) async {
    if (_inFlight) return;
    _inFlight = true;
    if (!silent) isLoading.value = true;

    try {
      final collected = <ActiveOrderSummary>[];
      for (final service in services) {
        if (OrderVerticalCapabilities.isRouteMissing(service, routeKey)) {
          continue;
        }
        collected.addAll(await _loadOne(service));
      }

      // Live only, most urgent first, then soonest deadline. A stable order
      // matters: this rail sits above the whole Discover feed and a list that
      // reshuffles between two identical loads reads as broken.
      collected
        ..removeWhere((o) => !o.isLive)
        ..sort((a, b) {
          final byUrgency = a.urgency.compareTo(b.urgency);
          if (byUrgency != 0) return byUrgency;
          final da = a.deadline;
          final db = b.deadline;
          if (da == null && db == null) return a.orderId.compareTo(b.orderId);
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

      orders.assignAll(collected);
    } finally {
      _inFlight = false;
      isLoading.value = false;
      hasLoaded.value = true;
    }
  }

  Future<List<ActiveOrderSummary>> _loadOne(String service) async {
    try {
      final res = await _repo.myOrders(service: service);
      final body = res.response?.data;

      if (!res.isSuccess) {
        // A route that is not deployed for this vertical answers with an
        // Express HTML page, not a typed error. Learn it once; a typed 404 is
        // about an order and must never land here.
        if (OrderVerticalCapabilities.isRouteMissingResponse(
            res.response?.statusCode, body)) {
          OrderVerticalCapabilities.markRouteMissing(service, routeKey);
          log('orders/me not deployed for $service — rail will skip it');
        }
        return const [];
      }
      return ActiveOrderSummary.listFrom(body, service: service);
    } catch (e) {
      // Transport failure. Not a missing route — the rail keeps whatever it
      // last showed and tries again on the next focus.
      log('orders/me failed for $service: $e');
      return const [];
    }
  }

  /// Drop one order off the rail without a round trip — used when the user
  /// dismisses it. It comes back on the next refresh if it is still live,
  /// which is correct: dismissing is "not now", not "cancel my order".
  void hide(String orderId) => orders.removeWhere((o) => o.orderId == orderId);
}
