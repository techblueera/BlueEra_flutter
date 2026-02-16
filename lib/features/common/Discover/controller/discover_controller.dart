import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../model/get_booking_rider_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum CategoryFilter {
  nearest('Nearest'),
  experienced('Experienced'),
  priceLowToHigh('Price (Low-High)');

  final String label;

  const CategoryFilter(this.label);
}

enum DiscoverFilter {
  home('Home'),
  deals('Deals'),
  events('Events'),
  careerJobs('Career / Jobs');

  final String label;

  const DiscoverFilter(this.label);
}

class DiscoverController extends GetxController {
  var selfProfessionServiceResponse = ApiResponse.initial('Initial').obs;

  var profConProfessionServiceResponse = ApiResponse.initial('Initial').obs;
  var rentalServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> productsResponse = ApiResponse.initial('Initial').obs;
  Set<Marker> markers = {};
  final ScrollController scrollController = ScrollController();
  final GlobalKey headerKey = GlobalKey();
  Function(bool isVisible)? onHeaderVisibilityChanged;
  final RxBool isHeaderVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;
  double headerHeight = 0;
  Rx<LatLng>? currentAddress = LatLng(0.0, 0.0).obs;

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
  RxBool isEarnServiceLoading = false.obs;
  RxBool isProfConServiceLoading = false.obs;
  int earnServicePage = 1;
  int profConsServicePage = 1;
  var isEarnServiceLoadingMore = false.obs;
  var isProfConServiceLoadingMore = false.obs;
  Rx<VehicleAllResponse> ridersDetailsList = VehicleAllResponse().obs;
  var bookingRiderListResponse = ApiResponse.initial('Initial').obs;

  bool hasMoreEarnServiceData = true;
  bool hasMoreProfConServiceData = true;

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

  Rx<RiderUser> selectedRider = RiderUser().obs;
  Rxn<OnboardingCategoryModel> selectedStayCategory =
      Rxn<OnboardingCategoryModel>();

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
    selectedRider.value = rider;
  }

  /// Consultant Service
  Rx<OnboardingCategoryModel?> selectedProfessionalConsultantData =
      Rx<OnboardingCategoryModel?>(null);

  /// Products
  RxList<GetProductData> productDataList = <GetProductData>[].obs;
  RxBool isProductDataLoadingMore = false.obs;
  RxBool isProductDataFirstLoading = false.obs;
  int productDataPage = 1;
  bool productDataHasMore = true;

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
        ApiKeys.maxDistance: kmRadius1000,
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

  Future<String?> getCurrentPostCode() async {
    try {
      // 1️⃣ Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      // 2️⃣ Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3️⃣ Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.postalCode;
      }

      return null;
    } catch (e) {
      print("Post code error: $e");
      return null;
    }
  }

  Future<void> getBookingRidersApi() async {
    if (selectedFromLat?.value != 0.0 &&
        selectedFromLong?.value != 0.0 &&
        selectedToLat?.value != 0.0 &&
        selectedToLong?.value != 0.0) {
      findRiderDetailsLoading.value = true;
      if (selectedHorizontalTab.value == 0 ||
          selectedHorizontalTab.value == 1) {}
      Map<String, dynamic> queryParams = {
        ApiKeys.orderFor: "InCity",
        ApiKeys.pickupLatitude: 23.266686,
        ApiKeys.pickupLongitude: 77.459075,
        ApiKeys.dropLatitude: 23.266686,
        ApiKeys.dropLongitude: 77.459075,
        ApiKeys.range_in_km: 5,
        if (selectedHorizontalTab.value == 0 ||
            selectedHorizontalTab.value == 1)
          ApiKeys.pincode: "462023",
      };
      // Map<String, dynamic> queryParams = {
      //   ApiKeys.orderFor : getOrderTypeString(),
      //   ApiKeys.pickupLatitude : selectedFromLat?.value,
      //   ApiKeys.pickupLongitude : selectedFromLong?.value,
      //   ApiKeys.dropLatitude : selectedToLat?.value,
      //   ApiKeys.dropLongitude : selectedToLong?.value,
      //   ApiKeys.range_in_km: 5,
      //   if(selectedHorizontalTab.value==0||selectedHorizontalTab.value==1)
      //     ApiKeys.pincode: postCodeData??'',
      // };
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

  Future<void> makeTransportBookOrderApi() async {
    bookRiderBtnLoading.value = true;
    Map<String, dynamic> params = {
      ApiKeys.selectedRiders: [selectedRider.value.riderId],
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
      ApiKeys.fare: ridersDetailsList.value.twoWheelerRider?.fare
    };

    final response = await DiscoverRepo().makeTransportBookOrderApi(
      params: params,
    );

    if (response.isSuccess) {
      bookRiderBtnLoading.value = false;
      commonSnackBar(
          message: response.message ??
              "Your Booking Request Send To Rider,Wait Rider Accept Soon");
    } else {
      bookRiderBtnLoading.value = false;
      commonSnackBar(message: response.message ?? "Unable to Book a Rider");
    }
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
      commonSnackBar(message: AppStrings.somethingWentWrong);
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
        rentalServices.clear();
        isRentalServiceLoading.value = true;
        rentalServicePage = 1;
        hasMoreRentalServiceData = true;
      }

      String city = LocationService.userCurrentAddress.value.city;
      // String state = LocationService.userCurrentAddress.value.state;
      // String pinCode = LocationService.userCurrentAddress.value.postalCode;

      Map<String, dynamic> queryParams = {
        ApiKeys.city: city,
        ApiKeys.category: category,
        // ApiKeys.state: state,
        // ApiKeys.pincode: pinCode,
        // ApiKeys.lat: lat,
        // ApiKeys.lng: lng,
        ApiKeys.radius: kmRadius1500,
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
