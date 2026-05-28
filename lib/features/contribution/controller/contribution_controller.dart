import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/string_utils.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';
import 'package:BlueEra/features/contribution/model/initiate_recharge_response_model.dart';
import 'package:BlueEra/features/contribution/model/recharge_plan_model.dart';
import 'package:BlueEra/features/contribution/repo/contribution_repo.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// State holder + workflow for the Contribution / Recharge flow.
///
/// Flow (per `lib/docs/RECHARGE_FLUTTER_GUIDE.md`):
/// 1. `fetchPlans()` → renders the cards
/// 2. `purchase(plan)` → calls initiate-order → opens Razorpay checkout
/// 3. Razorpay success → `verifyPayment()` → recharge active → `fetchCurrent()`
class ContributionController extends GetxController {
  final ContributionRepo _repo = ContributionRepo();
  final RazorpayService _razorpay = RazorpayService();

  // ── Plan list state ──────────────────────────────────────────
  final RxList<RechargePlan> plans = <RechargePlan>[].obs;
  final Rx<Status> plansStatus = Status.INITIAL.obs;
  final RxString plansError = ''.obs;

  /// Recharge environment surfaced by `GET /recharge/plans` — typically
  /// `'test'` or `'live'`. Empty until the first successful fetch. UI
  /// surfaces (the contribution screen header) display a "TEST MODE"
  /// badge while this is `'test'` so the merchant knows real money
  /// isn't being charged.
  final RxString mode = ''.obs;
  bool get isTestMode => mode.value.toLowerCase() == 'test';

  // ── Purchase flow state ──────────────────────────────────────
  final RxBool isPurchasing = false.obs;
  final Rxn<RechargePlan> activePlan = Rxn<RechargePlan>();
  final Rxn<InitiateRechargeResponse> pendingOrder =
      Rxn<InitiateRechargeResponse>();

  // ── Current active recharge (if any) ─────────────────────────
  final RxBool hasActiveRecharge = false.obs;
  /// Tracks the lifecycle of `/recharge/current`. UI gating (e.g. the
  /// peek sheet on the Me tab) should treat `INITIAL`/`LOADING` as
  /// "don't decide yet" to avoid flicker before the answer lands.
  final Rx<Status> currentStatus = Status.INITIAL.obs;
  /// Raw payload returned by `GET /recharge/current` when an active
  /// recharge exists. Stored as a map so the contribution screen can
  /// surface plan name / amount / validity / expiry without us having
  /// to hard-code a parser before the backend shape is final.
  final Rxn<Map<String, dynamic>> currentRecharge =
      Rxn<Map<String, dynamic>>();

  /// Resolved bucket sent to `GET /recharge/plans?entity_type=...`.
  /// Defaults to whatever [resolveEntityType] returns for the current
  /// user/business profile. Callers can override per-fetch if needed.
  String? entityType;

