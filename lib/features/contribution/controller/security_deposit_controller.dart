import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/keyed_json_cache.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';
import 'package:BlueEra/features/contribution/model/security_deposit_models.dart';
import 'package:BlueEra/features/contribution/repo/security_deposit_repo.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// State + workflow for the Security Deposit ("contribution v2") flow.
///
/// Flow (see docs/backend/SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md):
///   1. [fetchCurrent] — 200 → user already has a held deposit; 404 → none.
///   2. [fetchPlans]   — catalog for the user's account type.
///   3. [payDeposit]   — `initiate` (creates a Razorpay order) → open Razorpay
///      checkout → `verify-payment` (`created → held`). A zero-deposit tag skips
///      payment and comes back already `held`.
///   4. [requestRefund] — after the refund-lock window; [cancelDeposit] for an
///      unpaid `created` intent.
class SecurityDepositController extends GetxController {
  final SecurityDepositRepo _repo = SecurityDepositRepo();
  final RazorpayService _razorpay = RazorpayService();

  // ── Plans catalog ────────────────────────────────────────────
  final RxList<SecurityDepositPlan> plans = <SecurityDepositPlan>[].obs;
  final Rx<Status> plansStatus = Status.INITIAL.obs;
  final RxString plansError = ''.obs;

  /// Plan backing the pinned "Pay Security Deposit" bottom bar. Auto-set to the
  /// first payable plan when the catalog loads; the user can switch it by
  /// tapping another payable plan card. Zero-deposit plans are informational
  /// (no payment) and never become the selection.
  final Rxn<SecurityDepositPlan> selectedPlan = Rxn<SecurityDepositPlan>();

  void selectPlan(SecurityDepositPlan plan) => selectedPlan.value = plan;

  /// First plan that actually requires a payment (deposit > 0), or null when
  /// none. Backs the always-visible bottom Pay bar when no explicit selection
  /// has been made yet.
  SecurityDepositPlan? get firstPayablePlan {
    for (final p in plans) {
      if (p.depositAmount > 0) return p;
    }
    return null;
  }

  /// `live` / `test` (Razorpay env), surfaced from the plan/deposit payload so
  /// the UI can show a "TEST MODE" banner.
  final RxString mode = ''.obs;
  bool get isTestMode => mode.value.toLowerCase() == 'test';

  // ── Explainer videos (shown on top of the deposit screen) ────
  final RxList<SecurityDepositVideo> videos = <SecurityDepositVideo>[].obs;

  // ── Current (held) deposit ───────────────────────────────────
  final Rx<Status> currentStatus = Status.INITIAL.obs;
  final Rxn<UserSecurityDeposit> currentDeposit = Rxn<UserSecurityDeposit>();

  /// True only while the deposit is `held`.
  bool get hasActiveDeposit => currentDeposit.value?.isHeld == true;

  // ── Action flow (pay / refund / cancel) ──────────────────────
  final RxBool isProcessing = false.obs;

  /// Buyer details for Razorpay prefill — hydrated by the view before pay.
  String userName = '';
  String userEmail = '';
  String userPhone = '';

  /// `BUSINESS` / `INDIVIDUAL` — the account-type query the catalog is scoped
  /// to (matches the backend's uppercase values).
  String get accountType => isBusinessUser() ? 'BUSINESS' : 'INDIVIDUAL';

  /// Entity tag the catalog is scoped to: the business category for business
  /// accounts, the profession for individuals.
  String get tagId =>
      isBusinessUser() ? businessCategoryGlobal : userProfessionGlobal;

  @override
  void onInit() {
    super.onInit();
    fetchCurrent();
    fetchPlans();
    fetchVideos();
  }

  @override
  void onClose() {
    _razorpay.dispose();
    super.onClose();
  }

