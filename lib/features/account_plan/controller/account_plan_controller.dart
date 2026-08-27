import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../model/account_plan_models.dart';
import '../model/deposit_migration_model.dart';
import '../repo/account_plan_repo.dart';
import '../view/account_plan_checkout_sheet.dart';
import '../view/account_plan_gst_sheet.dart';
import '../view/upgrade_confirm_dialog.dart';
import 'account_plan_entitlement.dart';

/// Drives the Account Plan catalog and its purchase: initiate → Razorpay →
/// verify → re-fetch. Mirrors `SecurityDepositController`, which is the
/// closest working precedent in the app.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
class AccountPlanController extends GetxController with WidgetsBindingObserver {
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

  // ─── Discounts ──────────────────────────────────────────────────
  // See docs/backend/ACCOUNT_PLAN_DISCOUNT_FLUTTER_GUIDE.md. Nothing here
  // computes a discount: the catalog arrives priced, `initiate` arrives priced,
  // and both are shown as sent.

  /// A coupon the user typed. Sent on `plans` (to unlock a coupon-only
  /// campaign, which is invisible without it) and again on `initiate` (so the
  /// order is created under the same campaign the card promised).
  final RxString couponCode = ''.obs;

  /// True when a code was applied and the catalog came back with nothing
  /// matching it. **The server decides validity** — this is only the result of
  /// asking, never a rule of our own.
  final RxBool couponInvalid = false.obs;

  /// True while a coupon is being applied, so the field can show a spinner
  /// without blanking the catalog underneath it.
  final RxBool isApplyingCoupon = false.obs;

  /// Set when the server refuses a stale price (409 `price_changed`) — the
  /// campaign ended while the buyer was deciding. Drives the re-confirm
  /// dialog; **never** an automatic retry, because the buyer has to see and
  /// accept the new price.
  final Rxn<Map<String, dynamic>> priceChanged = Rxn<Map<String, dynamic>>();

  /// The campaign running over this catalog, or null when the system is off or
  /// nothing is live. The single gate for every discount affordance.
  PlanCampaign? get activeCampaign =>
      catalog.value?.showCampaign == true ? catalog.value!.campaign : null;

