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
  final String favoriteLocations = "rider-service/favorite-locations";

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

  // Medical rider-side
  final String medicalOrderUpdatePaymentStatus =
      'rider-service/medical/orders/payment-status';
  final String medicalOrderAvailableItem =
      'rider-service/medical/orders/available-items';
  final String myMedicalOrders = 'rider-service/medical/orders/business';
  final String ridersMedicalOrders = 'rider-service/riders/orders/medical/';

  /// Emergency contacts (user-facing endpoint hosted on rider-service).
  final String emergencyContacts = 'rider-service/emergency-contacts';
}
