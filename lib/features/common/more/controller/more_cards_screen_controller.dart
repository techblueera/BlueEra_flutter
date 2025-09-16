import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/more/model/card_model.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class MoreCardsScreenController extends GetxController{
  Rx<ApiResponse> AllCardCategoriesResponse = ApiResponse.initial('Initial').obs;
  RxBool isLoading = false.obs;
  RxList<Cards> allCards = <Cards>[].obs;
  RxList<Cards> filteredCards = <Cards>[].obs;
  RxString selectedCategory = 'All'.obs;
  RxList<String> allCategories = <String>[].obs;

  Future<void> getAllCardCategories() async {
    isLoading.value = true;
    try {
      ResponseModel responseModel = await UserRepo().getAllCardCategories();
      if (responseModel.isSuccess) {
        AllCardCategoriesResponse.value = ApiResponse.complete(responseModel);
        final cardModelResponse = CardModelResponse.fromJson(responseModel.response?.data);

        final List<Cards> cards = [];
        final List<String> categories = [];

        if (cardModelResponse.categories != null) {
          for (final category in cardModelResponse.categories!) {
            if (category.name != null) {
              print('category name -- ${category.name!}');
              categories.add(category.name!);
            }
            if (category.cards != null) {
              cards.addAll(category.cards!);
            }
          }
        }

        allCards.value = cards;
        allCategories.value = categories;

        filteredCards.value = List.from(cards);
      } else {
        AllCardCategoriesResponse.value = ApiResponse.error('error');

        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      AllCardCategoriesResponse.value = ApiResponse.error('error');
    } finally {
      isLoading.value = false;
    }
  }

  void filterCardsByCategory(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty || categoryName == "All") {
      filteredCards.value = List.from(allCards);
    } else {
      filteredCards.value = allCards.where((card) {
        return card.categoryName == categoryName;
      }).toList();
    }
  }

}