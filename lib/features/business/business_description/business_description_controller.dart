import 'dart:ui';

import 'package:BlueEra/core/api/apiService/response_model.dart'
    show ResponseModel;
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/business/widgets/description_selection_dialoge.dart';
import 'package:get/get.dart';

class BusinessDescriptionController extends GetxController {
  RxList<String> descriptionSuggestions = <String>[].obs;
  RxBool isLoading = false.obs;
  RxString selectedDescription = ''.obs;

  Future<void> generateDescriptions(
      {required Map<String, dynamic> bodyRequest,
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
        descriptionSuggestions.value = List<String>.from(data);
        await showDescriptionSuggestionsDialog(onSaved: onSaved);
      } else {
        Get.snackbar('Error', response.message ?? 'Something went wrong');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch descriptions');
    } finally {
      isLoading.value = false;
    }
  }

  void selectDescription(String description) {
    selectedDescription.value = description;
  }
}
