import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/model/all_education_res_model.dart';
import 'package:BlueEra/features/common/Discover/model/food_restaurant_service_model.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../../core/api/model/new_food_home_res_model.dart';
import '../model/get_booking_rider_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../chat/auth/controller/call_controller.dart';
import '../../../chat/auth/repo/make_order_repo.dart';
import '../../../chat/auth/socket/chat_socket.dart';
import '../../../chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';

enum CategoryFilter {
  nearest('Nearest', AppStrings.filterNearest),
  experienced('Experienced', AppStrings.filterExperienced),
  priceLowToHigh('Price (Low-High)', AppStrings.filterPriceLowToHigh);

  final String label;
  final String _translationKey;

  const CategoryFilter(this.label, this._translationKey);

  /// Returns the translated label, falling back to the English [label]
  /// if the current locale has no translation yet (so the UI never breaks
  /// or shows raw keys while Hindi/other-language packs are still loading).
  String get localizedLabel {
    final translated = _translationKey.tr;
    return translated == _translationKey ? label : translated;
  }
}

enum DiscoverFilter {
  home('Home', AppStrings.discoverHome),
  deals('Deals', AppStrings.discoverDeals),
  events('Events', AppStrings.discoverEvents),
  careerJobs('Career / Jobs', AppStrings.discoverCareerJobs);

  final String label;
  final String _translationKey;

  const DiscoverFilter(this.label, this._translationKey);

  String get localizedLabel {
    final translated = _translationKey.tr;
    return translated == _translationKey ? label : translated;
  }
}

class DiscoverController extends GetxController {
  var selfProfessionServiceResponse = ApiResponse.initial('Initial').obs;

  var profConProfessionServiceResponse = ApiResponse.initial('Initial').obs;

  // var educationServiceResponse = ApiResponse.initial('Initial').obs;
  // var foodRestaurantServiceResponse = ApiResponse.initial('Initial').obs;
  var rentalServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> productsResponse = ApiResponse.initial('Initial').obs;
  Set<Marker> markers = {};
  final ScrollController scrollController = ScrollController();
  Rx<LatLng>? currentAddress = LatLng(0.0, 0.0).obs;
  final GlobalKey headerKey = GlobalKey();
  Function(bool isVisible)? onHeaderVisibilityChanged;
  final RxBool isHeaderVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;
  double headerHeight = 0;

  final List<DiscoverFilter> discoverFilters = DiscoverFilter.values;
  Rx<DiscoverFilter> selectedDiscoverFilter = DiscoverFilter.home.obs;

  Rx<OnboardingCategoryModel?> selectedEarnServiceData =
      Rx<OnboardingCategoryModel?>(null);
  Rx<OnboardingCategoryModel?> selectedProfConsServiceData =
      Rx<OnboardingCategoryModel?>(null);
  RxInt selectedTabIndex = 0.obs;
  final List<CategoryFilter> filters = CategoryFilter.values;
  Rx<CategoryFilter> selectedFilter = CategoryFilter.nearest.obs;
  final int limit = 20;

  /// Self Profession Services
  RxList<ServiceData> earnServiceList = <ServiceData>[].obs;
  RxList<ProfessionalConsData> professionalConsDataList =
      <ProfessionalConsData>[].obs;
  RxList<SchoolDetailsData> schoolDetailsDataDataList =
      <SchoolDetailsData>[].obs;

  RxList<FoodData> foodRestaurantDataList = <FoodData>[].obs;
  RxBool isEarnServiceLoading = false.obs;
  RxBool isProfConServiceLoading = false.obs;
  RxBool isEducationServiceLoading = false.obs;
  RxBool isFoodRestaurantLoading = false.obs;
  int earnServicePage = 1;
  int profConsServicePage = 1;
  int educationServicePage = 1;
  int foodRestaurantServicePage = 1;
  var isEarnServiceLoadingMore = false.obs;
  var isProfConServiceLoadingMore = false.obs;
  var isEducationServiceLoadingMore = false.obs;
  var isFoodRestaurantLoadingMore = false.obs;
  Rx<VehicleAllResponse> ridersDetailsList = VehicleAllResponse().obs;
  var bookingRiderListResponse = ApiResponse.initial('Initial').obs;

  bool hasMoreEarnServiceData = true;
  bool hasMoreProfConServiceData = true;
  bool hasMoreEducationServiceData = true;
  bool hasMoreFoodRestaurantData = true;

