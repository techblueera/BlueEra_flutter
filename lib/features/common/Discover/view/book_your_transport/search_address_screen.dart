import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/search_address_controller.dart';
import 'package:BlueEra/features/common/Discover/model/favorite_location_model.dart';
import 'package:BlueEra/features/common/Discover/service/favourite_location_service.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/map_pick_address_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';

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
  final SearchAddressController controller =
      Get.find<SearchAddressController>();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController
        .addListener(() => controller.onQueryChanged(_searchController.text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─── Search ─────────────────────────────────────────────────────────────

  /// Resolve the tapped prediction's coordinates, then pick it.
  Future<void> _selectPrediction(PlacePrediction p) async {
    final resolved = await controller.selectPrediction(p);
    if (!mounted || resolved == null) return; // a second tap mid-lookup
    if (!resolved) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    await _pick(p.lat!, p.lng!, p.description ?? '');
  }

//  ─── Pick / submit ──────────────────────────────────────────────────────

  Future<void> _pick(double lat, double lng, String address) async {
    if (address.isNotEmpty) {
      await controller.saveRecentSearch(lat, lng, address);
    }
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

  Future<void> _toggleFavourite({
    required double lat,
    required double lng,
    required String address,
  }) async {
    if (address.isEmpty) {
      commonSnackBar(message: AppStrings.addressIsEmpty.tr);
      return;
    }
    final existing = controller.findFavourite(address);
    if (existing != null) {
      // Already a favourite — remove it.
      final error = await controller.removeFavourite(existing);
      if (!mounted) return;
      commonSnackBar(
          message: error == null
              ? AppStrings.removedFromFavourites.tr
              : (error.isNotEmpty
                  ? error
                  : AppStrings.couldNotRemoveFavourite.tr));
      return;
    }
    // Open the bottom sheet to choose a tag and save; the sheet adds it to
    // the controller's list.
    await showModalBottomSheet<FavoriteLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToFavouritesSheet(
        address: address,
        latitude: lat,
        longitude: lng,
      ),
    );
  }


  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title = widget.isPickup ? AppStrings.pickupFromTitle.tr : AppStrings.dropAtTitle.tr;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
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
          // The clear button shows once the (debounced) query is non-empty.
          Obx(() {
            controller.searchQuery.value;
            return _buildSearchRow();
          }),
          const SizedBox(height: 12),
          _buildSelectOnMapPill(),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(child: Obx(_buildList)),
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
                            controller.clearSearch();
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
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.black),
                const SizedBox(width: 6),
                CustomText(
                  AppStrings.selectOnMap.tr,
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
    // Read everything the rows use up front: ListView builds its rows lazily,
    // outside the Obx that wraps this, so reads there would not be tracked.
    final predictions = controller.predictions.toList();
    controller.resolvingPlaceId.value;
    controller.favourites.length;

    final showingPredictions =
        controller.searchQuery.value.isNotEmpty ||
        controller.isLoadingPredictions.value;

    if (showingPredictions) {
      if (controller.isLoadingPredictions.value) {
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
      if (predictions.isEmpty) {
        return _emptyTextCenter(AppStrings.noResultsFound.tr);
      }
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: predictions.length,
        separatorBuilder: (_, __) => _dashedDivider(),
        itemBuilder: (context, i) => _buildPredictionTile(predictions[i]),
      );
    }

    // Default: favourites + recents.
    final children = <Widget>[];
    if (controller.isLoadingFavourites.value) {
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
    for (final fav in controller.favourites) {
      children.add(_buildFavouriteTile(fav));
      children.add(_dashedDivider());
    }
    for (final r in controller.recentSearches) {
      children.add(_buildRecentTile(r));
      children.add(_dashedDivider());
    }
    if (children.isEmpty) {
      children.add(_emptyTextCenter(AppStrings.searchPlaceAboveHint.tr));
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
    final favourited = controller.isFavourited(address);
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
    final favourited = controller.isFavourited(desc);
    final resolving = controller.resolvingPlaceId.value != null &&
        controller.resolvingPlaceId.value == p.placeId;
    // Coordinates are no longer pre-fetched for the list, so the tap resolves
    // them — see [_selectPrediction]. The distance column that used to sit under
    // this icon went with that pre-fetch; nearby results now come back first
    // because the autocomplete request is location-biased.
    return InkWell(
      onTap: resolving ? null : () => _selectPrediction(p),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                      ),
                    )
                  : const Icon(Icons.location_on,
                      size: 22, color: AppColors.black),
            ),
            const SizedBox(width: 6),
            Expanded(child: _addressTwoLine(desc)),
            const SizedBox(width: 8),
            InkWell(
              // Favouriting needs coordinates too, and this row may not have
              // been resolved yet — so resolve on demand here as well (cached,
              // so favouriting then picking the same row costs one lookup).
              onTap: () async {
                if (!await controller.resolveCoordinates(p) || !mounted) {
                  return;
                }
                _toggleFavourite(lat: p.lat!, lng: p.lng!, address: desc);
              },
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
                CustomText(
                  AppStrings.addToFavourites.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
                const SizedBox(height: 12),
                _addressCard(),
                const SizedBox(height: 16),
                CustomText(
                  AppStrings.saveLocationAs.tr,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tagChip('home', AppStrings.home.tr, Icons.home_outlined),
                    _tagChip('office', AppStrings.office.tr,
                        Icons.business_center_outlined),
                    _tagChip('hostel', AppStrings.hostel.tr, Icons.apartment_outlined),
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
        : AppStrings.addNew.tr;
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
        title: CustomText(
          AppStrings.saveAsTitle.tr,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings.momsHouseExample.tr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: CustomText(AppStrings.cancel.tr, color: AppColors.grayText),
          ),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isEmpty) return;
              Navigator.of(ctx).pop(v);
            },
            child: CustomText(AppStrings.ok.tr,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (tag != null && tag.isNotEmpty) {
      if (!mounted) return;
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
            : CustomText(
                AppStrings.addToFavouriteButton.tr,
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
      final created = await Get.find<SearchAddressController>().addFavourite(
        address: widget.address,
        latitude: widget.latitude,
        longitude: widget.longitude,
        tag: tag,
        isCustomTag: _selectedTag == '__custom__',
      );
      if (!mounted) return;
      commonSnackBar(message: AppStrings.addedToFavourites.tr);
      Navigator.of(context).pop(created);
    } on FavouriteSaveError catch (e) {
      if (mounted) {
        commonSnackBar(
            message: e.message ?? AppStrings.couldNotSaveFavourite.tr);
      }
    } catch (e) {
      log('addFavoriteLocation error: $e');
      if (mounted) commonSnackBar(message: AppStrings.couldNotSaveFavourite.tr);
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
