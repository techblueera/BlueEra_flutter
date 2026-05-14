import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_service_categories_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

/// Drives the hotel service catalog tree: top-level categories and the
/// per-category subcategory toggles that get pushed back as a bulk update.
class HotelCategoryController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxList<HotelServiceCategoriesData> hotelServiceCategoryList =
      <HotelServiceCategoriesData>[].obs;
  final RxList<HotelServiceCategoriesData> hotelServiceSubCategoryList =
      <HotelServiceCategoriesData>[].obs;

  final Rx<ApiResponse> getAllHotelServiceResponse =
      ApiResponse.initial('Initial').obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  Future<void> fetchAllHotelServiceCategories({bool isRefresh = false}) async {
    try {
      isLoading.value = true;
      hotelServiceCategoryList.clear();
      final ResponseModel response = await _repo.getHotelServiceCategoryRepo();

      if (response.isSuccess && response.response?.data != null) {
        final resModel =
            HotelServiceCategoriesResModel.fromJson(response.response?.data);
        hotelServiceCategoryList.addAll(resModel.data ?? []);
        getAllHotelServiceResponse.value = ApiResponse.complete(resModel);
      } else {
        getAllHotelServiceResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getAllHotelServiceResponse.value = ApiResponse.error(e.toString());
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleRoom(int index, bool value) {
    hotelServiceSubCategoryList[index].isEnabled = value;
    hotelServiceSubCategoryList.refresh();
  }

  Future<void> updateHotelBulkStatus() async {
    try {
      isSaving.value = true;
      final nodes = hotelServiceSubCategoryList
          .where((room) => room.id != null)
          .map((room) => {
                "catalogNodeId": room.id!,
                "isEnabled": room.isEnabled ?? false,
              })
          .toList();

      final ResponseModel response =
          await _repo.updateHotelServiceRepo(reqBody: {"nodes": nodes});

      if (response.isSuccess) {
        commonSnackBar(
            message: response.message ??
                AppStrings.hotelServicesUpdatedSuccess.tr);
      } else {
        commonSnackBar(
            message: response.message ??
                AppStrings.hotelFailedToUpdateServices.tr);
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isSaving.value = false;
    }
  }
}
