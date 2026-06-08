import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_click_repo.dart';
import 'package:BlueEra/features/chat/auth/repo/profile_click_repo.dart';
import 'package:BlueEra/features/common/statistics/model/profile_visit_analytics_model.dart';
import 'package:BlueEra/features/me/medical/model/chat_click_analytics_model.dart';
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

class ProfileStatisticsController extends GetxController {
  /// Chat-click analytics — backs the "Chat count" card.
  final Rx<ApiResponse> analyticsResponse =
      ApiResponse.initial('Initial').obs;

  final Rxn<ChatClickAnalyticsResponse> analytics =
      Rxn<ChatClickAnalyticsResponse>();

  /// Profile-visit analytics — backs the "Profile visits" card. Served by a
  /// separate endpoint with its own (summary) response shape.
  final Rx<ApiResponse> profileVisitsResponse =
      ApiResponse.initial('Initial').obs;

  final Rxn<ProfileVisitAnalyticsResponse> profileVisits =
      Rxn<ProfileVisitAnalyticsResponse>();

  final Rx<StatsRange> selectedRange = StatsRange.last28Days.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  String? _userId;

  /// Initialise the controller with the profile [userId] whose stats should
  /// load. Fetches fresh analytics every time the tab is opened.
  void init({required String userId}) {
    if (userId.isEmpty) {
      errorMessage.value = AppStrings.businessNotConfigured.tr;
      return;
    }
    _userId = userId;
    _fetchAll();
  }

  void changeRange(StatsRange range) {
    if (selectedRange.value == range) return;
    selectedRange.value = range;
    _fetchAll();
  }

  Future<void> refresh() => _fetchAll();

  /// Fire both analytics endpoints together — the two cards are
  /// independent, so a failure in one doesn't block the other.
  Future<void> _fetchAll() async {
    await Future.wait([fetchAnalytics(), fetchProfileVisits()]);
  }

  Future<void> fetchAnalytics() async {
    final id = _userId;
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

      final ResponseModel response = await ChatClickRepo().fetchChatClickStatsRepo(
        userId: id,
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

  /// Loads profile-visit analytics for the "Profile visits" card. Mirrors
  /// [fetchAnalytics] but hits the separate profile-visit endpoint and keeps
  /// its own response/state so a failure here never affects the chat card.
  Future<void> fetchProfileVisits() async {
    final id = _userId;
    if (id == null || id.isEmpty) {
      profileVisitsResponse.value =
          ApiResponse.error(AppStrings.businessNotConfigured.tr);
      return;
    }

    try {
      profileVisitsResponse.value = ApiResponse.loading('Loading');

      // `full` (not `summary`) so the endpoint returns a per-day timeseries —
      // that's what powers the line chart on the "Profile visits" card. The
      // summary fields still come back nested under `data.summary`, which the
      // model handles.
      final params = <String, dynamic>{
        'format': 'full',
        'range': selectedRange.value.apiValue,
        'compare': true,
      };

      final ResponseModel response =
          await ProfileClickRepo().fetchProfileVisitStatsRepo(
        userId: id,
        queryParams: params,
      );

      if (!response.isSuccess) {
        final msg = response.message?.toString() ??
            AppStrings.unableToLoadStatistics.tr;
        profileVisitsResponse.value = ApiResponse.error(msg);
        return;
      }

      final raw = response.response?.data;
      if (raw is! Map<String, dynamic>) {
        profileVisitsResponse.value =
            ApiResponse.error(AppStrings.unexpectedResponseFormat.tr);
        return;
      }

      final parsed = ProfileVisitAnalyticsResponse.fromJson(raw);
      profileVisits.value = parsed;
      profileVisitsResponse.value = ApiResponse.complete(parsed);
    } catch (e, s) {
      log('fetchProfileVisits error: $e\n$s');
      profileVisitsResponse.value = ApiResponse.error('error');
    }
  }
}
