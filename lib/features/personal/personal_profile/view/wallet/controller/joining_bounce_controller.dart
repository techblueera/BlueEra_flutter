import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/model/joining_bounce_progress.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/repo/joining_bounce_repo.dart';
import 'package:get/get.dart';

/// Account-type tabs shown above the Joining Bounce list (mirrors the image's
/// Fiat/Referral/USDT tab row, but mapped to BUSINESS vs INDIVIDUAL).
enum JoiningBounceTab { business, individual }

extension JoiningBounceTabX on JoiningBounceTab {
  String get accountType =>
      this == JoiningBounceTab.business ? 'BUSINESS' : 'INDIVIDUAL';
}

class JoiningBounceController extends GetxController {
  final JoiningBounceRepo _repo = JoiningBounceRepo();

  /// Master list straight from `GET /joining-bounce/my-bounces` (unfiltered).
  /// Business/Individual buckets are derived from this in memory so switching
  /// tabs never re-hits the API.
  final RxList<JoiningBounceProgress> _allBounces = <JoiningBounceProgress>[].obs;

  Rx<ApiResponse> myBouncesResponse = ApiResponse.initial('Initial').obs;

  /// The user's active (`in_progress`/`eligible`) bounce from
  /// `GET /joining-bounce/current`. Null when there is no active record (404).
  final Rxn<JoiningBounceProgress> currentBounce = Rxn<JoiningBounceProgress>();
  Rx<ApiResponse> currentResponse = ApiResponse.initial('Initial').obs;

  /// Currently selected account-type tab.
  final Rx<JoiningBounceTab> selectedTab = JoiningBounceTab.business.obs;

  /// True while a claim is in flight (drives the per-row button spinner).
  final RxBool isClaiming = false.obs;

  /// Bounces for the currently selected tab.
  List<JoiningBounceProgress> get visibleBounces => _allBounces
      .where((b) => selectedTab.value == JoiningBounceTab.business
          ? b.isBusiness
          : b.isIndividual)
      .toList();

  void selectTab(JoiningBounceTab tab) => selectedTab.value = tab;

  /// Loads every bounce record once; tabs filter the cached list client-side.
  Future<void> getMyBouncesApi() async {
    try {
      myBouncesResponse.value = ApiResponse.loading();
      final ResponseModel response = await _repo.getMyBounces();
      if (response.isSuccess) {
        final data = response.data;
        _allBounces.value = (data is List)
            ? data
                .whereType<Map>()
                .map((e) => JoiningBounceProgress.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList()
            : <JoiningBounceProgress>[];
        myBouncesResponse.value = ApiResponse.complete(_allBounces);
      } else {
        myBouncesResponse.value =
            ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      myBouncesResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  /// Loads the user's active joining bonus
  /// (`GET /joining-bounce/current?tag_id=&account_type=`). Passing [tagId]
  /// (business category / profession) lets the backend auto-create the bonus
  /// on first visit. A 404 (no active record) is treated as "no bonus" rather
  /// than an error.
  Future<void> getCurrentApi({String? tagId, String? accountType}) async {
    try {
      currentResponse.value = ApiResponse.loading();
      final ResponseModel response =
          await _repo.getCurrent(tagId: tagId, accountType: accountType);
      if (response.isSuccess && response.data is Map) {
        currentBounce.value = JoiningBounceProgress.fromJson(
            Map<String, dynamic>.from(response.data));
        currentResponse.value = ApiResponse.complete(currentBounce.value);
      } else {
        currentBounce.value = null;
        currentResponse.value = ApiResponse.complete(null);
      }
    } catch (e) {
      currentBounce.value = null;
      currentResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  /// Claims an eligible bonus into the wallet. Returns true on success so the
  /// caller can refresh the wallet balance.
  Future<bool> claimBounce(JoiningBounceProgress bounce) async {
    if (isClaiming.value) return false;
    try {
      isClaiming.value = true;
      final ResponseModel response =
          await _repo.claim(joiningBounceId: bounce.joiningBounceId);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.message ??
                'Joining bonus credited to your wallet successfully.');
        await getMyBouncesApi();
        return true;
      }
      // 404 no eligible record, 400 not met, 409 already claimed, 502 wallet
      // credit failed — surface the backend message and keep the record as-is.
      commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isClaiming.value = false;
    }
  }
}
