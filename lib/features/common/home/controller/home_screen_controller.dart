import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/more/model/card_model.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class GreetingCheckResult {
  final bool canCall;
  final String today;

  GreetingCheckResult({required this.canCall, required this.today});
}


class HomeScreenController extends GetxController{
  Rx<ApiResponse> cardCategoriesSortedByDateResponse = ApiResponse.initial('Initial').obs;
  // ApiResponse viewBusinessResponse = ApiResponse.initial('Initial');

  final RxBool isVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;

  RxList<Cards> allCards = <Cards>[].obs;

  Future<void> getCardCategoriesSortedByDate({required String todayDate}) async {
    try {
      Map<String , dynamic> params = {
        ApiKeys.date: DateTime.now().toIso8601String()
      };
      ResponseModel responseModel = await UserRepo().cardCategoriesSortedByDate(queryParams: params);
      if (responseModel.isSuccess) {
        cardCategoriesSortedByDateResponse.value = ApiResponse.complete(responseModel);
        final cardModelResponse = CardModelResponse.fromJson(responseModel.response?.data);

        final List<Cards> cards = [];

        if (cardModelResponse.categories != null) {
          for (final category in cardModelResponse.categories!) {
            if (category.cards != null) {
              cards.addAll(category.cards!);
            }
          }
        }

        allCards.value = cards;

      } else {
        cardCategoriesSortedByDateResponse.value = ApiResponse.error('error');

        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      cardCategoriesSortedByDateResponse.value = ApiResponse.error('error');
    }
  }


  // Future<void> getBusinessProfileData() async {
  //   try {
  //     await getUserLoginBusinessId();
  //     ResponseModel responseModel = await BusinessProfileRepo().viewParticularBusinessProfile();
  //
  //     if (responseModel.isSuccess) {
  //       final data = responseModel.response?.data;
  //
  //       ViewBusinessProfileModel? businessProfileDetails = ViewBusinessProfileModel.fromJson(data);
  //
  //       await SharedPreferenceUtils.setSecureValue(
  //           SharedPreferenceUtils.userProfile,
  //           businessProfileDetails.data?.logo);
  //
  //       await SharedPreferenceUtils.setSecureValue(
  //           SharedPreferenceUtils.businessName,
  //           businessProfileDetails.data?.businessName);
  //
  //       await SharedPreferenceUtils.setSecureValue(
  //           SharedPreferenceUtils.businessOwnerName,
  //           businessProfileDetails.data?.ownerDetails?[0].name);
  //
  //       await SharedPreferenceUtils.setSecureValue(
  //           SharedPreferenceUtils.businessUserIdKey,
  //           businessProfileDetails.data?.userId);
  //
  //       await getBusinessData();
  //
  //       viewBusinessResponse = ApiResponse.complete(responseModel);
  //       update();
  //     } else {
  //       commonSnackBar(
  //           message: responseModel.message ?? AppStrings.somethingWentWrong
  //       );
  //     }
  //   } catch (e) {
  //     viewBusinessResponse = ApiResponse.error('error');
  //   }
  // }

}