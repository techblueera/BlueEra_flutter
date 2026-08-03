import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_map_widgets.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/rental/controller/property_discover_controller.dart';
import 'package:BlueEra/features/common/rental/controller/property_filter_registry.dart';
import 'package:BlueEra/features/common/rental/view/property_details_screen.dart';
import 'package:BlueEra/features/common/rental/view/rental_services_dashboard_screen_v2.dart';
import 'package:BlueEra/features/common/rental/widget/property_filter_sheet.dart';
import 'package:BlueEra/features/common/rental/widget/property_listing_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyDiscoverScreen extends StatefulWidget {
  final int initialCategoryIndex;

  const PropertyDiscoverScreen({super.key, this.initialCategoryIndex = 0});

  @override
  State<PropertyDiscoverScreen> createState() =>
      _PropertyDiscoverScreenState();
}

class _PropertyDiscoverScreenState extends State<PropertyDiscoverScreen> {
  late final PropertyDiscoverController _ctrl;
  final _scrollController = ScrollController();
  bool _showFab = true;

  static final _categories = propertyDiscoverTiles
      .map((t) => PropertyDiscoverCategory(
    label: t.label,
    listingType: t.listingType,
    propertyType: t.propertyType,
    image: t.image,
    isSale: t.isSale,
  ))
      .toList();

  List<String> get _stickyLabels => [
    AppStrings.housesSell.tr,
    AppStrings.housesRent.tr,
    AppStrings.newProjects.tr,
    AppStrings.landsSell.tr,
    AppStrings.shopsRent.tr,
    AppStrings.shopsSell.tr,
    AppStrings.landsRent.tr,
    AppStrings.pgAndGuest.tr,
  ];

  List<StickyCategory> get _stickyCategories => _categories
      .asMap()
      .entries
      .map((e) => StickyCategory(
    id: '${e.value.listingType}_${e.value.propertyType}',
    name: _stickyLabels[e.key],
    imageUrl: e.value.image,
  ))
      .toList();

