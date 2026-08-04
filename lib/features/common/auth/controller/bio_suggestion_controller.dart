import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/auth/model/bio_suggestion_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:get/get.dart';

/// Ready-written bios per profession / designation —
/// `GET individual-professions/bio-suggestions`.
/// See docs/FLUTTER_INDIVIDUAL_BIO_SUGGESTIONS_GUIDE.md
///
/// Deliberately its own controller rather than more state on
/// [AiSuggestionController]: this is predefined content keyed off the
/// profession, the other is a per-user AI generation, and both entry points
/// sit on the same screen. Same split as [BusinessDescriptionController] on
/// the business side.
class BioSuggestionController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<BioSuggestion> suggestions = <BioSuggestion>[].obs;

  /// Empty-state / failure copy for the list. A failure here must never block
  /// the user — the bio field stays editable by hand.
  final RxString message = ''.obs;

  /// True once a fetch has completed, so the UI can tell "not asked yet" from
  /// "asked and got nothing".
  final RxBool hasFetched = false.obs;

  /// Cached per (profession, designation) for the controller's lifetime — the
  /// content is static, so re-entering the screen shouldn't refetch.
  String? _cacheKey;

  /// [profession]  — profession tag_id, _id or name (tag_id preferred, and
  ///                 mandatory: the backend 400s without it).
  /// [subcategory] — designation tag_id, _id or name. Omit for every bio
  ///                 under the profession.
  /// [forceRefresh] — bypass the cache (the retry / refresh affordance).
  ///
  /// A designation the content doesn't cover 404s (free-text designations from
  /// the OTHERS profession do this routinely), so that case retries with the
  /// profession alone rather than showing the user nothing.
  Future<void> fetchBioSuggestions({
    required String? profession,
    String? subcategory,
    int? limit,
    bool forceRefresh = false,
  }) async {
    final professionParam = profession?.trim() ?? '';
    final subcategoryParam = subcategory?.trim() ?? '';

    if (professionParam.isEmpty) {
      suggestions.clear();
      message.value = AppStrings.noBioSuggestions.tr;
      hasFetched.value = true;
      return;
    }

    final key = '$professionParam|$subcategoryParam|${limit ?? ''}';
    if (!forceRefresh && key == _cacheKey && suggestions.isNotEmpty) return;
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      message.value = '';

      var parsed = await _requestBioSuggestions(
        profession: professionParam,
        subcategory: subcategoryParam,
        limit: limit,
      );

      // Unknown designation for this profession — fall back to everything the
      // profession has.
      if (parsed == null && subcategoryParam.isNotEmpty) {
        parsed = await _requestBioSuggestions(
          profession: professionParam,
          subcategory: '',
          limit: limit,
        );
      }

      suggestions.value = parsed?.suggestions ?? const [];
      message.value = suggestions.isEmpty ? AppStrings.noBioSuggestions.tr : '';
      // Only cache a response worth reusing; an empty one stays retryable.
      _cacheKey = suggestions.isEmpty ? null : key;
    } catch (e) {
      logs("BIO SUGGESTIONS ERROR $e");
      suggestions.clear();
      message.value = AppStrings.couldNotLoadBioSuggestions.tr;
      _cacheKey = null;
    } finally {
      hasFetched.value = true;
      isLoading.value = false;
    }
  }

  /// One call. Returns null on any non-2xx — a 404 here means "no content for
  /// that profession/designation yet", which is an empty state rather than an
  /// error the user has to act on.
  Future<BioSuggestionResponse?> _requestBioSuggestions({
    required String profession,
    required String subcategory,
    int? limit,
  }) async {
    final ResponseModel response = await AuthRepo().getBioSuggestionsRepo(
      params: {
        ApiKeys.profession: profession,
        if (subcategory.isNotEmpty) ApiKeys.subcategory: subcategory,
        if (limit != null) ApiKeys.limit: limit,
      },
    );

    if (response.isSuccess && response.response?.data is Map) {
      return BioSuggestionResponse.fromJson(
          Map<String, dynamic>.from(response.response!.data as Map));
    }
    return null;
  }
}
