import 'package:BlueEra/features/common/Discover/model/category_filter.dart';
import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:get/get.dart';
import 'service_enquiry_controller.dart';

/// Discover's earn-service and professional/consultant listings: the paged
/// lists and their unpaginated map lists, sort filter, the location picked on
/// the entry screen, providers saved on this device for the session, and the
/// single-provider lookups the deep links use.
class ProfessionalDiscoverController extends GetxController {
  /// Registered on first use and kept for the session: the entry and listing
  /// screens share the picked location, and a back-and-return reuses the loaded
  /// list (see the freshness guards). Logout deletes it.
  static ProfessionalDiscoverController get to =>
      Get.isRegistered<ProfessionalDiscoverController>()
          ? Get.find<ProfessionalDiscoverController>()
          : Get.put(ProfessionalDiscoverController(), permanent: true);

  var selfProfessionServiceResponse = ApiResponse.initial('Initial').obs;

  var profConProfessionServiceResponse = ApiResponse.initial('Initial').obs;

  Rx<OnboardingCategoryModel?> selectedEarnServiceData =
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

  /// Full unpaginated consultant list used by the v2 map view. Populated by
  /// [fetchAllProfessionalConsForMap]; kept separate from the paginated
  /// [professionalConsDataList] so list pagination state isn't disturbed.
  /// Mirrors the [earnServiceMapList] pairing above.
  RxList<ProfessionalConsData> professionalConsMapList =
      <ProfessionalConsData>[].obs;
  Rx<ApiResponse> professionalConsMapResponse =
      ApiResponse.initial('Initial').obs;

  RxBool isEarnServiceLoading = false.obs;
  RxBool isProfConServiceLoading = false.obs;
  int earnServicePage = 1;
  int profConsServicePage = 1;
  var isEarnServiceLoadingMore = false.obs;
  var isProfConServiceLoadingMore = false.obs;
  bool hasMoreEarnServiceData = true;
  bool hasMoreProfConServiceData = true;

  /// Consultant Service
  Rx<OnboardingCategoryModel?> selectedProfessionalConsultantData =
  Rx<OnboardingCategoryModel?>(null);

  // ── Freshness guards (skip refetch on screen re-entry) ──────────────
  // Keyed by the request params so changing the category/type refetches,
  // while a back-and-return for the same selection reuses the loaded list.
  final FetchCache _earnServiceCache = FetchCache();
  final FetchCache _profConCache = FetchCache();

  /// Radius (km) the earn-services search is scoped to — tightened to a real
  /// "near you" area (was 1500 km, which is national-scale). The v2 Book-Home-
  /// Services flow is location-first, so a tight radius is the point.
  static final int _earnServiceRadiusKm = kmRadius200;

  // ── Earn-discover location override (v2 entry screen) ─────────────────────
  // The entry screen lets the user pick WHERE they want a service — the device
  // location OR a searched place. That choice scopes the earn-services search
  // for this flow only; it deliberately does NOT mutate the global
  // `LocationService`, so unrelated screens keep their own location. Null here
  // means "no explicit pick" → fall back to the global fix (device location).
  double? earnDiscoverLat;
  double? earnDiscoverLng;

  /// Human-readable label for the picked location (e.g. "Lucknow, Uttar
  /// Pradesh"), shown in the entry field + results header pill.
  final RxString earnDiscoverLocationLabel = ''.obs;

  /// Set the location the earn-services search should scope to. Pass all-null
  /// to clear the override and fall back to the device fix.
  void setEarnDiscoverLocation({double? lat, double? lng, String? label}) {
    earnDiscoverLat = lat;
    earnDiscoverLng = lng;
    earnDiscoverLocationLabel.value = label ?? '';
  }

  /// The lat/lng the earn search resolves to: the explicit pick when set,
  /// otherwise the global device fix.
  double get _earnLat => earnDiscoverLat ?? LocationService.lat;
  double get _earnLng => earnDiscoverLng ?? LocationService.lng;

  // ── Local "saved provider" toggle (favorite star on the card) ─────────────
  // There is no saved-providers backend yet, so this is an in-memory, session-
  // only set that just fills the star. Persisting it is a future backend task.
  final RxSet<String> locallySavedProviderIds = <String>{}.obs;

  bool isProviderLocallySaved(String? id) =>
      id != null && locallySavedProviderIds.contains(id);

  void toggleProviderLocalSave(String? id) {
    if (id == null || id.isEmpty) return;
    if (locallySavedProviderIds.contains(id)) {
      locallySavedProviderIds.remove(id);
    } else {
      locallySavedProviderIds.add(id);
    }
  }

  /// Adds `lat` / `lng` / `radius` to an earn-services request — but only with
  /// a real fix. `LocationService` reports 0,0 before the first fix resolves
  /// (or when permission is denied), and sending that would scope the search
  /// to the middle of the ocean and return nothing; omitting the params lets
  /// the backend fall back to its unscoped behaviour instead.
  void _addLocationParams(Map<String, dynamic> queryParams) {
    final lat = _earnLat;
    final lng = _earnLng;
    if (lat == 0 && lng == 0) return;
    queryParams[ApiKeys.lat] = lat;
    queryParams[ApiKeys.lng] = lng;
    queryParams[ApiKeys.radius] = _earnServiceRadiusKm;
  }

  /// Includes the coarse location: the results are now radius-scoped, so a
  /// re-entry from a materially different place must refetch rather than reuse
  /// the previous area's list. Rounded to ~1 km (2 dp) so ordinary GPS jitter
  /// doesn't invalidate the cache on every screen open. Uses the picked
  /// override when set so switching location forces a fresh fetch.
  String get _earnServiceSignature =>
      'earn|${selectedEarnServiceData.value?.slugId ?? ''}'
      '|${_earnLat.toStringAsFixed(2)}'
      ',${_earnLng.toStringAsFixed(2)}';
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