  RxBool findRiderDetailsLoading = false.obs;
  RxBool bookRiderBtnLoading = false.obs;
  RxInt selectedHorizontalTab = 0.obs;
  RxInt selectedVehicleOptionIndex = 0.obs;
  RxDouble? selectedFromLat = 0.0.obs;
  RxDouble? selectedFromLong = 0.0.obs;
  RxDouble? selectedToLat = 0.0.obs;
  RxDouble? selectedToLong = 0.0.obs;
  RxString? selectedFromAddress = "".obs;
  RxString? selectedToAddress = "".obs;
  RxString transportDistanceText = "".obs;
  RxDouble roadDistanceKm = 0.0.obs;
  RxString selectedRideType = AppConstants.oneWay.obs;
  RxString selectedBookingFor = AppConstants.mySelf.obs;
  final myFriendPhoneController = TextEditingController();

  /// Rental Services && Hotel Services
  RxList<RentalServiceData> rentalServices = <RentalServiceData>[].obs;
  RxList<HotelServiceData> hotelServices = <HotelServiceData>[].obs;
  RxBool isRentalServiceLoading = false.obs;
  int rentalServicePage = 1;
  var isRentalServiceLoadingMore = false.obs;
  bool hasMoreRentalServiceData = true;

  // --- Fare-call queue state ---
  RxBool isFareCallInProgress = false.obs;
  RxString fareCallOrderId = ''.obs;
  RxInt fareCallCurrentRiderIndex = 0.obs;
  RxInt fareCallTotalRiders = 0.obs;
  RxString fareCallCurrentRiderId = ''.obs;
  Rxn<Map<String, dynamic>> fareCallAcceptedRiderInfo = Rxn<Map<String, dynamic>>();
  RxString fareCallAcceptedRiderId = ''.obs;
  RxString fareCallPickupOtp = ''.obs;
  RxBool isFareCallRideStarted = false.obs;
  Rxn<Map<String, dynamic>> fareCallRideStartedData = Rxn<Map<String, dynamic>>();
  RxBool isFareCallRideCompleted = false.obs;
  Rxn<Map<String, dynamic>> fareCallRideCompletedData = Rxn<Map<String, dynamic>>();

  Rx<RiderUser> selectedRider = RiderUser().obs;
  RxList<RiderUser> selectedRiders = <RiderUser>[].obs;
  Rxn<OnboardingCategoryModel> selectedStayCategory =
      Rxn<OnboardingCategoryModel>();
  RxString selectedParcelCategory = "Document".obs;
  final receiversNameController = TextEditingController();
  final receiversNumberController = TextEditingController();
  final parcelDescriptionController = TextEditingController();
  final parcelWeightController = TextEditingController();
  RxList<ParcelCategoryModel> parcelDetailsList = <ParcelCategoryModel>[].obs;

  void addParcelDetails() {
    parcelDetailsList.add(ParcelCategoryModel(
        category: selectedParcelCategory.value,
        description: parcelDescriptionController.text,
        weightKg: parcelWeightController.text));
  }

  void clearParcelField() {
    parcelDescriptionController.clear();
    parcelWeightController.clear();
  }

  void removeParcelDetails(ParcelCategoryModel value) {
    parcelDetailsList.remove(value);
  }

  var selectedRoomType = "".obs;

