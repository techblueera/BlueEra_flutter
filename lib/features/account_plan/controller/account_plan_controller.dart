import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../model/account_plan_models.dart';
import '../model/deposit_migration_model.dart';
import '../repo/account_plan_repo.dart';
import '../view/account_plan_gst_sheet.dart';
import '../view/upgrade_confirm_dialog.dart';
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

  /// The buyer's GSTIN, needed to buy a `gst_track: "GST"` plan.
  ///
  /// Hydrated by the screen from the business profile's `gst.number` when the
  /// account already has one; otherwise collected (and verified) on demand by
  /// [_ensureGstin] and kept for the rest of the session so a second GST plan
  /// doesn't ask again.
  ///
  /// Reactive because the CARDS read it: a GST-track card says "GST Required"
  /// in warning red to an account without one, and drops to a neutral "GST on
  /// file" once there is. A plain field would leave that line lying until the
  /// next rebuild.
  final RxnString buyerGstin = RxnString();

  bool get hasBuyerGstin => (buyerGstin.value ?? '').trim().isNotEmpty;

  // ─── Catalog ────────────────────────────────────────────────────
  final Rx<Status> plansStatus = Status.INITIAL.obs;
  final RxString plansError = ''.obs;
  final Rxn<PlanCatalog> catalog = Rxn<PlanCatalog>();

  // ─── What the user already owns ─────────────────────────────────
  final RxList<UserAccountPlan> myPlans = <UserAccountPlan>[].obs;

  // ─── Selection ──────────────────────────────────────────────────
  /// The card the pinned "Kindly Contribute Us" bar will buy.
  ///
  /// The screen sells one plan at a time from a single bottom CTA rather than
  /// a Buy button per card, so the chosen card has to live somewhere both the
  /// list and the bar can see — here.
  final RxString selectedOptionCode = ''.obs;

  /// Cards that can actually be bought: priced, not free, not already owned.
  List<PlanCard> get purchasableCards => (catalog.value?.plans ?? const [])
      .where((p) => p.isPurchasable && !ownsPlan(p))
      .toList();

  PlanCard? get selectedCard {
    final code = selectedOptionCode.value;
    if (code.isEmpty) return null;
    for (final plan in catalog.value?.plans ?? const <PlanCard>[]) {
      if (plan.optionCode == code) return plan;
    }
    return null;
  }

  void select(PlanCard card) {
    // Locked while a checkout is open: the order was created for one specific
    // option server-side, so letting the selection drift under it would leave
    // the pay bar naming a plan the user is not actually paying for.
    if (isProcessing.value) return;
    if (!card.isPurchasable || ownsPlan(card)) return;
    selectedOptionCode.value = card.optionCode;
  }

  bool isSelected(PlanCard card) =>
      selectedOptionCode.value == card.optionCode && card.optionCode.isNotEmpty;

  /// Keeps the selection pointing at something buyable after a catalog or
  /// my-plans refresh: a plan that was just purchased, withdrawn, or re-priced
  /// must not stay selected under the pay bar.
  ///
  /// The default lands on the backend's `popular` pick when there is one, and
  /// on the first buyable card otherwise — the recommendation is the plan the
  /// catalog is steering toward, so it should be the one already under the CTA.
  ///
  /// It only ever *re-picks* when the current selection has stopped being
  /// buyable, so this can never pull the choice out from under a user who has
  /// already tapped a card.
  void _syncSelection() {
    final options = purchasableCards;
    if (options.isEmpty) {
      selectedOptionCode.value = '';
      return;
    }
    final current = selectedOptionCode.value;
    if (options.any((p) => p.optionCode == current)) return;
    final recommended = options.where((p) => p.popular);
    selectedOptionCode.value = recommended.isNotEmpty
        ? recommended.first.optionCode
        : options.first.optionCode;
  }

  // ─── Purchase ───────────────────────────────────────────────────
  final RxBool isProcessing = false.obs;

  /// Which card is mid-purchase, so only the tapped one shows a spinner.
  final RxString purchasingCode = ''.obs;

  /// Buys whatever the list currently has selected — the pinned CTA's action.
  Future<void> buySelected() async {
    final card = selectedCard;
    if (card == null) {
      commonSnackBar(message: AppStrings.selectAPlanToContinue.tr);
      return;
    }
    await buyPlan(card);
  }

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
      _syncSelection();
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
    // A plan just bought stops being selectable, so the pay bar has to move on.
    _syncSelection();
    // Same payload the go-live gate needs, so a purchase updates it here
    // rather than every gate re-fetching on its next tap.
    AccountPlanEntitlement.to.publish(parsed);
  }

  // ─── 3. Purchase ────────────────────────────────────────────────
  Future<void> buyPlan(PlanCard card) async {
    if (isProcessing.value) return;

    // A free card is the default entitlement — the backend grants it without
    // an order, so there is nothing to open checkout for. A zero total is the
    // same case arriving by a different route, and must never reach checkout.
    if (!card.isPurchasable) {
      commonSnackBar(message: AppStrings.planAlreadyFree.tr);
      return;
    }
    if (ownsPlan(card)) {
      commonSnackBar(message: AppStrings.planAlreadyActive.tr);
      return;
    }

    // GST tiers can't be ordered without a GSTIN — ask BEFORE spending a round
    // trip that the backend would only refuse. Dismissing the sheet cancels the
    // purchase rather than proceeding into a guaranteed 400.
    if (card.requiresGst && !hasBuyerGstin) {
      final gstin = await _ensureGstin(card);
      if (gstin == null) return;
    }

    // Already holding a plan makes this an UPGRADE, not a purchase: what they
    // have already paid — their current plan, or the deposit they migrated
    // from — is credited, and Razorpay will show only the difference. That
    // path prices and confirms itself; only fall through to the plain purchase
    // below when there is nothing to credit against.
    if (hasActivePlan) {
      final handled = await _upgradePlan(card);
      if (handled) return;
    }

    isProcessing.value = true;
    purchasingCode.value = card.optionCode;

    var res = await _repo.initiate(
      optionCode: card.optionCode,
      tagId: tagId,
      hasGst: hasGst,
      buyerState: buyerState,
      buyerGstin: card.requiresGst ? buyerGstin.value : null,
    );

    // The backend is the authority on whether the GSTIN is acceptable, and it
    // can reject one this client was perfectly happy with — stale, cancelled,
    // or belonging to a different state. It says so with `requires_gst`, so
    // re-ask once and retry rather than reporting a payment failure.
    if (_requiresGst(res)) {
      buyerGstin.value = null;
      _reset();
      final gstin = await _ensureGstin(card, message: res.message);
      if (gstin == null) return;
      isProcessing.value = true;
      purchasingCode.value = card.optionCode;
      res = await _repo.initiate(
        optionCode: card.optionCode,
        tagId: tagId,
        hasGst: hasGst,
        buyerState: buyerState,
        buyerGstin: gstin,
      );
    }

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

  // ─── 3b. Upgrade with credit ────────────────────────────────────
  /// True when the user holds any active plan, which is what turns a purchase
  /// into an upgrade.
  bool get hasActivePlan => activeOptionCodes.isNotEmpty;

  /// Set for the lifetime of one upgrade checkout, so the payment that comes
  /// back is verified against the endpoint that priced it. Verifying an upgrade
  /// order through the plain plan verify would settle it against the wrong
  /// ledger — the order was created for a difference, not a plan price.
  bool _verifyingUpgrade = false;

  /// Prices, confirms and starts an upgrade for [card].
  ///
  /// Returns true when this path has taken responsibility for the tap —
  /// including when the user cancelled. False means "not an upgrade after all"
  /// (no options, no breakdown, endpoint unavailable), and the caller then runs
  /// the ordinary full-price purchase rather than leaving the merchant unable
  /// to buy anything.
  ///
  /// The confirmation is not optional and not a snackbar: the catalog card says
  /// one price and the payment sheet will say another, so the arithmetic that
  /// reconciles them is shown, in the middle of the screen, before anything is
  /// charged. When the credit is the refundable deposit, the same dialog
  /// carries the terms and the pay button stays dead until they are accepted.
  Future<bool> _upgradePlan(PlanCard card) async {
    final options = await _repo.upgradeOptions();
    final optionsData = _dataOf(options);
    if (optionsData == null) return false;

    final parsed = UpgradeOptions.fromJson(optionsData);
    if (!parsed.hasActivePlan) return false;

    final option = parsed.forCode(card.optionCode);
    final breakdown = option?.breakdown;
    // No breakdown means the backend is not offering this tier as an upgrade
    // (same tier, a downgrade, or a different archetype). Nothing to credit,
    // so it is an ordinary purchase.
    if (option == null || breakdown == null) return false;

    final context = Get.context;
    if (context == null) return false;

    final confirmed = await showUpgradeConfirmDialog(
      context,
      planLabel: card.label,
      breakdown: breakdown,
      requiresTnc: option.requiresTnc,
    );
    // Cancelled at the confirmation — handled, and deliberately silent.
    if (!confirmed) return true;

    isProcessing.value = true;
    purchasingCode.value = card.optionCode;

    var res = await _repo.upgrade(
      optionCode: card.optionCode,
      buyerState: buyerState,
      // Only sent when the user has just been shown the deposit terms and
      // ticked them; the dialog would not have returned true otherwise.
      tncAccepted: option.requiresTnc ? true : null,
    );
    var data = _dataOf(res);
    if (data == null) {
      _reset();
      commonSnackBar(
          message: res.message ?? AppStrings.couldNotStartPayment.tr);
      return true;
    }

    var order = UpgradeOrder.fromJson(data);

    // The backend can still ask for the terms — the credit source is decided
    // server-side and may not have been `deposit` when the options were read.
    // Show them with the breakdown IT sent, then re-post.
    if (order.requiresTnc) {
      _reset();
      if (!context.mounted) return true;
      final accepted = await showUpgradeConfirmDialog(
        context,
        planLabel: card.label,
        breakdown: order.breakdown ?? breakdown,
        requiresTnc: true,
      );
      if (!accepted) return true;
      isProcessing.value = true;
      purchasingCode.value = card.optionCode;
      res = await _repo.upgrade(
        optionCode: card.optionCode,
        buyerState: buyerState,
        tncAccepted: true,
      );
      data = _dataOf(res);
      if (data == null) {
        _reset();
        commonSnackBar(
            message: res.message ?? AppStrings.couldNotStartPayment.tr);
        return true;
      }
      order = UpgradeOrder.fromJson(data);
    }

    // The credit covered the whole tier — activated outright, nothing to pay.
    if (order.upgraded || !order.hasOrder) {
      _reset();
      commonSnackBar(message: AppStrings.planActivated.tr);
      await fetchPlans();
      return true;
    }

    _verifyingUpgrade = true;
    _razorpay.openCheckout(
      razorpayKeyId: order.keyId,
      name: AppStrings.appName,
      description: card.label,
      // PAISE, and the DIFFERENCE only — the credit is already deducted
      // server-side. Never the catalog price.
      amount: order.totalAmount.toDouble(),
      contact: buyerPhone,
      email: buyerEmail,
      subscriptionId: '',
      orderId: order.orderId,
      currency: order.currency,
      onPaymentSuccess: _onPaymentSuccess,
      onPaymentError: _onPaymentError,
    );
    return true;
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    // An upgrade order settles through the upgrade's own verify — see
    // [_verifyingUpgrade].
    final wasUpgrade = _verifyingUpgrade;
    _verifyingUpgrade = false;
    final res = wasUpgrade
        ? await _repo.verifyUpgrade(
            orderId: r.orderId ?? '',
            paymentId: r.paymentId ?? '',
            signature: r.signature ?? '',
          )
        : await _repo.verifyPayment(
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
    _verifyingUpgrade = false;
  }

  // ─── GST gate ───────────────────────────────────────────────────
  /// Whether a refusal was specifically "this plan needs a GST number".
  ///
  /// Read defensively: it lives in the ERROR body, which is returned rather
  /// than thrown, and its shape is only guaranteed for this one case.
  bool _requiresGst(ResponseModel res) {
    if (res.statusCode == 200) return false;
    try {
      final body = res.response?.data;
      if (body is! Map) return false;
      final data = body['data'];
      return data is Map && data['requires_gst'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Collects and verifies a GSTIN through the shared sheet, storing it for the
  /// rest of the session. Returns null when the user dismissed it — the caller
  /// must then abandon the purchase.
  ///
  /// The sheet needs a BuildContext; `Get.context` is the app's own way of
  /// reaching one from a controller (the availability sheet does the same). No
  /// context means no way to ask, so the purchase stops with the reason shown.
  Future<String?> _ensureGstin(PlanCard card, {String? message}) async {
    if (hasBuyerGstin) return buyerGstin.value;
    if (message != null && message.isNotEmpty) {
      commonSnackBar(message: message);
    }
    final context = Get.context;
    if (context == null) {
      commonSnackBar(message: AppStrings.gstRequiredForPlan.tr);
      return null;
    }
    final gstin = await showAccountPlanGstSheet(context, card: card);
    if (gstin == null || gstin.isEmpty) return null;
    buyerGstin.value = gstin;
    return gstin;
  }
}
