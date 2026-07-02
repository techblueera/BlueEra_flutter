import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/referral/model/referral_bdm_details_model.dart';
import 'package:BlueEra/features/common/referral/model/referral_testimonial_model.dart';
import 'package:BlueEra/features/common/referral/model/wallet_referral_history_model.dart';
import 'package:BlueEra/features/common/referral/model/wallet_referral_stats_model.dart';
import 'package:BlueEra/features/common/referral/model/wallet_statics_model.dart';
import 'package:BlueEra/features/common/referral/model/creator_program_model.dart';
import 'package:BlueEra/features/common/referral/repo/referral_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReferralController extends GetxController {
  final ReferralRepoNew _repo = ReferralRepoNew();

  // --- Async statuses ------------------------------------------------------
  final Rx<ApiResponse> bdmDetailsResponse = ApiResponse.initial('Initial').obs;
  final Rx<ApiResponse> statsResponse = ApiResponse.initial('Initial').obs;
  final Rx<ApiResponse> historyResponse = ApiResponse.initial('Initial').obs;
  final Rx<ApiResponse> suggestionsResponse =
      ApiResponse.initial('Initial').obs;
  final Rx<ApiResponse> testimonialsResponse =
      ApiResponse.initial('Initial').obs;
  final Rx<ApiResponse> tutorialsResponse =
      ApiResponse.initial('Initial').obs;
  final Rx<ApiResponse> overviewResponse =
      ApiResponse.initial('Initial').obs;
  final Rx<ApiResponse> creatorResponse =
      ApiResponse.initial('Initial').obs;
  final Rx<ApiResponse> directReferralIncomeResponse =
      ApiResponse.initial('Initial').obs;
  final RxBool registerLoading = false.obs;
  final RxBool creatingPost = false.obs;

  // Parsed wallet statics payload from `direct-referral-income` —
  // populates all four cards on the Statics tab.
  final Rxn<WalletStaticsModel> walletStatics = Rxn<WalletStaticsModel>();

  // --- State ---------------------------------------------------------------
  final Rxn<ReferralBdmDetailsModel> bdmDetails =
      Rxn<ReferralBdmDetailsModel>();
  final Rxn<WalletReferralStats> stats = Rxn<WalletReferralStats>();
  final RxList<WalletReferralHistoryItem> history =
      <WalletReferralHistoryItem>[].obs;
  final RxList<String> referralSuggestions = <String>[].obs;
  // Testimonials are mapped from AdminPost → ReferralTestimonial so the
  // existing testimonial card design keeps working unchanged.
  final RxList<ReferralTestimonial> testimonials =
      <ReferralTestimonial>[].obs;
  // Overview posts from GET /earn-service/overview (title/description/images/
  // video) — same media model as testimonials.
  final RxList<ReferralTestimonial> overviews = <ReferralTestimonial>[].obs;
  // Tutorials come from GET /earn-service/tutorial (title/description/images/
  // video) — same media model the testimonials use.
  final RxList<ReferralTestimonial> tutorials = <ReferralTestimonial>[].obs;
  // Content-creator program + progress + submitted videos, from
  // GET /earn-service/creator. Powers the whole Creator tab.
  final Rxn<CreatorData> creatorData = Rxn<CreatorData>();

  // Step-2 form fields
  final TextEditingController referralCodeController = TextEditingController();
  final RxString selectedSuggestion = ''.obs;
  final RxBool termsAccepted = false.obs;
  final FocusNode referralFocusNode = FocusNode();

  // History filter tabs
  final RxString selectedFilter = 'All'.obs;
  final List<String> filters = const [
    'All',
    'Pending',
    'Subscribe',
    'Un-Subscribe',
    'Expired',
  ];

  // --- Computed ------------------------------------------------------------
  String get status => bdmDetails.value?.status ?? 'NOT_STARTED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isNotStarted => status == 'NOT_STARTED';
  String get myReferralCode => stats.value?.referralCode ?? '';

  @override
  void onClose() {
    referralCodeController.dispose();
    referralFocusNode.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // BDM status + dependent fetches
  // ---------------------------------------------------------------------------
  Future<void> fetchBdmDetails() async {
    bdmDetailsResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getBdmDetails();
      if (res.isSuccess) {
        bdmDetails.value =
            ReferralBdmDetailsModel.fromJson(res.response?.data ?? {});
        bdmDetailsResponse.value = ApiResponse.complete(res.response?.data);

        if (isCompleted) {
          await Future.wait([
            fetchStats(),
            fetchTestimonials(),
          ]);
        }
      } else {
        bdmDetailsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      bdmDetailsResponse.value = ApiResponse.error(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Wallet stats
  // ---------------------------------------------------------------------------
  Future<void> fetchStats() async {
    statsResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getWalletReferralStats();
      if (res.isSuccess) {
        final parsed =
            WalletReferralStatsResponse.fromJson(res.response?.data ?? {});
        stats.value = parsed.data;
        statsResponse.value = ApiResponse.complete(res.response?.data);
      } else {
        statsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      statsResponse.value = ApiResponse.error(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------
  Future<void> fetchHistory(String filter) async {
    selectedFilter.value = filter;
    historyResponse.value = ApiResponse.loading('loading');
    try {
      final query = <String, dynamic>{};
      switch (filter) {
        case 'Pending':
          query['pending'] = true;
          break;
        case 'Subscribe':
          query['subscribed'] = true;
          break;
        case 'Un-Subscribe':
          query['non-subscribed'] = true;
          break;
        case 'Expired':
          query['expired'] = true;
          break;
        case 'All':
        default:
          break;
      }
      final res = await _repo.getWalletReferralHistory(queryParams: query);
      if (res.isSuccess) {
        final parsed =
            WalletReferralHistoryResponse.fromJson(res.response?.data ?? {});
        history.value = parsed.data ?? <WalletReferralHistoryItem>[];
        historyResponse.value = ApiResponse.complete(res.response?.data);
      } else {
        historyResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      historyResponse.value = ApiResponse.error(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Direct referral income — populates the Statics tab's
  // "Direct Referral Income" card. Stores raw payload; binding is done
  // by the view layer.
  // ---------------------------------------------------------------------------
  Future<void> fetchDirectReferralIncome({
    Map<String, dynamic>? queryParams,
  }) async {
    directReferralIncomeResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getDirectReferralIncome(queryParams: queryParams);
      if (res.isSuccess) {
        final raw = res.response?.data;
        final parsed = WalletStaticsResponse.fromJson(
          raw is Map<String, dynamic> ? raw : <String, dynamic>{},
        );
        walletStatics.value = parsed.data;
        directReferralIncomeResponse.value = ApiResponse.complete(raw);
      } else {
        directReferralIncomeResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      directReferralIncomeResponse.value = ApiResponse.error(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Referral suggestions
  // ---------------------------------------------------------------------------
  Future<void> fetchSuggestions() async {
    suggestionsResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getReferralSuggestions();
      if (res.isSuccess) {
        final raw = res.response?.data['data'];
        referralSuggestions.value = raw is List
            ? raw
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList()
            : <String>[];
        suggestionsResponse.value = ApiResponse.complete(res.response?.data);
      } else {
        suggestionsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      suggestionsResponse.value = ApiResponse.error(e.toString());
    }
  }

  void selectSuggestion(String code) {
    selectedSuggestion.value = code;
    referralCodeController.text = code;
  }

  // ---------------------------------------------------------------------------
  // Submit registration (single-step: referral code only)
  //
  // Bank-details / Aadhar / PAN / address-proof are no longer collected
  // during BDM onboarding — the user types a referral code, accepts the
  // terms, and submits. On success we re-fetch /bdm/status; the backend
  // flips it to COMPLETED and the dashboard renders.
  // ---------------------------------------------------------------------------
  Future<void> submitRegistration() async {
    if (registerLoading.value) return;
    final code = referralCodeController.text.trim();
    if (code.isEmpty) {
      commonSnackBar(message: 'Please enter a referral code to continue.');
      return;
    }
    registerLoading.value = true;
    try {
      final res = await _repo.registerStepTwo(referralCode: code);
      if (res.isSuccess) {
        commonSnackBar(
            message: res.message ?? 'BDM registration completed successfully');
        await fetchBdmDetails();
      } else {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      commonSnackBar(message: e.toString());
    } finally {
      registerLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Admin posts feed — testimonial / overview / tutorial all share the
  // same endpoint and response shape; only the `?type=` param changes.
  // ---------------------------------------------------------------------------

  /// Fetches referral testimonials from `GET /earn-service/testimonial`.
  /// Each item carries a title/description plus either images or a video.
  Future<void> fetchTestimonials() async {
    testimonialsResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getTestimonials();
      if (res.isSuccess) {
        // The endpoint returns the payload unwrapped (no `data` envelope):
        // { testimonials: [...], currentPage, totalPages, totalTestimonials }.
        final body = res.response?.data;
        final list =
            (body is Map ? body['testimonials'] as List? : null) ?? const [];
        testimonials.value = list
            .whereType<Map>()
            .map((e) => ReferralTestimonial.fromJson(e.cast<String, dynamic>()))
            .toList();
        testimonialsResponse.value = ApiResponse.complete(body);
      } else {
        testimonialsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      testimonialsResponse.value = ApiResponse.error(e.toString());
    }
  }

  /// Overview posts from `GET /earn-service/overview` — same media shape
  /// (title/description/images/video) as testimonials & tutorials.
  Future<void> fetchOverview() async {
    overviewResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getOverviews();
      if (res.isSuccess) {
        final body = res.response?.data;
        final list =
            (body is Map ? body['overviews'] as List? : null) ?? const [];
        overviews.value = list
            .whereType<Map>()
            .map((e) => ReferralTestimonial.fromJson(e.cast<String, dynamic>()))
            .toList();
        overviewResponse.value = ApiResponse.complete(body);
      } else {
        overviewResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      overviewResponse.value = ApiResponse.error(e.toString());
    }
  }

  /// Tutorials from `GET /earn-service/tutorial`. Same media shape as
  /// testimonials (title/description/images/video).
  Future<void> fetchTutorials() async {
    tutorialsResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getTutorials();
      if (res.isSuccess) {
        final body = res.response?.data;
        final list =
            (body is Map ? body['tutorials'] as List? : null) ?? const [];
        tutorials.value = list
            .whereType<Map>()
            .map((e) => ReferralTestimonial.fromJson(e.cast<String, dynamic>()))
            .toList();
        tutorialsResponse.value = ApiResponse.complete(body);
      } else {
        tutorialsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      tutorialsResponse.value = ApiResponse.error(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Content-creator program (`GET /earn-service/creator`)
  // ---------------------------------------------------------------------------

  Future<void> fetchCreator() async {
    creatorResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getCreator();
      if (res.isSuccess) {
        final body = res.response?.data;
        if (body is Map) {
          creatorData.value =
              CreatorData.fromJson(body.cast<String, dynamic>());
        }
        creatorResponse.value = ApiResponse.complete(body);
      } else {
        creatorResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      creatorResponse.value = ApiResponse.error(e.toString());
    }
  }

  /// Submit a creator video link (`POST /earn-service/creator`), then re-pull
  /// the creator data so the new video appears in "My Videos". [platform] is
  /// the chip the user picked (youtube / instagram / facebook / twitter /
  /// other); when absent it's inferred from the URL. Any link is accepted —
  /// non-matching URLs fall back to `other`.
  Future<bool> createUserPost(String url, {String? platform}) async {
    if (creatingPost.value) return false;
    // Normalize whatever the user pasted (browser URL, share-sheet link
    // with tracking tokens, or share text wrapping a URL) into a clean
    // canonical address so the backend scraper resolves real metadata
    // instead of a consent/redirect page. See [canonicalizeSharedUrl].
    final trimmed = ReferralRepoNew.canonicalizeSharedUrl(url);
    if (trimmed.isEmpty) {
      commonSnackBar(message: 'Please paste a valid link.');
      return false;
    }
    final plat = (platform != null &&
            platform.isNotEmpty &&
            platform != 'unknown')
        ? platform
        : ReferralRepoNew.detectPlatform(trimmed);
    creatingPost.value = true;
    try {
      final res =
          await _repo.createCreatorVideo(url: trimmed, platform: plat);
      if (res.isSuccess) {
        await fetchCreator();
        return true;
      }
      commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr);
      return false;
    } catch (e) {
      commonSnackBar(message: 'Failed to add link: $e');
      return false;
    } finally {
      creatingPost.value = false;
    }
  }
}
