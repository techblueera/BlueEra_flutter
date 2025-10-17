import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/more/model/card_model.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class MoreCardsScreenController extends GetxController{
  Rx<ApiResponse> allCardCategoriesResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> cardCategoriesSortedByDateResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> daysRangeAllCardCategoriesResponse = ApiResponse.initial('Initial').obs;

  /// Home page scroll variable
  final RxBool isVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;

  RxBool isLoading = false.obs;

  // RxList<Cards> allCards = <Cards>[].obs;
  // RxList<Cards> filteredCards = <Cards>[].obs;

  RxString selectedCategory = 'All'.obs;
  RxList<String> allCategories = <String>[].obs;

  RxList<Cards> dayCards = <Cards>[].obs;

  RxList<Cards> daysRangeAllCards = <Cards>[].obs;
  RxList<Cards> filteredDaysRangeAllCards = <Cards>[].obs;

  Future<void> getCardCategoriesSortedByDate({required String todayDate}) async {
    try {

      // Map<String , dynamic> params = {
      //   ApiKeys.date: DateTime.now().toIso8601String()
      // };

      Map<String , dynamic> queryParams = {
        ApiKeys.fromDate: DateTime.now().toIso8601String(),
        ApiKeys.toDate: DateTime.now().add(Duration(days: 7)).toIso8601String(),
      };

       ResponseModel responseModel = await UserRepo().getAllCards(queryParams: queryParams);

      // ResponseModel responseModel = await UserRepo().cardCategoriesSortedByDate(queryParams: params);
      if (responseModel.isSuccess) {
        cardCategoriesSortedByDateResponse.value = ApiResponse.complete(responseModel);
        final cardResponseModel = CardResponseModel.fromJson(responseModel.response?.data);
        dayCards.assignAll(cardResponseModel.cards??[]);

      } else {
        cardCategoriesSortedByDateResponse.value = ApiResponse.error('error');

        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e,s) {
      log('stack trace - $s');
      cardCategoriesSortedByDateResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getAllCards() async {
    isLoading.value = true;
    try {
      Map<String , dynamic> queryParams = {
        ApiKeys.fromDate: DateTime.now().toIso8601String(),
        ApiKeys.toDate: DateTime.now().add(Duration(days: 1)).toIso8601String(),
      };
      ResponseModel responseModel = await UserRepo().getAllCards(queryParams: queryParams);
      if (responseModel.isSuccess) {
        daysRangeAllCardCategoriesResponse.value = ApiResponse.complete(responseModel);
        final cardResponseModel = CardResponseModel.fromJson(responseModel.response?.data);

        final List<Cards> cards = [];
        final List<String> categories = [];

        if (cardResponseModel.cards != null) {
          for (final card in cardResponseModel.cards!) {
            cards.add(card);
            categories.add(card.categoryName ?? '');
            print('category name -- ${card.categoryName}');
          }
        }

        daysRangeAllCards.assignAll(cards);
        allCategories.assignAll(categories);

        filteredDaysRangeAllCards.value = List.from(cards);
      } else {
        daysRangeAllCardCategoriesResponse.value = ApiResponse.error('error');

        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('stack trace - $s');
      daysRangeAllCardCategoriesResponse.value = ApiResponse.error('error');
    } finally {
      isLoading.value = false;
    }
  }

  void filterCardsByCategory(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty || categoryName == "All") {
      filteredDaysRangeAllCards.value = List.from(daysRangeAllCards);
    } else {
      filteredDaysRangeAllCards.value = daysRangeAllCards.where((card) {
        return card.categoryName == categoryName;
      }).toList();
    }
  }

}