/// All `rider-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: grocery- and medical-order endpoints under `rider-service/...`
/// (the rider-facing side of grocery/medical orders) live here. The
/// merchant-facing CRUD lives in `GroceryServiceApi` / `MedicalServiceApi`.
mixin RiderServiceApi {
  String checkTrackOrderStatus(String orderId) =>
      'rider-service/fare/orders/${orderId}/status';

  /// Customer-side live rider position for an active order, polled ~every 10s.
  /// Keyed on orderId (resolves assignedRider server-side, returns order status
  /// + distances). Replaces the map-provider SSE on the tracking screens.
  /// See docs/backend/RIDER_LOCATION_POLLING_GUIDE.md.
  String riderLiveLocationForOrder(String orderId) =>
      'rider-service/fare/orders/$orderId/rider-location';

  String getNearByRiderApi = "rider-service/riders/nearby";

  final String ridersOnboardingPersonalInformation =
      "rider-service/riders/onboarding/personal-information"; // Onboarding rider (step 1)
  final String ridersOnboardingAddress =
      "rider-service/riders/onboarding/address"; // Onboarding rider (step 2)
  final String ridersOnboardingPersonalIdentification =
      "rider-service/riders/onboarding/personal-identification"; // Onboarding rider (step 3)
  final String ridersOnboardingDrivingVerification =
      "rider-service/riders/onboarding/driving-verification"; // Onboarding rider (step 4)
  final String ridersOnboardingVehicleImages =
      "rider-service/riders/onboarding/vehicle-images"; // Onboarding rider (step 5)
  final String vehicleEnums =
      "rider-service/riders/onboarding/vehicle-enums"; // Onboarding rider (step 5)
  final String ridersOnboardingVehicleInformation =
      "rider-service/riders/onboarding/vehicle-information"; // Onboarding rider (step 6)
  final String ridersOnboardingStatus =
      "rider-service/riders/onboarding/status"; // Fetch onboarding rider status

  /// Rider's daily auto-go-live schedule (opt-in window).
  /// GET → current { enabled, windowStart, windowEnd, timezone, manualOffDate }.
  /// PUT → update { enabled } | { manualOffToday } | { windowStart, windowEnd }.
  /// See docs/backend/RIDER_GO_LIVE_GUIDE.md.
  final String ridersAutoGoLive = "rider-service/riders/auto-golive";

  /// Rider earnings + performance dashboard (Statistics tab).
  /// GET → `?period=today|week|month`, scoped to the authenticated rider.
  /// See docs/backend/RIDER_STATISTICS_API_GUIDE.md.
  final String ridersStatistics = "rider-service/riders/statistics";
  // Delete a single uploaded onboarding document. [documentType] is one
  // of: aadhar | pan | dl | rc | vehicle-images | vehicle-information.
  // NOTE: assumed REST path — confirm with backend before relying on it.
  String ridersOnboardingDeleteDocument(String documentType) =>
      "rider-service/riders/onboarding/documents/$documentType";
  final String initRiderServiceUpload = "rider-service/s3/presigned-url";
  final String ridersAssociatedShops =
      "rider-service/riders/associations/shops";
  final String ridersAssociationRequest =
      "rider-service/riders/associations/request";
  final String ridersAssociationRespond =
      "rider-service/riders/associations"; // append /:id/respond

  final String sendOrderReqToRider = "rider-service/riders/orders";
  final String getOrderFare = "rider-service/riders/fare";
  final String getBookingRiders = "rider-service/fare/riders";

  /// Dynamic fare quote for the BROADCAST flow — riders grouped by vehicle
  /// type with a computed fare per type. Unlike [getBookingRiders] the
  /// customer never picks a rider from this; it only prices the vehicle
  /// options. See docs/backend/RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md §1.
  final String getBookingRidersDynamic = "rider-service/fare/riders/dynamic";

  /// Customer-initiated cancel of a broadcast order. Distinct from
  /// [cancelFareCallQueue], which cancels the sequential fare-call QUEUE of
  /// the old hand-picked flow.
  String cancelFareOrder(String orderId) =>
      'rider-service/fare/orders/$orderId/cancel';
  final String favoriteLocations = "rider-service/favorite-locations";

  // Claim an order surfaced on the rider's active route (the
  // ROUTE_ORDER_AVAILABLE notification). See
  // docs/backend/NEW_NOTIFICATIONS_FRONTEND_GUIDE.md.
  String claimRouteOrder(String orderId) =>
      "rider-service/riders/orders/$orderId/claim";

  // En-route route management — the rider declares a pickup→drop route and
  // gets a live feed of claimable jobs along it. See
  // docs/backend/RIDER_JOBTYPE_CALL_OTP_MASTER_FRONTEND_GUIDE.md §4.
  final String riderRoutes = 'rider-service/riders/routes'; // POST create/activate
  final String riderActiveRoute = 'rider-service/riders/routes/active'; // GET
  final String riderEndRoute = 'rider-service/riders/routes/active/end'; // PATCH
  final String riderRouteOrders = 'rider-service/riders/routes/orders'; // GET list
  final String riderRouteOrdersStream =
      'rider-service/riders/routes/orders/stream'; // GET (SSE)

  final String getRiderBookingList = "rider-service/riders/orders/requested";
  final String getRiderRejectOrder = "rider-service/riders/orders/rejected";
  String updateOrderStatusFromPialot(String orderId) =>
      'rider-service/riders/orders/$orderId/status';
  String updateRideOrParcelOrderStatus(String orderId) =>
      'rider-service/fare/orders/${orderId}/status';
  String verifyPickupOtpRideOrParcel(String orderId) =>
      'rider-service/fare/orders/${orderId}/start';
  String completePickupRider(String orderId) =>
      'rider-service/fare/orders/${orderId}/complete';
  String rideAction(String orderId) =>
      'rider-service/fare/orders/${orderId}/ride-action';
  String cancelFareCallQueue(String orderId) =>
      'rider-service/fare/orders/${orderId}/cancel-queue';
  String updatePaymentStaus(String orderId) =>
      'rider-service/riders/orders/$orderId/confirm-payment';
  String cancelOrderForceFully(String orderId) =>
      'rider-service/riders/orders/$orderId/admin/status';
  String deliverOtpVerify(String orderId) =>
      "rider-service/riders/orders/$orderId/deliver";
  String updateOrderStatusFromAdmin(String orderId) =>
      "rider-service/riders/orders/$orderId/admin/status";
  String updateThePickupOtpUrl(String orderId) =>
      "rider-service/riders/orders/$orderId/pickup";

  // Grocery rider-side
  final String ridersGroceryOrders = 'rider-service/riders/orders/grocery/';
  String groceryServiceOrderAccept(String rideOrderId) =>
      'rider-service/riders/orders/grocery/$rideOrderId/accept';
  String groceryAcceptOrder(String orderId) =>
      'rider-service/riders/orders/grocery/${orderId}/accept';
  String groceryRejectOrder(String orderId) =>
      'rider-service/riders/orders/grocery/${orderId}/reject';
  final String myGroceryOrders = 'rider-service/grocery/orders/business';
  final String groceryOrderItemAvailability =
      'rider-service/grocery/orders/item-availability';
  final String groceryOrderAvailableItem =
      'rider-service/grocery/orders/available-items';
  final String groceryOrderUpdatePaymentStatus =
      'rider-service/grocery/orders/payment-status';

  final String makeTransportBookOrder = 'rider-service/fare/orders';

  // Chat self-pickup → rider dispatch (shop = pickup, customer = drop). Creates
  // a delivery ride from a self-pickup chat card and issues the two handoff
  // OTPs. See docs/backend/CHAT_DISPATCH_RIDER_FRONTEND_GUIDE.md.
  final String chatDispatchOrders = 'rider-service/fare/chat-dispatch/orders';

  // Multi-shop (multi-stop) orders. Additive — single-stop flow is unchanged.
  // 1) Sort shops furthest→nearest + find riders near the furthest shop.
  final String multiShopRiders = 'rider-service/fare/multi-shop/riders';
  // 2) Create the multi-stop order (book a rider).
  final String multiShopOrders = 'rider-service/fare/multi-shop/orders';
  // 2b) Create the multi-stop order as a Rapido-style BROADCAST — no rider is
  // picked; the server discovers nearby riders in expanding waves and the
  // first to accept wins. Same body as [multiShopOrders] with `selectedRiders`
  // OMITTED and an optional `vehicleType` to restrict the race to one type.
  // Sending selectedRiders here would put it back on the hand-picked path.
  final String multiShopOrdersBroadcast =
      'rider-service/fare/multi-shop/orders/broadcast';
  // Per-stop progress (rider-side): arrive / pickup at each shop.
  String multiShopStopArrive(String orderId, String businessId) =>
      'rider-service/fare/multi-shop/orders/$orderId/stops/$businessId/arrive';
  String multiShopStopPickup(String orderId, String businessId) =>
      'rider-service/fare/multi-shop/orders/$orderId/stops/$businessId/pickup';

  // Medical rider-side
  final String medicalOrderUpdatePaymentStatus =
      'rider-service/medical/orders/payment-status';
  final String medicalOrderAvailableItem =
      'rider-service/medical/orders/available-items';
  final String myMedicalOrders = 'rider-service/medical/orders/business';
  final String ridersMedicalOrders = 'rider-service/riders/orders/medical/';

  /// Rider → customer rating. POST `{ rating: 1-5, orderId }`; the server only
  /// accepts it from the order's assigned rider, on a completed order, once
  /// per order (a duplicate comes back as `alreadyRated`).
  String rateCustomer(String userId) =>
      'rider-service/riders/customers/$userId/rate';

  /// The customer's aggregate `{ average, count }`. The order lists already
  /// embed this per customer — this is for looking one up on its own.
  String customerRating(String userId) =>
      'rider-service/riders/customers/$userId/rating';

  /// Emergency contacts (user-facing endpoint hosted on rider-service).
  final String emergencyContacts = 'rider-service/emergency-contacts';

  /// Rider "Contact Us" support queries.
  /// POST → submit a query, GET → list own queries.
  /// See docs/backend/SUPPORT_QUERY_FRONTEND_GUIDE.md.
  final String supportQueries = 'rider-service/support-queries';
}
