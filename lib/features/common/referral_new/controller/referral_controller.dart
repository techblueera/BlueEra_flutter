import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/referral_new/model/admin_post_model.dart';
import 'package:BlueEra/features/common/referral_new/model/referral_bdm_details_model.dart';
import 'package:BlueEra/features/common/referral_new/model/referral_testimonial_model.dart';
import 'package:BlueEra/features/common/referral_new/model/wallet_referral_history_model.dart';
import 'package:BlueEra/features/common/referral_new/model/wallet_referral_stats_model.dart';
import 'package:BlueEra/features/common/referral_new/repo/referral_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single GetX controller for the new BDM/referral flow.
///
/// Responsibilities:
///   • BDM status (NOT_STARTED / PENDING / COMPLETED)
///   • Referral suggestions + chosen code
///   • Register submit (referral code only — no documents in the new
///     single-step flow)
///   • Wallet stats + referral history (with filter tabs)
///   • Admin-posts feed split into testimonial / overview / tutorial
///     buckets (`GET /earn-service/admin-posts?type=...`)
///   • Social posts the user pastes from Instagram/Twitter/YouTube
class ReferralControllerNew extends GetxController {
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
  final Rx<ApiResponse> userPostsResponse =
      ApiResponse.initial('Initial').obs;
  final RxBool registerLoading = false.obs;
  final RxBool creatingPost = false.obs;

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
  // Overview + Tutorial sections render AdminPost directly via the new
  // AdminPostCard widget — they share the same shape (title /
  // description / link / video / images) so no extra model is needed.
  final RxList<AdminPost> overviewPosts = <AdminPost>[].obs;
  final RxList<AdminPost> tutorialPosts = <AdminPost>[].obs;
  // User-created posts (type=post) — populated by [fetchUserPosts] and
  // refreshed after each successful [createUserPost].
  final RxList<AdminPost> userPosts = <AdminPost>[].obs;

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

  /// Fetches testimonial-type admin posts and maps them onto the
  /// existing [ReferralTestimonial] view model so the testimonial
  /// section's UI doesn't need to change.
  Future<void> fetchTestimonials() async {
    testimonialsResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getAdminPosts(type: 'testimonial');
      if (res.isSuccess) {
        final parsed = AdminPostsResponse.fromJson(res.response?.data ?? {});
        testimonials.value =
            parsed.adminPosts.map(_mapTestimonial).toList();
        testimonialsResponse.value = ApiResponse.complete(res.response?.data);
      } else {
        testimonialsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      testimonialsResponse.value = ApiResponse.error(e.toString());
    }
  }

  ReferralTestimonial _mapTestimonial(AdminPost post) {
    final creator = post.creator;
    return ReferralTestimonial(
      id: post.id,
      name: creator?.name ?? '',
      role: creator?.designation ?? '',
      company: creator?.currentOrganisation ?? '',
      profileImage: creator?.profileImage ?? '',
      // The testimonial card emphasises the quote — fall back to the
      // post title when description is missing.
      quote: post.description.isNotEmpty ? post.description : post.title,
      website: post.link.isEmpty ? null : post.link,
      videoUrl: post.video,
    );
  }

  Future<void> fetchOverviewPosts() async {
    overviewResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getAdminPosts(type: 'overview');
      if (res.isSuccess) {
        final parsed = AdminPostsResponse.fromJson(res.response?.data ?? {});
        overviewPosts.value = parsed.adminPosts;
        overviewResponse.value = ApiResponse.complete(res.response?.data);
      } else {
        overviewResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      overviewResponse.value = ApiResponse.error(e.toString());
    }
  }

  Future<void> fetchTutorials() async {
    tutorialsResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getAdminPosts(type: 'tutorial');
      if (res.isSuccess) {
        final parsed = AdminPostsResponse.fromJson(res.response?.data ?? {});
        tutorialPosts.value = parsed.adminPosts;
        tutorialsResponse.value = ApiResponse.complete(res.response?.data);
      } else {
        tutorialsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      tutorialsResponse.value = ApiResponse.error(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // User posts (`type=post`)
  // ---------------------------------------------------------------------------

  Future<void> fetchUserPosts() async {
    userPostsResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getAdminPosts(type: 'post');
      if (res.isSuccess) {
        final parsed = AdminPostsResponse.fromJson(res.response?.data ?? {});
        userPosts.value = parsed.adminPosts;
        userPostsResponse.value = ApiResponse.complete(res.response?.data);
      } else {
        userPostsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      userPostsResponse.value = ApiResponse.error(e.toString());
    }
  }

  /// POST a social link, then re-pull the `type=post` list so the new
  /// card appears in "My Videos". Platform comes from URL detection and
  /// is sent as the `title` field per the new contract.
  Future<bool> createUserPost(String url) async {
    if (creatingPost.value) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      commonSnackBar(message: 'Please paste a valid link.');
      return false;
    }
    final platform = ReferralRepoNew.detectPlatform(trimmed);
    if (platform == 'unknown') {
      commonSnackBar(
          message: 'Only Instagram, Twitter (X), or YouTube links are supported.');
      return false;
    }
    creatingPost.value = true;
    try {
      final res = await _repo.createAdminPost(link: trimmed, title: platform);
      if (res.isSuccess) {
        await fetchUserPosts();
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
