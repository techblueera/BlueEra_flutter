import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/map/widget/search_place_list.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/getx_utils.dart';
import '../../auth/controller/auth_controller.dart';

class SearchLocationScreen extends StatefulWidget {
  final Function(double?, double?, String?)? onPlaceSelected;
  final String fromScreen;

  const SearchLocationScreen({Key? key, this.onPlaceSelected, required this.fromScreen}) : super(key: key);

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController searchController = TextEditingController();
  final locationTextController = TextEditingController();
  final authController = getOrPut(() => AuthController());

  Timer? _debounce;
  LatLng _currentPosition = const LatLng(20.5937, 78.9629);
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    checkPermissionAndSetData();
    authController.isSearchOpen.value=true;
    searchController.addListener(() {
      _onSearchChanged(searchController.text);
    }); // To show/hide clear icon
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        setState(() {});
      }
    });
  }

  Future<void> checkPermissionAndSetData() async {
    // LocationPermission permission = await Geolocator.checkPermission();
    //
    // if (permission == LocationPermission.denied) {
    //   permission = await Geolocator.requestPermission();
    // }

  /*  if (permission == LocationPermission.deniedForever) {
      openAppSettings();
    } */
    // else {

      log('lat--> ${LocationService.lat}, lng--> ${LocationService.lng}, current address--> ${LocationService.userCurrentAddress.value.formattedAddress}');
      if (LocationService.lat!=0.0 && LocationService.lng!=0.0) {
        _currentPosition = LatLng(LocationService.lat, LocationService.lng);
        _currentAddress = LocationService.userCurrentAddress.value.formattedAddress;
        // _currentAddress = address.first;
        // _currentCity = address;
        setState(() {});
      }
    // }
  }

  @override
  Widget build(BuildContext context) {
    // final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
          isSearch: true,
          controller: searchController,
          onClearCallback: () {
            searchController.clear();
          }),
      body: SearchPlaceList(
          query: searchController.text,
          lat: _currentPosition.latitude,
          lng: _currentPosition.longitude,
          currentAddress: _currentAddress ?? '',
          fromScreen: widget.fromScreen,
          onPlaceSelected: widget.onPlaceSelected),
    );
  }
}
