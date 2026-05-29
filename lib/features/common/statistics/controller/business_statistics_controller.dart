import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/medical/model/chat_click_analytics_model.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:get/get.dart';

/// Selectable preset windows for the statistics tab. Values match the
/// `range` enum from the chat-click analytics endpoint.
enum StatsRange {
  last7Days('last_7_days', AppStrings.statsRangeLast7Days),
  last28Days('last_30_days', AppStrings.statsRangeLast28Days),
  last90Days('last_90_days', AppStrings.statsRangeLast90Days),
  thisMonth('this_month', AppStrings.statsRangeThisMonth),
  allTime('all_time', AppStrings.statsRangeAllTime);

  final String apiValue;
  final String _labelKey;

  const StatsRange(this.apiValue, this._labelKey);

  String get label => _labelKey.tr;
}

class BusinessStatisticsController extends GetxController {
  final Rx<ApiResponse> analyticsResponse =
      ApiResponse.initial('Initial').obs;

  final Rxn<ChatClickAnalyticsResponse> analytics =
      Rxn<ChatClickAnalyticsResponse>();

  final Rx<StatsRange> selectedRange = StatsRange.last28Days.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  String? _businessId;

  /// Initialise the controller with the business id whose stats should load.
  /// Re-uses cached data if the same business is requested again.
  void init({required String businessId}) {
    if (businessId.isEmpty) {
      errorMessage.value = AppStrings.businessNotConfigured.tr;
      return;
    }
    final shouldFetch =
        _businessId != businessId || analytics.value == null;
    _businessId = businessId;
    if (shouldFetch) {
      fetchAnalytics();
    }
  }

  void changeRange(StatsRange range) {
    if (selectedRange.value == range) return;
    selectedRange.value = range;
    fetchAnalytics();
  }

  Future<void> refresh() => fetchAnalytics();

  Future<void> fetchAnalytics() async {
    final id = _businessId;
    if (id == null || id.isEmpty) {
      errorMessage.value = AppStrings.businessNotConfigured.tr;
      analyticsResponse.value = ApiResponse.error(AppStrings.businessNotConfigured.tr);
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      analyticsResponse.value = ApiResponse.loading('Loading');

      final params = <String, dynamic>{
        'format': 'full',
        'range': selectedRange.value.apiValue,
        'compare': true,
      };

      final ResponseModel response = await MedicalRepo().fetchChatClickStatsRepo(
        businessId: id,
        queryParams: params,
      );

      if (!response.isSuccess) {
        final msg = response.message?.toString() ?? AppStrings.unableToLoadStatistics.tr;
        errorMessage.value = msg;
        analyticsResponse.value = ApiResponse.error(msg);
        return;
      }

      final raw = response.response?.data;
      if (raw is! Map<String, dynamic>) {
        final msg = AppStrings.unexpectedResponseFormat.tr;
        errorMessage.value = msg;
        analyticsResponse.value = ApiResponse.error(msg);
        return;
      }

      final parsed = ChatClickAnalyticsResponse.fromJson(raw);
      analytics.value = parsed;
      analyticsResponse.value = ApiResponse.complete(parsed);
    } catch (e, s) {
      log('fetchAnalytics error: $e\n$s');
      errorMessage.value = AppStrings.unableToLoadStatistics.tr;
      analyticsResponse.value = ApiResponse.error('error');
    } finally {
      isLoading.value = false;
    }
  }
}
