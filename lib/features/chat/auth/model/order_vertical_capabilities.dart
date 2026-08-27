/// **What each vertical's order service can actually do today.**
///
/// ```
/// lifecycle available  → product-service only
/// /actions available   → product-service only
/// /track available     → product-service, grocery-service, food-service
/// chat order card      → every vertical, grocery included
/// socket updates       → product-service, and grocery's own four events
/// ```
///
/// **The last two lines were wrong until 27 Aug 2026.** They came from
/// `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` §7, which recorded that grocery has
/// no chat card and no socket event; `ORDER_UI_CONDITIONAL_FLOW_GUIDE.md` §12
/// corrects that against production on four counts, two of which this table
/// encoded:
///
///  1. *"No grocery chat card is ever created."* — **false**, 977 exist. The
///     audit called `latest-chat` without `?type=business`, and that endpoint
///     defaults to `personal` and only returns threads carrying unread
///     messages from someone else.
///  2. *"No grocery socket event exists."* — **false**, four fire:
///     `newSelfPickupOrderReceived`, `selfPickupOrderReady`,
///     `groceryOrderDispatched`, `groceryOrderCompleted`.
///  3. *"No grocery order list."* — **false**, `GET /api/orders/business/me`
///     and `/me` both work.
///  4. *"`chat/order-status` is dead."* — **false**, it is `PUT`, not `POST`.
///
/// Facts 3 and 4 are about endpoints this table does not gate; they are
/// recorded here so the next reader does not re-import them from the old doc.
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

  /// Verticals that emit **any** order socket event.
  ///
  /// Product emits the one generic `productOrderLifecycle` channel. Grocery
  /// emits four narrower events instead (§12 fact 2) — so it belongs here too,
  /// even though it has no lifecycle payload and every event is only a cue to
  /// re-read `/track`. Focus-refresh stays as the fallback either way (§13).
  static const Set<String> _socketServices = {
    OrderServiceApi.productOrderService,
    OrderServiceApi.groceryOrderService,
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

  // ── Derived clocks ───────────────────────────────────────────────────

  /// Grocery's server-side auto-expiry window for a `placed` self-pickup
  /// order (§12). Swept every 15 minutes, so the wall clock is a guide, not a
  /// deadline any client may act on.
  static const Duration groceryPlacedWindow = Duration(hours: 1);

  /// **The one deadline a client is allowed to derive**, and only because the
  /// service that owns it sends no `deadlines` block at all.
  ///
  /// Grocery self-pickup orders auto-expire one hour after they are placed —
  /// **978 of 1,099 production orders are `expired`** (§12), so this is the
  /// *common* ending, not an edge case. With no server clock to render, a
  /// customer watching a grocery order sees nothing at all until it silently
  /// dies, which is exactly the invisible waiting the guide is about.
  ///
  /// Three things keep this honest:
  ///
  ///  * callers reach it **only** when the server sent no deadlines, so a
  ///    ported vertical's real clock can never be shadowed by this one;
  ///  * it answers only for **grocery**, and only at **`placed`** — the one
  ///    stage the sweep applies to. Everything else gets null, and null draws
  ///    nothing (§8.1 rule 2);
  ///  * reaching zero still changes nothing. The sweeper runs on its own
  ///    15-minute cadence, so an order is frequently alive well past the hour;
  ///    the countdown re-reads and lets the server say (§8.1 rule 1).
  ///
  /// Returns null whenever any of that does not hold.
  static DateTime? derivedPlacedExpiry({
    required String service,
    required String? orderStatus,
    required DateTime? createdAt,
  }) {
    if (service != OrderServiceApi.groceryOrderService) return null;
    if (orderStatus != 'placed') return null;
    if (createdAt == null) return null;
    return createdAt.add(groceryPlacedWindow);
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
