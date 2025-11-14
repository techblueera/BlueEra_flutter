import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/repo/rental_service_repo.dart';
import 'package:get/get.dart';

class RentalController extends GetxController{
  Rx<ApiResponse> rentalServicesResponse = ApiResponse.initial('Initial').obs; // Declare your RxLists

  final List<RentalServiceType> rentalTabs = RentalServiceType.values;
  Rx<RentalServiceType> selectedRentalTabs = RentalServiceType.homeStay.obs;

  RxList<RentalServiceData> homeStayServices = <RentalServiceData>[].obs;
  RxList<RentalServiceData> flatRoomServices = <RentalServiceData>[].obs;
  RxList<RentalServiceData> vehicleServices = <RentalServiceData>[].obs;
  RxBool isLoading = false.obs;
  // // int page = 1;
  // // int limit = 10;
  // // bool hasMoreData = true;
  // // bool isLoadingMore = false;

  void callApi({bool forceRefresh = false}) {
    RxList<RentalServiceData> targetList;

    switch (selectedRentalTabs.value) {
      case RentalServiceType.homeStay:
        targetList = homeStayServices;
        break;
      case RentalServiceType.flatRoom:
        targetList = flatRoomServices;
        break;
      case RentalServiceType.vehicle:
        targetList = vehicleServices;
        break;
    }

    if (forceRefresh || targetList.isEmpty) {
      fetchRentalServicesData(
        rentalServiceType: selectedRentalTabs.value.apiValue,
        targetList: targetList,
      );
    }
  }

  Future<void> fetchRentalServicesData({
    required String rentalServiceType,
    required RxList<RentalServiceData> targetList,
  }) async {
    try {
      isLoading.value = true;

      Map<String, dynamic> queryParams = {
        ApiKeys.type: rentalServiceType,
      };

      final response = await RentalServiceRepo().getRentalService(
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        rentalServicesResponse.value = ApiResponse.complete(response);

        final rentalServiceResponse =
        RentalServiceResponse.fromJson(response.response!.data);

        final List<RentalServiceData> results = rentalServiceResponse.data ?? [];

        targetList
          ..clear()
          ..assignAll(results);

      } else {
        rentalServicesResponse.value =
            ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);

        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      rentalServicesResponse.value = ApiResponse.error(AppStrings.somethingWentWrong);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

}