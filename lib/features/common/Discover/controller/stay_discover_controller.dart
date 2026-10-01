import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:get/get.dart';

/// Discover's stays: rental and hotel listings (paginated for the list, and
/// unpaginated for the map), the picked stay category and the room-type
/// filter on a hotel. Registered by StayDiscoverBinding on the stays screen's
/// route, so each visit starts fresh.
class StayDiscoverController extends GetxController {
  final int limit = 20;

  /// Index of the picked stay category tab.
  final RxInt selectedTabIndex = 0.obs;

  var rentalServiceResponse = ApiResponse.initial('Initial').obs;

  /// Rental Services && Hotel Services
  RxList<RentalServiceData> rentalServices = <RentalServiceData>[].obs;
  RxList<HotelServiceData> hotelServices = <HotelServiceData>[].obs;

  /// Unpaginated stay lists for the map view. Same separation rationale as
  /// [earnServiceMapList] — list pagination state is left untouched.
  RxList<RentalServiceData> rentalServicesMapList = <RentalServiceData>[].obs;
  RxList<HotelServiceData> hotelServicesMapList = <HotelServiceData>[].obs;
  Rx<ApiResponse> staysMapResponse = ApiResponse.initial('Initial').obs;
  RxBool isRentalServiceLoading = false.obs;
  int rentalServicePage = 1;
  var isRentalServiceLoadingMore = false.obs;
  bool hasMoreRentalServiceData = true;

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

  final FetchCache _rentalCache = FetchCache();

  /// Freshness-guarded variant of [fetchRentalServices].
  Future<void> fetchRentalServicesIfNeeded(
      {required RentalServiceType rentalServiceType}) async {
    final sig = 'rental|${rentalServiceType.apiValue}';
    if (_rentalCache.isFresh(sig, hasData: rentalServices.isNotEmpty)) return;
    await fetchRentalServices(rentalServiceType: rentalServiceType);
  }

  /// Loads ALL rentals (unpaginated) for the map view.
  Future<void> fetchAllRentalsForMap({
    required RentalServiceType rentalServiceType,
  }) async {
    staysMapResponse.value = ApiResponse.initial('Initial');
    final queryParams = <String, dynamic>{
      ApiKeys.type: rentalServiceType.apiValue,
      ApiKeys.radius: kmRadius1500,
      ApiKeys.page: 1,
      ApiKeys.limit: 1000,
    };
    try {
      final response =
      await DiscoverRepo().getRentalService(queryParams: queryParams);
      if (!response.isSuccess) {
        staysMapResponse.value = ApiResponse.error(response.message ?? 'error');
        return;
      }
      final model = RentalServiceResponse.fromJson(response.response!.data);
      rentalServicesMapList.assignAll(model.data ?? []);
      hotelServicesMapList.clear();
      staysMapResponse.value = ApiResponse.complete(response);
    } catch (e) {
      staysMapResponse.value = ApiResponse.error(e.toString());
    }
  }

  /// Loads ALL hotels (unpaginated) for the map view.
  Future<void> fetchAllHotelsForMap({required String category}) async {
    staysMapResponse.value = ApiResponse.initial('Initial');
    final queryParams = <String, dynamic>{
      "categoryOfBusiness":category,
      // ApiKeys.category: category,
      ApiKeys.page: 1,
      ApiKeys.limit: 1000,
    };
    try {
      final response =
      await DiscoverRepo().fetchHotelSearchRepo(queryParams: queryParams);
      if (!response.isSuccess) {
        staysMapResponse.value = ApiResponse.error(response.message ?? 'error');
        return;
      }
      final model = HotelSearchModelResponse.fromJson(response.response!.data);
      hotelServicesMapList.assignAll(model.data ?? []);
      rentalServicesMapList.clear();
      staysMapResponse.value = ApiResponse.complete(response);
    } catch (e) {
      staysMapResponse.value = ApiResponse.error(e.toString());
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
          _rentalCache.mark('rental|${rentalServiceType.apiValue}');
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
        "categoryOfBusiness":category,

        // ApiKeys.category: category,
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