  /// Maps the current user/business globals to the entity-type string
  /// the recharge service expects. Returns `null` for profiles that
  /// aren't on the contribution allowlist (e.g. gig roles outside the
  /// rider professions) — callers should treat that as "no plans".
  static String? resolveEntityType() {
    // ─── Individual profile types ─────────────────────────────────
    if (userProfileTypeGlobal == SELF_EMPLOYED) return 'SELF_EMPLOYED';
    if (userProfileTypeGlobal == PROFESSIONAL) return 'PROFESSIONAL';

    // Gig worker is allowlisted only for the four rider professions.
    if (userProfileTypeGlobal == GIG_WORKER) {
      if (userProfessionGlobal == BIKE_RIDER) return 'BIKE_RIDER';
      if (userProfessionGlobal == AUTO_TAXI) return 'AUTO_TAXI';
      if (userProfessionGlobal == GOODS_TAXI) return 'GOODS_TAXI';
      if (userProfessionGlobal == CAR_TAXI_DRIVER) return 'CAR_DRIVER_TAXI';
      return null;
    }

    // ─── Business types ───────────────────────────────────────────
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Food.name)) {
      return 'FOOD';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Grocery.name)) {
      return 'GROCERY';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Product.name)) {
      return 'PRODUCT';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Service.name)) {
      return 'SERVICE';
    }
    if (businessTypeGlobal
        .equalsIgnoreCase(BusinessType.Manufacturing.name)) {
      return 'MANUFACTURING';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Motel.name)) {
      return 'MOTEL';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Siksha.name)) {
      return 'SIKSHA';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Finance.name)) {
      return 'FINANCE';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Healthcare.name)) {
      return 'HEALTH_CARE';
    }

    // Automotive folds into PRODUCT (sales/parts) or SERVICE (rental,
    // service, support, transport-logistic) — same split the old
    // subscription flow used so existing dealerships and workshops keep
    // matching the same plan bucket.
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Automotive.name)) {
      final isProductLike = [
        AppConstants.SALES_SECTOR,
        AppConstants.PARTS_SECTOR,
      ].any((s) => s.equalsIgnoreCase(businessCategoryGlobal));
      return isProductLike ? 'PRODUCT' : 'SERVICE';
    }

    return null;
  }

  /// Buyer details for Razorpay prefill.
  String userName = '';
  String userEmail = '';
  String userPhone = '';

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
    fetchCurrent();
  }

  @override
  void onClose() {
    _razorpay.dispose();
    super.onClose();
  }

  // ─── 1. Plans ─────────────────────────────────────────────────
  Future<void> fetchPlans({String? entityType}) async {
    // Caller's override wins, otherwise auto-resolve from the current
    // profile/business globals so UI sites don't need to know the
    // bucket strings.
    this.entityType = entityType ?? resolveEntityType();
    plansStatus.value = Status.LOADING;
    plansError.value = '';
    final ResponseModel res = await _repo.fetchPlans(entityType: this.entityType);
    if (res.statusCode == 200 && res.response?.data != null) {
      final body = res.response!.data;
      // Capture the recharge mode flag the backend sends alongside the
      // plan list so the UI can surface a "TEST MODE" badge.
      final rawMode = body is Map<String, dynamic> ? body['mode'] : null;
      mode.value = rawMode?.toString() ?? '';
      final raw = body['data'];
      if (raw is List) {
        plans.assignAll(
          raw
              .whereType<Map<String, dynamic>>()
              .map(RechargePlan.fromJson)
              .toList(),
        );
        plansStatus.value = Status.COMPLETE;
        return;
      }
    }
    plansError.value = res.message ?? AppStrings.couldNotLoadPlans.tr;
    plansStatus.value = Status.ERROR;
  }

  // ─── 2. Purchase ──────────────────────────────────────────────
  /// One-shot: initiate an order on the server, then open Razorpay checkout.
  /// `referralCode` is only passed if the caller is collecting one via a
  /// dialog at recharge-time (otherwise the server applies the parked
  /// onboarding code automatically). See guide §3.2.
  Future<void> purchase(
    RechargePlan plan, {
    String? referralCode,
  }) async {
    if (isPurchasing.value) return;
    isPurchasing.value = true;
    activePlan.value = plan;
    pendingOrder.value = null;

    final ResponseModel res = await _repo.initiateOrder(
      rechargePlanId: plan.id,
      referralCode: referralCode,
    );

    if (res.statusCode != 200 || res.response?.data == null) {
      isPurchasing.value = false;
      commonSnackBar(message: res.message ?? AppStrings.failedToStartPayment.tr);
      return;
    }

    final data = res.response!.data['data'];
    if (data is! Map<String, dynamic>) {
      isPurchasing.value = false;
      commonSnackBar(message: AppStrings.unexpectedServerResponse.tr);
      return;
    }

    final order = InitiateRechargeResponse.fromJson(data);
    pendingOrder.value = order;
    _openCheckout(plan, order);
  }

  void _openCheckout(RechargePlan plan, InitiateRechargeResponse order) {
    _razorpay.openCheckout(
      razorpayKeyId: order.keyId,
      name: AppStrings.appName,
      description: '${plan.name} ${AppStrings.contributionSuffix.tr}',
      amount: order.finalAmount.toDouble(),
      contact: userPhone,
      email: userEmail,
      // Empty subscriptionId tells RazorpayService to use orderId path.
      subscriptionId: '',
      orderId: order.orderId,
      currency: order.currency,
      onPaymentSuccess: _onRazorpaySuccess,
      onPaymentError: _onRazorpayError,
    );
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      isPurchasing.value = false;
      commonSnackBar(message: AppStrings.paymentVerificationDataMissing.tr);
      return;
    }
    final ResponseModel res = await _repo.verifyPayment(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
    );
    isPurchasing.value = false;
    if (res.statusCode == 200) {
      hasActiveRecharge.value = true;
      commonSnackBar(message: AppStrings.contributionActivatedThankYou.tr);
      // Refresh /recharge/current so the status surfaces immediately.
      await fetchCurrent();
    } else {
      commonSnackBar(
        message: res.message ?? AppStrings.paymentVerificationFailedWebhook.tr,
      );
    }
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    isPurchasing.value = false;
    commonSnackBar(message: response.message ?? AppStrings.paymentFailed.tr);
  }

  // ─── 3. Current active recharge ───────────────────────────────
  Future<void> fetchCurrent() async {
    currentStatus.value = Status.LOADING;
    final ResponseModel res = await _repo.fetchCurrent();
    if (res.statusCode == 200 && res.response?.data?['data'] != null) {
      final data = res.response!.data['data'];
      currentRecharge.value =
          data is Map<String, dynamic> ? data : <String, dynamic>{};
      hasActiveRecharge.value = true;
      currentStatus.value = Status.COMPLETE;
    } else if (res.statusCode == 404) {
      // 404 = no active recharge — that's a successful "answer", not an error.
      currentRecharge.value = null;
      hasActiveRecharge.value = false;
      currentStatus.value = Status.COMPLETE;
    } else {
      currentRecharge.value = null;
      hasActiveRecharge.value = false;
      currentStatus.value = Status.ERROR;
    }
  }
}
