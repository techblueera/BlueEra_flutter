import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/common/map/controller/map_service_controller.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/map/widget/custom_service_bottom_sheet.dart';
import 'package:BlueEra/features/common/map/widget/home_service_bottom_sheet.dart';
import 'package:BlueEra/features/common/map/widget/job_service_bottom_sheet.dart';
import 'package:BlueEra/features/common/map/widget/search_place_list.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:mappls_gl/mappls_gl.dart';
import '../controller/getplace_list_controller.dart';

class CustomizeMapScreen extends StatefulWidget {
  final int? isShowCount;

  const CustomizeMapScreen({super.key, this.isShowCount});

  @override
  State<CustomizeMapScreen> createState() => _CustomizeMapScreenState();
}

class _CustomizeMapScreenState extends State<CustomizeMapScreen> with WidgetsBindingObserver {
  final TextEditingController address = TextEditingController();
  final PlaceController placeController = Get.put(PlaceController());
  final MapServiceController mapServiceController = Get.put(MapServiceController());

  bool isOpenKeyBoard = false;
  late MapplsMapController _mapController;
  LatLng _currentPosition = const LatLng(20.5937, 78.9629); // Default: India center
  double _zoom = 14.0;
  final List<MapCategory> categories = MapCategory.values.where((category) {
    if (isBusiness()) {
      return category != MapCategory.jobs;
    }
    return true;
  }).toList();
  final List<ServiceCategory> serviceCategory = ServiceCategory.values;
  final List<StoresCategory> storesCategory = StoresCategory.values;
  int selectedIndex = 0;
  int selectedServiceCategoryIndex = 0;
  int selectedStoresCategoryIndex = 0;
  MapCategory? mapCategoryType = MapCategory.services;
  ServiceCategory? serviceCategoryType = ServiceCategory.homeServices;
  StoresCategory? storesCategoryType = StoresCategory.clothing;
  final TextEditingController searchController = TextEditingController();
  final locationTextController = TextEditingController();
  Timer? _debounce;
  String? _currentAddress;
  String? _currentCity;
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
      _initializeLocationAndMarkers(context);
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
  void _onMapCreated(MapplsMapController mapController) async {
    _mapController = mapController;
    _initializeLocationAndMarkers(context);
  }

  /// Initial location fetch + marker setup
  Future<void> _initializeLocationAndMarkers(BuildContext context) async {
    // final permission = await _handleLocationPermission();
    // if (!permission) return;

    final locationData = await LocationService.fetchLocation(context, isPermissionRequired: false);
    if (locationData != null) {
      final position = locationData["position"];
      final address = locationData["address"];

      _currentPosition = LatLng(position.latitude, position.longitude);
      _currentAddress = address.where((e) => e != null && e.isNotEmpty).join(', ');
      searchController.text = _currentAddress??'';
      _currentCity = address[1];
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

    Symbol symbol = await _mapController.addSymbol(
      SymbolOptions(
        iconImage: AppImageAssets.markerBlue,
        geometry: LatLng(_lat, _lng),
        iconSize: 1.5,
        textField: 'Location',
        textSize: SizeConfig.small,
        textColor: AppColors.mainTextColor.toString(),
        textOffset: const Offset(0, -2),
      ),
    );

    // Calculate distance between selected location and current GPS location
    double distanceInMeters = Geolocator.distanceBetween(
        _lng,
        _lng,
        _currentPosition.latitude,
        _currentPosition.longitude
    );

    print("lat--> lng--> $lat $lng");
    print("current lat--> current lng--> ${_currentPosition.latitude} ${_currentPosition.longitude}");
    print("distance from current location--> ${distanceInMeters.toStringAsFixed(2)} meters");

    // If the selected location is within 50 meters of current location,
    // consider it as current location and remove marker
    // This handles GPS precision differences between device GPS and Google Places API
    if (distanceInMeters < 50.0) {
      print("Selected location is within 50m of current position, removing marker");
      _mapController.removeSymbol(symbol);
    }

    await _loadPlaceMarkers(lat: _lat, lng: _lng);
    _moveCameraTo(LatLng(_lat, _lng));
  }

  /// Loads profile image markers
  Future<void> _loadPlaceMarkers({required double lat, required double lng}) async {
    placeController.fetchPlaces(
        _lat,
        _lng
    );

    // final placeMarker = await createMarkerUsingTearDropImage(
    //   tearDropAssetPath: AppImageAssets.tearDrop,
    //   centerIconAssetPath: AppImageAssets.temple,
    // );

    generateNearbyDummyPlaces(
      lat: lat,
      lng: lng,
    );

    // add each place as a symbol
    for (final place in placeController.allPlaces) {
      await _mapController.addSymbol(
        SymbolOptions(
          iconImage: AppImageAssets.tearDrop,
          geometry: LatLng(
            place.location.coordinates.latitude,
            place.location.coordinates.longitude,
          ),
          iconSize: 1.0,
          textField: place.name,
          textSize: 12.0,
          textColor: '#000000',
          textOffset: const Offset(0, -1.5),
        ),
      );
    }

    // final Set<Marker> markers = placeController.allPlaces.map((place) {
    //   return Marker(
    //     markerId: MarkerId(place.id.toString()),
    //     position: LatLng(
    //       place.location.coordinates.latitude,
    //       place.location.coordinates.longitude,
    //     ),
    //     icon: placeMarker,
    //     infoWindow: InfoWindow(title: place.name),
    //   );
    // }).toSet();

    // setState(() {
    //   _placeMarkers = markers;
    //   print("fieuf $_placeMarkers");
    // });
  }

  List<Map<String, dynamic>> generateNearbyDummyPlaces({required double lat, required double lng, int count = 5}) {
    final random = Random();
    final dummyTypes = [
      'restaurant',
      'cafe',
      'park',
      'temple',
      'market',
      'museum'
    ];
    final dummyNames = ['Spot', 'Place', 'Zone', 'Corner', 'Point'];

    return List.generate(count, (index) {
      final offsetLat = (random.nextDouble() - 0.5) * 0.02; // ~2km range
      final offsetLng = (random.nextDouble() - 0.5) * 0.02;

      return {
        'name':
            '${GetStringUtils(dummyTypes[index % dummyTypes.length]).capitalize!} ${dummyNames[index % dummyNames.length]}',
        'position': LatLng(
          lat + offsetLat,
          lng + offsetLng,
        ),
        'type': dummyTypes[index % dummyTypes.length],
      };
    });
  }

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
    _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(position, _zoom),
        duration: Duration(milliseconds: 300)
    );

