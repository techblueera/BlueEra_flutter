import 'dart:async';
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
import 'package:BlueEra/core/services/ongoing_ride_store.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/features/common/Discover/model/business_filter_res_model.dart';
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
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../../core/api/model/new_food_home_res_model.dart';
import '../model/get_booking_rider_model.dart';
import '../model/multi_shop_rider_model.dart';
import '../../../business/auth/repo/business_profile_repo.dart';
import '../../../chat/auth/model/GetChatListModel.dart';
import '../../../chat/auth/model/saved_address_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../chat/auth/controller/call_controller.dart';
import '../../../chat/auth/repo/make_order_repo.dart';
import '../../../chat/auth/socket/chat_socket.dart';
import '../../../chat/auth/controller/live_trach_rider_controller.dart';
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

  /// Full unpaginated service list used by the map view. Populated by
  /// [fetchAllEarnServicesForMap]; kept separate from the paginated
  /// [earnServiceList] so list-screen pagination state isn't disturbed.
  RxList<ServiceData> earnServiceMapList = <ServiceData>[].obs;
  Rx<ApiResponse> earnServiceMapResponse = ApiResponse.initial('Initial').obs;
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

  /// Multi-shop (multi-stop) order state. Populated by
  /// [resolveAndFindMultiShopRiders]; the booking screen renders the route
  /// from [multiShopSortedShops] and books via [makeMultiShopOrderApi].
  RxList<SortedShop> multiShopSortedShops = <SortedShop>[].obs;
  Rxn<SortedShop> multiShopFurthestShop = Rxn<SortedShop>();
  RxDouble multiShopRouteDistanceKm = 0.0.obs;

  /// Resolved input shops (businessId + coords) used to build the order body,
  /// and the drop (user) location chosen for the multi-shop order.
  final List<SortedShop> _multiShopOrderShops = [];
  SavedAddress? _multiShopDropAddress;

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

  /// Unpaginated stay lists for the map view. Same separation rationale as
  /// [earnServiceMapList] — list pagination state is left untouched.
  RxList<RentalServiceData> rentalServicesMapList = <RentalServiceData>[].obs;
  RxList<HotelServiceData> hotelServicesMapList = <HotelServiceData>[].obs;
  Rx<ApiResponse> staysMapResponse = ApiResponse.initial('Initial').obs;
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
  Rxn<Map<String, dynamic>> fareCallAcceptedRiderInfo =
  Rxn<Map<String, dynamic>>();
  RxString fareCallAcceptedRiderId = ''.obs;
  RxString fareCallPickupOtp = ''.obs;

  /// Which orderId [fareCallPickupOtp]/[fareCallDeliveryOtp] belong to.
  /// OTPs from one order must NEVER display for another — a stale pickup OTP
  /// read out to the rider makes the ride-start call fail with
  /// INVALID_PICKUP_OTP. Every setter of the OTP Rx values records the owning
  /// orderId here; [hydrateFareCallDeliveryOtp] and the socket handlers use it
  /// to drop stale values instead of trusting whatever is in memory.
  String fareCallOtpOrderId = '';
  // Delivery (drop) OTP — held by the customer and read out to the rider at the
  // drop. Goods/multi-shop orders surface this on the customer tracking screen
  // instead of the pickup OTP (see RIDER_FRONTEND_INTEGRATION_GUIDE §8).
  RxString fareCallDeliveryOtp = ''.obs;
  // The order category of the active fare-call order (`InCity` / `OutStation` /
  // `HourlyRental` / `Parcel` / `product` / `grocery` …). Used to decide which
  // OTPs apply: a passenger ride has ONLY a pickup (ride-start) OTP and no
  // delivery OTP, whereas product/parcel/goods pickups also have a delivery OTP.
  RxString fareCallOrderFor = ''.obs;
  RxBool isFareCallRideStarted = false.obs;
  Rxn<Map<String, dynamic>> fareCallRideStartedData =
  Rxn<Map<String, dynamic>>();
  RxBool isFareCallRideCompleted = false.obs;
  Rxn<Map<String, dynamic>> fareCallRideCompletedData =
  Rxn<Map<String, dynamic>>();

  /// A passenger ride (`InCity` / `OutStation` / `HourlyRental`) has a single
  /// OTP — the pickup / ride-start OTP the customer reads to the rider. It has
  /// NO delivery OTP; that belongs only to product / parcel / goods pickups.
  bool get isFareCallPassengerRide => const {
        'InCity',
        'OutStation',
        'HourlyRental',
      }.contains(fareCallOrderFor.value);

  /// Fallback poll that flips [isFareCallRideStarted] when the backend order
  /// status reaches the ride-started stage. The customer normally learns the
  /// rider verified the pickup OTP via the `ride:started` socket event (or the
  /// `ride_started` FCM data-push), but both can be missed (socket reconnect /
  /// different room, silenced notifications). Without this, the customer never
  /// sees the delivery OTP, the Share-Ride button, or the destination route.
  Timer? _rideStartedPollTimer;

  /// The orderId the active [_rideStartedPollTimer] was started for. Lets a
  /// rebook replace the old order's poll instead of being blocked by it.
  String _rideStartedPollOrderId = '';

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

  /// Service-enquiry submission used by the Discover self-profession
  /// "Enquire" form. **Dummy for now** — it simulates a successful network
  /// round-trip so the form → chat flow works end-to-end. Swap the body for
  /// the real `DiscoverRepo` call once the backend endpoint exists (which,
  /// like the grocery order flow, should also create the in-chat enquiry card
  /// + emit a socket event so it surfaces on the provider's side).
  /// Backend `earn-service/service-enquiries` endpoints are live, so the real
  /// REST calls run. Set to `true` only to fall back to a simulated success
  /// (e.g. for local UI testing without the backend).
  static const bool _useServiceEnquiryStub = false;

  RxBool isServiceEnquiryLoading = false.obs;

  /// [selections] is keyed by the enquiry group api key
  /// (`serviceType` / `typesOfWork` / `servicesOffered`); each value is the
  /// list of options the customer ticked. Sent as-is in the request body.
  Future<bool> submitServiceEnquiry({
    required String providerId,
    required Map<String, List<String>> selections,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    try {
      isServiceEnquiryLoading.value = true;
      AppLoader.show();

      if (_useServiceEnquiryStub) {
        await Future.delayed(const Duration(milliseconds: 600));
        return true;
      }

      // Only non-empty arrays (filtered upstream) + a non-empty note are sent,
      // mirroring the server-side "at least one selection or a note" gating.
      final body = <String, dynamic>{
        ApiKeys.provider_id: providerId,
        ...selections,
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      final response = await DiscoverRepo()
          .sendServiceEnquiry(params: body, photoPaths: photoPaths);
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      AppLoader.hide();
      isServiceEnquiryLoading.value = false;
    }
  }

  /// Segment query key → enquiry-body apiKey + display title for the dynamic
  /// enquiry options. The segments are fetched from the predefined-category API
  /// per the provider's profession so the customer picks profession-relevant
  /// choices (electrician / plumber / …) instead of static data.
  static const List<Map<String, String>> _enquiryOptionSegments = [
    {'segment': 'serviceTypes', 'apiKey': 'serviceType', 'title': 'Service Type'},
    {'segment': 'typesOfWork', 'apiKey': 'typesOfWork', 'title': 'Type of Work'},
    {
      'segment': 'workCategories',
      'apiKey': 'workCategories',
      'title': 'Work Categories'
    },
    {
      'segment': 'servicesOffered',
      'apiKey': 'servicesOffered',
      'title': 'Services Offered'
    },
  ];

  /// Per-profession cache so the enquiry sheet never refetches the same
  /// profession — across providers, tab switches, and re-opens. Keyed by the
  /// category slug (e.g. ELECTRICIAN). [_enquiryOptionsInflight] dedupes
  /// concurrent callers (e.g. a prefetch racing with an open) onto one request.
  final Map<String, List<Map<String, dynamic>>> _enquiryOptionsCache = {};
  final Map<String, Future<List<Map<String, dynamic>>>>
      _enquiryOptionsInflight = {};

  /// Warm the cache for a profession [category] without awaiting — called when
  /// a profession tab loads so the Enquire sheet opens instantly later and the
  /// same profession is never fetched twice.
  void prefetchEnquiryOptions(String? category) {
    final key = (category ?? '').trim();
    if (key.isEmpty || _enquiryOptionsCache.containsKey(key)) return;
    fetchEnquiryOptions(key);
  }

  /// Returns the predefined option catalog for a provider's profession
  /// [category] as `{apiKey, title, options}` groups. Cached: a profession is
  /// fetched at most once per session. An empty [category] yields an empty list.
  Future<List<Map<String, dynamic>>> fetchEnquiryOptions(String category) async {
    final key = category.trim();
    if (key.isEmpty) return [];

    final cached = _enquiryOptionsCache[key];
    if (cached != null) return cached;
    final inflight = _enquiryOptionsInflight[key];
    if (inflight != null) return inflight;

    final future = _fetchEnquiryOptionsFromApi(key);
    _enquiryOptionsInflight[key] = future;
    try {
      final result = await future;
      _enquiryOptionsCache[key] = result;
      return result;
    } finally {
      _enquiryOptionsInflight.remove(key);
    }
  }

  /// ONE network call — no `segment` param, so the backend returns the whole
  /// predefined catalog for the profession; we split it client-side into the
  /// enquiry segments.
  Future<List<Map<String, dynamic>>> _fetchEnquiryOptionsFromApi(
      String category) async {
    Map<String, List<String>> bySegment = const {};
    try {
      final response = await DiscoverRepo().fetchPredefinedCategory(
        professionCategory: category,
        queryParams: const {},
      );
      if (response.isSuccess) {
        bySegment = _parseAllPredefinedSegments(response.response?.data);
      }
    } catch (_) {}

    final out = <Map<String, dynamic>>[];
    for (final seg in _enquiryOptionSegments) {
      final items = (bySegment[seg['segment']] ?? const <String>[])
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        out.add({
          'apiKey': seg['apiKey']!,
          'title': seg['title']!,
          'options': items,
        });
      }
    }
    return out;
  }

  /// Splits the all-segments predefined response into a `segment → options`
  /// map. The response is a flat document keyed by segment, e.g.:
  /// `{ "category":"LABOUR", "serviceTypes":[], "typesOfWork":[…],
  ///    "workCategories":[…], "servicesOffered":[…], "expertise":[…] }`.
  /// (A `data` envelope is unwrapped if present.)
  Map<String, List<String>> _parseAllPredefinedSegments(dynamic data) {
    final result = <String, List<String>>{};
    dynamic root = data;
    if (root is Map && root['data'] is Map) root = root['data'];
    if (root is! Map) return result;
    for (final seg in _enquiryOptionSegments) {
      final v = root[seg['segment']];
      if (v is List) {
        result[seg['segment']!] = v.map((e) => e.toString()).toList();
      }
    }
    return result;
  }

  // ── Professional-consultant enquiry options ─────────────────────────
  // Consultants use a different predefined endpoint
  // (`earn-service/predefined-professional/<slug>`) that returns a single
  // `servicesOffered` segment. Cached per profession slug, same as self-work.
  final Map<String, List<Map<String, dynamic>>> _consultantOptionsCache = {};
  final Map<String, Future<List<Map<String, dynamic>>>>
      _consultantOptionsInflight = {};

  void prefetchConsultantEnquiryOptions(String? professionSlug) {
    final key = (professionSlug ?? '').trim();
    if (key.isEmpty || _consultantOptionsCache.containsKey(key)) return;
    fetchConsultantEnquiryOptions(key);
  }

  /// Returns the consultant's predefined option groups (`Services Offered`)
  /// as `{apiKey, title, options}` maps. Cached per profession slug.
  Future<List<Map<String, dynamic>>> fetchConsultantEnquiryOptions(
      String professionSlug) async {
    final key = professionSlug.trim();
    if (key.isEmpty) return [];

    final cached = _consultantOptionsCache[key];
    if (cached != null) return cached;
    final inflight = _consultantOptionsInflight[key];
    if (inflight != null) return inflight;

    final future = _fetchConsultantOptionsFromApi(key);
    _consultantOptionsInflight[key] = future;
    try {
      final result = await future;
      _consultantOptionsCache[key] = result;
      return result;
    } finally {
      _consultantOptionsInflight.remove(key);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchConsultantOptionsFromApi(
      String professionSlug) async {
    var servicesOffered = const <String>[];
    try {
      final response =
          await DiscoverRepo().fetchPredefinedProfession(professionSlug: professionSlug);
      if (response.isSuccess) {
        dynamic root = response.response?.data;
        if (root is Map && root['data'] is Map) root = root['data'];
        if (root is Map && root['servicesOffered'] is List) {
          servicesOffered =
              (root['servicesOffered'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    final items = servicesOffered.where((e) => e.trim().isNotEmpty).toList();
    if (items.isEmpty) return [];
    return [
      {'apiKey': 'servicesOffered', 'title': 'Services Offered', 'options': items},
    ];
  }

  /// Provider accepts / declines a service enquiry from the in-chat card.
  /// [status] is 'accepted' or 'declined'. Returns true on success.
  Future<bool> updateServiceEnquiryStatus({
    required String enquiryId,
    required String status,
  }) async {
    if (_useServiceEnquiryStub) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    try {
      final response = await DiscoverRepo().updateServiceEnquiryStatus(
        enquiryId: enquiryId,
        params: {ApiKeys.status: status},
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  // ── Freshness guards (skip refetch on screen re-entry) ──────────────
  // Keyed by the request params so changing the category/type refetches,
  // while a back-and-return for the same selection reuses the loaded list.
  final FetchCache _earnServiceCache = FetchCache();
  final FetchCache _profConCache = FetchCache();
  final FetchCache _rentalCache = FetchCache();

  String get _earnServiceSignature =>
      'earn|${selectedEarnServiceData.value?.slugId ?? ''}';
  String get _profConSignature =>
      'profCon|${selectedProfessionalConsultantData.value?.slugId ?? ''}';

  /// Fetch self-work services only when the cached list is missing/stale for
  /// the current category. Use on screen entry; category taps call
  /// [fetchEarnServices] directly to force a refresh.
  Future<void> fetchEarnServicesIfNeeded(
      {required String earnServiceType, required String subType}) async {
    if (_earnServiceCache.isFresh(_earnServiceSignature,
        hasData: earnServiceList.isNotEmpty)) {
      return;
    }
    await fetchEarnServices(
        earnServiceType: earnServiceType, subType: subType);
  }

  /// Freshness-guarded variant of [fetchProfessionalConsultantServices].
  Future<void> fetchProfessionalConsultantServicesIfNeeded() async {
    if (_profConCache.isFresh(_profConSignature,
        hasData: professionalConsDataList.isNotEmpty)) {
      return;
    }
    await fetchProfessionalConsultantServices();
  }

  /// Freshness-guarded variant of [fetchRentalServices].
  Future<void> fetchRentalServicesIfNeeded(
      {required RentalServiceType rentalServiceType}) async {
    final sig = 'rental|${rentalServiceType.apiValue}';
    if (_rentalCache.isFresh(sig, hasData: rentalServices.isNotEmpty)) return;
    await fetchRentalServices(rentalServiceType: rentalServiceType);
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

    // Silently warm the enquiry-options cache for this profession so the
    // Enquire bottom sheet opens instantly and the same profession is never
    // fetched again (across providers / tab switches).
    if (!isLoadMore) {
      prefetchEnquiryOptions(selectedEarnServiceData.value?.slugId);
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
          _earnServiceCache.mark(_earnServiceSignature);
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

  /// Loads ALL earn services (unpaginated) for the map view. Uses the same
  /// `fetchSelfWorkServices` endpoint as the list, but with a high limit
  /// and no pagination so every provider with valid lat/lng can be
  /// rendered as a map marker. Distance is intentionally not recomputed
  /// here — it's only useful in the list view and would slow this call
  /// down significantly when there are hundreds of providers.
  Future<void> fetchAllEarnServicesForMap({
    required String earnServiceType,
    required String subType,
  }) async {
    earnServiceMapResponse.value = ApiResponse.initial('Initial');

    final queryParams = <String, dynamic>{
      ApiKeys.type: earnServiceType,
      ApiKeys.subType: subType,
      ApiKeys.page: 1,
      ApiKeys.limit: 1000,
    };
    if (selectedEarnServiceData.value != null) {
      queryParams[ApiKeys.category] = selectedEarnServiceData.value?.slugId;
    }

    try {
      final response =
      await DiscoverRepo().fetchSelfWorkServices(queryParams: queryParams);
      if (!response.isSuccess) {
        earnServiceMapResponse.value =
            ApiResponse.error(response.message ?? 'error');
        return;
      }
      final responseModel =
      ServiceModelResponse.fromJson(response.response?.data);
      final all = <ServiceData>[];
      for (final service in responseModel.services ?? []) {
        if (service.data != null) {
          all.addAll(service.data!);
        }
      }
      earnServiceMapList.assignAll(all);
      earnServiceMapResponse.value = ApiResponse.complete(response);
    } catch (e) {
      earnServiceMapResponse.value = ApiResponse.error(e.toString());
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

  /// Fetches education-category businesses (colleges, schools, etc.) using the
  /// shared `business/filter` endpoint. The category slug
  /// (e.g. `COLLEGE_UNIVERSITY`) comes from [selectedEducationServiceData].
  ///
  /// The endpoint returns business records (see [BusinessFilterResModel]).
  /// Each is adapted into a [SchoolDetailsData] via [_businessToSchoolDetail]
  /// so the existing UI (`AllEducationServiceScreen`, `DiscoverSchoolHomeScreen`,
  /// `SchoolAboutUsController`) keeps working without a parallel rewrite —
  /// they all consume `schoolDetailsDataDataList`.
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
        ApiKeys.category: selectedEducationServiceData.value?.slugId,
      if (selectedEducationServiceData.value?.slugId == null)
        "typeOfBusiness": "Siksha",
      ApiKeys.page: educationServicePage,
      ApiKeys.limit: limit,
    };

    try {
      final ResponseModel response = await DiscoverRepo()
          .fetchBusinessFilterRepo(queryParams: queryParams);

      if (response.isSuccess) {
        final responseModel =
        BusinessFilterResModel.fromJson(response.response?.data);

        final List<BusinessFilterData> rawItems = responseModel.data ?? [];
        final List<SchoolDetailsData> tempNewItems =
        rawItems.map((b) => b.toSchoolDetail()).toList();

        // Pagination: prefer the server's totalPages signal when available,
        // and fall back to the page-size heuristic used elsewhere in this
        // controller for consistency.
        final pagination = responseModel.pagination;
        if (pagination?.totalPages != null && pagination?.page != null) {
          if (pagination!.page! >= pagination.totalPages!) {
            hasMoreEducationServiceData = false;
          }
        } else if (tempNewItems.length < limit) {
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
      }
    } catch (e, s) {
      print('stack trace --> $s');
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

    // Silently warm the consultant enquiry-options cache for this profession so
    // the Enquire sheet opens instantly and the same profession isn't refetched.
    if (!isLoadMore) {
      prefetchConsultantEnquiryOptions(
          selectedProfessionalConsultantData.value?.slugId);
    }

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
          _profConCache.mark(_profConSignature);
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

  /// Fetch ONE self-employed earn-service by its owner [userId] for the visit
  /// flow (where we only have an author id, not a list item). Parses
  /// defensively because the by-user endpoint's envelope isn't pinned down:
  /// it may return the list `{services:[{data:[...]}]}` shape, a `{data:{…}}`
  /// wrapper, or the bare service object.
  Future<ServiceData?> getEarnServiceByUserId(String userId) async {
    try {
      final res = await DiscoverRepo().fetchEarnServiceByUserId(userId);
      if (!res.isSuccess) return null;
      final data = res.response?.data;
      if (data is! Map<String, dynamic>) return null;

      // The by-user endpoint (`earn-service/services/user/{id}`) returns RAW
      // service documents, not the grouped Discover-list envelope:
      //   { "services": [ { _id, providerDetails:{…owner…}, expertise:[],
      //                      serviceType:[], timings:[], availability, … } ] }
      // The owner sits under `providerDetails` and the service arrays sit at
      // the top level of each document — a different shape from the list
      // response ({ services:[{profession, data:[ServiceData]}], professions }).
      // Feeding it to ServiceModelResponse threw (its `data[]` is absent and
      // `professions` is missing), so the old code fell through to null and the
      // screen showed "No data found". Remap the first document into the flat
      // ServiceData the screen renders instead.
      final services = data['services'];
      if (services is List) {
        for (final doc in services) {
          if (doc is Map<String, dynamic>) {
            return _serviceDataFromEarnDoc(doc);
          }
        }
        return null;
      }

      final inner = data['data'];
      if (inner is Map<String, dynamic>) return ServiceData.fromJson(inner);
      if (inner is List && inner.isNotEmpty) {
        return ServiceData.fromJson(inner.first);
      }
      return ServiceData.fromJson(data);
    } catch (e, s) {
      log('getEarnServiceByUserId error: $e\n$s');
      return null;
    }
  }

  /// Maps ONE raw earn-service document (from `earn-service/services/user/{id}`)
  /// into the flat [ServiceData] the discover self-employee screen expects.
  /// The owner is nested under `providerDetails` (whose keys already match the
  /// user-level fields ServiceData reads), the service detail arrays live at
  /// the document's top level (so they map straight into the nested `service`
  /// [ServiceInfo]), photos sit on the document, and price is the migrated
  /// top-level `priceRange{min,max}` + `feeType` folded back into `priceData`.
  ServiceData _serviceDataFromEarnDoc(Map<String, dynamic> doc) {
    final provider = (doc['providerDetails'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final merged = <String, dynamic>{
      // Owner / user-level fields — providerDetails uses the same JSON keys
      // ServiceData.fromJson reads (id, name, contact_no, profile_image,
      // skills, projects, experiences, …), so a spread hydrates them directly.
      ...provider,
      'category': doc['category'],
      // Gallery photos live on the service document, not the provider.
      'serviceMedia': {'photos': doc['photos'] ?? const <String>[]},
      // ServiceInfo reads timings / expertise / serviceType / serviceOffered /
      // typesOfWork / workCategories / whyChooseMe / facilities / availability
      // straight off the service document.
      'service': doc,
      // Price migrated to a top-level priceRange{min,max} + feeType; fold it
      // back into the priceData shape PriceData.fromJson understands.
      if (doc['priceRange'] != null || doc['feeType'] != null)
        'priceData': {
          'feeType': doc['feeType'],
          'priceRange': doc['priceRange'],
        },
    };
    return ServiceData.fromJson(merged);
  }

  /// Fetch ONE professional/consultant by [userId] (search filtered to one,
  /// first result) for the visit flow.
  Future<ProfessionalConsData?> getProfessionalByUserId(String userId) async {
    try {
      final res = await DiscoverRepo().fetchProfessionalByUserId(userId);
      if (!res.isSuccess) return null;
      final parsed = ProfessionalConsResModel.fromJson(res.response?.data);
      final list = parsed.data ?? [];
      return list.isNotEmpty ? list.first : null;
    } catch (e, s) {
      log('getProfessionalByUserId error: $e\n$s');
      return null;
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
        if (roadDistanceKm.value > 0) 'distance_in_km': roadDistanceKm.value,
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

  /// Resolve each selected inquiry shop's pickup coordinates, then call
  /// `/fare/multi-shop/riders` to sort the shops (furthest→nearest) and find
  /// riders near the furthest shop. Seeds the shared rider state
  /// ([ridersDetailsList] / [selectedRiders]) and the pickup/drop coords so the
  /// existing booking + fare-call-queue screens work unchanged.
  ///
  /// Returns true when riders were fetched. Surfaces a snackbar and returns
  /// false on any failure (no drop coords, no resolvable shops, API error).
  Future<bool> resolveAndFindMultiShopRiders({
    required List<ChatList> pickups,
    required SavedAddress drop,
  }) async {
    final dropLat = drop.lat ?? 0.0;
    final dropLng = drop.lng ?? 0.0;
    if (dropLat == 0.0 && dropLng == 0.0) {
      commonSnackBar(
          message:
              'Selected drop address has no location. Please re-select it from the suggestions.');
      return false;
    }

    findRiderDetailsLoading.value = true;
    bookingRiderListResponse.value = ApiResponse.initial('Initial');
    // A fresh search clears any previous rider selection.
    selectedRiders.clear();
    selectedRider.value = RiderUser();
    selectedVehicleOptionIndex.value = 0;

    try {
      // Resolve every shop's pickup coordinates. EVERY selected shop must
      // resolve — if even one has no pickup location, abort the whole order with
      // an error instead of silently dropping it, so the rider never gets a
      // partial order and the user is never confused about which shops are in.
      final resolvedShops = <SortedShop>[];
      final unresolvedShops = <String>[];
      for (final chat in pickups) {
        final shopLabel = chat.sender?.name ?? 'Shop';
        // The shop's pickup location is looked up by the business *owner's*
        // user id (`/user-service/business/user/{ownerUserId}`), not the
        // conversation id or the business id.
        final ownerUserId = (chat.businessOwnerUserId?.isNotEmpty ?? false)
            ? chat.businessOwnerUserId!
            : (chat.sender?.id ?? '');
        if (ownerUserId.isEmpty) {
          unresolvedShops.add(shopLabel);
          continue;
        }
        final loc = await _resolveShopLocation(ownerUserId);
        if (loc == null) {
          unresolvedShops.add(shopLabel);
          continue;
        }
        // The order body still identifies each shop by its businessId where
        // available, falling back to the owner user id.
        final shopBusinessId = (chat.sender?.businessId?.isNotEmpty ?? false)
            ? chat.sender!.businessId!
            : ownerUserId;
        resolvedShops.add(SortedShop(
          businessId: shopBusinessId,
          name: shopLabel,
          address: loc.$3,
          latitude: loc.$1,
          longitude: loc.$2,
        ));
      }

      // Any shop without a pickup location => hard stop. Do not proceed with a
      // partial set of shops.
      if (unresolvedShops.isNotEmpty) {
        findRiderDetailsLoading.value = false;
        bookingRiderListResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message:
              'No pickup location for: ${unresolvedShops.join(', ')}. '
              'Remove these shop(s) or set their location, then try again.',
        );
        return false;
      }

      if (resolvedShops.isEmpty) {
        findRiderDetailsLoading.value = false;
        bookingRiderListResponse.value = ApiResponse.error('error');
        commonSnackBar(message: 'Could not get the shop pickup locations.');
        return false;
      }

      final params = {
        'userLocation': {
          ApiKeys.address: drop.fullAddress,
          ApiKeys.latitude: dropLat,
          ApiKeys.longitude: dropLng,
        },
        'shops': resolvedShops.map((s) => s.toRequestJson()).toList(),
        ApiKeys.orderFor: 'grocery',
        ApiKeys.range_in_km: 20,
      };

      final response =
          await DiscoverRepo().getMultiShopRidersApi(params: params);
      if (!response.isSuccess) {
        findRiderDetailsLoading.value = false;
        bookingRiderListResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }

      final data = MultiShopRidersResponse.fromJson(
        response.response?.data is Map
            ? Map<String, dynamic>.from(response.response?.data)
            : <String, dynamic>{},
      );

      multiShopSortedShops.assignAll(data.sortedShops);
      multiShopFurthestShop.value = data.furthestShop ??
          (data.sortedShops.isNotEmpty ? data.sortedShops.first : null);
      multiShopRouteDistanceKm.value = data.routeDistanceKm ?? 0.0;
      // Remember the shops (in sorted order, falling back to resolved order)
      // and drop for the subsequent order-creation call.
      _multiShopOrderShops
        ..clear()
        ..addAll(
            data.sortedShops.isNotEmpty ? data.sortedShops : resolvedShops);
      _multiShopDropAddress = drop;

      // Drive the shared rider widgets + fare-call queue screen.
      ridersDetailsList.value = data.riders;
      bookingRiderListResponse.value = ApiResponse.complete(data.riders);

      // The fare-call queue tracks pickup = route start (furthest shop) and
      // drop = user. Seed the shared coords so live tracking renders correctly.
      final start = multiShopFurthestShop.value;
      if (start != null) {
        selectedFromLat?.value = start.latitude;
        selectedFromLong?.value = start.longitude;
        selectedFromAddress?.value =
            start.address.isNotEmpty ? start.address : start.name;
      }
      selectedToLat?.value = dropLat;
      selectedToLong?.value = dropLng;
      selectedToAddress?.value = drop.fullAddress;

      findRiderDetailsLoading.value = false;
      return true;
    } catch (e) {
      findRiderDetailsLoading.value = false;
      bookingRiderListResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Fetch a shop's pickup `(lat, lng, address)` from its [businessId] via the
  /// business-location endpoint. Returns null when unavailable.
  Future<(double, double, String)?> _resolveShopLocation(
      String businessId) async {
    try {
      final response = await BusinessProfileRepo()
          .viewBusinessIdForLocation(businessId, 'BUSINESS');
      final data = response.response?.data;
      if (data is! Map || data['success'] != true) return null;
      final body = data['data'];
      if (body is! Map) return null;
      final loc = body['business_location'];
      final lat = double.tryParse(loc?['lat']?.toString() ?? '') ?? 0.0;
      final lng = double.tryParse(loc?['lon']?.toString() ?? '') ?? 0.0;
      if (lat == 0.0 && lng == 0.0) return null;
      return (lat, lng, body['address']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  /// In-City fare for the vehicle tab [index], mirroring the tab-0 mapping of
  /// `getSelectedVehicleData` (0 Bike, 1 min(carMini,carSedan), 2 Auto,
  /// 3 eRickshaw).
  double? selectedInCityFare(int index) {
    final r = ridersDetailsList.value;
    switch (index) {
      case 0:
        return r.twoWheelerRider?.fare;
      case 1:
        final a = r.carMini?.fare;
        final b = r.carSedan?.fare;
        if (a != null && b != null) return a < b ? a : b;
        return a ?? b;
      case 2:
        return r.autoTempo?.fare;
      case 3:
        return r.eRickshaw?.fare;
    }
    return null;
  }

  /// Book the multi-shop order via `/fare/multi-shop/orders` using the
  /// currently [selectedRiders] and the selected vehicle fare. Uses the
  /// `fare-call` order type so the existing fare-call queue/accept/track flow
  /// applies. Returns true on success (and seeds [fareCallOrderId] for the
  /// queue screen).
  Future<bool> makeMultiShopOrderApi() async {
    if (selectedRiders.isEmpty) {
      commonSnackBar(message: 'Please select at least one rider');
      return false;
    }
    final drop = _multiShopDropAddress;
    if (drop == null || _multiShopOrderShops.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }

    bookRiderBtnLoading.value = true;

    final params = {
      ApiKeys.selectedRiders: selectedRiders.map((r) => r.riderId).toList(),
      'userLocation': {
        ApiKeys.address: drop.fullAddress,
        ApiKeys.latitude: drop.lat ?? 0.0,
        ApiKeys.longitude: drop.lng ?? 0.0,
      },
      'shops': _multiShopOrderShops.map((s) => s.toRequestJson()).toList(),
      ApiKeys.orderFor: 'grocery',
      ApiKeys.modeOfPayment: 'prepaid',
      ApiKeys.fare: selectedInCityFare(selectedVehicleOptionIndex.value),
      ApiKeys.orderType: 'fare-call',
      ApiKeys.orderForWhom: 'myself',
    };

    final response = await DiscoverRepo().makeMultiShopOrderApi(params: params);
    if (response.isSuccess) {
      bookRiderBtnLoading.value = false;
      final data = response.response?.data;
      if (data is Map) {
        fareCallOrderId.value =
            (data['orderId'] ?? data['_id'] ?? '').toString();
        fareCallPickupOtp.value = (data['pickupOTP'] ?? '').toString();
        fareCallDeliveryOtp.value = (data['deliveryOTP'] ?? '').toString();
        fareCallOtpOrderId = fareCallOrderId.value;
      }
      isFareCallInProgress.value = true;
      fareCallTotalRiders.value = selectedRiders.length;
      fareCallCurrentRiderIndex.value = 0;
      return true;
    } else {
      bookRiderBtnLoading.value = false;
      commonSnackBar(message: response.message ?? 'Unable to Book a Rider');
      return false;
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

  // ─── Chat-dispatch (self-pickup → rider) ──────────────────────────
  // Set right before opening the rider-selection screen from a self-pickup
  // chat card. When present, the booking screen creates the ride via the
  // chat-dispatch endpoint (shop = pickup, customer = drop) instead of the
  // regular fare order. Cleared after a successful dispatch or when the
  // booking screen is dismissed. See CHAT_DISPATCH_RIDER_FRONTEND_GUIDE.md.
  Map<String, dynamic>? chatDispatchContext;

  void setChatDispatchContext({
    required String selfpickupOrderId,
    required String selfpickupType,
    required String businessId,
    required String orderFor,
  }) {
    chatDispatchContext = {
      'selfpickupOrderId': selfpickupOrderId,
      'selfpickupType': selfpickupType,
      'businessId': businessId,
      'orderFor': orderFor,
    };
  }

  void clearChatDispatchContext() => chatDispatchContext = null;

  /// Create a chat self-pickup → rider dispatch order. Reuses the shop/customer
  /// coordinates already seeded on this controller by the chat card (pickup =
  /// shop, drop = customer) plus the [chatDispatchContext]. Returns true on a
  /// 201; the OTP cards then arrive over the chat socket.
  Future<bool> makeChatDispatchOrderApi() async {
    final ctx = chatDispatchContext;
    if (ctx == null) return false;
    if (selectedRiders.isEmpty) {
      commonSnackBar(message: AppStrings.noRidersAvailable.tr);
      return false;
    }
    bookRiderBtnLoading.value = true;
    try {
      final params = <String, dynamic>{
        'selfpickupOrderId': ctx['selfpickupOrderId'],
        'selfpickupType': ctx['selfpickupType'],
        ApiKeys.businessId: ctx['businessId'],
        'shopLocation': {
          ApiKeys.address: "${selectedFromAddress?.value}",
          ApiKeys.latitude: selectedFromLat?.value,
          ApiKeys.longitude: selectedFromLong?.value,
        },
        ApiKeys.dropLocation: {
          ApiKeys.address: "${selectedToAddress?.value}",
          ApiKeys.latitude: selectedToLat?.value,
          ApiKeys.longitude: selectedToLong?.value,
        },
        ApiKeys.orderFor: ctx['orderFor'],
        ApiKeys.selectedRiders: selectedRiders.map((r) => r.riderId).toList(),
        ApiKeys.modeOfPayment: "prepaid",
        ApiKeys.fare: ridersDetailsList.value.twoWheelerRider?.fare,
      };
      final response =
          await DiscoverRepo().makeChatDispatchOrderApi(params: params);
      if (response.isSuccess) {
        return true;
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      bookRiderBtnLoading.value = false;
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
        // Remember the order category so the tracking screen knows whether a
        // delivery OTP applies (passenger rides have none — pickup OTP only).
        fareCallOrderFor.value =
            (data['orderFor'] ?? getTabName(selectedHorizontalTab.value))
                .toString();
        // Save pickup OTP from order creation response so the customer
        // can see it even if ride:queue:accepted socket event is missed.
        fareCallPickupOtp.value = (data['pickupOTP'] ?? '').toString();
        fareCallDeliveryOtp.value = (data['deliveryOTP'] ?? '').toString();
        fareCallOtpOrderId = fareCallOrderId.value;
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

  /// True when a fare-call socket event carries an orderId that does NOT
  /// match the active fare-call order — i.e. a delayed event from a previous
  /// (cancelled / completed) order arriving after a rebook. Events without an
  /// orderId, or with no active order to compare against, are let through so
  /// older backends keep working.
  bool _isStaleFareCallEvent(dynamic data) {
    if (data is! Map) return false;
    final evOrderId = (data['orderId'] ?? '').toString();
    final currentOrderId = fareCallOrderId.value;
    if (evOrderId.isEmpty || currentOrderId.isEmpty) return false;
    final stale = evOrderId != currentOrderId;
    if (stale) {
      print('[FARE_CALL_QUEUE] ⚠️ dropping stale event for order $evOrderId '
          '(active order is $currentOrderId)');
    }
    return stale;
  }

  /// Setup socket listeners for fare-call queue progress
  void setupFareCallQueueListeners() {
    final socket = ChatSocketService();

    socket.listenEvent('ride:queue:calling', (data) {
      print('[FARE_CALL_QUEUE] ride:queue:calling → $data');
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

      print(
          '[FARE_CALL_DEBUG] ride:queue:calling → callId=$callId, roomId=$roomId, riderId=$riderId, iceServers count=${iceServers.length}');
      print('[FARE_CALL_DEBUG] ride:queue:calling → iceServers=$iceServers');

      if (callId.isNotEmpty && roomId.isNotEmpty && riderId.isNotEmpty) {
        if (!Get.isRegistered<CallController>()) {
          print(
              '[FARE_CALL_DEBUG] ride:queue:calling → CallController not registered, creating new');
          Get.put(CallController(), permanent: true);
        }
        final callController = Get.find<CallController>();
        print(
            '[FARE_CALL_DEBUG] ride:queue:calling → CallController current status=${callController.callStatus.value}');
        callController.joinFareCallAsCustomer(
          fareCallId: callId,
          fareRoomId: roomId,
          riderId: riderId,
          fareConversationId: conversationId,
          iceServers: iceServers,
        );
      } else {
        print(
            '[FARE_CALL_DEBUG] ride:queue:calling → ⚠️ MISSING DATA: callId=$callId, roomId=$roomId, riderId=$riderId — cannot join call!');
      }
    });

    socket.listenEvent('ride:queue:accepted', (data) {
      print('[FARE_CALL_QUEUE] ride:queue:accepted → $data');
      // Stale-order guard: a delayed accepted event from a PREVIOUS order
      // (cancelled mid-queue, then rebooked) must not touch the current
      // ride's state — most critically the OTPs. Overwriting the new order's
      // pickup OTP with the old order's made the customer read out a code the
      // backend rejects (INVALID_PICKUP_OTP on the rider's ride-start call).
      if (_isStaleFareCallEvent(data)) return;
      // IMPORTANT: Set riderInfo BEFORE setting isFareCallInProgress=false.
      // The exhausted worker triggers on isFareCallInProgress change and checks
      // fareCallAcceptedRiderInfo — if riderInfo is still null, it pops the screen.
      fareCallAcceptedRiderInfo.value = data['riderInfo'] != null
          ? Map<String, dynamic>.from(data['riderInfo'])
          : null;
      fareCallAcceptedRiderId.value =
          data['riderId'] ?? data['riderInfo']?['riderId'] ?? '';
      // Never wipe an OTP already captured from the order-creation response —
      // older backends omit deliveryOTP on this event, and overwriting with ''
      // blanked the delivery OTP card for the rest of the ride.
      final evPickupOtp = (data['pickupOTP'] ?? '').toString();
      if (evPickupOtp.isNotEmpty) fareCallPickupOtp.value = evPickupOtp;
      final evDeliveryOtp = (data['deliveryOTP'] ?? '').toString();
      if (evDeliveryOtp.isNotEmpty) fareCallDeliveryOtp.value = evDeliveryOtp;
      if (evPickupOtp.isNotEmpty || evDeliveryOtp.isNotEmpty) {
        fareCallOtpOrderId = fareCallOrderId.value;
      }
      // Re-confirm the OTPs against the server the moment a rider is
      // assigned — this is right before the customer reads the ride-start
      // OTP aloud, so whatever is on screen MUST match the DB value the
      // rider's start call verifies against.
      final evOrderId =
          (data['orderId'] ?? fareCallOrderId.value).toString();
      if (evOrderId.isNotEmpty) {
        unawaited(hydrateFareCallDeliveryOtp(evOrderId));
      }
      isFareCallInProgress.value = false;
    });

    socket.listenEvent('ride:queue:exhausted', (data) {
      print('[FARE_CALL_QUEUE] ride:queue:exhausted → $data');
      isFareCallInProgress.value = false;
      fareCallAcceptedRiderInfo.value = null;
      commonSnackBar(message: 'No riders available. Please try again.');
    });

    socket.listenEvent('ride:started', (data) {
      print('[FARE_CALL_QUEUE] ride:started → $data');
      // Stale-order guard: a delayed started event for a previous order must
      // not flip the CURRENT ride to "started" (which hides the pickup OTP
      // card before the rider ever verified it).
      if (_isStaleFareCallEvent(data)) return;
      isFareCallRideStarted.value = true;
      fareCallRideStartedData.value =
      data != null ? Map<String, dynamic>.from(data) : null;
    });

    socket.listenEvent('ride:completed', (data) {
      print('[FARE_CALL_QUEUE] ✅ ride:completed RECEIVED from backend → $data');
      // Stale-order guard — see ride:started above.
      if (_isStaleFareCallEvent(data)) return;
      isFareCallRideCompleted.value = true;
      fareCallRideCompletedData.value =
      data != null ? Map<String, dynamic>.from(data) : null;

      // Clear the floating overlay and its ride data
      if (Get.isRegistered<RideNavigationOverlayController>()) {
        final overlayCtrl = Get.find<RideNavigationOverlayController>();
        overlayCtrl.clearRideData();
      }
      // Drop the persisted ongoing-ride snapshot so the card doesn't reappear
      // on the next app launch after the ride finished.
      OngoingRideStore.clear();
    });
  }

  /// Start a low-frequency fallback poll that tracks the order status through
  /// the whole ride lifecycle, in case the `ride:started` / `ride:completed`
  /// socket events (or FCM pushes) are missed. It flips [isFareCallRideStarted]
  /// at the in-progress / picked-up stage and [isFareCallRideCompleted] at
  /// completion (which removes the OTP cards and shows the ride-completed
  /// panel), then stops. Safe to call repeatedly — no-op if already polling or
  /// the ride is already completed. Cancelled on [resetFareCallState] / screen
  /// dispose / logout.
  void startRideStartedFallbackPoll(String orderId) {
    if (orderId.isEmpty) return;
    if (isFareCallRideCompleted.value) return; // nothing left to detect
    // Same order already being polled → no-op. A DIFFERENT order means the
    // customer rebooked: the old poll must die, or it keeps applying the OLD
    // order's status and delivery OTP to the new ride's state (the customer
    // then reads out a stale delivery OTP the backend rejects).
    if (_rideStartedPollTimer?.isActive ?? false) {
      if (_rideStartedPollOrderId == orderId) return;
      stopRideStartedFallbackPoll();
    }
    _rideStartedPollOrderId = orderId;

    // Order status state machine (RIDER_FRONTEND_INTEGRATION_GUIDE §"status"):
    // pending → payment-pending → confirmed → in-progress → picked-up → completed
    // The ride has "started" at in-progress and stays started through picked-up.
    const startedStatuses = {'in-progress', 'picked-up'};
    const abortedStatuses = {'cancelled', 'rejected'};

    _rideStartedPollTimer =
        Timer.periodic(const Duration(seconds: 7), (timer) async {
      // Completion (from any source) is the terminal signal — stop polling.
      if (isFareCallRideCompleted.value) {
        stopRideStartedFallbackPoll();
        return;
      }
      // The active order changed since this poll started (rebook) — this
      // poll's results belong to the old order and must not touch state.
      if (fareCallOrderId.value.isNotEmpty &&
          fareCallOrderId.value != orderId) {
        stopRideStartedFallbackPoll();
        return;
      }
      try {
        final res =
            await ChatViewRepo().checkTrackOrderStatusSilentApi(orderId);
        if (!res.isSuccess) return;
        final data = res.response?.data;
        if (data is! Map) return;

        final status =
            (data['status'] ?? '').toString().toLowerCase().replaceAll('_', '-');

        // Capture the order category if not already known (killed-state restore
        // enters tracking without going through order creation). orderFor sits
        // inside `metadata` on this endpoint — the old top-level read was
        // always empty, so passenger-ride detection never worked via the poll.
        final polledMeta = data['metadata'];
        final polledOrderFor =
            ((polledMeta is Map ? polledMeta['orderFor'] : null) ??
                    data['orderFor'] ??
                    '')
                .toString();
        if (polledOrderFor.isNotEmpty && fareCallOrderFor.value.isEmpty) {
          fareCallOrderFor.value = polledOrderFor;
        }

        if (status == 'completed') {
          _applyRideCompletedFromPoll(Map<String, dynamic>.from(data));
          stopRideStartedFallbackPoll();
        } else if (startedStatuses.contains(status)) {
          if (!isFareCallRideStarted.value) {
            isFareCallRideStarted.value = true;
            fareCallRideStartedData.value = Map<String, dynamic>.from(data);
            // Rehydrate the customer's delivery OTP if the status payload
            // carries it, so the OTP card shows without a separate fetch.
            final deliveryOtp = (data['deliveryOTP'] ?? '').toString();
            if (deliveryOtp.isNotEmpty) {
              fareCallDeliveryOtp.value = deliveryOtp;
              fareCallOtpOrderId = orderId;
            }
            print('[FARE_CALL_QUEUE] ride-started detected via status poll '
                '(status=$status) → isFareCallRideStarted=true');
          }
          // Keep polling — we still need to catch completion.
        } else if (abortedStatuses.contains(status)) {
          stopRideStartedFallbackPoll();
        }
      } catch (_) {
        // Best-effort fallback; the socket/FCM paths remain the primary signal.
      }
    });
  }

  /// Mirror the `ride:completed` socket handler when completion is detected via
  /// the status poll instead: flip the flag, stash the payload, and clear the
  /// floating overlay + persisted ongoing-ride snapshot.
  void _applyRideCompletedFromPoll(Map<String, dynamic> data) {
    if (isFareCallRideCompleted.value) return;
    isFareCallRideCompleted.value = true;
    fareCallRideCompletedData.value = data;
    if (Get.isRegistered<RideNavigationOverlayController>()) {
      Get.find<RideNavigationOverlayController>().clearRideData();
    }
    OngoingRideStore.clear();
    print('[FARE_CALL_QUEUE] ride-completed detected via status poll → '
        'isFareCallRideCompleted=true');
  }

  void stopRideStartedFallbackPoll() {
    _rideStartedPollTimer?.cancel();
    _rideStartedPollTimer = null;
    _rideStartedPollOrderId = '';
  }

  /// Cancel fare-call queue
  Future<void> cancelFareCallQueue() async {
    if (fareCallOrderId.value.isEmpty) return;
    final response =
    await MakeOrderRepo().cancelFareCallQueueApi(fareCallOrderId.value);
    if (response.isSuccess) {
      isFareCallInProgress.value = false;
      commonSnackBar(message: 'Ride request cancelled');
    } else {
      commonSnackBar(message: response.message ?? 'Failed to cancel');
    }
  }

  /// Re-fetch the customer's OTPs from the order status endpoint — the SAME
  /// source of truth the rider's start/complete calls verify against. Always
  /// fetches and overwrites the in-memory values with the server's; memory is
  /// only ever an instant-display cache, never authoritative. This closes
  /// every "customer read out an OTP the backend rejects" staleness class in
  /// one move (stale Rx from a previous ride, missed socket events, replayed
  /// state after restore — all of it).
  Future<void> hydrateFareCallDeliveryOtp(String orderId) async {
    if (orderId.isEmpty) return;

    if (fareCallOtpOrderId != orderId) {
      // Never display another order's OTPs while the fetch is in flight.
      fareCallPickupOtp.value = '';
      fareCallDeliveryOtp.value = '';
      fareCallOrderFor.value = '';
    }
    try {
      final res = await ChatViewRepo().checkTrackOrderStatusSilentApi(orderId);
      if (res.isSuccess) {
        final data = res.response?.data;
        // Server values OVERWRITE memory (not fill-if-empty): the endpoint
        // returns the exact OTPs the rider will be verified against.
        final otp =
            (data is Map ? data['deliveryOTP'] : null)?.toString() ?? '';
        if (otp.isNotEmpty) fareCallDeliveryOtp.value = otp;
        final pickupOtp =
            (data is Map ? data['pickupOTP'] : null)?.toString() ?? '';
        if (pickupOtp.isNotEmpty) fareCallPickupOtp.value = pickupOtp;
        if (otp.isNotEmpty || pickupOtp.isNotEmpty) {
          fareCallOtpOrderId = orderId;
        }
        print('[FARE_CALL_OTP] hydrated from server for $orderId → '
            'pickup=${pickupOtp.isNotEmpty ? pickupOtp : '(not returned)'}, '
            'delivery=${otp.isNotEmpty ? otp : '(not returned)'}');
        // orderFor lives inside `metadata` on this endpoint (top-level read
        // always came back empty — passenger-ride detection never hydrated).
        final metadata = (data is Map ? data['metadata'] : null);
        final orderFor = ((metadata is Map ? metadata['orderFor'] : null) ??
                (data is Map ? data['orderFor'] : null))
            ?.toString() ??
            '';
        if (orderFor.isNotEmpty) {
          fareCallOrderFor.value = orderFor;
        }
      }
    } catch (_) {
      // Tracking is best-effort; the chat card remains the durable OTP source.
    }
  }

  /// Cleanup fare-call queue state and all ride-related cache
  void resetFareCallState() {
    isFareCallInProgress.value = false;
    fareCallOrderId.value = '';
    fareCallCurrentRiderIndex.value = 0;
    fareCallTotalRiders.value = 0;
    fareCallCurrentRiderId.value = '';
    fareCallAcceptedRiderInfo.value = null;
    fareCallAcceptedRiderId.value = '';
    fareCallPickupOtp.value = '';
    fareCallDeliveryOtp.value = '';
    fareCallOtpOrderId = '';
    fareCallOrderFor.value = '';
    isFareCallRideStarted.value = false;
    fareCallRideStartedData.value = null;
    isFareCallRideCompleted.value = false;
    fareCallRideCompletedData.value = null;
    stopRideStartedFallbackPoll();

    // Clean up live tracking controller if registered
    if (Get.isRegistered<LiveTrachRiderController>()) {
      Get.delete<LiveTrachRiderController>();
    }

    // Clean up ride overlay if registered
    if (Get.isRegistered<RideNavigationOverlayController>()) {
      Get.find<RideNavigationOverlayController>().clearRideData();
    }
    // Forget the persisted ongoing-ride snapshot too.
    OngoingRideStore.clear();
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

  /// Fetches a single hotel (profile + rooms) by its owner [businessId].
  ///
  /// Backs the `https://beapp.in/app/hotel/<businessId>` deep link, which
  /// opens [HotelDiscoverHomeScreen] — that screen needs a fully-hydrated
  /// [HotelServiceData], not just an id. Uses the hotel search endpoint
  /// filtered to the one business (mirroring [fetchProfessionalByUserId]) and
  /// matches the result client-side so an unfiltered response can't return the
  /// wrong hotel. Returns null when nothing matches.
  Future<HotelServiceData?> fetchHotelByBusinessId(String businessId) async {
    try {
      final response = await DiscoverRepo().fetchHotelSearchRepo(
        queryParams: {
          ApiKeys.businessId: businessId,
          ApiKeys.page: 1,
          ApiKeys.limit: 50,
        },
      );
      if (!response.isSuccess) return null;
      final model = HotelSearchModelResponse.fromJson(response.response!.data);
      final list = model.data ?? [];
      if (list.isEmpty) return null;
      for (final hotel in list) {
        if (hotel.businessId == businessId ||
            hotel.profile?.businessId == businessId) {
          return hotel;
        }
      }
      // Only fall back to the sole result when the endpoint already narrowed
      // it down — never guess from a multi-item, unfiltered list.
      return list.length == 1 ? list.first : null;
    } catch (e) {
      log('fetchHotelByBusinessId error: $e');
      return null;
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