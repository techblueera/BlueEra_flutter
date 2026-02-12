import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/common/map/controller/map_service_controller.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/map/widget/food_service_bottom_sheet.dart';
import 'package:BlueEra/features/common/map/widget/home_service_bottom_sheet.dart';
import 'package:BlueEra/features/common/map/widget/rental_service_bottom_sheet.dart';
import 'package:BlueEra/features/common/map/widget/search_place_list.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/getplace_list_controller.dart';

class CustomizeMapScreen extends StatefulWidget {
  final int? isShowCount;
  final String? selectedMapCategoryType;

  const CustomizeMapScreen({super.key, this.isShowCount, this.selectedMapCategoryType});

  @override
  State<CustomizeMapScreen> createState() => _CustomizeMapScreenState();
}

class _CustomizeMapScreenState extends State<CustomizeMapScreen>
    with WidgetsBindingObserver {
  final TextEditingController address = TextEditingController();
  final PlaceController placeController = Get.put(PlaceController());
  final MapServiceController mapServiceController =
      Get.put(MapServiceController());

  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  LatLng _currentPosition = const LatLng(20.5937, 78.9629); // Default: India center
  double _zoom = 14.0;
  final List<MapServiceCategory> categories = MapServiceCategory.values.where((category) {
    // if (isBusiness()) {
    //   return category != MapCategory.jobs;
    // }
    return true;
  }).toList();
  final List<ServiceCategory> serviceCategory = ServiceCategory.values;
  final List<StoresCategory> storesCategory = StoresCategory.values;
  int selectedIndex = 0;
  int selectedServiceCategoryIndex = 0;
  int selectedStoresCategoryIndex = 0;
  int selectedFoodCategoryIndex = 0;
  MapServiceCategory? mapServiceCategoryType = MapServiceCategory.services;
  ServiceCategory? serviceCategoryType = ServiceCategory.homeServices;
  StoresCategory? storesCategoryType = StoresCategory.clothing;
  FoodCategory? selectedFoodCategoryType = FoodCategory.tiffin;
  final TextEditingController searchController = TextEditingController();
  final locationTextController = TextEditingController();
  Timer? _debounce;
  String? _currentAddress;
  bool searchLocationShow = false;

  // Set<Marker> _placeMarkers = {};
  // Marker? _currentMarker;
  // BitmapDescriptor? placeMarker;
  double _lat = 0.0;
  double _lng = 0.0;
  String _currentSearchQuery = '';
  bool isCurrentLocationMarkerShown = false;

  @override
  void initState() {
    super.initState();
    if(widget.selectedMapCategoryType!=null) {
      final (category, index) = MapServiceCategory.fromStringWithIndex(widget.selectedMapCategoryType!);
      log('category--- $category -----  index --- $index');
      mapServiceCategoryType = category;
      selectedIndex = index;
    }

    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(() {
      _onSearchChanged(searchController.text);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // debugPrint("App is in background");
    } else if (state == AppLifecycleState.resumed) {
      // debugPrint("App resumed");
      // _initializeLocationAndMarkers(context);
    }
  }

  /// Search handling with debounce
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        setState(() {
          _currentSearchQuery = query.trim(); // 👈 update here
        });
      }
    });
  }

  // void _onSearchChanged(String query) {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //
  //   _debounce = Timer(const Duration(milliseconds: 400), () {
  //     if (query.trim().isNotEmpty) {
  //       context.read<PlacesBloc>().add(SearchPlacesEvent(
  //         query.trim(),
  //         _currentPosition.latitude,
  //         _currentPosition.longitude,
  //       ));
  //     }
  //   });
  // }

  // inside onMapCreated
  void _onMapCreated(GoogleMapController mapController) async {
    _mapController = mapController;
    _initializeLocationAndMarkers();
  }

  /// Initial location fetch + marker setup
  Future<void> _initializeLocationAndMarkers() async {
    log('lat--> ${LocationService.lat}, lng--> ${LocationService.lng}, current address--> ${LocationService.userCurrentAddress}');
    if (LocationService.lat!=0.0 && LocationService.lng!=0.0) {
      final position = LatLng(LocationService.lat, LocationService.lng);

      _currentPosition = LatLng(position.latitude, position.longitude);
      _currentAddress = LocationService.userCurrentAddress.value.formattedAddress;
      searchController.text = _currentAddress ?? '';
      isCurrentLocationMarkerShown = true;

      _updateLocationMarker(
        lat: _currentPosition.latitude,
        lng: _currentPosition.longitude,
      );
    }
  }

  // /// Location permission logic
  // Future<bool> _handleLocationPermission() async {
  //   LocationPermission permission = await Geolocator.checkPermission();
  //
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) {
  //     openAppSettings();
  //     return false;
  //   }
  //
  //   return true;
  // }

  /// Updates blue dot marker
  Future<void> _updateLocationMarker({required double lat, required double lng}) async {
    _lat = lat;
    _lng = lng;

    // 1. Calculate distance
    double distanceInMeters = Geolocator.distanceBetween(
        _lat, _lng, _currentPosition.latitude, _currentPosition.longitude
    );

    // 2. Prepare the marker (Load icon only once if possible)
    final BitmapDescriptor locationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      AppImageAssets.markerBlue,
    );

    Marker? selectedMarker;

    // 3. Logic: Only create marker if > 50m away from current location
    if (distanceInMeters >= 50.0) {
      selectedMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: LatLng(_lat, _lng),
        icon: locationIcon,
        infoWindow: const InfoWindow(title: "Selected Location"),
      );
    } else {
      debugPrint("Selected location is within 50m. Hiding marker.");
    }

    // 4. Update State (Add/Remove logic)
    setState(() {
      // Always remove old one first to avoid duplicates
      _markers.removeWhere((m) => m.markerId.value == 'selected_location');

      // Add new one if it exists
      if (selectedMarker != null) {
        _markers.add(selectedMarker);
      }
    });

    // 5. Load nearby places and move camera
    await _loadPlaceMarkers(lat: _lat, lng: _lng);

    _moveCameraTo(LatLng(_lat, _lng));
  }
  /// Loads profile image markers
  Future<void> _loadPlaceMarkers({required double lat, required double lng}) async {
    // 1. Fetch Data (Assuming this is an async API call)
    await placeController.fetchPlaces(lat, lng);

    // 2. Load Icon
    final BitmapDescriptor placeIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(40, 40)),
      AppImageAssets.tearDrop,
    );

    // 3. Convert List<Place> to Set<Marker>
    final Set<Marker> newPlaceMarkers = placeController.allPlaces.map((place) {
      return Marker(
        markerId: MarkerId(place.id.toString()), // Unique ID per place
        position: LatLng(
          place.location.coordinates.latitude,
          place.location.coordinates.longitude,
        ),
        icon: placeIcon,
        // Google Maps standard: Show name on Tap
        infoWindow: InfoWindow(
          title: place.name,
          snippet: "Tap for details", // Optional subtitle
        ),
        onTap: () {
          print("Tapped on place: ${place.name}");
        },
      );
    }).toSet();

    // 4. Update Map State
    setState(() {
      // We REMOVE old place markers (if any) before adding new ones
      // This prevents "ghost" markers from previous searches remaining on the map
      // (Assuming place IDs are numeric, we can clear logic, or just rebuild the set)

      // Option A: If you want to keep the "Selected Location" marker but clear others:
      _markers.removeWhere((m) => m.markerId.value != 'selected_location' && m.markerId.value != 'profile-circle-icon');

      // Add the new batch
      _markers.addAll(newPlaceMarkers);
    });

    print("Markers updated. Total count: ${_markers.length}");
  }

  // List<Map<String, dynamic>> generateNearbyDummyPlaces(
  //     {required double lat, required double lng, int count = 5}) {
  //   final random = Random();
  //   final dummyTypes = [
  //     'restaurant',
  //     'cafe',
  //     'park',
  //     'temple',
  //     'market',
  //     'museum'
  //   ];
  //   final dummyNames = ['Spot', 'Place', 'Zone', 'Corner', 'Point'];
  //
  //   return List.generate(count, (index) {
  //     final offsetLat = (random.nextDouble() - 0.5) * 0.02; // ~2km range
  //     final offsetLng = (random.nextDouble() - 0.5) * 0.02;
  //
  //     return {
  //       'name':
  //           '${GetStringUtils(dummyTypes[index % dummyTypes.length]).capitalize!} ${dummyNames[index % dummyNames.length]}',
  //       'position': LatLng(
  //         lat + offsetLat,
  //         lng + offsetLng,
  //       ),
  //       'type': dummyTypes[index % dummyTypes.length],
  //     };
  //   });
  // }

  // void _openBottomSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent, // keep map visible under radius
  //     builder: (_) =>
  //         CommonDraggableBottomSheet(
  //           builder: (scrollController) =>
  //               OtherProfileDetailsBottomSheet(scrollController: scrollController),
  //         ),
  //   );
  // }

  /// Moves camera to current location
  void _moveCameraTo(LatLng position) {
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(position, _zoom),
        duration: Duration(milliseconds: 300));

    setState(() {});
  }

  // Set<Marker> get _allMarkers => {
  //       if (_currentMarker != null && !isCurrentLocationMarkerShown) _currentMarker!,
  //       ..._placeMarkers,
  //     };
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: searchLocationShow ? false : true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          log("do popping");
          return;
        }
        searchLocationShow = false;
        setState(() {});
      },
      child: GestureDetector(
        onTap: () => unFocus(),
        child: Scaffold(
          appBar: CommonBackAppBar(
            isSearch: true,
            controller: searchController,
            onSearchTap: () {
              searchLocationShow = true;
              setState(() {});
            },
            onClearCallback: () {
              searchController.clear();
            },
            isGoLive: true,
            isGoLiveWidget: () {
              if (accountTypeGlobal == AppConstants.individual) {
                final statusData = serviceProviderStatusGlobal.toUpperCase();
                if (statusData == AppConstants.OPEN.toUpperCase()) {
                  viewProfileController.shopStatusOpenClose.value = true;
                } else {
                  viewProfileController.shopStatusOpenClose.value = false;
                }
                return Container(
                  margin: EdgeInsets.only(left: SizeConfig.size10),
                  height: SizeConfig.size40,
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor,
                      ),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: SizeConfig.size10,
                      ),
                      CustomText(
                       AppStrings.goLive,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      buildToggleSwitchChip(
                        value: viewProfileController.shopStatusOpenClose,
                        onChanged: viewProfileController.toggleShopStatus,
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                // 🗺 Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: _zoom,
                  ),
                  myLocationEnabled: true,
                  onMapCreated: _onMapCreated,
                ),

                // 🧭 Top Controls
                Positioned(
                  top: SizeConfig.size12,
                  right: SizeConfig.size5,
                  left: SizeConfig.size5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HorizontalTabSelector(
                        tabs: categories,
                        selectedIndex: selectedIndex,
                        onTabSelected: (index, value) {
                          setState(() {
                            selectedIndex = index;
                            mapServiceCategoryType =
                                value.toMapCategory() ?? MapServiceCategory.services;
                          });
                          searchController.clear();
                        },
                        labelBuilder: (MapServiceCategory mapCategory) {
                          return mapCategory.label;
                        },
                        unSelectedBackgroundColor: AppColors.white,
                        unSelectedBorderColor: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                      SizedBox(height: SizeConfig.size10),
                      // buildSubCategory(),
                    ],
                  ),
                ),

                // ➕➖ Zoom Controls
                Positioned(
                  bottom: 40 + kBottomNavigationBarHeight,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        shape: CircleBorder(),
                        elevation: 0,
                        heroTag: "zoom-in",
                        onPressed: () {
                          _zoom++;
                          _mapController.animateCamera(
                            CameraUpdate.zoomTo(_zoom),
                          );
                        },
                        child: const Icon(Icons.add,
                            color: AppColors.primaryColor),
                        backgroundColor: AppColors.white,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      FloatingActionButton(
                        shape: CircleBorder(),
                        mini: true,
                        elevation: 0,
                        heroTag: "zoom-out",
                        onPressed: () {
                          _zoom--;
                          _mapController.animateCamera(
                            CameraUpdate.zoomTo(_zoom),
                          );
                        },
                        child: const Icon(Icons.remove,
                            color: AppColors.primaryColor),
                        backgroundColor: AppColors.white,
                      ),
                    ],
                  ),
                ),

                // ✅ Custom "Current Location" Button at Bottom Left
                Positioned(
                  bottom: 40 + kBottomNavigationBarHeight,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: "my-location",
                    backgroundColor: AppColors.white,
                    elevation: 0,
                    onPressed: () {
                      _initializeLocationAndMarkers();
                    },
                    child:
                        Icon(Icons.my_location, color: AppColors.primaryColor),
                  ),
                ),

                buildBottomSheet(),

                searchLocationShow
                    ? SearchPlaceList(
                        onRefresh: () {
                          _initializeLocationAndMarkers();
                        },
                        query: _currentSearchQuery,
                        lat: _currentPosition.latitude,
                        lng: _currentPosition.longitude,
                        currentAddress: _currentAddress ?? '',
                        fromScreen: RouteConstant.CustomizeMapScreen,
                        onPlaceSelected: (lat, lng, address) async {
                          searchController.text = address!;
                          searchLocationShow = false;
                          if (lat != null && lng != null) {
                            unFocus();
                            _updateLocationMarker(lat: lat, lng: lng);
                          } else {
                            _updateLocationMarker(
                                lat: _currentPosition.latitude,
                                lng: _currentPosition.longitude);
                          }
                        })
                    : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSubCategory() {
    switch (mapServiceCategoryType) {
      case MapServiceCategory.services:
        return HorizontalTabSelector(
          tabs: serviceCategory,
          selectedIndex: selectedServiceCategoryIndex,
          onTabSelected: (index, value) {
            setState(() {
              selectedServiceCategoryIndex = index;

              serviceCategoryType =
                  value.toServiceCategory() ?? ServiceCategory.homeServices;
            });
          },
          labelBuilder: (ServiceCategory serviceSubCategory) {
            return serviceSubCategory.label;
          },
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor: AppColors.white,
          boxShadow: [
            BoxShadow(
                color: AppColors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        );
      case MapServiceCategory.foods:
        return HorizontalTabSelector(
          tabs: serviceCategory,
          selectedIndex: selectedServiceCategoryIndex,
          // onTabSelected: (index, value) {
          //   final selected = value.toServiceCategory();
          //   setState(() {
          //     serviceCategoryType = selected;
          //   });
          //   logs("selected=== ${selected}");
          //   logs("serviceCategoryType=== ${serviceCategoryType}");
          //   logs("ServiceCategory.foods.name=== ${ServiceCategory.foods.name}");
          // },

          onTabSelected: (index, value) {
            setState(() {
              selectedServiceCategoryIndex = index;
              serviceCategoryType =
                  value.toServiceCategory() ?? ServiceCategory.foods;
            });
          },
          labelBuilder: (ServiceCategory serviceSubCategory) {
            return serviceSubCategory.label;
          },
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor: AppColors.white,
          boxShadow: [
            BoxShadow(
                color: AppColors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        );

      /*    case MapCategory.stores:
        return HorizontalTabSelector(
            tabs: storesCategory,
            selectedIndex: selectedStoresCategoryIndex,
            onTabSelected: (index, value) {
              setState(() {
                selectedStoresCategoryIndex = index;
                storesCategoryType =
                    value.toStoresCategory() ?? StoresCategory.clothing;
              });
            },
            labelBuilder: (StoresCategory storesSubCategory) {
              return storesSubCategory.label;
            },
            unSelectedBackgroundColor: AppColors.white,
            unSelectedBorderColor: AppColors.white);
*/
      default:
        return const SizedBox(); // or any fallback widget
    }
  }

  Widget buildBottomSheet() {
    /// Service Category
    if (mapServiceCategoryType == MapServiceCategory.services) {
      return HomeServicesBottomSheet(
        key: const ValueKey("services"),
        lat: _lat,
        lng: _lng,
        onClose: () {
          setState(() {
            selectedServiceCategoryIndex = -1;
            serviceCategoryType = null;
          });
        },
        category: "service",
        subType: EarnServiceTypes.selfWork.label,
      );
    } else if (mapServiceCategoryType == MapServiceCategory.homeService) {
      return HomeServicesBottomSheet(
        key: const ValueKey("home_services"),
        lat: _lat,
        lng: _lng,
        onClose: () {
          setState(() {
            selectedServiceCategoryIndex = -1;
            serviceCategoryType = null;
          });
        },
        category: "service",
        subType: EarnServiceTypes.homeService.label,
      );
    } else if (mapServiceCategoryType == MapServiceCategory.foods) {
      return FoodServicesBottomSheet(
        key: const ValueKey("foods"),
        lat: _lat,
        lng: _lng,
        onClose: () {
          setState(() {
            selectedServiceCategoryIndex = -1;
            serviceCategoryType = null;
          });
        },
        category: "food",
        subType: EarnServiceTypes.homeMadeFood.label,
      );
    }
    else if (mapServiceCategoryType == MapServiceCategory.rental) {
      return RentalServicesBottomSheet(
        key: const ValueKey("rental_service"),
        lat: _lat,
        lng: _lng,
        onClose: () {
          setState(() {
            selectedServiceCategoryIndex = -1;
            serviceCategoryType = null;
          });
        },
        category: "rental",
        subType: EarnServiceTypes.homeMadeFood.label,
      );
    }

/*
    /// Stores Category
    if (mapCategoryType == MapCategory.stores) {
      switch (storesCategoryType) {
        case StoresCategory.clothing:
          return CustomServiceBottomSheet(
            serviceType: 'CLOTHING',
            onClose: () {
              setState(() {
                selectedStoresCategoryIndex = -1;
                storesCategoryType = null;
              });
            },
            lat: _lat,
            lng: _lng,
          );
        case StoresCategory.footwear:
          return CustomServiceBottomSheet(
            serviceType: 'FOOTWEAR',
            onClose: () {
              setState(() {
                selectedStoresCategoryIndex = -1;
                storesCategoryType = null;
              });
            },
            lat: _lat,
            lng: _lng,
          );
        case StoresCategory.giftShops:
          return CustomServiceBottomSheet(
            serviceType: 'GIFTSHOPS',
            onClose: () {
              setState(() {
                selectedStoresCategoryIndex = -1;
                storesCategoryType = null;
              });
            },
            lat: _lat,
            lng: _lng,
          );

        default:
          return const SizedBox(); // or any fallback widget
      }
    }

    /// Jobs Category
    if (mapCategoryType == MapCategory.jobs) {
      return JobServiceBottomSheet(
          onClose: () {
            setState(() {
              selectedIndex = -1;
              mapCategoryType = null;
            });
          },
          lat: '$_lat',
          lng: '$_lng');
    }

    /// Places Category
    if (mapCategoryType == MapCategory.places) {
      return CustomServiceBottomSheet(
        serviceType: 'PLACES',
        onClose: () {
          setState(() {
            selectedIndex = -1;
            mapCategoryType = null;
          });
        },
        lat: _lat,
        lng: _lng,
      );
    }
*/

    return SizedBox();
  }
}