  // ─── 1. Plans ─────────────────────────────────────────────────
  Future<void> fetchPlans() async {
    plansStatus.value = Status.LOADING;
    plansError.value = '';
    final ResponseModel res =
        await _repo.fetchPlans(tagId: tagId, accountType: accountType);
    if (res.statusCode == 200 && res.response?.data != null) {
      final raw = res.response!.data['data'];
      if (raw is List) {
        final parsed = raw
            .whereType<Map<String, dynamic>>()
            .map(SecurityDepositPlan.fromJson)
            .toList();
        plans.assignAll(parsed);
        if (parsed.isNotEmpty && mode.value.isEmpty) {
          mode.value = parsed.first.mode;
        }
        // Default the bottom-bar selection to the first payable plan (preserve
        // an existing valid selection across refreshes).
        final current = selectedPlan.value;
        final stillPresent =
            current != null && parsed.any((p) => p.id == current.id);
        if (!stillPresent) {
          SecurityDepositPlan? firstPayable;
          for (final p in parsed) {
            if (p.depositAmount > 0) {
              firstPayable = p;
              break;
            }
          }
          selectedPlan.value = firstPayable;
        }
        plansStatus.value = Status.COMPLETE;
        return;
      }
    }
    plansError.value = res.message ?? 'Could not load deposit plans';
    plansStatus.value = Status.ERROR;
  }

  // ─── 1b. Explainer videos ─────────────────────────────────────
  static const String _videosCacheKey = 'videos';

  /// Loads the deposit-screen explainer videos. Cache-first: once fetched, the
  /// raw list is persisted to Hive and served from there on subsequent opens so
  /// the API isn't called again (the videos are effectively static; the box is
  /// wiped on logout, so a re-login refetches once). Only a cache miss hits the
  /// network. Silent on failure — the video section just stays hidden, it's not
  /// critical to the pay/refund flow.
  Future<void> fetchVideos() async {
    // 1) Serve from cache and skip the network when we already have a copy.
    final cached = await securityDepositVideosCache.get(_videosCacheKey);
    final cachedList = cached?['videos'];
    if (cachedList is List && cachedList.isNotEmpty) {
      _applyVideos(cachedList);
      return;
    }

    // 2) Cache miss → hit the API, render, then persist the raw master list.
    final ResponseModel res = await _repo.fetchVideos();
    if (res.statusCode == 200 && res.response?.data?['data'] is List) {
      final raw = res.response!.data['data'] as List;
      _applyVideos(raw);
      final maps = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await securityDepositVideosCache.save(_videosCacheKey, {'videos': maps});
    }
  }

  /// Parses a raw video list (from cache or API) into the observable [videos],
  /// keeping only active videos that carry a playable URL.
  void _applyVideos(List raw) {
    final parsed = raw
        .whereType<Map>()
        .map((e) => SecurityDepositVideo.fromJson(Map<String, dynamic>.from(e)))
        .where((v) => v.isActive && v.hasUrl)
        .toList();
    videos.assignAll(parsed);
  }

  // ─── 2. Current held deposit ──────────────────────────────────
  Future<void> fetchCurrent() async {
    currentStatus.value = Status.LOADING;
    final ResponseModel res = await _repo.fetchCurrent();
    if (res.statusCode == 200 && res.response?.data?['data'] != null) {
      final data = res.response!.data['data'];
      if (data is Map<String, dynamic>) {
        final deposit = UserSecurityDeposit.fromJson(data);
        currentDeposit.value = deposit;
        if (deposit.mode.isNotEmpty) mode.value = deposit.mode;
      } else {
        currentDeposit.value = null;
      }
      currentStatus.value = Status.COMPLETE;
    } else if (res.statusCode == 404) {
      // 404 = no active deposit — a valid "answer", not an error.
      currentDeposit.value = null;
      currentStatus.value = Status.COMPLETE;
    } else {
      currentDeposit.value = null;
      currentStatus.value = Status.ERROR;
    }
  }

  // ─── 3. Pay (initiate → Razorpay → verify-payment) ────────────
  /// Creates a Razorpay order for [plan], opens checkout, and on success
  /// verifies the payment to flip the deposit to `held`. An optional
  /// [referralCode] applies the refer-&-earn discount (the server also
  /// auto-applies a parked onboarding code when none is passed). A
  /// zero-deposit plan skips Razorpay and is activated immediately.
  Future<void> payDeposit(SecurityDepositPlan plan, {String? referralCode}) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    final ResponseModel initRes = await _repo.initiate(
      securityDepositPlanId: plan.id,
      referralCode: referralCode,
    );

