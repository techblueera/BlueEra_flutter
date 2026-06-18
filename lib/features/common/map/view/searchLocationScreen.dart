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
    // Defer flipping the observable to after the first frame: an Obx up in
    // main.dart's Stack listens to `isSearchOpen`, so setting it synchronously
    // during initState marks that Obx dirty mid-build → "setState() called
    // during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authController.isSearchOpen.value = true;
    });
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.greyE4.withValues(alpha: 0.5),
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
          const SizedBox(height: 8),

          /// Use Current Location
          _buildActionTile(
            icon: Icons.my_location,
            iconBgColor: AppColors.primaryColor.withValues(alpha: 0.1),
            iconColor: AppColors.primaryColor,
            title: "Use Current Location",
            titleColor: AppColors.primaryColor,
            subtitle: (_currentAddress != null && _currentAddress!.isNotEmpty)
                ? _currentAddress
                : null,
            onTap: () {
              _onPlaceSelected(
                _currentPosition.latitude,
                _currentPosition.longitude,
                _currentAddress ?? '',
              );
              Navigator.pop(context);
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),

          /// Choose on Map
          _buildActionTile(
            icon: Icons.map_outlined,
            iconBgColor: Colors.orange.withValues(alpha: 0.1),
            iconColor: Colors.orange,
            title: "Choose on Map",
            onTap: () {
              Navigator.pop(context);
            },
          ),

          /// Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Colors.grey.shade200),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: AppColors.grayText),
                      const SizedBox(width: 6),
                      CustomText(
                        "Recent Searches",
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grayText,
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _clearRecentSearches,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: CustomText(
                        "Clear All",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.red00,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ..._recentSearches.asMap().entries.map((entry) {
              final index = entry.key;
              final search = entry.value;
              return Column(
                children: [
                  InkWell(
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
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on_outlined,
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
                          const SizedBox(width: 8),
                          Icon(Icons.north_west,
                              color: Colors.grey.shade400, size: 14),
                        ],
                      ),
                    ),
                  ),
                  if (index < _recentSearches.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 58),
                      child: Divider(
                          height: 1, color: Colors.grey.shade200),
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    CustomText(
                      subtitle,
                      fontSize: 12,
                      color: AppColors.grayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
