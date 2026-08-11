import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../model/account_plan_models.dart';
import '../repo/account_plan_repo.dart';
import 'account_plan_entitlement.dart';

/// Drives the Account Plan catalog and its purchase: initiate → Razorpay →
/// verify → re-fetch. Mirrors `SecurityDepositController`, which is the
/// closest working precedent in the app.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
class AccountPlanController extends GetxController {
  final AccountPlanRepo _repo = AccountPlanRepo();
  final RazorpayService _razorpay = RazorpayService();

  // ─── Inputs, set by the screen from the user's profile ──────────
  String? tagId;
  bool? hasGst;
  String? accountType;
  String? buyerState;
  String buyerName = '';
  String buyerEmail = '';
  String buyerPhone = '';

  // ─── Catalog ────────────────────────────────────────────────────
  final Rx<Status> plansStatus = Status.INITIAL.obs;
  final RxString plansError = ''.obs;
  final Rxn<PlanCatalog> catalog = Rxn<PlanCatalog>();

  // ─── What the user already owns ─────────────────────────────────
  final RxList<UserAccountPlan> myPlans = <UserAccountPlan>[].obs;

  // ─── Purchase ───────────────────────────────────────────────────
  final RxBool isProcessing = false.obs;

  /// Which card is mid-purchase, so only the tapped one shows a spinner.
  final RxString purchasingCode = ''.obs;

  /// Option codes the user already holds — the catalog does not mark them, so
  /// this is what turns a Buy button into "Active".
  Set<String> get activeOptionCodes => myPlans
      .where((p) => p.isActive)
      .map((p) => p.optionCode)
      .where((c) => c.isNotEmpty)
      .toSet();

  bool ownsPlan(PlanCard card) => activeOptionCodes.contains(card.optionCode);

  @override
  void onClose() {
    _razorpay.dispose();
    super.onClose();
  }

  /// The `data` map of a 2xx envelope, or null when the call failed or the
  /// body wasn't the shape we expect. `badResponse` is RETURNED by the Dio
  /// helper rather than thrown, so every call site branches on the status
  /// code instead of catching.
  Map<String, dynamic>? _dataOf(ResponseModel res) {
    if (res.statusCode != 200) return null;
    final data = res.response?.data;
    if (data is! Map) return null;
    final inner = data['data'];
    return inner is Map ? Map<String, dynamic>.from(inner) : null;
  }

  // ─── 1. Catalog ─────────────────────────────────────────────────
  Future<void> fetchPlans() async {
    plansStatus.value = Status.LOADING;
    plansError.value = '';
    final res = await _repo.getPlans(
      tagId: tagId,
      hasGst: hasGst,
      accountType: accountType,
    );
    final data = _dataOf(res);
    if (data != null) {
      catalog.value = PlanCatalog.fromJson(data);
      plansStatus.value = Status.COMPLETE;
      // Owned plans decide how each card renders, so they are loaded
      // alongside — but a failure there must not blank the catalog.
      await fetchMyPlans();
      return;
    }
    plansError.value = res.message ?? AppStrings.somethingWentWrong.tr;
    plansStatus.value = Status.ERROR;
  }

  // ─── 2. Owned plans ─────────────────────────────────────────────
  Future<void> fetchMyPlans() async {
    final res = await _repo.myPlans(status: 'active');
    if (res.statusCode != 200) return;
    final raw = res.response?.data;
    final list = (raw is Map ? raw['data'] : null);
    if (list is! List) return;
    final parsed = list
        .whereType<Map>()
        .map((e) => UserAccountPlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    myPlans.assignAll(parsed);
    // Same payload the go-live gate needs, so a purchase updates it here
    // rather than every gate re-fetching on its next tap.
    AccountPlanEntitlement.to.publish(parsed);
  }

  // ─── 3. Purchase ────────────────────────────────────────────────
  Future<void> buyPlan(PlanCard card) async {
    if (isProcessing.value) return;

    // A free card is the default entitlement — the backend grants it without
    // an order, so there is nothing to open checkout for.
    if (card.isFree) {
      commonSnackBar(message: AppStrings.planAlreadyFree.tr);
      return;
    }
    if (ownsPlan(card)) {
      commonSnackBar(message: AppStrings.planAlreadyActive.tr);
      return;
    }

    isProcessing.value = true;
    purchasingCode.value = card.optionCode;

    final res = await _repo.initiate(
      optionCode: card.optionCode,
      tagId: tagId,
      hasGst: hasGst,
      buyerState: buyerState,
    );
    final data = _dataOf(res);
    if (data == null) {
      // Covers "already owned" (400) and every other refusal. Never open
      // checkout on a non-200.
      _reset();
      commonSnackBar(
          message: res.message ?? AppStrings.couldNotStartPayment.tr);
      await fetchMyPlans();
      return;
    }

    final order = InitiatePlanResponse.fromJson(data);

    // Free option, or a resumed order that turned out to be already paid: the
    // backend has activated it and there is no order to pay.
    if (order.isAlreadyActive) {
      _reset();
      commonSnackBar(message: AppStrings.planActivated.tr);
      await fetchPlans();
      return;
    }

    _razorpay.openCheckout(
      razorpayKeyId: order.keyId,
      name: AppStrings.appName,
      description: card.label,
      // PAISE, GST-inclusive, straight from the server. Never a locally
      // computed total — the catalog price is for display only.
      amount: order.totalAmount.toDouble(),
      contact: buyerPhone,
      email: buyerEmail,
      // '' selects the one-time order_id path rather than the recurring one.
      subscriptionId: '',
      orderId: order.orderId,
      currency: order.currency,
      onPaymentSuccess: _onPaymentSuccess,
      onPaymentError: _onPaymentError,
    );
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    final res = await _repo.verifyPayment(
      orderId: r.orderId ?? '',
      paymentId: r.paymentId ?? '',
      signature: r.signature ?? '',
    );
    _reset();

    final body = res.response?.data;
    final ok = res.statusCode == 200 &&
        (body is Map && (body['status'] == 'ok' || body['success'] == true));
    // Not an error when it isn't ok: the webhook is the source of truth and
    // may simply have not landed yet, so the wording says "pending", not
    // "failed", and the catalog is re-read either way.
    commonSnackBar(
      message: ok
          ? AppStrings.planActivated.tr
          : AppStrings.paymentVerifyPending.tr,
    );
    await fetchPlans();
  }

  void _onPaymentError(PaymentFailureResponse r) {
    _reset();
    commonSnackBar(message: RazorpayService.humanReadableError(r));
  }

  void _reset() {
    isProcessing.value = false;
    purchasingCode.value = '';
  }
}
