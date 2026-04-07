import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/map/widget/search_place_list.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/getx_utils.dart';
import '../../auth/controller/auth_controller.dart';

class SearchLocationScreen extends StatefulWidget {
  final Function(double?, double?, String?)? onPlaceSelected;
  final String fromScreen;

  const SearchLocationScreen(
      {Key? key, this.onPlaceSelected, required this.fromScreen})
      : super(key: key);

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController searchController = TextEditingController();
  final authController = getOrPut(() => AuthController());
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  LatLng _currentPosition = const LatLng(20.5937, 78.9629);
  String? _currentAddress;
  String _searchQuery = '';

  /// Recent searches — latest 3 places
  List<Map<String, dynamic>> _recentSearches = [];

  static const String _recentSearchesKey = 'recent_transport_searches';

  @override
  void initState() {
    super.initState();
    checkPermissionAndSetData();
    _loadRecentSearches();
    authController.isSearchOpen.value = true;
    searchController.addListener(() {
      _onSearchChanged(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
        });
      }
    });
  }

  Future<void> checkPermissionAndSetData() async {
    log('lat--> ${LocationService.lat}, lng--> ${LocationService.lng}, current address--> ${LocationService.userCurrentAddress.value.formattedAddress}');
    if (LocationService.lat != 0.0 && LocationService.lng != 0.0) {
      _currentPosition = LatLng(LocationService.lat, LocationService.lng);
      _currentAddress =
          LocationService.userCurrentAddress.value.formattedAddress;
      if (mounted) setState(() {});
    }
  }

  // ─── Recent Searches ──────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_recentSearchesKey) ?? [];
    if (mounted) {
      setState(() {
        _recentSearches = stored
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  Future<void> _saveRecentSearch(
      double lat, double lng, String address) async {
    if (address.isEmpty) return;

    final entry = {'lat': lat, 'lng': lng, 'address': address};

    // Remove duplicate if exists
    _recentSearches.removeWhere((e) => e['address'] == address);
    // Add to top
    _recentSearches.insert(0, entry);
    // Keep only latest 3
    if (_recentSearches.length > 3) {
      _recentSearches = _recentSearches.sublist(0, 3);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchesKey,
      _recentSearches.map((e) => jsonEncode(e)).toList(),
    );
  }

  void _onPlaceSelected(double? lat, double? lng, String? address) {
    if (lat != null && lng != null && address != null) {
      _saveRecentSearch(lat, lng, address);
    }
    widget.onPlaceSelected?.call(lat, lng, address);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (mounted) {
      setState(() {
        _recentSearches.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.greyE4,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search for a place...',
              hintStyle: TextStyle(
                  color: AppColors.grayText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400),
              prefixIcon: Icon(Icons.search,
                  color: AppColors.grayText, size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.grayText),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: _searchQuery.isNotEmpty
          ? SearchPlaceList(
              query: _searchQuery,
              lat: _currentPosition.latitude,
              lng: _currentPosition.longitude,
              currentAddress: _currentAddress ?? '',
              fromScreen: widget.fromScreen,
              onPlaceSelected: _onPlaceSelected,
            )
          : _buildDefaultView(),
    );
  }

  Widget _buildDefaultView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Use Current Location
          InkWell(
            onTap: () {
              _onPlaceSelected(
                _currentPosition.latitude,
                _currentPosition.longitude,
                _currentAddress ?? '',
              );
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.my_location,
                        color: AppColors.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "Use Current Location",
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                        if (_currentAddress != null &&
                            _currentAddress!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          CustomText(
                            _currentAddress,
                            fontSize: 12,
                            color: AppColors.grayText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: AppColors.grayText, size: 20),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: AppColors.whiteE5),

          /// Choose on Map
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.map_outlined,
                        color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomText(
                      "Choose on Map",
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: AppColors.grayText, size: 20),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: AppColors.whiteE5),

          /// Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    "Recent Searches",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayText,
                  ),
                  InkWell(
                    onTap: _clearRecentSearches,
                    child: CustomText(
                      "Clear All",
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.red00,
                    ),
                  ),
                ],
              ),
            ),
            ..._recentSearches.map((search) {
              return InkWell(
                onTap: () {
                  final lat = (search['lat'] as num).toDouble();
                  final lng = (search['lng'] as num).toDouble();
                  final address = search['address'] as String;
                  _onPlaceSelected(lat, lng, address);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.greyE4,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.history,
                            color: AppColors.grayText, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: CustomText(
                          search['address'],
                          fontSize: 14,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.north_west,
                          color: AppColors.grayText, size: 16),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
