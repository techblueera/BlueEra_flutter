import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart'
    show ResponseModel;
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/business/business_description/model/business_description_suggestion_model.dart';
import 'package:BlueEra/features/business/widgets/description_selection_dialoge.dart';
import 'package:get/get.dart';

class BusinessDescriptionController extends GetxController {
  RxBool isLoading = false.obs;
  var descriptionSuggestions = <String>[].obs;
  var selectedDescription = "".obs;

  /// ── Category-based ready-written descriptions ──────────────────────
  /// `GET business/description-suggestions`. Kept separate from
  /// [descriptionSuggestions] (the AI-generated ones) so both entry points
  /// can live on the same screen.
  final RxBool isCategorySuggestionsLoading = false.obs;
  final RxList<DescriptionSuggestion> categorySuggestions =
      <DescriptionSuggestion>[].obs;

  /// Empty-state / failure copy for the suggestion list. A failure here must
  /// never block the user — the description field stays editable by hand.
  final RxString categorySuggestionsMessage = "".obs;

  /// [category]     — category tag_id, _id or name (tag_id preferred).
  /// [subCategory]  — subcategory _id or name. Omit for every description of
  ///                  the category. A bare *name* is only safe alongside its
  ///                  category.
  /// [businessName] — fills `{business_name}` server-side; also applied
  ///                  locally afterwards as a no-op safety net.
  Future<void> fetchCategorySuggestions({
    String? category,
    String? subCategory,
    String? businessName,
    int? limit,
  }) async {
    final categoryParam = category?.trim() ?? '';
    final subCategoryParam = subCategory?.trim() ?? '';
    final businessNameParam = businessName?.trim() ?? '';

    // The backend needs a category, or a subcategory _id it can derive one
    // from. Nothing to ask for otherwise.
    if (categoryParam.isEmpty && subCategoryParam.isEmpty) {
      categorySuggestions.clear();
      categorySuggestionsMessage.value = AppStrings.noDescriptionSuggestions;
      return;
    }

    try {
      isCategorySuggestionsLoading.value = true;
      categorySuggestionsMessage.value = '';

      final ResponseModel response =
          await BusinessProfileRepo().getBusinessDescriptionSuggestions(
        params: {
          if (categoryParam.isNotEmpty) ApiKeys.category: categoryParam,
          if (subCategoryParam.isNotEmpty) ApiKeys.sub_category: subCategoryParam,
          if (businessNameParam.isNotEmpty)
            ApiKeys.business_name: businessNameParam,
          if (limit != null) ApiKeys.limit: limit,
        },
      );

      if (response.isSuccess && response.response?.data is Map) {
        final parsed = DescriptionSuggestionResponse.fromJson(
            Map<String, dynamic>.from(response.response!.data as Map));

        // Belt-and-braces: no-op once the backend has replaced the token.
        categorySuggestions.value =
            parsed.filledWith(businessNameParam).suggestions;
        categorySuggestionsMessage.value = categorySuggestions.isEmpty
            ? AppStrings.noDescriptionSuggestions
            : '';
      } else {
        // 404 here means "no content uploaded for this category yet" — an
        // empty state, not an error the user has to act on.
        categorySuggestions.clear();
        categorySuggestionsMessage.value = AppStrings.noDescriptionSuggestions;
      }
    } catch (e) {
      logs("DESCRIPTION SUGGESTIONS ERROR $e");
      categorySuggestions.clear();
      categorySuggestionsMessage.value = AppStrings.couldNotLoadSuggestions;
    } finally {
      isCategorySuggestionsLoading.value = false;
    }
  }

  Future<void> generateDescriptions({
    required Map<String, dynamic> bodyRequest,
    VoidCallback? onSaved, // <-- add this callback
  }) async {
    try {
      isLoading.value = true;
      descriptionSuggestions.clear();
      selectedDescription.value = '';

      final ResponseModel response = await BusinessProfileRepo()
          .aiGenerateDescriptionRepo(bodyParam: bodyRequest);

      if (response.isSuccess && response.response?.data != null) {
        final data = response.response?.data['description_suggestions'] ?? [];
        setSuggestions(data);
        // descriptionSuggestions.value = List<String>.from(data);
        await showDescriptionSuggestionsDialog(onSaved: onSaved);
      } else {
        commonSnackBar(
            message:
                "Error ${response.message ?? AppStrings.somethingWentWrong.tr}");
      }
    } catch (e) {
      logs("ERROR ${e}");
      commonSnackBar(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void selectDescription(String description) {
    selectedDescription.value = description;
  }


  void setSuggestions(dynamic json) {
    final data = json as List<dynamic>;

    descriptionSuggestions.value = data.map((inner) {
      return (inner as List<dynamic>).join("\n"); // join lines as paragraph
    }).toList();

    selectedDescription.value = ""; // reset selection
  }
}