    setState(() {});
  }

  // Set<Marker> get _allMarkers => {
  //       if (_currentMarker != null && !isCurrentLocationMarkerShown) _currentMarker!,
  //       ..._placeMarkers,
  //     };

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
            onBackTap: () {
              // if(searchLocationShow) {
              //   searchController.clear();
              //   searchLocationShow = false;
              //   setState(() {});
              // }else{
              //   Navigator.pop(context);
              // }
            },
            isSearch: true,
            isLeading: false,
            controller: searchController,
            onSearchTap: () {
              searchLocationShow = true;
              setState(() {});
            },
            onClearCallback: () {
              searchController.clear();
            },
            currentCity: _currentCity
          ),
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                // 🗺 Mappls Map
                MapplsMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: _zoom,
                  ),
                  myLocationEnabled: true,
                  onMapCreated: _onMapCreated,
                  // zoomControlsEnabled: false,
                  // we use our custom zoom controls
                  // mapType: MapType.normal,
                  // ✅ Satellite view here
                  // markers: _allMarkers,
                  // ✅ Show _markers
                  // myLocationButtonEnabled: false,
                  // ✅ shows default button
                  // style: mapLightCode,

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
                            mapCategoryType = value.toMapCategory() ?? MapCategory.services;
                          });
                          searchController.clear();
                        },
                        labelBuilder: (MapCategory mapCategory) {
                          return mapCategory.label;
                        },
                        unSelectedBackgroundColor: AppColors.white,
                        unSelectedBorderColor : AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: Offset(0, 2)
                          )
                        ],
                      ),

                      SizedBox(height: SizeConfig.size10),

                      buildSubCategory(),
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
                      _initializeLocationAndMarkers(context, );
                    },
                    child:
                        Icon(Icons.my_location, color: AppColors.primaryColor),
                  ),
                ),

                buildBottomSheet(),

                searchLocationShow
                    ? SearchPlaceList(
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
                            _updateLocationMarker(lat: _currentPosition.latitude, lng: _currentPosition.longitude);
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
    switch (mapCategoryType) {
      case MapCategory.services:
        return HorizontalTabSelector(
          tabs: serviceCategory,
          selectedIndex: selectedServiceCategoryIndex,
          onTabSelected: (index, value) {
            setState(() {
              selectedServiceCategoryIndex = index;
              serviceCategoryType = value.toServiceCategory() ?? ServiceCategory.homeServices;
            });
          },
          labelBuilder: (ServiceCategory serviceSubCategory) {
            return serviceSubCategory.label;
          },
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor : AppColors.white,
          boxShadow: [
            BoxShadow(
                color: AppColors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: Offset(0, 2)
            )
          ],
        );

      case MapCategory.stores:
        return HorizontalTabSelector(
          tabs: storesCategory,
          selectedIndex: selectedStoresCategoryIndex,
          onTabSelected: (index, value) {
            setState(() {
              selectedStoresCategoryIndex = index;
              storesCategoryType = value.toStoresCategory() ?? StoresCategory.clothing;
            });
          },
          labelBuilder: (StoresCategory storesSubCategory) {
            return storesSubCategory.label;
          },
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor : AppColors.white
        );

      default:
        return const SizedBox(); // or any fallback widget
    }
  }

  Widget buildBottomSheet() {
    /// Service Category
    if(mapCategoryType == MapCategory.services){
      switch (serviceCategoryType) {
        case ServiceCategory.homeServices:
          return HomeServicesBottomSheet(
            lat: _lat,
            lng: _lng,
            onClose: () {
              setState(() {
                selectedServiceCategoryIndex = -1;
                serviceCategoryType = null;
              });
            }
          );
        case ServiceCategory.foods:
          return CustomServiceBottomSheet(
              serviceType: 'FOODS',
              onClose: () {
                setState(() {
                  selectedServiceCategoryIndex = -1;
                  serviceCategoryType = null;
                });
              },
             lat: _lat,
             lng: _lng,
          );
        // case ServiceCategory.stay:
        //   return SizedBox();

        default:
          return const SizedBox(); // or any fallback widget
      }
    }

    /// Stores Category
    if(mapCategoryType == MapCategory.stores){
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
          lng: '$_lng'
      );
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

    return SizedBox();
  }
}