  List<String> getDynamicRoomTypes(HotelServiceData hotelData) {
    final rooms = hotelData.rooms ?? [];

    return rooms
        .map((e) => e.type ?? "")
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  void onSelectRider(RiderUser rider) {
    if (selectedRiders.any((r) => r.riderId == rider.riderId)) {
      selectedRiders.removeWhere((r) => r.riderId == rider.riderId);
    } else {
      selectedRiders.add(rider);
    }
    // Keep selectedRider as the first selected for backward compatibility
    if (selectedRiders.isNotEmpty) {
      selectedRider.value = selectedRiders.first;
    } else {
      selectedRider.value = RiderUser();
    }
  }

  /// Consultant Service
  Rx<OnboardingCategoryModel?> selectedProfessionalConsultantData =
      Rx<OnboardingCategoryModel?>(null);
  Rx<OnboardingCategoryModel?> selectedEducationServiceData =
      Rx<OnboardingCategoryModel?>(null);

  Rx<OnboardingCategoryModel?> selectedFoodServiceData =
      Rx<OnboardingCategoryModel?>(null);

  /// Products
  RxList<GetProductData> productDataList = <GetProductData>[].obs;
  RxBool isProductDataLoadingMore = false.obs;
  RxBool isProductDataFirstLoading = false.obs;
  int productDataPage = 1;
  bool productDataHasMore = true;

  // final List<CollapsibleGridModel> discoverOptions = [
  //   CollapsibleGridModel(
  //     name: 'Suggested',
  //     slugId: 'SUGGESTED_SECTOR',
  //     icon: AppImageAssets.plumber,
  //   ),
  //   CollapsibleGridModel(
  //       name: 'Grocery & Food',
  //       slugId: 'GROCERY_FOOD_SECTOR',
  //       icon: AppImageAssets.deliveryPartner),
  //   CollapsibleGridModel(
  //       name: AppStrings.homeMadeProducts,
  //       slugId: 'HOME_MADE_PRODUCTS',
  //       icon: AppImageAssets.homeMadeProduct
  //   ),
  //   CollapsibleGridModel(
  //       name: 'Ride & Transport',
  //       slugId: 'RIDE_TRANSPORT',
  //       icon: AppImageAssets.homeMadeFood
  //   ),
  //   CollapsibleGridModel(
  //       name: 'Shopping',
  //       slugId: 'SHOPPING_SECTOR',
  //       icon: AppImageAssets.homeService
  //   ),
  //   CollapsibleGridModel(
  //       name: 'Book Professionals',
  //       slugId: 'BOOK_PROFESSIONAL',
  //       icon: AppImageAssets.consultation
  //   ),
  //   CollapsibleGridModel(
  //       name: 'Home Made',
  //       slugId: 'HOME_MADE_SECTOR',
  //       icon: AppImageAssets.homeMadeProduct
  //   ),
  //   CollapsibleGridModel(
  //       name: 'Hotel & Stay',
  //       slugId: 'HOTEL_STAY',
  //       icon: AppImageAssets.contentCreator
  //   ),
  //   CollapsibleGridModel(
  //       name: 'Health Care',
  //       slugId: 'HEALTH_CARE',
  //       icon: OnboardingBusinessAssets.healthcareMedicalServices),
  //   CollapsibleGridModel(
  //       name: 'Rent & Property',
  //       slugId: 'RENT_PROPERTY',
  //       icon: AppImageAssets.rentalService),
  //   CollapsibleGridModel(
  //       name: 'Automotive Services',
  //       slugId: 'AUTOMOTIVE_SERVICE',
  //       icon: AppImageAssets.tutor),
  //   CollapsibleGridModel(
  //       name: 'Find Services',
  //       slugId: 'FIND_SERVICE',
  //       icon: AppImageAssets.tutor),
  //   CollapsibleGridModel(
  //       name: 'Education & Training',
  //       slugId: 'EDUCATION_TRAINING',
  //       icon: OnboardingBusinessAssets.educationAndTraining),
  //   CollapsibleGridModel(
  //       name: 'Jobs Near Me',
  //       slugId: 'JOBS_NEAR_ME_SECTOR',
  //       icon: AppImageAssets.tutor),
  // ];
  // final selectedOption = Rxn<CollapsibleGridModel>();

  ///GET STORE PRODUCT ONLY....
  Future<void> getAllProductNearBy(
      {ProviderType? providerType,
      String? productCategory,
      bool isLoadMore = false,
      String? query}) async {
    if (isLoadMore) {
      if (isProductDataLoadingMore.value || !productDataHasMore) return;
      isProductDataLoadingMore.value = true;
    } else {
      isProductDataFirstLoading.value = true;
      productDataPage = 1;
      productDataHasMore = true;
      productDataList.clear();

      // /// fetch local data not for search
      // if(query == null){
      //   final cachedProduct = await HiveServices().getAllStoreProduct(userId);
      //   if (cachedProduct != null && cachedProduct.isNotEmpty) {
      //     productDataList.assignAll(cachedProduct);
      //     isProductDataFirstLoading.value = false;
      //   }
      // }
    }

    try {
      log('lat--> ${LocationService.lat}, lng--> ${LocationService.lng}');

      const int limit = 20;

      // Build query parameters dynamically
      final Map<String, dynamic> queryParams = {
        ApiKeys.page: productDataPage,
        ApiKeys.limit: limit,
        ApiKeys.maxDistance: kmRadius5000,
      };
      double lat = LocationService.lat != 0.0 ? LocationService.lat : 0.0;
      double long = LocationService.lng != 0.0 ? LocationService.lng : 0.0;

      if ((lat != 0.0) && (long != 0.0)) {
        queryParams[ApiKeys.latitude] = lat;
        queryParams[ApiKeys.longitude] = long;
      }
      if (providerType != null)
        queryParams[ApiKeys.ownerType] = providerType.title;
      if (productCategory != null) queryParams[ApiKeys.key] = productCategory;

      final response;
      if (query != null) {
        response =
            await StoreRepo().productSearchFilterRepo(queryParams: queryParams);
      } else {
        if (productCategory != null) {
          response =
              await StoreRepo().productFilterRepo(queryParams: queryParams);
        } else {
          response =
              await StoreRepo().homePageProductRepo(queryParams: queryParams);
        }
      }

      if (response.isSuccess) {
        productsResponse.value = ApiResponse.complete(response);
        final getOwnProductModel =
            GetProductModel.fromJson(response.response?.data);

        final List<GetProductData> newData = getOwnProductModel.data;

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            productDataList.addAll(newData);
          } else {
            productDataList.assignAll(newData);
            log('product data length--> ${productDataList.length}');
            log('loggggg 1--> ${productDataList[0].product.business_name}');

            if (query == null) {
              await HiveServices().saveAllStoreProduct(productDataList, userId);
            }
          }
          productDataPage++;
        }
      } else {
        productDataHasMore = false;
        productsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      log('stack trace --> $s');
      productsResponse.value = ApiResponse.error('error');
    } finally {
      if (isLoadMore) {
        isProductDataLoadingMore.value = false;
      } else {
        isProductDataFirstLoading.value = false;
      }
    }
  }