    final Map<String, dynamic> queryParams = {
      ApiKeys.type: earnServiceType,
      ApiKeys.subType: subType,
      ApiKeys.page: earnServicePage,
      ApiKeys.limit: limit,
    };
    // Location-scope the search so the list is providers near the user rather
    // than every provider in the country. Sent only when we actually have a
    // fix — posting 0,0 would scope the search to the Gulf of Guinea and come
    // back empty.
    _addLocationParams(queryParams);
    if (selectedEarnServiceData.value != null) {
      queryParams[ApiKeys.category] = selectedEarnServiceData.value?.slugId;
    }

    // Silently warm the enquiry-options cache for this profession so the
    // Enquire bottom sheet opens instantly and the same profession is never
    // fetched again (across providers / tab switches).
    if (!isLoadMore) {
      ServiceEnquiryController.to
          .prefetchEnquiryOptions(selectedEarnServiceData.value?.slugId);
    }

    // Response-time trace for the earn-services list — uncomment to measure
    // again. Wraps the repo call only, so it reports the network round-trip +
    // decode, NOT the distance pass below. See
    // docs/backend/EARN_SERVICES_MAP_PERFORMANCE_GUIDE.md.
    // final sw = Stopwatch()..start();
    ResponseModel response =
    await DiscoverRepo().fetchSelfWorkServices(queryParams: queryParams);
    // sw.stop();
    // log('EARN_SERVICES_API: list took ${sw.elapsedMilliseconds}ms '
    //     '(page=$earnServicePage, category=${selectedEarnServiceData.value?.slugId ?? '-'}, '
    //     'lat=${queryParams[ApiKeys.lat] ?? '-'}, lng=${queryParams[ApiKeys.lng] ?? '-'}, '
    //     'radius=${queryParams[ApiKeys.radius] ?? '-'}, success=${response.isSuccess})');

    try {
      if (response.isSuccess) {
        selfProfessionServiceResponse.value = ApiResponse.complete(response);

        final responseModel =
        ServiceModelResponse.fromJson(response.response?.data);

        List<ServiceData> tempNewItems = [];

        for (var service in responseModel.services ?? []) {
          if (service.data != null && service.data!.isNotEmpty) {
            for (ServiceData item in service.data!) {
              // Distance comes from the server (`distanceKm`) now that the
              // request carries lat/lng. Only fall back to the shared
              // [calculateDistance] when it didn't — that reads the fix
              // LocationService already holds.
              //
              // This used to `await getDistanceInKm(...)` per item, and that
              // helper asks the platform for a FRESH best-accuracy GPS fix on
              // every call: 20 serial fixes ran AFTER the response landed, so
              // the list kept spinning long after the data was in memory.
              if (item.distance == null) {
                final lat = item.userLocation?.lat?.toDouble();
                final lng = item.userLocation?.lon?.toDouble();
                if (lat != null && lng != null && !(lat == 0 && lng == 0)) {
                  item.distance = calculateDistance(lat, lng);
                }
              }
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
    _addLocationParams(queryParams);
    if (selectedEarnServiceData.value != null) {
      queryParams[ApiKeys.category] = selectedEarnServiceData.value?.slugId;
    }

    try {
      // Response-time trace — uncomment alongside the one in
      // [fetchEarnServices] when profiling this endpoint.
      // final sw = Stopwatch()..start();
      final response =
      await DiscoverRepo().fetchSelfWorkServices(queryParams: queryParams);
      // sw.stop();
      // log('EARN_SERVICES_API: map took ${sw.elapsedMilliseconds}ms '
      //     '(limit=1000, category=${selectedEarnServiceData.value?.slugId ?? '-'}, '
      //     'lat=${queryParams[ApiKeys.lat] ?? '-'}, lng=${queryParams[ApiKeys.lng] ?? '-'}, '
      //     'radius=${queryParams[ApiKeys.radius] ?? '-'}, success=${response.isSuccess})');
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

  /// Loads ALL professional consultants (unpaginated) for the v2 map view.
  /// Same `professionalSearch` endpoint as the list, with a high limit and no
  /// pagination so every consultant with usable coords can become a marker.
  ///
  /// Deliberately sends NO lat/lng/radius: unlike the self-work endpoint, the
  /// consultant search is not location-scoped server-side (it returns no
  /// `distanceKm` either — the screens compute distance client-side). Adding
  /// params the API doesn't read would only invite confusion.
  Future<void> fetchAllProfessionalConsForMap() async {
    professionalConsMapResponse.value = ApiResponse.initial('Initial');

    final queryParams = <String, dynamic>{
      if (selectedProfessionalConsultantData.value?.slugId != null)
        "profession": selectedProfessionalConsultantData.value?.slugId,
      ApiKeys.page: 1,
      ApiKeys.limit: 1000,
    };

    try {
      final response = await DiscoverRepo()
          .fetchProfessionalConsServices(queryParams: queryParams);
      if (!response.isSuccess) {
        professionalConsMapResponse.value =
            ApiResponse.error(response.message ?? 'error');
        return;
      }
      final responseModel =
          ProfessionalConsResModel.fromJson(response.response?.data);
      professionalConsMapList.assignAll(responseModel.data ?? []);
      professionalConsMapResponse.value = ApiResponse.complete(response);
    } catch (e) {
      professionalConsMapResponse.value = ApiResponse.error(e.toString());
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
      ServiceEnquiryController.to.prefetchConsultantEnquiryOptions(
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
}
