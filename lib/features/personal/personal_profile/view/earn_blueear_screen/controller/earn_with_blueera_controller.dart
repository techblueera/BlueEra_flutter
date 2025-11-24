import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:get/get.dart';


class EarnWithBlueEraController extends GetxController{
  Rx<ApiResponse> ownProductsResponse =
      ApiResponse.initial('Initial').obs;

  RxInt selectedProductsServicesTabIndex = 0.obs;
  final List<String> productsServicesTab = [
    AppStrings.selfWork,
    AppStrings.deliveryPartner,
    AppStrings.homeMadeProducts,
    AppStrings.homeMadeFoodItems,
    AppStrings.homeServices,
    AppStrings.rentalServices,
  ];
  RxBool showGoLiveEnabled = false.obs;

  /// Product data
  RxList<GetProductData> ownProductDataList = <GetProductData>[].obs;
  RxBool isOwnProductDataLoadingMore = false.obs;
  RxBool isOwnProductDataFirstLoading = false.obs;
  int ownProductDataPage = 1;
  bool ownProductDataHasMore = true;

  /// Food Service Data
  RxList<GetProductData> ownFoodDataList = <GetProductData>[].obs;
  RxBool isOwnFoodDataLoadingMore = false.obs;
  RxBool isOwnFoodDataFirstLoading = false.obs;
  int ownFoodDataPage = 1;
  bool ownFoodDataHasMore = true;

  /// Services data
  RxList<GetProductData> ownServiceDataList = <GetProductData>[].obs;
  RxBool isOwnServiceDataLoadingMore = false.obs;
  RxBool isOwnServiceDataFirstLoading = false.obs;
  int ownServiceDataPage = 1;
  bool ownServiceDataHasMore = true;

  Future<void> fetchOwnProducts({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isOwnProductDataLoadingMore.value || !ownProductDataHasMore) return;
      isOwnProductDataLoadingMore.value = true;
    } else {
      isOwnProductDataFirstLoading.value = true;
      ownProductDataPage = 1;
      ownProductDataHasMore = true;
      ownProductDataList.clear();
    }

    try {

      Map<String, dynamic> queryParams = {
        'DRAFT': false,
        'ownerId': userId,
        'ownerType': ProductServiceProviderType.user.title,
      };


      final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsRepo(queryParams: queryParams);
      if (response.isSuccess) {
        ownProductsResponse.value = ApiResponse.complete(response);
        final getProductModel =
        GetProductModel.fromJson(response.response?.data);

        final List<GetProductData> newData =
            getProductModel.data;

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            ownProductDataList.addAll(newData);
          } else {
            ownProductDataList.assignAll(newData);
          }
          ownProductDataPage++;
        }
      } else {
        ownProductDataHasMore = false;
        ownProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
    } finally {
      if (isLoadMore) {
        isOwnProductDataLoadingMore.value = false;
      } else {
        isOwnProductDataFirstLoading.value = false;
      }
    }
  }

}