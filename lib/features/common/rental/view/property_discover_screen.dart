import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_map_widgets.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/controller/property_discover_controller.dart';
import 'package:BlueEra/features/common/rental/view/property_details_screen.dart';
import 'package:BlueEra/features/common/rental/view/rental_services_dashboard_screen_v2.dart';
import 'package:BlueEra/features/common/rental/widget/property_listing_card.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
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

  static const _stickyLabels = [
    'Houses Sell',
    'Houses Rent',
    'New Projects',
    'Lands Sell',
    'Shops Rent',
    'Shops Sell',
    'Lands Rent',
    'PG & Guest',
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
    _ctrl = Get.put(PropertyDiscoverController());
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
        backgroundColor: AppColors.appBackgroundColor,
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
                                'List Your Property',
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

  Widget _buildFilterStrip() {
    final filterCount = _ctrl.activeFilterCount;
    final applied = _ctrl.activeFilters;
    final sort = _ctrl.sortBy.value;
    final isSortActive = sort != PropertySortBy.none;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
        child: Row(
          children: [
            _filterChip(
              icon: Icons.tune_rounded,
              label: filterCount > 0 ? 'Filters ($filterCount)' : 'Filters',
              isActive: filterCount > 0,
              onTap: _showFilterSheet,
            ),
            const SizedBox(width: 8),
            // Sort chip — opens a bottom sheet with price/distance/rating
            // options. Active when anything other than Default is chosen.
            _filterChip(
              icon: Icons.swap_vert_rounded,
              label: sort.chipLabel,
              isActive: isSortActive,
              onTap: _showSortSheet,
            ),
            // One removable chip per active filter so the user can see
            // exactly what's applied and drop a single one without
            // re-opening the sheet.
            for (final f in applied) ...[
              const SizedBox(width: 8),
              _appliedFilterChip(
                label: f.label,
                onRemove: () => _ctrl.removeFilter(f.key),
              ),
            ],
            if (_ctrl.hasActiveFilters) ...[
              const SizedBox(width: 8),
              _filterChip(
                icon: Icons.close,
                label: 'Clear All',
                isActive: false,
                isDestructive: true,
                onTap: () => _ctrl.clearFilters(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sheet listing the available [PropertySortBy] options. Single-select;
  /// tapping a row applies the sort immediately and dismisses.
  void _showSortSheet() {
    const options = PropertySortBy.values;
    Get.bottomSheet(
      Container(
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE2EE),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            'Sort By',
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
                              border: Border.all(
                                  color: const Color(0xFFDDE2EE)),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF505050)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              for (final option in options)
                Obx(() {
                  final selected = _ctrl.sortBy.value == option;
                  return InkWell(
                    onTap: () {
                      _ctrl.setSort(option);
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              option.label,
                              fontSize: SizeConfig.medium,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primaryColor
                                  : AppColors.mainTextColor,
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_rounded,
                                size: 20, color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Pill showing one applied filter's value with a tap-to-remove (×)
  /// icon. Uses a subtle primary-tinted fill so it visually links back
  /// to the active "Filters (n)" chip on the left.
  Widget _appliedFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(label,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor),
            const SizedBox(width: 6),
            Icon(Icons.close_rounded,
                size: 14, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color fg;
    final Color bg;
    final Color border;
    if (isDestructive) {
      fg = AppColors.redB4;
      bg = Colors.white;
      border = AppColors.redB4.withValues(alpha: 0.3);
    } else if (isActive) {
      fg = Colors.white;
      bg = AppColors.primaryColor;
      border = AppColors.primaryColor;
    } else {
      fg = AppColors.secondaryTextColor;
      bg = Colors.white;
      border = const Color(0xFFDDE2EE);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            CustomText(label, fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ],
        ),
      ),
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
                  ? 'No matching properties'
                  : 'No properties available',
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            CustomText(
              hasFilters
                  ? 'We couldn\'t find properties matching your filters. Try adjusting or clearing them.'
                  : 'There are no properties listed in this category yet. Check back later or explore other categories.',
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
                    'Clear All Filters',
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

  void _showFilterSheet() {
    final cityCtrl = TextEditingController(text: _ctrl.city.value);
    final minCtrl = TextEditingController(text: _ctrl.minPrice.value);
    final maxCtrl = TextEditingController(text: _ctrl.maxPrice.value);

    // House filters
    int bhkIdx = _chipIdx(PropertyController.bhkOptions, _ctrl.filterBhk.value);
    int bathIdx = _chipIdx(PropertyController.bathroomOptions, _ctrl.filterBathrooms.value);
    int faceIdx = _chipIdx(PropertyController.facingOptions, _ctrl.filterFacing.value);
    int parkIdx = _chipIdx(PropertyController.parkingOptions, _ctrl.filterCarParking.value);

    // Shop filters
    int furnIdx = _chipIdx(PropertyController.furnishingOptions, _ctrl.filterFurnishing.value);

    // PG filters
    int subIdx = _chipIdx(PropertyController.pgSubtypeOptions, _ctrl.filterSubType.value);
    int mealIdx = _chipIdx(PropertyController.mealsOptions, _ctrl.filterMealsIncluded.value);

    // New project filters
    int statusIdx = _chipIdx(PropertyController.availabilityOptions, _ctrl.filterProjectStatus.value);
    int propTypeIdx = _chipIdx(PropertyController.npPropertyTypeOptions, _ctrl.filterTypeOfProperty.value);

    final propType = _ctrl.currentPropertyType;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE2EE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          'Filter Properties',
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
                            border: Border.all(
                                color: const Color(0xFFDDE2EE)),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFF505050)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── City ──
                    RentalLabeledField(
                      label: 'City',
                      hint: 'E.g. Mumbai, Delhi...',
                      controller: cityCtrl,
                    ),
                    const SizedBox(height: 14),

                    // ── Price ──
                    Row(
                      children: [
                        Expanded(
                          child: RentalLabeledField(
                            label: 'Min Price',
                            hint: '5000',
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RentalLabeledField(
                            label: 'Max Price',
                            hint: '50000',
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    // ── Type-specific filters ──
                    if (propType == 'HouseAndApartment') ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),
                      RentalChipSelector(
                        label: 'BHK',
                        options: const ['All', ...['1', '2', '3', '4+']],
                        initialIndex: bhkIdx,
                        onChanged: (i) => bhkIdx = i,
                      ),
                      const SizedBox(height: 14),
                      RentalChipSelector(
                        label: 'Bathrooms',
                        options: const ['All', ...['1', '2', '3', '4+']],
                        initialIndex: bathIdx,
                        onChanged: (i) => bathIdx = i,
                      ),
                      const SizedBox(height: 14),
                      RentalChipSelector(
                        label: 'Facing',
                        options: const ['All', ...['North', 'South', 'East', 'West', 'North-East', 'North-West', 'South-East', 'South-West']],
                        initialIndex: faceIdx,
                        onChanged: (i) => faceIdx = i,
                      ),
                      const SizedBox(height: 14),
                      RentalChipSelector(
                        label: 'Car Parking',
                        options: const ['All', ...['1', '2', '3', '4+']],
                        initialIndex: parkIdx,
                        onChanged: (i) => parkIdx = i,
                      ),
                    ],

                    if (propType == 'ShopAndOffices') ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),
                      RentalChipSelector(
                        label: 'Furnishing',
                        options: const ['All', ...['Furnished', 'Semi-Furnished', 'Unfurnished']],
                        initialIndex: furnIdx,
                        onChanged: (i) => furnIdx = i,
                      ),
                    ],

                    if (propType == 'PGAndGuestHouse') ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),
                      RentalChipSelector(
                        label: 'Subtype',
                        options: const ['All', ...['Guest House', 'PG', 'Roommate']],
                        initialIndex: subIdx,
                        onChanged: (i) => subIdx = i,
                      ),
                      const SizedBox(height: 14),
                      RentalChipSelector(
                        label: 'Meals Included',
                        options: const ['All', ...['Yes Included', 'Not Included']],
                        initialIndex: mealIdx,
                        onChanged: (i) => mealIdx = i,
                      ),
                    ],

                    if (propType == 'NewProjectsAndProperties') ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),
                      RentalChipSelector(
                        label: 'Project Status',
                        options: const ['All', ...['Ready to Move', 'Under Construction']],
                        initialIndex: statusIdx,
                        onChanged: (i) => statusIdx = i,
                      ),
                      const SizedBox(height: 14),
                      RentalChipSelector(
                        label: 'Property Type',
                        options: const ['All', ...['1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '4 BHK+', 'Office']],
                        initialIndex: propTypeIdx,
                        onChanged: (i) => propTypeIdx = i,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                          _ctrl.clearFilters();
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryColor),
                          ),
                          child: CustomText(
                            'Reset',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RentalPrimaryButton(
                        label: 'Apply',
                        onTap: () {
                          Get.back();
                          _ctrl.applyAllFilters(
                            cityVal: cityCtrl.text.trim(),
                            min: minCtrl.text.trim(),
                            max: maxCtrl.text.trim(),
                            bhk: _chipVal(PropertyController.bhkOptions, bhkIdx),
                            bathrooms: _chipVal(PropertyController.bathroomOptions, bathIdx),
                            facing: _chipVal(PropertyController.facingOptions, faceIdx),
                            carParking: _chipVal(PropertyController.parkingOptions, parkIdx),
                            furnishing: _chipVal(PropertyController.furnishingOptions, furnIdx),
                            subType: _chipVal(PropertyController.pgSubtypeOptions, subIdx),
                            mealsIncluded: _chipVal(PropertyController.mealsOptions, mealIdx),
                            projectStatus: _chipVal(PropertyController.availabilityOptions, statusIdx),
                            typeOfProperty: _chipVal(PropertyController.npPropertyTypeOptions, propTypeIdx),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  int _chipIdx(List<String> options, String value) {
    if (value.isEmpty) return 0;
    final idx = options.indexOf(value);
    return idx >= 0 ? idx + 1 : 0;
  }

  String _chipVal(List<String> options, int filterIdx) {
    if (filterIdx <= 0) return '';
    final realIdx = filterIdx - 1;
    return realIdx < options.length ? options[realIdx] : '';
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
    DiscoverMarkerIcons.circle(icon: Icons.home_work_outlined).then((d) {
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
                          '$count properties on the map',
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
