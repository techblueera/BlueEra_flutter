/// **What each vertical's order service can actually do today.**
///
/// `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` §7 states the gate:
///
/// ```
/// lifecycle available  → product-service only
/// /actions available   → product-service only
/// /track available     → product-service, grocery-service, food-service
/// chat order card      → nowhere for grocery
/// socket updates       → nowhere for grocery
/// ```
///
/// Two separate things live here, and they are separate on purpose:
///
/// * the **static** table above — what is known, at build time, not to be
///   deployed. Asking for it can only 404, so the UI does not offer it.
/// * the **learned** set — a route that answered `404` with an HTML body
///   (`Cannot POST /…`), i.e. not deployed for that vertical after all. B8
///   says such a button is hidden permanently for that vertical rather than
///   re-offered every time the card rebuilds.
///
/// The learned set is per process, not persisted: a deploy should not need an
/// app reinstall to be noticed.
library;

import 'package:BlueEra/core/api/apiService/order_service_api.dart';

class OrderVerticalCapabilities {
  const OrderVerticalCapabilities._();

  /// Verticals whose chat card carries `metadata.lifecycle`, and whose
  /// `/actions` route exists. Everything else renders legacy: status only, no
  /// action buttons (C5).
  static const Set<String> _lifecycleServices = {
    OrderServiceApi.productOrderService,
  };

  /// Verticals that answer `GET /track`. This is the one route grocery has,
  /// and the reason the steps screen is the entire usable order UI for it.
  static const Set<String> _trackServices = {
    OrderServiceApi.productOrderService,
    OrderServiceApi.groceryOrderService,
    OrderServiceApi.foodOrderService,
  };

  /// Verticals that emit `productOrderLifecycle` (or any per-vertical order
  /// socket event). Grocery emits nothing — its cards never update live, so
  /// the screen refreshes on focus and on pull-to-refresh instead (T7).
  static const Set<String> _socketServices = {
    OrderServiceApi.productOrderService,
  };

  /// Lifecycle routes grocery-service **does** serve, despite having no
  /// lifecycle payload. `PUT /ready` and the direct status write are the two
  /// verified-working seller controls (§7).
  static const Set<String> _groceryLifecycleActions = {
    _RouteKey.ready,
    _RouteKey.complete,
  };

  static bool hasLifecycle(String service) =>
      _lifecycleServices.contains(service);

  static bool hasActions(String service) =>
      _lifecycleServices.contains(service);

  static bool hasTrack(String service) => _trackServices.contains(service);

  static bool hasSocketUpdates(String service) =>
      _socketServices.contains(service);

  /// Whether an action button may be offered at all for this vertical.
  ///
  /// A fully ported vertical offers whatever the server listed. A vertical
  /// with no lifecycle offers only the routes verified to exist for it —
  /// which for grocery is Mark Ready and Mark Collected, and nothing else
  /// (§7: "Everything else → 404 → **Hide**").
  static bool allowsAction(String service, String actionKey) {
    if (isRouteMissing(service, actionKey)) return false;
    if (hasLifecycle(service)) return true;
    if (service == OrderServiceApi.groceryOrderService) {
      return _groceryLifecycleActions.contains(actionKey);
    }
    // A vertical nobody has verified: trust the server's own action list.
    return true;
  }

  // ── Learned 404s (B8) ────────────────────────────────────────────────

  static final Set<String> _missingRoutes = <String>{};

  static String _key(String service, String actionKey) =>
      '$service::$actionKey';

  /// Record that `<service>` has no such route. Called only for a 404 whose
  /// body is **not** a JSON error envelope — an Express `Cannot POST /…`
  /// page. A typed `ORDER_NOT_FOUND` is about the order, not the route, and
  /// must never land here.
  static void markRouteMissing(String service, String actionKey) {
    if (service.isEmpty || actionKey.isEmpty) return;
    _missingRoutes.add(_key(service, actionKey));
  }

  static bool isRouteMissing(String service, String actionKey) =>
      _missingRoutes.contains(_key(service, actionKey));

  /// Test seam.
  static void resetLearnedRoutes() => _missingRoutes.clear();

  /// True when a 404 body is a route-not-deployed page rather than a JSON
  /// error about the order.
  static bool isRouteMissingResponse(int? statusCode, dynamic body) {
    if (statusCode != 404) return false;
    if (body is Map) {
      // A JSON envelope means the route ran and answered about the order.
      return false;
    }
    final text = body?.toString() ?? '';
    return text.contains('Cannot POST') ||
        text.contains('Cannot GET') ||
        text.contains('Cannot PUT') ||
        text.contains('<html') ||
        text.contains('<!DOCTYPE');
  }
}

/// Action keys used by the capability table. They mirror `OrderAction`, but a
/// couple of grocery-only controls have no lifecycle key at all — `complete`
/// is a direct `PUT :id {orderStatus: completed}` — so they are named here.
class _RouteKey {
  static const ready = 'MARK_READY';
  static const complete = 'MARK_COLLECTED';
}

/// Public alias for the grocery-only "Mark Collected" control, which is a
/// direct status write rather than a lifecycle action.
const String kOrderActionMarkCollected = _RouteKey.complete;
