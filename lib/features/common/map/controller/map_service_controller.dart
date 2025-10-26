import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/map/model/food_service_model_response.dart';
import 'package:BlueEra/features/common/map/model/service_model_response.dart';
import 'package:BlueEra/features/common/map/repo/map_service_repo.dart';
import 'package:get/get.dart';

class MapServiceController extends GetxController{
  var homeServiceResponse = ApiResponse.initial('Initial').obs;
  var foodServiceResponse = ApiResponse.initial('Initial').obs;
  ApiResponse stayServiceResponse = ApiResponse.initial('Initial');

  RxnDouble lat = RxnDouble();
  RxnDouble lng = RxnDouble();

  /// Home Service Category
  var serviceModelResponse = ServiceModelResponse().obs;
  RxList<ServiceData> homeServiceList = <ServiceData>[].obs;
  RxList<FoodServicesData> foodServiceList = <FoodServicesData>[].obs;
  RxBool isHomeServiceLoading = true.obs;
  /// Food Service Category
  RxList<FoodServices> foodServicesList = <FoodServices>[].obs;
  RxBool isFoodServiceLoading = true.obs;


  RxList<Post> vegList = <Post>[].obs;
  RxBool isVegLoading = true.obs;
  RxList<Post> nonVegList = <Post>[].obs;
  RxBool isNonVegLoading = true.obs;
  RxList<Post> bakeryList = <Post>[].obs;
  RxBool isBakeryLoading = true.obs;
  RxList<Post> restaurantList = <Post>[].obs;
  RxBool isRestaurantLoading = true.obs;
  RxList<Post> southIndianList = <Post>[].obs;
  RxBool isSouthIndianLoading = true.obs;

  RxList<Post> stayServicesList = <Post>[].obs;
  RxBool isStayServiceLoading = true.obs;


  // Future<void> getHomeServiceDataByProfession(
  //     {
  //       required SubCategory serviceType,
  //     }) async {
  //   switch (serviceType) {
  //     case SubCategory.electrician:
  //       await fetchHomeService(
  //           // serviceType: serviceType,
  //           targetList: electricianList,
  //          isTargetLoading: isElectricianLoading.value,
  //       );
  //       break;
  //     case SubCategory.plumber:
  //       await fetchHomeService(
  //         // serviceType: serviceType,
  //         targetList: plumberList,
  //         isTargetLoading: isPlumberLoading.value,
  //       );
  //       break;
  //     case SubCategory.gardener:
  //       await fetchHomeService(
  //         // serviceType: serviceType,
  //         targetList: gardenerList,
  //         isTargetLoading: isGardenerLoading.value,
  //       );
  //     case SubCategory.painter:
  //       await fetchHomeService(
  //         // serviceType: serviceType,
  //         targetList: painterList,
  //         isTargetLoading: isPainterLoading.value,
  //       );
  //       break;
  //     case SubCategory.maid:
  //       await fetchHomeService(
  //         // serviceType: serviceType,
  //         targetList: maidList,
  //         isTargetLoading: isMaidLoading.value,
  //       );
  //   }
  // }


  /// fetch home service
  Future<void> fetchHomeService({
    required double lat,
    required double lng,
  }) async {

    final Map<String, dynamic> queryParams = {
      ApiKeys.lat: lat.toStringAsFixed(4),
      ApiKeys.lng: lng.toStringAsFixed(4),
      ApiKeys.radius: 1000,
    };

    ResponseModel response = await MapServiceRepo().fetchAllHomeServices(queryParams: queryParams);

    try {
      if (response.isSuccess) {
        homeServiceResponse.value = ApiResponse.complete(response);
        final responseModel = ServiceModelResponse.fromJson(response.response?.data);
        homeServiceList.clear();
        for (var service in responseModel.services ?? []) {
          if (service.data != null && service.data!.isNotEmpty) {
            homeServiceList.addAll(service.data!);
          }
        }

      } else {
        homeServiceResponse.value = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('stack trace --> $s');
      homeServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isHomeServiceLoading.value = false;
      // isTargetLoading = false;
    }
  }

  Map<String, List<ServiceData>> groupServicesByProfession(List<ServiceData> services) {
    final Map<String, List<ServiceData>> result = {};

    for (var service in services) {
      final designation = service.designation;

      if (designation == null || designation == 'OTHER') continue;

        final key = service.designation ?? "Unknown";

        // If profession already exists, add to existing list without duplicates
        if (result.containsKey(key)) {
          if (!result[key]!.contains(service)) {
            result[key]!.add(service);
          }
        } else {
          result[key] = [service];
        }

    }

    return result;
  }
  Map<String, List<FoodServicesData>> groupFoodServicesByProfessionDataList(List<FoodServicesData> services) {
    final Map<String, List<FoodServicesData>> result = {};

    for (var service in services) {
      final designation = service.subCategoryOfBusiness?.name;

      if (designation == null || designation == 'OTHER') continue;

        final key = designation;

        // If profession already exists, add to existing list without duplicates
        if (result.containsKey(key)) {
          if (!result[key]!.contains(service)) {
            result[key]!.add(service);
          }
        } else {
          result[key] = [service];
        }

    }

    return result;
  }



  /// fetch food service
  Future<void> fetchFoodService({
    required double lat,
    required double lng,
  }) async {

    final Map<String, dynamic> queryParams = {
      // ApiKeys.lat: lat,
      // ApiKeys.lng: lng,
      ApiKeys.radius: 1000.0,
    };

    ResponseModel response = await MapServiceRepo().fetchAllFoodServices(queryParams: queryParams);

    try {
      if (response.isSuccess) {
        foodServiceResponse.value = ApiResponse.complete(response);
        final foodServiceModelResponse = FoodServiceModelResponse.fromJson(response.response?.data);
        foodServicesList.value = foodServiceModelResponse.foodServices??[];
        foodServiceList.clear();
        for (var service in foodServiceModelResponse.foodServices ?? []) {
          if (service.data != null && service.data!.isNotEmpty) {
            foodServiceList.addAll(service.data!);
          }
        }
      } else {
        foodServiceResponse.value = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('error--> $s');
      foodServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isFoodServiceLoading.value = false;
    }
  }

  Map<String, List<FoodServicesData>> groupFoodServicesByProfession(List<FoodServices> foodServices) {
    final Map<String, List<FoodServicesData>> result = {};

    for (var service in foodServices) {
      final key = service.subCategory ?? "Unknown";

      // If profession already exists, add to existing list
      if (result.containsKey(key)) {
        result[key]!.addAll(service.data ?? []);
      } else {
        result[key] = [...(service.data ?? [])];
      }
    }

    return result;
  }

  // Future<void> fetchStayService({
  //   required String serviceType,
  // }) async {
  //
  //   final Map<String, dynamic> queryParams = {
  //     // ApiKeys.page: page,
  //     // ApiKeys.limit: limit,
  //   };
  //
  //   ResponseModel response = await MapServiceRepo().fetchAllHomeServices(queryParams: queryParams);
  //
  //   try {
  //     if (response.isSuccess) {
  //       stayServiceResponse = ApiResponse.complete(response);
  //       final postResponse = PostResponse.fromJson(response.response?.data);
  //       homeServicesList.addAll(postResponse.data);
  //     } else {
  //       stayServiceResponse = ApiResponse.error('error');
  //       commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     stayServiceResponse = ApiResponse.error('error');
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   } finally {
  //     isStayServiceLoading.value = false;
  //   }
  // }

}