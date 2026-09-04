import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../model/account_plan_models.dart';
import '../repo/account_plan_repo.dart';

/// "Does this account hold a paid plan?" — the go-live gate, in one place.
///
/// Go-live used to key off a refundable security deposit, read from a
/// server-computed flag on the profile / rider onboarding status. That feature
/// has been REMOVED from the product; the contribution screen sells Account
/// Plans, so the
/// entitlement moved with it: an account is allowed to go live once it holds
/// an active plan (`GET /account-plan/my-plans?status=active`).
///
/// Every gate ORs this with its existing signals rather than replacing them —
/// see [allowsGoLive]. A merchant who already paid the deposit must not be
/// knocked offline by this migration, and the free-quota / first-service
/// waivers are unrelated to plans.
///
/// Registered permanently: the gates are spread across the rider, business,
/// professional and self-employed screens, and all of them must see the same
/// answer rather than each re-fetching on mount.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md and
/// docs/DEPOSIT_TO_PAID_PLAN_REDESIGN.txt §7–8.
class AccountPlanEntitlement extends GetxController {
  static AccountPlanEntitlement get to =>
      getOrPut(() => AccountPlanEntitlement(), permanent: true);

  final AccountPlanRepo _repo = AccountPlanRepo();

  /// True when the account holds at least one PAID active plan.
  final RxBool hasActivePlan = false.obs;

  /// False until a `my-plans` read has actually completed. Distinguishes
  /// "we know there is no plan" from "we have not looked yet", which is what
  /// [allowsGoLive] hangs on.
  bool _known = false;
  bool get isKnown => _known;

  bool _inFlight = false;

  /// The gate's answer, for the SYNCHRONOUS call sites.
  ///
  /// Fail-open until the answer is known. A network
  /// blip must not knock a paying merchant offline, and the client is not the
  /// enforcement point anyway — the server is, in the separate release the
  /// redesign doc covers.
  bool get allowsGoLive => !_known || hasActivePlan.value;

  /// Re-reads `my-plans`. Returns [allowsGoLive] afterwards.
  ///
  /// A failed read leaves [_known] alone: an unreachable API means we still
  /// have not looked, so the gate keeps failing open instead of locking the
  /// user out on a timeout.
  Future<bool> refresh() async {
    if (_inFlight) return allowsGoLive;
    _inFlight = true;
    try {
      final res = await _repo.myPlans(status: 'active');
      if (res.statusCode != 200) return allowsGoLive;
      final body = res.response?.data;
      final list = body is Map ? body['data'] : null;
      if (list is! List) return allowsGoLive;
      publish(
        list
            .whereType<Map>()
            .map((e) => UserAccountPlan.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
      return allowsGoLive;
    } catch (e) {
      debugPrint('❌ AccountPlanEntitlement.refresh error: $e');
      return allowsGoLive;
    } finally {
      _inFlight = false;
    }
  }

  /// Records a `my-plans` result fetched elsewhere — the catalog screen already
  /// loads it to mark owned cards, so a purchase updates the gate with no
  /// second round trip.
  ///
  /// A FREE plan does not satisfy the gate: `A0_SOCIAL_FREE` is the default
  /// entitlement every social profile has, so counting it would open go-live
  /// to everyone and make the gate meaningless.
  void publish(List<UserAccountPlan> plans) {
    hasActivePlan.value =
        plans.any((p) => p.isActive && p.totalAmount > 0);
    _known = true;
  }

  /// For the ASYNCHRONOUS gates: answers from cache when the plan is already
  /// known to be held, otherwise re-reads first.
  ///
  /// The re-read matters for the same reason `ensureGoLiveAllowed` had
  /// one: activation is reconciled server-side by the Razorpay webhook, so
  /// nothing in the app refreshes the snapshot after a purchase completes and
  /// a stale `false` would bounce a paid user back to the payment screen.
  Future<bool> ensureAllowed() async {
    if (hasActivePlan.value) return true;
    return refresh();
  }
}