  /// Applies (or clears) a coupon and re-reads the catalog under it.
  Future<void> applyCoupon(String code) async {
    final next = code.trim().toUpperCase();
    if (isApplyingCoupon.value) return;
    isApplyingCoupon.value = true;
    couponCode.value = next;
    couponInvalid.value = false;
    try {
      await fetchPlans();
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  Future<void> clearCoupon() => applyCoupon('');

  /// A countdown hit zero with the screen open — the offer is over, so go and
  /// get honest prices.
  ///
  /// Skipped while a checkout is open: re-pricing the cards under a buyer who
  /// is mid-payment would change the plan behind the sheet they are looking at.
  /// That case is not unguarded — `expected_total_amount` makes the server
  /// refuse the stale price with a 409 instead.
  Future<void> onOfferExpired() async {
    if (isProcessing.value) return;
    await fetchPlans();
  }

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

  /// The option code a checkout is currently open for, or null.
  ///
  /// This is what [_onAppResumed] recovers against: it is set the instant
  /// before the sheet opens and cleared by [_reset] once the payment has been
  /// settled one way or the other, so a non-null value on resume means "we
  /// went away mid-payment and never heard how it ended".
  String? _pendingOptionCode;

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

  /// The PURCHASE behind a catalog card, or null when the user doesn't hold it.
  ///
  /// The catalog card is what the plan costs; this is what the user bought —
  /// and only the purchase carries the refund window, so the refund control
  /// reads through here rather than off the card.
  UserAccountPlan? ownedPlanFor(PlanCard card) => myPlans.firstWhereOrNull(
      (p) => p.isActive && p.optionCode == card.optionCode);

  /// True while a refund request is in flight, so the tapped control can show
  /// a spinner and stop a second tap creating a second request.
  final RxBool isRequestingRefund = false.obs;

  /// Ask for the plan fee back. The confirm sheet (with the terms the guide
  /// dictates) is the CALLER's job — reaching here means the user accepted it,
  /// which is what `tnc_accepted: true` asserts.
  ///
  /// Refreshes `my-plans` on success rather than patching the object in place:
  /// the server owns `refund_status` and the window, and a locally-flipped
  /// status that the next read disagreed with would be worse than a moment's
  /// wait.
  Future<void> requestRefund(UserAccountPlan plan, {String? note}) async {
    if (isRequestingRefund.value || plan.id.isEmpty) return;
    // The API is NEVER called while the button is disabled — `can_request_refund`
    // is the single enable condition (guide §2.2.2), and this is the one place
    // that can enforce it for every caller. The control that leads here is not
    // tappable in that state, so this is a backstop against a future caller,
    // not a path a user can reach; it stays silent for that reason.
    if (!plan.refund.canRequestRefund) {
      debugPrint('⛔ requestRefund blocked: can_request_refund=false '
          '(status=${plan.refund.refundStatus}, '
          'daysUntilEligible=${plan.refund.daysUntilEligible})');
      return;
    }
    isRequestingRefund.value = true;
    try {
      final res = await _repo.requestRefund(accountPlanId: plan.id, note: note);
      if (res.statusCode == 200) {
        // The 200 body carries the updated refund object, but my-plans is what
        // every card on this screen reads, so re-read it rather than keeping
        // two copies that can disagree.
        await fetchMyPlans();
        commonSnackBar(message: AppStrings.refundRequestSubmitted.tr);
        return;
      }
      // `refund_window_not_open` means our snapshot was stale — the card said
      // the window was open, the server disagrees, and it sends back the same
      // `days_until_eligible` the disabled label would have quoted. Re-read
      // my-plans so the card corrects itself to the countdown instead of
      // staying an enabled button that just failed.
      final blockedDays = _refundWindowNotOpenDays(res);
      if (blockedDays != null) {
        await fetchMyPlans();
        commonSnackBar(
          message: blockedDays == 1
              ? AppStrings.refundWindowNotOpenOneDay.tr
              : AppStrings.refundWindowNotOpenFmt
                  .trParams({'days': '$blockedDays'}),
        );
        return;
      }
      // Every other 400/403 carries the reason — already requested, refunds
      // disabled. The server's wording is more specific than anything this
      // screen could say, so it is shown as sent.
      commonSnackBar(
        message: res.message?.toString().trim().isNotEmpty == true
            ? res.message.toString()
            : AppStrings.refundRequestFailed.tr,
      );
    } catch (e) {
      debugPrint('❌ AccountPlanController.requestRefund error: $e');
      commonSnackBar(message: AppStrings.refundRequestFailed.tr);
    } finally {
      isRequestingRefund.value = false;
    }
  }

  /// `days_until_eligible` off a `refund_window_not_open` rejection, or null
  /// when the failure was anything else (already requested, refunds disabled)
  /// and the server's own `message` should be shown instead.
  ///
  /// The code and the count are looked for at the root, under `data` and under
  /// `data.refund`: the guide pins the SUCCESS shape but not the error
  /// envelope, and reading only one of the three would quietly fall back to the
  /// generic message for the other two.
  int? _refundWindowNotOpenDays(ResponseModel res) {
    try {
      final body = res.response?.data;
      if (body is! Map) return null;
      final root = Map<String, dynamic>.from(body);
      final data = root['data'] is Map
          ? Map<String, dynamic>.from(root['data'] as Map)
          : const <String, dynamic>{};
      final refund = data['refund'] is Map
          ? Map<String, dynamic>.from(data['refund'] as Map)
          : const <String, dynamic>{};

      final code =
          (root['error'] ?? root['code'] ?? data['error'] ?? data['code'] ?? '')
              .toString()
              .toLowerCase();
      final message = res.message?.toString().toLowerCase() ?? '';
      if (code != 'refund_window_not_open' &&
          !message.contains('refund_window_not_open')) {
        return null;
      }

      final raw = root['days_until_eligible'] ??
          data['days_until_eligible'] ??
          refund['days_until_eligible'];
      final days =
          raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
      return (days != null && days > 0) ? days : null;
    } catch (e) {
      debugPrint('❌ _refundWindowNotOpenDays parse error: $e');
      return null;
    }
  }

  /// The active A1 sales plan, or null. Both halves of the guide's gate in one
  /// place: an ACTIVE plan (§2.2) whose archetype is `A1_SALES_SHOP` (§2.2.1).
  UserAccountPlan? get activeSalesPlan =>
      myPlans.firstWhereOrNull((p) => p.isActive && p.isSalesShop);

  /// How much of the active sales plan's cap is spent. Null until read, and
  /// null for every account that isn't a sales shop — which is most of them.
  final Rxn<SalesUsage> salesUsage = Rxn<SalesUsage>();

  /// Reads `sales/usage`, but ONLY for an A1 sales-shop holding an active plan.
  ///
  /// The gate is the point of this method. The endpoint answers
  /// `has_sales_plan: false` for gig drivers, services, lead/booking,
  /// manufacturing, free and wide-reach accounts, so calling it for them is a
  /// request that can never say anything — the guide (§2.2.1) asks for it to be
  /// skipped entirely rather than called and ignored.
  ///
  /// Fail-quiet on every other outcome: a non-200, an unparseable body or
  /// `has_sales_plan: false` all clear the bar rather than showing an error.
  /// This is a progress bar beside a plan the merchant already owns — nothing
  /// on the screen depends on it, and an error state here would only be noise
  /// over a working catalog.
  Future<void> refreshSalesUsage() async {
    if (activeSalesPlan == null) {
      salesUsage.value = null;
      return;
    }
    try {
      final res = await _repo.salesUsage();
      final data = _dataOf(res);
      if (data == null) {
        salesUsage.value = null;
        return;
      }
      final usage = SalesUsage.fromJson(data);
      salesUsage.value = usage.isRenderable ? usage : null;
    } catch (e) {
      debugPrint('❌ AccountPlanController.refreshSalesUsage error: $e');
      salesUsage.value = null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // For [didChangeAppLifecycleState] — the payment can finish while this app
    // is in the background, see [_onAppResumed].
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    // A no-op while a checkout is still outstanding — the service defers its
    // teardown so a payment made after this screen is gone still lands.
    _razorpay.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) _onAppResumed();
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
      couponCode: couponCode.value.isEmpty ? null : couponCode.value,
    );
    final data = _dataOf(res);
    if (data != null) {
      final parsed = PlanCatalog.fromJson(data);
      catalog.value = parsed;
      // A code that unlocked nothing. Read off the RESULT rather than from any
      // rule of ours: the server owns validity, scope and exhaustion, and the
      // only honest question the client can ask is "did anything come back
      // under it".
      //
      // Either kind of evidence counts — a discount whose code IS the one that
      // was typed, or any coupon-gated discount at all. The two are usually the
      // same campaign, but a code that unlocks a differently-named campaign is
      // the server's business, and treating that as invalid would call a
      // working coupon a typo.
      couponInvalid.value = couponCode.value.isNotEmpty &&
          !parsed.plans.any((p) =>
              p.showsOffer &&
              (p.discount!.requiresCoupon ||
                  p.discount!.code.toUpperCase() ==
                      couponCode.value.toUpperCase()));
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
    // The sales bar hangs off THIS list — the gate needs the active plan's
    // archetype, which only arrives here. Not awaited: the catalog must not
    // wait on a bar that decorates one card.
    unawaited(refreshSalesUsage());
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
    priceChanged.value = null;

    var res = await _initiate(card, gstin: card.requiresGst ? buyerGstin.value : null);

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
      res = await _initiate(card, gstin: gstin);
    }

    // The offer moved under the buyer. Handled entirely by [_handlePriceChanged]
    // — refresh, re-confirm, and never a silent retry at the higher price.
    if (await _handlePriceChanged(res)) return;

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

    // Nothing to collect. Three roads here and one destination: a free option,
    // a resumed order that turned out to be already paid, and a campaign that
    // covered the entire price (a ≥99.9% discount is settled the same way,
    // because Razorpay cannot take less than ₹1). Opening checkout on a zero
    // order fails at the gateway, so it must not be attempted.
    if (order.isAlreadyActive || order.isFreeAfterDiscount) {
      _reset();
      commonSnackBar(
        message: order.hasDiscount
            ? AppStrings.planActivatedFreeOffer.tr
            : AppStrings.planActivated.tr,
      );
      await fetchPlans();
      return;
    }

    // The receipt, before the money. Shown only when a campaign applied: that
    // is the case where the arithmetic between the plan's list price and the
    // amount about to be charged is worth stating, and it is the authoritative
    // price — `initiate`'s, not the card's. An ordinary full-price purchase
    // keeps going straight to checkout as it always has.
    if (order.hasDiscount) {
      final context = Get.context;
      if (context != null) {
        final confirmed = await showAccountPlanCheckoutSheet(
          context,
          planLabel: card.label,
          order: order,
        );
        // Backed out at the receipt. The order stays unpaid server-side and
        // `initiate` will resume it, so this costs nothing but the tap.
        if (!confirmed) {
          _reset();
          return;
        }
      }
    }

    _pendingOptionCode = card.optionCode;
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

  /// One place that builds an `initiate` call, so the two attempts in
  /// [buyPlan] (the second after a GSTIN re-ask) cannot drift apart — and, in
  /// particular, so both carry the overcharge guard.
  ///
  /// `expected_total_amount` is **what the card promised**, in paise, and it is
  /// always [PlanCard.finalPriceTotal] — the discounted total, or the list
  /// total when nothing is running, which is the same number either way.
  /// Without it the server would quietly charge the list price when a campaign
  /// expired between the catalog and the tap.
  Future<ResponseModel> _initiate(PlanCard card, {String? gstin}) {
    return _repo.initiate(
      optionCode: card.optionCode,
      tagId: tagId,
      hasGst: hasGst,
      buyerState: buyerState,
      buyerGstin: gstin,
      couponCode: couponCode.value.isEmpty ? null : couponCode.value,
      expectedTotalAmount: card.finalPriceTotal,
    );
  }

  /// The 409 the overcharge guard exists to produce: the price went UP between
  /// the catalog and the tap, because the campaign ended while the buyer was
  /// deciding. (Paying *less* than expected never errors.)
  ///
  /// Returns true when it has taken responsibility for the response. The rule
  /// it enforces is that there is **no automatic retry** — the buyer is shown
  /// the new total and re-buys from the REFRESHED card, so the amount they
  /// approve is the amount the next order is created for.
  Future<bool> _handlePriceChanged(ResponseModel res) async {
    if (res.statusCode != 409) return false;
    final body = res.response?.data;
    final raw = body is Map ? body['data'] : null;
    _reset();
    if (raw is Map && raw['reason']?.toString() == 'price_changed') {
      final detail = Map<String, dynamic>.from(raw);
      priceChanged.value = detail;
      // Honest prices first — the dialog offers to continue at the new one, and
      // that has to buy the card as it now stands.
      await fetchPlans();
      await _confirmNewPrice(detail);
      return true;
    }
    // Some other conflict. The server's wording is more specific than anything
    // this screen could invent.
    commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
    return true;
  }

  /// Shows the re-confirm dialog and, if accepted, re-buys the plan at the
  /// price the catalog now carries.
  Future<void> _confirmNewPrice(Map<String, dynamic> detail) async {
    final context = Get.context;
    if (context == null) return;
    final accepted = await showAccountPlanPriceChangedDialog(context, detail);
    priceChanged.value = null;
    if (!accepted) return;

    // The REFRESHED card, never the one that was tapped: its `finalPriceTotal`
    // is the stale figure the server just refused, and replaying it would only
    // earn the same 409.
    final code = detail['option_code']?.toString() ?? '';
    final fresh = catalog.value?.plans
        .firstWhereOrNull((p) => p.optionCode == code && p.isPurchasable);
    if (fresh == null) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    await buyPlan(fresh);
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
    _pendingOptionCode = card.optionCode;
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
    final orderId = r.orderId ?? '';
    final paymentId = r.paymentId ?? '';
    final signature = r.signature ?? '';
    _reset();

    // The money is taken by this point, so a half-empty response is never a
    // failure to report — verify would only 400 on it. The webhook settles it
    // instead, and the re-fetch below is what tells the user.
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      logs('AccountPlan: incomplete Razorpay success payload '
          '(order=$orderId payment=$paymentId signature=${signature.isEmpty ? "missing" : "present"}) '
          '— leaving activation to the webhook');
      commonSnackBar(message: AppStrings.paymentVerifyPending.tr);
      await fetchPlans();
      return;
    }

    // POST /account-plan/verify-payment — {razorpay_order_id,
    // razorpay_payment_id, razorpay_signature}, exactly as sent back by
    // Razorpay. Nothing about the amount is re-sent or re-computed.
    final res = wasUpgrade
        ? await _repo.verifyUpgrade(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          )
        : await _repo.verifyPayment(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          );

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
    logs('AccountPlan: payment failed for '
        '${_pendingOptionCode ?? "-"} (code=${r.code}) ${r.message}');
    _reset();
    commonSnackBar(message: RazorpayService.humanReadableError(r));
  }

  // ─── 3c. Coming back from a backgrounded payment ────────────────
  /// Settles a checkout the app was away for.
  ///
  /// A UPI payment leaves the app: the user finishes in their bank app and
  /// Android may recreate the activity underneath, which is enough for the
  /// plugin's result to be delivered to a channel nobody is awaiting any more
  /// — no success event, and the purchase looks like it never happened.
  ///
  /// Two recoveries, cheapest first:
  ///  1. [RazorpayService.resync] asks the native side for a result it had to
  ///     park. When there is one it arrives through the normal success path,
  ///     verify included, and this method has nothing left to do.
  ///  2. Otherwise the backend webhook is the source of truth and has very
  ///     likely activated the plan already — so re-read `/my-plans` and treat
  ///     the option turning `active` as the success we missed.
  ///
  /// If neither lands, the UI is unwound anyway: leaving the pay bar spinning
  /// forever is the one outcome that helps nobody. `initiate` resumes the same
  /// unpaid order, so retrying is safe and cannot double-charge.
  Future<void> _onAppResumed() async {
    final code = _pendingOptionCode;
    // Nothing outstanding, or a recovery already walking the steps below — a
    // second pass would only re-fetch and re-announce the same thing.
    if (code == null || _recovering) return;
    _recovering = true;
    try {
      await _recoverPendingCheckout(code);
    } finally {
      _recovering = false;
    }
  }

  /// Guards [_onAppResumed] against overlapping runs (resume → pause → resume
  /// while the first pass is still waiting on the webhook).
  bool _recovering = false;

  Future<void> _recoverPendingCheckout(String code) async {
    _razorpay.resync();

    // The parked result comes back over the platform channel; give it a beat
    // to arrive and settle itself before falling back to the webhook.
    await Future.delayed(const Duration(seconds: 2));
    if (_pendingOptionCode != code) return; // recovered path 1

    // Webhook activation is not instant — a couple of unhurried re-reads
    // rather than one, then give up on the optimistic path.
    for (var attempt = 0; attempt < 3; attempt++) {
      if (_pendingOptionCode != code) return;
      await fetchMyPlans();
      if (activeOptionCodes.contains(code)) {
        logs('AccountPlan: $code activated while backgrounded (webhook)');
        _reset();
        commonSnackBar(message: AppStrings.planActivated.tr);
        await fetchPlans();
        return;
      }
      await Future.delayed(const Duration(seconds: 3));
    }

    if (_pendingOptionCode != code) return;
    logs('AccountPlan: no result for $code after resume — releasing the UI');
    _reset();
  }

  void _reset() {
    isProcessing.value = false;
    purchasingCode.value = '';
    _verifyingUpgrade = false;
    _pendingOptionCode = null;
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