  String get _selectedStickyId {
    final cat = _categories[_ctrl.selectedCategoryIndex.value];
    return '${cat.listingType}_${cat.propertyType}';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = getOrPut(() => PropertyDiscoverController());
    _ctrl.initWithCategories(_categories, widget.initialCategoryIndex);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _ctrl.fetchProperties(isLoadMore: true);
      }
      final direction = _scrollController.position.userScrollDirection;
      if (direction == ScrollDirection.reverse && _showFab) {
        setState(() => _showFab = false);
      } else if (direction == ScrollDirection.forward && !_showFab) {
        setState(() => _showFab = true);
      }
    });
  }

  void _openPropertyMapScreen() {
    _ctrl.fetchAllForMap();
    Get.to(() => const _PropertyMapScreen());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: isIndividualUser()
            ? AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: _showFab ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _showFab ? 1.0 : 0.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primaryColor.withValues(alpha: 0.75),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.to(
                              () => const RentalServicesDashboardScreenV2()),
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.white.withValues(alpha: 0.15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_home_rounded,
                                size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            CustomText(
                              AppStrings.listYourProperty.tr,
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
            : null,
        body: Obx(() {
          _ctrl.selectedCategoryIndex.value;
          _ctrl.properties.length;
          _ctrl.totalCount.value;
          _ctrl.isLoading.value;
          _ctrl.isLoadingMore.value;
          _ctrl.activeFilterCount;
          _ctrl.sortBy.value;

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: DiscoverMapPreview(
                  statusBarHeight: statusBarHeight,
                  onTap: _openPropertyMapScreen,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyCategoryHeaderDelegate(
                  topPadding: statusBarHeight,
                  categories: _stickyCategories,
                  selectedId: _selectedStickyId,
                  onCategoryTap: (item) {
                    final idx = _stickyCategories
                        .indexWhere((c) => c.id == item.id);
                    if (idx >= 0) _ctrl.selectCategory(idx);
                    setState(() {});
                  },
                  onBack: () => Navigator.pop(context),
                  expandedLabelColor: AppColors.white,
                  backgroundGradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.blue5CAF.withValues(alpha: 0.1),
                      AppColors.blue5CAF.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildFilterStrip()),
              _buildListSliver(),
            ],
          );
        }),
      ),
    );
  }

  /// FilterIds surfaced as quick-access dropdown chips in the strip
  /// (in order). Only those visible for the current category render;
  /// each opens the filter sheet pre-scrolled to its own section.
  static const _quickChipIds = [
    FilterId.bhk,
    FilterId.houseApartmentType,
    FilterId.typeOfProperty,
    FilterId.listedBy,
    FilterId.furnishing,
  ];

  Widget _buildFilterStrip() {
    final filterCount = _ctrl.activeFilterCount;
    final sort = _ctrl.sortBy.value;
    final isSortActive = sort != PropertySortBy.relevance;
    final cat = _ctrl.categories[_ctrl.selectedCategoryIndex.value];
    final cityLabel =
    _ctrl.city.value.isNotEmpty ? _ctrl.city.value : AppStrings.yourArea.tr;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick filter pills (99acres-style strip) ──
          Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
              child: Row(
                children: [
                  // Leading filter icon → opens the full sheet.
                  _filterIconButton(filterCount),
                  const SizedBox(width: 8),
                  // Sort stays on the strip (not inside the filter sheet).
                  _sortChip(sort, isSortActive),
                  const SizedBox(width: 8),
                  _quickChip(
                    label: _budgetChipLabel(),
                    isActive: _ctrl.minPrice.value.isNotEmpty ||
                        _ctrl.maxPrice.value.isNotEmpty,
                    onTap: () => _showFilterSheet(initialKey: 'budget'),
                  ),
                  for (final id in _quickChipIds)
                    if (_isFilterVisible(id)) ...[
                      const SizedBox(width: 8),
                      _quickChipForFilter(id),
                    ],
                ],
              ),
            ),
          ),
          // ── "537 RESULTS | Property in Durgapur for Sale" line ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size14,
              0,
              SizeConfig.size14,
              SizeConfig.size10,
            ),
            child: Row(
              children: [
                CustomText(
                  '${_ctrl.totalCount.value} ${AppStrings.resultsCaps.tr}',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 12,
                  color: const Color(0xFFDDE2EE),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    AppStrings.propertyInForFmt.trParams({
                      'city': cityLabel,
                      'type': cat.isSale ? AppStrings.sale.tr : AppStrings.rent.tr,
                    }),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEFEFEF)),
        ],
      ),
    );
  }

  bool _isFilterVisible(FilterId id) =>
      _ctrl.visibleFilterDefs.any((d) => d.id == id);

  String _budgetChipLabel() {
    final min = _ctrl.minPrice.value;
    final max = _ctrl.maxPrice.value;
    if (min.isNotEmpty && max.isNotEmpty) return '₹$min - ₹$max';
    if (min.isNotEmpty) return '${AppStrings.minPrefix.tr} ₹$min';
    if (max.isNotEmpty) return '${AppStrings.maxPrefix.tr} ₹$max';
    return AppStrings.budget.tr;
  }

  /// Quick chip for a registry filter — shows the picked value when set,
  /// otherwise the filter's label. Deep-links the sheet to its section.
  Widget _quickChipForFilter(FilterId id) {
    final def = _ctrl.visibleFilterDefs.firstWhere((d) => d.id == id);
    final values = _ctrl.currentFilterValues[id] ?? const <String>[];
    final hasValue = values.isNotEmpty;
    return _quickChip(
      label: hasValue ? _quickValueLabel(id, values) : def.label,
      isActive: hasValue,
      onTap: () => _showFilterSheet(initialKey: id.name),
    );
  }

  /// Compact label for a multi-select quick chip: the first picked
  /// value, plus a "+N" tail when more than one is selected.
  String _quickValueLabel(FilterId id, List<String> values) {
    final first = chipLabelFor(id, values.first);
    return values.length == 1 ? first : '$first +${values.length - 1}';
  }

  Widget _filterIconButton(int count) {
    final active = count > 0;
    return GestureDetector(
      onTap: () => _showFilterSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primaryColor : const Color(0xFFDDE2EE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 16,
                color: active ? Colors.white : AppColors.mainTextColor),
            if (active) ...[
              const SizedBox(width: 5),
              CustomText('$count',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sortChip(PropertySortBy sort, bool isActive) {
    final fg = isActive ? AppColors.primaryColor : AppColors.mainTextColor;
    return GestureDetector(
      onTap: _showSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryColor : const Color(0xFFDDE2EE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 16, color: fg),
            const SizedBox(width: 4),
            CustomText(sort.chipLabel,
                fontSize: 13, fontWeight: FontWeight.w600, color: fg),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          ],
        ),
      ),
    );
  }

  /// Generic dropdown-style quick chip with a trailing chevron.
  Widget _quickChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final fg = isActive ? AppColors.primaryColor : AppColors.mainTextColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryColor : const Color(0xFFDDE2EE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(label,
                fontSize: 13, fontWeight: FontWeight.w600, color: fg),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          ],
        ),
      ),
    );
  }

  /// Sheet listing the available [PropertySortBy] options as a radio
  /// group with a "Done" button (matches the design). Selection is held
  /// locally and only applied to the controller when Done is tapped.
  void _showSortSheet() {
    const options = PropertySortBy.values;
    PropertySortBy local = _ctrl.sortBy.value;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setLocal) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            AppStrings.sortByTitle.tr,
                            fontSize: SizeConfig.large18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF4F6FA),
                              border:
                              Border.all(color: const Color(0xFFDDE2EE)),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF505050)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  for (final option in options)
                    InkWell(
                      onTap: () => setLocal(() => local = option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            _radio(local == option),
                            const SizedBox(width: 14),
                            Expanded(
                              child: CustomText(
                                option.label,
                                fontSize: SizeConfig.medium,
                                fontWeight: local == option
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: AppColors.mainTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          _ctrl.setSort(local);
                          Get.back();
                        },
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CustomText(
                            'done'.tr,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  /// Radio indicator used in the sort sheet.
  Widget _radio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primaryColor : const Color(0xFFBDBDBD),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor,
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildListSliver() {
    if (_ctrl.isLoading.value && _ctrl.properties.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ctrl.properties.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmpty(),
      );
    }

    final list = _ctrl.properties;
    final showMoreLoader = _ctrl.isLoadingMore.value;

    return SliverPadding(
      padding: EdgeInsets.only(
        left: SizeConfig.size8,
        right: SizeConfig.size8,
        top: SizeConfig.size10,
        bottom: SizeConfig.size24,
      ),
      sliver: SliverList.builder(
        itemCount: list.length + (showMoreLoader ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == list.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.size10),
            child: PropertyListingCard(
              property: list[i],
              onTap: () => Get.to(() => PropertyDetailsScreen(
                property: list[i],
                isOwner: false,
              )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    final hasFilters = _ctrl.hasActiveFilters;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size32,
          vertical: SizeConfig.size24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(
                hasFilters
                    ? Icons.filter_alt_off_outlined
                    : Icons.search_off_rounded,
                size: 48,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            CustomText(
              hasFilters
                  ? AppStrings.noMatchingProperties.tr
                  : AppStrings.noPropertiesAvailable.tr,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            CustomText(
              hasFilters
                  ? AppStrings.noPropertiesMatchingHint.tr
                  : AppStrings.noPropertiesInCategoryHint.tr,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              InkWell(
                onTap: () => _ctrl.clearFilters(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomText(
                    AppStrings.clearAllFilters.tr,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Opens the tabbed filter sheet. [initialKey] deep-links to a
  /// section (`'budget'`, `'locality'`, or a [FilterId.name]) so a
  /// quick chip lands the user straight on the relevant tab.
  void _showFilterSheet({String? initialKey}) {
    Get.bottomSheet(
      PropertyFilterSheet(
        controller: _ctrl,
        initialSectionKey: initialKey,
      ),
      isScrollControlled: true,
    );
  }
}

class _PropertyMapScreen extends StatefulWidget {
  const _PropertyMapScreen();

  @override
  State<_PropertyMapScreen> createState() => _PropertyMapScreenState();
}

class _PropertyMapScreenState extends State<_PropertyMapScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _propertyIcon;

  final PropertyDiscoverController _ctrl =
  Get.find<PropertyDiscoverController>();
  static const ClusterManagerId _clusterManagerId =
  ClusterManagerId('property_listings');

  @override
  void initState() {
    super.initState();
    DiscoverMarkerIcons.circleBitmap(icon: Icons.home_work_outlined).then((d) {
      if (mounted) setState(() => _propertyIcon = d);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (final p in _ctrl.mapProperties) {
      final coords = p.location?.coordinates;
      if (coords == null || coords.isEmpty) continue;
      final lng = coords.length > 0 ? coords[0] : 0.0;
      final lat = coords.length > 1 ? coords[1] : 0.0;
      if (lat == 0 && lng == 0) continue;
      markers.add(
        Marker(
          markerId: MarkerId(p.id ?? '${p.propertyName}_$lat,$lng'),
          position: LatLng(lat, lng),
          clusterManagerId: _clusterManagerId,
          icon: _propertyIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: p.propertyName,
            snippet: p.formattedPrice,
            onTap: () => Get.to(() => PropertyDetailsScreen(
              property: p,
              isOwner: false,
            )),
          ),
          onTap: () => Get.to(() => PropertyDetailsScreen(
            property: p,
            isOwner: false,
          )),
        ),
      );
    }
    return markers;
  }

  Future<void> _zoomToCluster(Cluster cluster) async {
    if (_mapController == null) return;
    if (cluster.markerIds.length <= 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(cluster.position, 15),
      );
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(cluster.bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLat =
    LocationService.lat != 0.0 ? LocationService.lat : 28.6139;
    final initialLng =
    LocationService.lng != 0.0 ? LocationService.lng : 77.2090;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            _ctrl.mapProperties.length;
            final markers = _buildMarkers();
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(initialLat, initialLng),
                zoom: 12,
              ),
              markers: markers,
              clusterManagers: {
                ClusterManager(
                  clusterManagerId: _clusterManagerId,
                  onClusterTap: _zoomToCluster,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (c) => _mapController = c,
            );
          }),
          Obx(() {
            if (!_ctrl.isMapLoading.value) return const SizedBox.shrink();
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }),
          Positioned(
            top: statusBarHeight + SizeConfig.size4,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                bannerMapCircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(child: bannerMapLocationPill()),
                SizedBox(width: SizeConfig.size8),
                bannerMapCircleIconButton(
                  icon: Icons.my_location,
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(initialLat, initialLng),
                        13,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final count = _ctrl.mapProperties.where((p) {
                final c = p.location?.coordinates;
                return c != null &&
                    c.length >= 2 &&
                    !(c[0] == 0 && c[1] == 0);
              }).length;
              return Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          '$count ${AppStrings.propertiesOnMapSuffix.tr}',
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

