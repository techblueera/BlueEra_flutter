import 'dart:async';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/map/widget/search_place_list.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' show Geolocator, LocationPermission;
import 'package:mappls_gl/mappls_gl.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

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
  Timer? _debounce;
  LatLng _currentPosition = const LatLng(20.5937, 78.9629);
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    checkPermissionAndSetData();
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
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
    } else {
      var locationData = await LocationService.fetchLocation(context);
      logs("locationData ==== ${locationData}");
      if (locationData != null) {
        var position = locationData["position"];
        final address = locationData["address"];
        _currentPosition = LatLng(position.latitude, position.longitude);
        _currentAddress = address.first;
        // _currentCity = address;
        setState(() {});
      }
    }
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
