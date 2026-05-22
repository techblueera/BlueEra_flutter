import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/me/medical/model/chat_click_analytics_model.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:get/get.dart';

/// Selectable preset windows for the statistics tab. Values match the
/// `range` enum from the chat-click analytics endpoint.
enum StatsRange {
  last7Days('last_7_days', 'Last 7 days'),
  last28Days('last_30_days', 'Last 28 days'),
  last90Days('last_90_days', 'Last 90 days'),
  thisMonth('this_month', 'This month'),
  allTime('all_time', 'All time');

  final String apiValue;
  final String label;

  const StatsRange(this.apiValue, this.label);
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
      errorMessage.value = 'Business not configured';
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
      errorMessage.value = 'Business not configured';
      analyticsResponse.value = ApiResponse.error('Business not configured');
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
        final msg = response.message?.toString() ?? 'Unable to load statistics';
        errorMessage.value = msg;
        analyticsResponse.value = ApiResponse.error(msg);
        return;
      }

      final raw = response.response?.data;
      if (raw is! Map<String, dynamic>) {
        const msg = 'Unexpected response format';
        errorMessage.value = msg;
        analyticsResponse.value = ApiResponse.error(msg);
        return;
      }

      final parsed = ChatClickAnalyticsResponse.fromJson(raw);
      analytics.value = parsed;
      analyticsResponse.value = ApiResponse.complete(parsed);
    } catch (e, s) {
      log('fetchAnalytics error: $e\n$s');
      errorMessage.value = 'Unable to load statistics';
      analyticsResponse.value = ApiResponse.error('error');
    } finally {
      isLoading.value = false;
    }
  }
}
