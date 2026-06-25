import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/contribution/model/security_deposit_models.dart';
import 'package:BlueEra/features/contribution/repo/security_deposit_repo.dart';
import 'package:get/get.dart';

/// State + workflow for the Security Deposit ("contribution v2") flow.
///
/// Flow (see docs/backend/SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md):
///   1. [fetchCurrent] — 200 → user already has a held deposit; 404 → none.
///   2. [fetchPlans]   — catalog for the user's account type.
///   3. [payDeposit]   — `initiate` (records intent) → `confirm` (payment
///      placeholder until Razorpay lands) → `held`.
///   4. [requestRefund] — after the refund-lock window; [cancelDeposit] for an
///      unpaid `created` intent.
class SecurityDepositController extends GetxController {
  final SecurityDepositRepo _repo = SecurityDepositRepo();

  // ── Plans catalog ────────────────────────────────────────────
  final RxList<SecurityDepositPlan> plans = <SecurityDepositPlan>[].obs;
  final Rx<Status> plansStatus = Status.INITIAL.obs;
  final RxString plansError = ''.obs;

  /// `live` / `test` (Razorpay env), surfaced from the plan/deposit payload so
  /// the UI can show a "TEST MODE" banner.
  final RxString mode = ''.obs;
  bool get isTestMode => mode.value.toLowerCase() == 'test';

  // ── Current (held) deposit ───────────────────────────────────
  final Rx<Status> currentStatus = Status.INITIAL.obs;
  final Rxn<UserSecurityDeposit> currentDeposit = Rxn<UserSecurityDeposit>();

  /// True only while the deposit is `held`.
  bool get hasActiveDeposit => currentDeposit.value?.isHeld == true;

  // ── Action flow (pay / refund / cancel) ──────────────────────
  final RxBool isProcessing = false.obs;

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
        plansStatus.value = Status.COMPLETE;
        return;
      }
    }
    plansError.value = res.message ?? 'Could not load deposit plans';
    plansStatus.value = Status.ERROR;
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

  // ─── 3. Pay (initiate → confirm) ──────────────────────────────
  /// Records intent for [plan], then confirms it (payment placeholder).
  Future<void> payDeposit(SecurityDepositPlan plan) async {
    if (isProcessing.value) return;
    isProcessing.value = true;
    try {
      final ResponseModel initRes =
          await _repo.initiate(securityDepositPlanId: plan.id);

      // "Already has a held deposit" comes back as 400 carrying the existing
      // deposit id/status — just refresh and surface the active card.
      if (initRes.statusCode == 400 &&
          initRes.response?.data?['data']?['security_deposit_id'] != null) {
        await fetchCurrent();
        commonSnackBar(
            message: initRes.message ?? 'You already have an active deposit');
        return;
      }

      if (initRes.statusCode != 200 ||
          initRes.response?.data?['data']?['security_deposit_id'] == null) {
        commonSnackBar(
            message: initRes.message ?? 'Could not start the deposit');
        return;
      }

      final depositId =
          initRes.response!.data['data']['security_deposit_id'].toString();

      final ResponseModel confirmRes = await _repo.confirm(depositId: depositId);
      if (confirmRes.statusCode == 200) {
        commonSnackBar(message: 'Security deposit activated');
        await fetchCurrent();
      } else {
        commonSnackBar(
            message: confirmRes.message ?? 'Could not confirm the deposit');
      }
    } finally {
      isProcessing.value = false;
    }
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
