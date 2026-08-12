import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/contribution/repo/contribution_repo.dart';
import 'package:get/get.dart';

/// Read-only status of the user's legacy recharge, from `GET /recharge/current`.
///
/// **This controller no longer sells anything.** Plans are bought through the
/// Account Plan flow (`lib/features/account_plan/`, hosted by
/// `ContributionScreen`); the recharge catalog, its Razorpay purchase path
/// and the 24h plans cache were removed with the old contribution screens on
/// 2026-08-12. What survives is the *status* of a recharge bought before that,
/// which two surfaces still show:
///
/// * `lib/widgets/order_actions_carousel.dart` — the contribution deck card
/// * `contribution_status_view.dart` — the Me-dashboard Statistics tab
///
/// Both read [hasActiveRecharge] / [currentRecharge] and nothing else. If those
/// two surfaces ever move to `/account-plan/my-plans`, this controller, its repo
/// and the `recharge/*` endpoints can go with them.
class ContributionController extends GetxController {
  final ContributionRepo _repo = ContributionRepo();

  final RxBool hasActiveRecharge = false.obs;

  /// Lifecycle of `/recharge/current`. UI gating should treat
  /// `INITIAL`/`LOADING` as "don't decide yet" to avoid deciding before the
  /// answer lands.
  final Rx<Status> currentStatus = Status.INITIAL.obs;

  /// Raw payload returned by `GET /recharge/current` when an active recharge
  /// exists. Kept as a map so callers can surface plan name / perks / amount
  /// without a parser that would have to track the backend shape.
  final Rxn<Map<String, dynamic>> currentRecharge = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchCurrent();
  }

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