  /// fetch Earn service
  Future<void> fetchEarnServices(
      {required String earnServiceType,
      required String subType,
      bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isEarnServiceLoadingMore.value || !hasMoreEarnServiceData) {
        return;
      }
      isEarnServiceLoadingMore.value = true;
    } else {
      earnServiceList.clear();
      isEarnServiceLoading.value = true;
      earnServicePage = 1;
      hasMoreEarnServiceData = true;
    }

    // double lat = LocationService.lat;
    // double lng = LocationService.lng;

    final Map<String, dynamic> queryParams = {
      ApiKeys.type: earnServiceType,
      ApiKeys.subType: subType,
      // ApiKeys.lat: lat,
      // ApiKeys.lng: lng,
      // ApiKeys.radius: kmRadius1500,
      ApiKeys.page: earnServicePage,
      ApiKeys.limit: limit,
    };
    if (selectedEarnServiceData.value != null) {
      queryParams[ApiKeys.category] = selectedEarnServiceData.value?.slugId;
    }

    ResponseModel response =
        await DiscoverRepo().fetchSelfWorkServices(queryParams: queryParams);

    try {
      if (response.isSuccess) {
        selfProfessionServiceResponse.value = ApiResponse.complete(response);

        final responseModel =
            ServiceModelResponse.fromJson(response.response?.data);

        List<ServiceData> tempNewItems = [];

        for (var service in responseModel.services ?? []) {
          if (service.data != null && service.data!.isNotEmpty) {
            for (ServiceData item in service.data!) {
              // Distance Calculation Logic
              double itemLat =
                  double.tryParse(item.userLocation?.lat.toString() ?? "0") ??
                      0.0;
              double itemLng =
                  double.tryParse(item.userLocation?.lon.toString() ?? "0") ??
                      0.0;

              double? tempDistance;
              if (itemLat != 0 && itemLng != 0) {
                tempDistance = await getDistanceInKm(itemLat, itemLng);
              } else {
                tempDistance = 0.0;
              }
              item.distance = tempDistance?.toInt();

              tempNewItems.add(item);
            }
          }
        }

        if (tempNewItems.length < limit) {
          hasMoreEarnServiceData = false;
        }

        if (isLoadMore) {
          earnServiceList.addAll(tempNewItems);
        } else {
          earnServiceList.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          earnServicePage++;
        }
      } else {
        if (!isLoadMore) {
          selfProfessionServiceResponse.value = ApiResponse.error('error');
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e, s) {
      print('stack trace --> $s');
      selfProfessionServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      if (isLoadMore) {
        isEarnServiceLoadingMore.value = false;
      } else {
        isEarnServiceLoading.value = false;
      }
    }
  }

  /// fetch Earn service
  Future<void> fetchFoodRestaurantService({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFoodRestaurantLoadingMore.value || !hasMoreFoodRestaurantData) {
        return;
      }
      isFoodRestaurantLoadingMore.value = true;
    } else {
      foodRestaurantDataList.clear();
      isFoodRestaurantLoading.value = true;
      foodRestaurantServicePage = 1;
      hasMoreFoodRestaurantData = true;
    }

    final Map<String, dynamic> queryParams = {
      if (selectedFoodServiceData.value?.slugId != null)
        "categoryId": selectedFoodServiceData.value?.slugId,
      // ApiKeys.page: foodRestaurantServicePage,
      // ApiKeys.limit: limit,
    };

    ResponseModel response = await SchoolRepo().getSearchFoodRepo(
        reqParm: selectedFoodServiceData.value?.slugId ?? "");

    try {
      if (response.isSuccess) {
        // foodRestaurantServiceResponse.value = ApiResponse.complete(response);
        final responseModel =
            FoodRestaurantServiceModel.fromJson(response.response?.data);

        List<FoodData> tempNewItems = responseModel.data ?? [];
        if (tempNewItems.length < limit) {
          hasMoreFoodRestaurantData = false;
        }

        if (isLoadMore) {
          foodRestaurantDataList.addAll(tempNewItems);
        } else {
          foodRestaurantDataList.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          foodRestaurantServicePage++;
        }
      } else {
        if (!isLoadMore) {
          // foodRestaurantServiceResponse.value = ApiResponse.error('error');
        }
      }
    } catch (e, s) {
      print('stack trace --> $s');
      // foodRestaurantServiceResponse.value = ApiResponse.error('error');
    } finally {
      if (isLoadMore) {
        isFoodRestaurantLoadingMore.value = false;
      } else {
        isFoodRestaurantLoading.value = false;
      }
    }
  }

