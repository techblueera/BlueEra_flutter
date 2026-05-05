import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/model/favorite_location_model.dart';
import 'package:BlueEra/features/common/Discover/repo/favorite_location_repo.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/map_pick_address_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rapido-rider–style "Pickup from / Drop at" search screen.
///
/// Returns `{lat, lng, address}` via Get.back when the user picks an
/// address (from search predictions, recents, favourites or the map).
/// Returns null on back-navigation.
class SearchAddressScreen extends StatefulWidget {
  final bool isPickup;

  /// Used to centre the "Select on map" picker if the user opens it.
  final LatLng? initialMapCenter;

  const SearchAddressScreen({
    super.key,
    required this.isPickup,
    this.initialMapCenter,
  });

  @override
  State<SearchAddressScreen> createState() => _SearchAddressScreenState();
}

class _SearchAddressScreenState extends State<SearchAddressScreen> {
  static const String _recentSearchesKey = 'recent_transport_searches';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  String _searchQuery = '';
  bool _isLoadingPredictions = false;
  List<PlacePrediction> _predictions = [];

  List<Map<String, dynamic>> _recentSearches = [];
  List<FavoriteLocation> _favourites = [];
  bool _isLoadingFavourites = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _onSearchChanged(_searchController.text));
    _loadRecentSearches();
    _loadFavourites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─── Data loaders ───────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_recentSearchesKey) ?? [];
    if (!mounted) return;
    setState(() {
      _recentSearches =
          stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveRecentSearch(double lat, double lng, String address) async {
    if (address.isEmpty) return;
    final entry = {'lat': lat, 'lng': lng, 'address': address};
    _recentSearches.removeWhere((e) => e['address'] == address);
    _recentSearches.insert(0, entry);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchesKey,
      _recentSearches.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<void> _loadFavourites() async {
    setState(() => _isLoadingFavourites = true);
    try {
      final ResponseModel res =
          await FavoriteLocationRepo().listFavorites();
      if (!mounted) return;
      if (res.isSuccess) {
        final data = res.response?.data;
        final list = (data is Map ? data['favorites'] as List? : null) ?? [];
        _favourites = list
            .map((e) => FavoriteLocation.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      log('listFavorites error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFavourites = false);
    }
  }

  // ─── Search ─────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final trimmed = query.trim();
      setState(() => _searchQuery = trimmed);
      if (trimmed.isEmpty) {
        setState(() => _predictions = []);
      } else {
        _fetchPredictions(trimmed);
      }
    });
  }

  Future<void> _fetchPredictions(String query) async {
    setState(() => _isLoadingPredictions = true);
    try {
      final responseModel = await PlaceRepo().autoCompleteSearch(query: query);
      if (!mounted) return;
      if (responseModel.statusCode == 200) {
        final data = responseModel.response?.data;
        final predictionsJson = (data['predictions'] as List?) ?? [];
        final results = PlacePrediction.fromList(predictionsJson);
        setState(() {
          _predictions = results;
          _isLoadingPredictions = false;
        });
        for (final prediction in results) {
          try {
            final detailsResponse = await PlaceRepo()
                .getCompletePlaceDetails(placeId: prediction.placeId ?? '');
            final detailsData = detailsResponse.response?.data;
            final placeDetails = PlaceDetailsResponse.fromJson(detailsData);
            final location = placeDetails.result?.geometry?.location;
            final distance = Geolocator.distanceBetween(
                  LocationService.lat,
                  LocationService.lng,
                  location?.lat ?? 0.0,
                  location?.lng ?? 0.0,
                ) /
                1000;
            prediction.lat = location?.lat ?? 0.0;
            prediction.lng = location?.lng ?? 0.0;
            prediction.distanceInKm = "${distance.toStringAsFixed(1)} km";
          } catch (e) {
            log('Place details error: $e');
          }
        }
        if (mounted) setState(() {});
      } else {
        setState(() {
          _predictions = [];
          _isLoadingPredictions = false;
        });
      }
    } catch (e) {
      log('Autocomplete error: $e');
      if (mounted) {
        setState(() {
          _predictions = [];
          _isLoadingPredictions = false;
        });
      }
    }
  }

  // ─── Pick / submit ──────────────────────────────────────────────────────

  Future<void> _pick(double lat, double lng, String address) async {
    if (address.isNotEmpty) await _saveRecentSearch(lat, lng, address);
    if (!mounted) return;
    Navigator.of(context).pop({
      'lat': lat,
      'lng': lng,
      'address': address,
    });
  }

  Future<void> _openMapPicker() async {
    _searchFocusNode.unfocus();
    final start =
        widget.initialMapCenter ?? _bestKnownCenter();
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MapPickAddressScreen(
          initialLatLng: start,
          isPickup: widget.isPickup,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final lat = (result['lat'] as num?)?.toDouble();
    final lng = (result['lng'] as num?)?.toDouble();
    final address = (result['address'] as String?) ?? '';
    if (lat == null || lng == null) return;
    await _pick(lat, lng, address);
  }

  LatLng _bestKnownCenter() {
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    if (lat != 0.0 && lng != 0.0) return LatLng(lat, lng);
    return const LatLng(26.7836, 80.9013);
  }

  // ─── Favourites toggle ──────────────────────────────────────────────────

  bool _isFavourited(String address) {
    return _favourites.any((f) => f.address == address);
  }

  FavoriteLocation? _findFavourite(String address) {
    for (final f in _favourites) {
      if (f.address == address) return f;
    }
    return null;
  }

  Future<void> _toggleFavourite({
    required double lat,
    required double lng,
    required String address,
  }) async {
    if (address.isEmpty) {
      commonSnackBar(message: 'Address is empty.');
      return;
    }
    final existing = _findFavourite(address);
    if (existing != null) {
      // Already a favourite — remove it.
      try {
        final res = await FavoriteLocationRepo().deleteFavorite(existing.id);
        if (!mounted) return;
        if (res.isSuccess) {
          setState(() => _favourites.removeWhere((f) => f.id == existing.id));
          commonSnackBar(message: 'Removed from favourites');
        } else {
          commonSnackBar(message: res.message ?? 'Could not remove favourite');
        }
      } catch (e) {
        log('deleteFavorite error: $e');
        if (mounted) commonSnackBar(message: 'Could not remove favourite');
      }
      return;
    }
    // Open the bottom sheet to choose tag and save.
    final saved = await showModalBottomSheet<FavoriteLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToFavouritesSheet(
        address: address,
        latitude: lat,
        longitude: lng,
      ),
    );
    if (!mounted || saved == null) return;
    setState(() => _favourites.insert(0, saved));
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title = widget.isPickup ? 'Pickup from' : 'Drop at';
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: CustomText(
          title,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
      ),
      body: SafeArea(
        child: Column(
        children: [
          _buildSearchRow(),
          const SizedBox(height: 12),
          _buildSelectOnMapPill(),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.greenShade, width: 3),
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grayText.withValues(alpha: 0.4)),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: InputBorder.none,
                  hintText: '',
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: AppColors.grayText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _predictions = [];
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectOnMapPill() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _openMapPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.grayText.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.black),
                SizedBox(width: 6),
                CustomText(
                  'Select on map',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final showingPredictions =
        _searchQuery.isNotEmpty || _isLoadingPredictions;

    if (showingPredictions) {
      if (_isLoadingPredictions) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
              ),
            ),
          ),
        );
      }
      if (_predictions.isEmpty) {
        return _emptyTextCenter('No results found');
      }
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _predictions.length,
        separatorBuilder: (_, __) => _dashedDivider(),
        itemBuilder: (context, i) => _buildPredictionTile(_predictions[i]),
      );
    }

    // Default: favourites + recents.
    final children = <Widget>[];
    if (_isLoadingFavourites) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        ),
      ));
    }
    for (final fav in _favourites) {
      children.add(_buildFavouriteTile(fav));
      children.add(_dashedDivider());
    }
    for (final r in _recentSearches) {
      children.add(_buildRecentTile(r));
      children.add(_dashedDivider());
    }
    if (children.isEmpty) {
      children.add(_emptyTextCenter(
          'Search a place above or use “Select on map”.'));
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  Widget _emptyTextCenter(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: CustomText(
            text,
            fontSize: 13,
            color: AppColors.grayText,
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _dashedDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedLinePainter(
            color: AppColors.grayText.withValues(alpha: 0.35),
          ),
        ),
      );

  IconData _iconForTag(String tag) {
    switch (tag) {
      case 'home':
        return Icons.home_outlined;
      case 'office':
      case 'work':
        return Icons.business_center_outlined;
      case 'hostel':
        return Icons.apartment_outlined;
      case 'gym':
        return Icons.fitness_center_outlined;
      case 'college':
      case 'school':
        return Icons.school_outlined;
      default:
        return Icons.bookmark_outline;
    }
  }

  Widget _buildFavouriteTile(FavoriteLocation fav) {
    return InkWell(
      onTap: () => _pick(fav.latitude, fav.longitude, fav.address),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(_iconForTag(fav.tag),
                  size: 22, color: AppColors.black),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    fav.displayTitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    fav.address,
                    fontSize: 12,
                    color: AppColors.grayText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _toggleFavourite(
                lat: fav.latitude,
                lng: fav.longitude,
                address: fav.address,
              ),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.favorite,
                    color: Color(0xFFE53935), size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTile(Map<String, dynamic> search) {
    final lat = (search['lat'] as num).toDouble();
    final lng = (search['lng'] as num).toDouble();
    final address = (search['address'] as String?) ?? '';
    final favourited = _isFavourited(address);
    return InkWell(
      onTap: () => _pick(lat, lng, address),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.access_time,
                  size: 22, color: AppColors.grayText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _addressTwoLine(address),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _toggleFavourite(
                lat: lat,
                lng: lng,
                address: address,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  favourited ? Icons.favorite : Icons.favorite_border,
                  color:
                      favourited ? const Color(0xFFE53935) : AppColors.grayText,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionTile(PlacePrediction p) {
    final desc = p.description ?? '';
    final lat = p.lat ?? 0.0;
    final lng = p.lng ?? 0.0;
    final favourited = _isFavourited(desc);
    return InkWell(
      onTap: () {
        if (lat == 0.0 && lng == 0.0) return;
        _pick(lat, lng, desc);
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on,
                      size: 22, color: AppColors.black),
                  if ((p.distanceInKm ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      p.distanceInKm ?? '',
                      fontSize: 11,
                      color: AppColors.grayText,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(child: _addressTwoLine(desc)),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _toggleFavourite(
                lat: lat,
                lng: lng,
                address: desc,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  favourited ? Icons.favorite : Icons.favorite_border,
                  color:
                      favourited ? const Color(0xFFE53935) : AppColors.grayText,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressTwoLine(String address) {
    final parts = address.split(',');
    final title = parts.isNotEmpty ? parts.first.trim() : address;
    final rest = parts.length > 1
        ? parts.sublist(1).join(',').trim()
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title.isEmpty ? address : title,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 4),
          CustomText(
            rest,
            fontSize: 12,
            color: AppColors.grayText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet shown when the user taps the heart icon to add a place
/// to favourites. Returns the saved [FavoriteLocation] on success.
class _AddToFavouritesSheet extends StatefulWidget {
  final String address;
  final double latitude;
  final double longitude;

  const _AddToFavouritesSheet({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<_AddToFavouritesSheet> createState() => _AddToFavouritesSheetState();
}

class _AddToFavouritesSheetState extends State<_AddToFavouritesSheet> {
  String? _selectedTag;
  String? _customTag;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.greyE5,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const CustomText(
                  'Add to favourites',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
                const SizedBox(height: 12),
                _addressCard(),
                const SizedBox(height: 16),
                CustomText(
                  'SAVE LOCATION AS',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tagChip('home', 'Home', Icons.home_outlined),
                    _tagChip('office', 'Office',
                        Icons.business_center_outlined),
                    _tagChip('hostel', 'Hostel', Icons.apartment_outlined),
                    _addNewChip(),
                  ],
                ),
                const SizedBox(height: 16),
                _submitButton(),
              ],
            ),
          ),
          Positioned(
            top: -52,
            right: 0,
            child: Material(
              color: AppColors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close,
                      size: 20, color: AppColors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.greenShade, width: 3),
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              widget.address,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String tag, String label, IconData icon) {
    final selected = _selectedTag == tag;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() {
        _selectedTag = tag;
        _customTag = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor
              : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : AppColors.grayText.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppColors.white : AppColors.primaryColor),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _addNewChip() {
    final selected = _selectedTag == '__custom__';
    final label = selected && (_customTag?.isNotEmpty ?? false)
        ? _customTag!
        : 'Add New';
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _promptCustom,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : AppColors.grayText.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add,
                size: 16,
                color: selected ? AppColors.white : AppColors.primaryColor),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.black,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptCustom() async {
    final controller =
        TextEditingController(text: _selectedTag == '__custom__' ? _customTag : '');
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const CustomText(
          'Save as',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Mom\'s house',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const CustomText('Cancel', color: AppColors.grayText),
          ),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isEmpty) return;
              Navigator.of(ctx).pop(v);
            },
            child: const CustomText('OK',
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (tag != null && tag.isNotEmpty) {
      setState(() {
        _selectedTag = '__custom__';
        _customTag = tag;
      });
    }
  }

  Widget _submitButton() {
    final canSave = _selectedTag != null && !_saving;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSave ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              )
            : const CustomText(
                'Add to favourite',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
      ),
    );
  }

  Future<void> _save() async {
    final tag = _selectedTag == '__custom__' ? (_customTag ?? '') : _selectedTag;
    if (tag == null || tag.isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await FavoriteLocationRepo().addFavoriteLocation(
        address: widget.address,
        latitude: widget.latitude,
        longitude: widget.longitude,
        tag: tag,
      );
      if (!mounted) return;
      if (res.isSuccess) {
        final data = res.response?.data;
        FavoriteLocation? created;
        if (data is Map) {
          // Server may return either the FavoriteLocation directly or
          // nested under a 'favorite' key.
          final raw = data.containsKey('_id') || data.containsKey('id')
              ? data
              : (data['favorite'] as Map?);
          if (raw != null) {
            created = FavoriteLocation.fromJson(
                Map<String, dynamic>.from(raw));
          }
        }
        // Fall back to a locally-built model so the caller can update
        // its list immediately even if the server response shape differs.
        created ??= FavoriteLocation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          address: widget.address,
          latitude: widget.latitude,
          longitude: widget.longitude,
          tag: tag,
          isCustomTag: _selectedTag == '__custom__',
        );
        commonSnackBar(message: 'Added to favourites');
        Navigator.of(context).pop(created);
      } else {
        commonSnackBar(message: res.message ?? 'Could not save favourite');
      }
    } catch (e) {
      log('addFavoriteLocation error: $e');
      if (mounted) commonSnackBar(message: 'Could not save favourite');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