    // "Already has a held deposit" comes back as 400 carrying the existing
    // deposit id/status — just refresh and surface the active card.
    if (initRes.statusCode == 400 &&
        initRes.response?.data?['data']?['security_deposit_id'] != null) {
      isProcessing.value = false;
      await fetchCurrent();
      commonSnackBar(
          message: initRes.message ?? 'You already have an active deposit');
      return;
    }

    final data = initRes.response?.data?['data'];
    if (initRes.statusCode != 200 || data is! Map<String, dynamic>) {
      isProcessing.value = false;
      commonSnackBar(message: initRes.message ?? 'Could not start the deposit');
      return;
    }

    final order = InitiateSecurityDepositResponse.fromJson(data);
    if (order.securityDepositId.isEmpty) {
      isProcessing.value = false;
      commonSnackBar(message: AppStrings.unexpectedServerResponse.tr);
      return;
    }
    // Zero-deposit tag: no payment needed, already `held`.
    if (order.isZeroDeposit) {
      isProcessing.value = false;
      commonSnackBar(message: 'Security deposit activated');
      await fetchCurrent();
      return;
    }

    // Open Razorpay checkout — verification happens in the success handler.
    _razorpay.openCheckout(
      razorpayKeyId: order.keyId,
      name: AppStrings.appName,
      description: '${plan.name} security deposit',
      amount: order.finalAmount.toDouble(), // paise
      contact: userPhone,
      email: userEmail,
      // Empty subscriptionId tells RazorpayService to use the orderId path.
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
      isProcessing.value = false;
      commonSnackBar(message: AppStrings.paymentVerificationDataMissing.tr);
      return;
    }
    final ResponseModel res = await _repo.verifyPayment(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
    );
    isProcessing.value = false;
    if (res.statusCode == 200) {
      commonSnackBar(message: 'Security deposit activated');
    } else {
      // The webhook is the source of truth and will still activate the
      // deposit server-side, so re-fetch below surfaces the held state.
      commonSnackBar(
          message: res.message ?? AppStrings.paymentVerificationFailedWebhook.tr);
    }
    await fetchCurrent();
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    isProcessing.value = false;
    commonSnackBar(message: response.message ?? AppStrings.paymentFailed.tr);
  }

  // ─── 4a. Refund ───────────────────────────────────────────────
  /// Requests a refund for the current held deposit. On a 400 lock-window
  /// response the eligible date is returned via [onLocked].
  Future<void> requestRefund({void Function(String eligibleAt)? onLocked}) async {
    final depositId = currentDeposit.value?.id ?? '';
    if (depositId.isEmpty || isProcessing.value) return;
    isProcessing.value = true;
    try {
      final ResponseModel res = await _repo.requestRefund(depositId: depositId);
      if (res.statusCode == 200) {
        commonSnackBar(message: 'Refund requested');
        await fetchCurrent();
        return;
      }
      final eligibleAt =
          res.response?.data?['data']?['refund_eligible_at']?.toString() ?? '';
      if (res.statusCode == 400 && eligibleAt.isNotEmpty) {
        onLocked?.call(eligibleAt);
        return;
      }
      commonSnackBar(message: res.message ?? 'Could not request the refund');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── 4b. Cancel (unpaid intent only) ──────────────────────────
  Future<void> cancelDeposit() async {
    final depositId = currentDeposit.value?.id ?? '';
    if (depositId.isEmpty || isProcessing.value) return;
    isProcessing.value = true;
    try {
      final ResponseModel res = await _repo.cancel(depositId: depositId);
      if (res.statusCode == 200) {
        commonSnackBar(message: 'Deposit cancelled');
        await fetchCurrent();
      } else {
        commonSnackBar(message: res.message ?? 'Could not cancel the deposit');
      }
    } finally {
      isProcessing.value = false;
    }
  }
}