  Future<void> fetchEducationServiceServices({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isEducationServiceLoadingMore.value || !hasMoreEducationServiceData) {
        return;
      }
      isEducationServiceLoadingMore.value = true;
    } else {
      schoolDetailsDataDataList.clear();
      isEducationServiceLoading.value = true;
      educationServicePage = 1;
      hasMoreEducationServiceData = true;
    }

    final Map<String, dynamic> queryParams = {
      if (selectedEducationServiceData.value?.slugId != null)
        "search": selectedEducationServiceData.value?.slugId,
      ApiKeys.page: educationServicePage,
      ApiKeys.limit: limit,
    };

    ResponseModel response =
        await SchoolRepo().getSearchSchoolRepo(reqParm: queryParams);

    try {
      if (response.isSuccess) {
        // educationServiceResponse.value = ApiResponse.complete(response);
        final responseModel =
            AllEducationResModel.fromJson(response.response?.data);

        List<SchoolDetailsData> tempNewItems = responseModel.data ?? [];
        if (tempNewItems.length < limit) {
          hasMoreEducationServiceData = false;
        }

        if (isLoadMore) {
          schoolDetailsDataDataList.addAll(tempNewItems);
        } else {
          schoolDetailsDataDataList.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          educationServicePage++;
        }
      } else {
        if (!isLoadMore) {
          // educationServiceResponse.value = ApiResponse.error('error');
        }
      }
    } catch (e, s) {
      print('stack trace --> $s');
      // educationServiceResponse.value = ApiResponse.error('error');
    } finally {
      if (isLoadMore) {
        isEducationServiceLoadingMore.value = false;
      } else {
        isEducationServiceLoading.value = false;
      }
    }
  }

  Future<void> fetchProfessionalConsultantServices(
      {bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isProfConServiceLoadingMore.value || !hasMoreProfConServiceData) {
        return;
      }
      isProfConServiceLoadingMore.value = true;
    } else {
      professionalConsDataList.clear();
      isProfConServiceLoading.value = true;
      profConsServicePage = 1;
      hasMoreProfConServiceData = true;
    }

    final Map<String, dynamic> queryParams = {
      if (selectedProfessionalConsultantData.value?.slugId != null)
        "profession": selectedProfessionalConsultantData.value?.slugId,
      ApiKeys.page: profConsServicePage,
      ApiKeys.limit: limit,
    };

    ResponseModel response = await DiscoverRepo()
        .fetchProfessionalConsServices(queryParams: queryParams);

    try {
      if (response.isSuccess) {
        profConProfessionServiceResponse.value = ApiResponse.complete(response);
        final responseModel =
            ProfessionalConsResModel.fromJson(response.response?.data);

        List<ProfessionalConsData> tempNewItems = responseModel.data ?? [];
        if (tempNewItems.length < limit) {
          hasMoreProfConServiceData = false;
        }

        if (isLoadMore) {
          professionalConsDataList.addAll(tempNewItems);
        } else {
          professionalConsDataList.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          profConsServicePage++;
        }
      } else {
        if (!isLoadMore) {
          profConProfessionServiceResponse.value = ApiResponse.error('error');
        }
      }
    } catch (e, s) {
      print('stack trace --> $s');
      profConProfessionServiceResponse.value = ApiResponse.error('error');
    } finally {
      if (isLoadMore) {
        isProfConServiceLoadingMore.value = false;
      } else {
        isProfConServiceLoading.value = false;
      }
    }
  }

  Future<String> getOrderTypeString() async {
    switch (selectedHorizontalTab.value) {
      case 0:
        return "InCity";
      case 1:
        return "OutStation";
      case 2:
        return "HourlyRental";
      case 3:
        return "Parcel";
      default:
        return "InCity";
    }
  }

  /// Reverse-geocode the given lat/lng to extract the postal code.
  Future<String?> getPostCodeFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return placemarks.first.postalCode;
      }
      return null;
    } catch (e) {
      print("Post code from coordinates error: $e");
      return null;
    }
  }

  /// Get pincode from the selected "from" location, falling back to current location.
  Future<String> _getFromLocationPincode() async {
    // Try selected from-location first
    if (selectedFromLat?.value != null &&
        selectedFromLat!.value != 0.0 &&
        selectedFromLong?.value != null &&
        selectedFromLong!.value != 0.0) {
      final pincode = await getPostCodeFromCoordinates(
        selectedFromLat!.value,
        selectedFromLong!.value,
      );
      if (pincode != null && pincode.isNotEmpty) return pincode;
    }
    // Fallback to current location
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return '';
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final pincode = await getPostCodeFromCoordinates(
        position.latitude,
        position.longitude,
      );
      return pincode ?? '';
    } catch (e) {
      print("Current location post code error: $e");
      return '';
    }
  }

  Future<void> getBookingRidersApi() async {
    if (selectedFromLat?.value != 0.0 &&
        selectedFromLong?.value != 0.0 &&
        selectedToLat?.value != 0.0 &&
        selectedToLong?.value != 0.0) {
      findRiderDetailsLoading.value = true;

      String pincode = '';
      if (selectedHorizontalTab.value == 0 ||
          selectedHorizontalTab.value == 1) {
        pincode = await _getFromLocationPincode();
      }

      Map<String, dynamic> queryParams = {
        ApiKeys.orderFor: await getOrderTypeString(),
        ApiKeys.pickupLatitude: selectedFromLat?.value,
        ApiKeys.pickupLongitude: selectedFromLong?.value,
        ApiKeys.dropLatitude: selectedToLat?.value,
        ApiKeys.dropLongitude: selectedToLong?.value,
        ApiKeys.range_in_km: 20,
        if (selectedHorizontalTab.value == 0 ||
            selectedHorizontalTab.value == 1)
          ApiKeys.pincode: pincode,
        if (roadDistanceKm.value > 0)
          'distance_in_km': roadDistanceKm.value,
      };
      final response = await DiscoverRepo().getBookingRidersApi(
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        ridersDetailsList.value =
            VehicleAllResponse.fromJson(response.response?.data);
        bookingRiderListResponse.value =
            ApiResponse.complete(ridersDetailsList.value);
        findRiderDetailsLoading.value = false;
      } else {
        bookingRiderListResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        findRiderDetailsLoading.value = false;
      }
    }
  }

  String getTabName(int index) {
    switch (index) {
      case 0:
        return 'InCity';
      case 1:
        return 'OutStation';
      case 2:
        return 'HourlyRental';
      case 3:
        return 'Parcel';
      default:
        return '';
    }
  }

  String getSelectedVehicleFare(int index) {
    switch (index) {
      case 0:
        return '${ridersDetailsList.value.twoWheelerRider?.fare}';
      case 1:
        return '${ridersDetailsList.value.carMini?.fare}';
      case 2:
        return '${ridersDetailsList.value.autoTempo?.fare}';
      case 3:
        return '${ridersDetailsList.value.eRickshaw?.fare}';
      default:
        return '';
    }
  }

  Future<bool> makeTransportBookOrderApi() async {
    bookRiderBtnLoading.value = true;
    Map<String, dynamic> params = {
      ApiKeys.selectedRiders: selectedRiders.map((r) => r.riderId).toList(),
      ApiKeys.pickupLocation: {
        ApiKeys.address: "${selectedFromAddress?.value}",
        ApiKeys.latitude: selectedFromLat?.value,
        ApiKeys.longitude: selectedFromLong?.value
      },
      ApiKeys.dropLocation: {
        ApiKeys.address: "${selectedToAddress?.value}",
        ApiKeys.latitude: selectedToLat?.value,
        ApiKeys.longitude: selectedToLong?.value
      },
      ApiKeys.receiverUserId: "${selectedRider.value.riderId}",
      ApiKeys.orderFor: "${getTabName(selectedHorizontalTab.value)}",
      ApiKeys.modeOfPayment: "prepaid",
      if (selectedHorizontalTab.value == 1)
        ApiKeys.tripType: selectedRideType.value == AppConstants.oneWay
            ? "oneWay"
            : selectedRideType.value == AppConstants.roundTrip
                ? "roundTrip"
                : "sharing",
      if (selectedHorizontalTab.value == 1)
        ApiKeys.orderForWhom: selectedBookingFor.value == AppConstants.mySelf
            ? "myself"
            : "someoneElse",
      if (selectedHorizontalTab.value == 1)
        if (selectedBookingFor.value == AppConstants.myFriend)
          ApiKeys.contactNo: myFriendPhoneController.text,
      ApiKeys.fare: ridersDetailsList.value.twoWheelerRider?.fare,
      ApiKeys.orderType: 'fare-call',
    };

    final response = await DiscoverRepo().makeTransportBookOrderApi(
      params: params,
    );

    if (response.isSuccess) {
      bookRiderBtnLoading.value = false;
      // Store the orderId for fare-call queue tracking
      final data = response.response?.data;
      if (data != null && data is Map) {
        fareCallOrderId.value = data['orderId'] ?? data['_id'] ?? '';
        // Save pickup OTP from order creation response so the customer
        // can see it even if ride:queue:accepted socket event is missed.
        fareCallPickupOtp.value = (data['pickupOTP'] ?? '').toString();
      }
      isFareCallInProgress.value = true;
      fareCallTotalRiders.value = selectedRiders.length;
      fareCallCurrentRiderIndex.value = 0;
      return true;
    } else {
      bookRiderBtnLoading.value = false;
      commonSnackBar(message: response.message ?? "Unable to Book a Rider");
      return false;
    }
  }

  /// Setup socket listeners for fare-call queue progress
  void setupFareCallQueueListeners() {
    final socket = ChatSocketService();

    socket.listenEvent('ride:queue:calling', (data) {
      debugPrint('[FARE_CALL_QUEUE] ride:queue:calling → $data');
      fareCallCurrentRiderIndex.value = (data['riderIndex'] ?? 0) + 1;
      fareCallTotalRiders.value = data['totalRiders'] ?? selectedRiders.length;
      fareCallCurrentRiderId.value = data['riderId'] ?? '';

      // Auto-join the WebRTC call room so audio connects when rider accepts
      final callId = (data['call_id'] ?? '').toString();
      final roomId = (data['room_id'] ?? '').toString();
      final riderId = (data['riderId'] ?? '').toString();
      final conversationId = (data['conversation_id'] ?? '').toString();
      // ice_servers can be a List [...] or a Map {iceServers: [...]}
      final rawIceServers = data['ice_servers'];
      List iceServers;
      if (rawIceServers is List) {
        iceServers = rawIceServers;
      } else if (rawIceServers is Map && rawIceServers['iceServers'] is List) {
        iceServers = rawIceServers['iceServers'] as List;
      } else {
        iceServers = [];
      }

      debugPrint('[FARE_CALL_DEBUG] ride:queue:calling → callId=$callId, roomId=$roomId, riderId=$riderId, iceServers count=${iceServers.length}');
      debugPrint('[FARE_CALL_DEBUG] ride:queue:calling → iceServers=$iceServers');

      if (callId.isNotEmpty && roomId.isNotEmpty && riderId.isNotEmpty) {
        if (!Get.isRegistered<CallController>()) {
          debugPrint('[FARE_CALL_DEBUG] ride:queue:calling → CallController not registered, creating new');
          Get.put(CallController(), permanent: true);
        }
        final callController = Get.find<CallController>();
        debugPrint('[FARE_CALL_DEBUG] ride:queue:calling → CallController current status=${callController.callStatus.value}');
        callController.joinFareCallAsCustomer(
          fareCallId: callId,
          fareRoomId: roomId,
          riderId: riderId,
          fareConversationId: conversationId,
          iceServers: iceServers,
        );
      } else {
        debugPrint('[FARE_CALL_DEBUG] ride:queue:calling → ⚠️ MISSING DATA: callId=$callId, roomId=$roomId, riderId=$riderId — cannot join call!');
      }
    });

    socket.listenEvent('ride:queue:accepted', (data) {
      debugPrint('[FARE_CALL_QUEUE] ride:queue:accepted → $data');
      // IMPORTANT: Set riderInfo BEFORE setting isFareCallInProgress=false.
      // The exhausted worker triggers on isFareCallInProgress change and checks
      // fareCallAcceptedRiderInfo — if riderInfo is still null, it pops the screen.
      fareCallAcceptedRiderInfo.value = data['riderInfo'] != null
          ? Map<String, dynamic>.from(data['riderInfo'])
          : null;
      fareCallAcceptedRiderId.value = data['riderId'] ?? data['riderInfo']?['riderId'] ?? '';
      fareCallPickupOtp.value = data['pickupOTP']?.toString() ?? '';
      isFareCallInProgress.value = false;
    });

    socket.listenEvent('ride:queue:exhausted', (data) {
      debugPrint('[FARE_CALL_QUEUE] ride:queue:exhausted → $data');
      isFareCallInProgress.value = false;
      fareCallAcceptedRiderInfo.value = null;
      commonSnackBar(message: 'No riders available. Please try again.');
    });

    socket.listenEvent('ride:started', (data) {
      log('[FARE_CALL_QUEUE] ride:started → $data');
      isFareCallRideStarted.value = true;
      fareCallRideStartedData.value = data != null
          ? Map<String, dynamic>.from(data)
          : null;
    });

    socket.listenEvent('ride:completed', (data) {
      log('[FARE_CALL_QUEUE] ride:completed → $data');
      isFareCallRideCompleted.value = true;
      fareCallRideCompletedData.value = data != null
          ? Map<String, dynamic>.from(data)
          : null;

      // If the floating overlay is showing, close it and show a snackbar
      if (Get.isRegistered<RideNavigationOverlayController>()) {
        final overlayCtrl = Get.find<RideNavigationOverlayController>();
        if (overlayCtrl.isOverlayVisible.value) {
          overlayCtrl.hideOverlay();
          commonSnackBar(message: 'Ride completed successfully!');
        }
      }
    });
  }

  /// Cancel fare-call queue
  Future<void> cancelFareCallQueue() async {
    if (fareCallOrderId.value.isEmpty) return;
    final response = await MakeOrderRepo().cancelFareCallQueueApi(fareCallOrderId.value);
    if (response.isSuccess) {
      isFareCallInProgress.value = false;
      commonSnackBar(message: 'Ride request cancelled');
    } else {
      commonSnackBar(message: response.message ?? 'Failed to cancel');
    }
  }

  /// Cleanup fare-call queue state
  void resetFareCallState() {
    isFareCallInProgress.value = false;
    fareCallOrderId.value = '';
    fareCallCurrentRiderIndex.value = 0;
    fareCallTotalRiders.value = 0;
    fareCallCurrentRiderId.value = '';
    fareCallAcceptedRiderInfo.value = null;
    fareCallAcceptedRiderId.value = '';
    fareCallPickupOtp.value = '';
    isFareCallRideStarted.value = false;
    fareCallRideStartedData.value = null;
    isFareCallRideCompleted.value = false;
    fareCallRideCompletedData.value = null;
  }

  Future<void> fetchRentalServices(
      {required RentalServiceType rentalServiceType,
      bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        log('more rental data -- $hasMoreRentalServiceData');
        if (isRentalServiceLoadingMore.value || !hasMoreRentalServiceData) {
          return;
        }
        isRentalServiceLoadingMore.value = true;
      } else {
        rentalServices.clear();
        isRentalServiceLoading.value = true;
        rentalServicePage = 1;
        hasMoreRentalServiceData = true;
      }

      Map<String, dynamic> queryParams = {
        ApiKeys.type: rentalServiceType.apiValue,
        // ApiKeys.lat: lat,
        // ApiKeys.lng: lng,
        ApiKeys.radius: kmRadius1500,
        ApiKeys.page: rentalServicePage,
        ApiKeys.limit: limit,
      };

      final response = await DiscoverRepo().getRentalService(
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        rentalServiceResponse.value = ApiResponse.complete(response);

        final responseModel =
            RentalServiceResponse.fromJson(response.response!.data);

        final List<RentalServiceData> tempNewItems = responseModel.data ?? [];

        if (tempNewItems.length < limit) {
          hasMoreRentalServiceData = false;
        }

        if (isLoadMore) {
          rentalServices.addAll(tempNewItems);
        } else {
          rentalServices.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          rentalServicePage++;
        }
      } else {
        if (!isLoadMore) {
          rentalServiceResponse.value = ApiResponse.error('error');
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e) {
      rentalServiceResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
      // commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      if (isLoadMore) {
        isRentalServiceLoadingMore.value = false;
      } else {
        isRentalServiceLoading.value = false;
      }
    }
  }

  Future<void> fetchHotelServices(
      {required String category, bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        log('more rental data -- $hasMoreRentalServiceData');
        if (isRentalServiceLoadingMore.value || !hasMoreRentalServiceData) {
          return;
        }
        isRentalServiceLoadingMore.value = true;
      } else {
        hotelServices.clear();
        isRentalServiceLoading.value = true;
        rentalServicePage = 1;
        hasMoreRentalServiceData = true;
      }

      Map<String, dynamic> queryParams = {
        ApiKeys.category: category,
        ApiKeys.page: rentalServicePage,
        ApiKeys.limit: limit,
      };

      final response = await DiscoverRepo().fetchHotelSearchRepo(
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        rentalServiceResponse.value = ApiResponse.complete(response);

        final responseModel =
            HotelSearchModelResponse.fromJson(response.response!.data);

        final List<HotelServiceData> tempNewItems = responseModel.data ?? [];

        if (tempNewItems.length < limit) {
          hasMoreRentalServiceData = false;
        }

        if (isLoadMore) {
          hotelServices.addAll(tempNewItems);
        } else {
          hotelServices.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          rentalServicePage++;
        }
      } else {
        if (!isLoadMore) {
          rentalServiceResponse.value = ApiResponse.error('error');
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e) {
      rentalServiceResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      if (isLoadMore) {
        isRentalServiceLoadingMore.value = false;
      } else {
        isRentalServiceLoading.value = false;
      }
    }
  }
}

class ParcelCategoryModel {
  String? category;
  String? weightKg;
  String? description;

  ParcelCategoryModel({
    this.category,
    this.weightKg,
    this.description,
  });

  /// From JSON
  factory ParcelCategoryModel.fromJson(Map<String, dynamic> json) {
    return ParcelCategoryModel(
      category: json['category'] as String?,
      weightKg: (json['weightKg'] as num?)?.toString(),
      description: json['description'] as String?,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'weightKg': weightKg,
      'description': description,
    };
  }
}
