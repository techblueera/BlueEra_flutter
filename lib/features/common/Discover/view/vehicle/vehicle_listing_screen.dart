import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/add_vehicle_flow_screen.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_discover_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Public Discover-side listing of vehicles.
///
/// Hits `GET /vehicles` (the only public catalogue exposed by the
/// vehicle service) and supports the filters the API documents:
/// free-text query, **category** (L0 root: `2W` / `4W` / …),
/// **sub_category** (L1 vehicle type: `MOTORCYCLE` / `SUV` / …),
/// optionally **type** (L2 segment leaf: `SPORTS_BIKE` / `COMPACT_SUV`
/// / …), and pincode.
///
/// Taxonomy is a **3-level tree** (per `UI_CHANGES_taxonomy-level2.md` →
/// supersedes the brief flatten doc): `category` → `sub_category` →
/// `type`. The sticky header chips drive the **category** filter; the
/// strip just below drives the **sub_category** (vehicle type) filter.
/// A third segment picker is intentionally not surfaced here yet — the
/// catalog (Brand → Model → Variant) narrows the rest. ⚠️ Vehicle-type
/// keys (e.g. `MOTORCYCLE`) are L1 `sub_category`s, so chip taps must
/// send `sub_category=`; `?type=MOTORCYCLE` returns empty under the
/// level-2 split (`type=` is only for segment leaves like `SPORTS_BIKE`).
///
/// Pagination is infinite-scroll driven, so we keep on calling
/// [VehicleController.loadMorePublicVehicles] while the scroll is within
/// 300px of the bottom and `hasMore` is true.
class VehicleListingScreen extends StatefulWidget {
  /// Optional pre-applied **root category** (L0, e.g. `2W`, `4W`) —
  /// wired up so the Discover home tile for "Cars", "Bikes", etc. can
  /// drop the user into a pre-filtered listing without an extra dropdown
  /// tap.
  final String? initialCategory;

  /// Optional pre-applied **vehicle type** (L1, e.g. `MOTORCYCLE`,
  /// `SUV`) — sent as `sub_category=` on `GET /vehicles`, which expands
  /// to every segment underneath. Legacy mid-tier keys (`2W_PETROL`,
  /// `LCV`, `PASSENGER*`) are gone server-side and return empty.
  final String? initialSubCategory;

  /// Condition the entry-point implies — `VehicleCondition.isNew` ("NEW")
  /// for "New Vehicle Sales" (`Vehicle_Sales`), `VehicleCondition.used`
  /// ("USED") for "Old Vehicle Sales" (`Vehicle_Rental`). Used two ways:
  ///
  /// 1. **Listing filter** — sent as `condition` on `GET /vehicles` so the
  ///    list only shows vehicles in that condition.
  /// 2. **Add-vehicle flow** — the Add button skips the NEW/USED chooser
  ///    and drops the user straight into the matching flow.
  ///
  /// When null neither filter nor flow-skip applies.
  final String? initialCondition;

  const VehicleListingScreen({
    super.key,
    this.initialCategory,
    this.initialSubCategory,
    this.initialCondition,
  });

  @override
  State<VehicleListingScreen> createState() => _VehicleListingScreenState();
}

class _VehicleListingScreenState extends State<VehicleListingScreen> {
  static const String _allOptionId = 'ALL_OPTION';

  final VehicleController _ctrl = getOrPut(() => VehicleController(), permanent: true);
  final TextEditingController _searchCtrl = TextEditingController();

  String? _category;

  /// Selected **vehicle type** (L1, e.g. `MOTORCYCLE`, `SUV`) — sent as
  /// `sub_category=` on `GET /vehicles`. The chip strip below the root
  /// header is the picker for this.
  String? _subCategory;

  /// Selected **segment leaf** (L2, e.g. `STANDARD_SCOOTER`,
  /// `SPORTS_BIKE`) — sent as `type=` on `GET /vehicles`. Only valid
  /// when [_subCategory] is set; the second chip strip is the picker
  /// for this and hides when the active L1 has no children.
  String? _type;
  int? _pincode;

  /// Server-driven taxonomy from `GET /vehicles/types` — a 3-deep nested
  /// tree (`category` → `sub_category` → `type`). The screen uses the
  /// first two levels: a root's [VehicleType.value] (e.g. `2W`) drives
  /// the `category` filter, and its direct children (`MOTORCYCLE`,
  /// `SUV`, …) drive the `sub_category` filter. Segment leaves are
  /// reachable via `children.children` if/when we add a third picker.
  List<VehicleType> _types = const <VehicleType>[];

  /// Fires once `GET /vehicles/types` resolves so the sticky header can be
  /// rebuilt with the server taxonomy.
  late final Worker _typesWorker;

  // Same blue wash the rest of the discover surfaces use under the banner.
  LinearGradient get _bgGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.blue5CAF.withValues(alpha: 0.1),
          AppColors.blue5CAF.withValues(alpha: 0.8),
        ],
      );

  // Banners tuned to this screen's intent — vehicle showroom imagery
  // (browse a catalogue) plus vehicle service / mechanic imagery
  // (post-purchase support). All URLs verified live (HTTP 200, real
  // image/jpeg payload) at the time of this edit; if any goes missing
  // later, swap with another freepik vehicle-themed slug.
  final List<String> _bannerImages = const [
    'https://img.magnific.com/free-vector/seller-talking-customer-about-car-dealer-future-vehicle-owner-rental-center-service_575670-280.jpg?semt=ais_hybrid&w=740&q=80',
    'https://img.magnific.com/free-photo/benchman-fixing-engine-car_114579-2807.jpg',
    'https://img.magnific.com/free-photo/hands-female-mechanic-using-laptop_1170-1248.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _subCategory = widget.initialSubCategory;
    // Seed from whatever the controller has cached so a revisit shows the
    // real tabs immediately; the worker fills them in on first load.
    _types = List<VehicleType>.from(_ctrl.vehicleTypes);
    _typesWorker = ever<List<VehicleType>>(_ctrl.vehicleTypes, (types) {
      if (!mounted) return;
      setState(() => _types = List<VehicleType>.from(types));
    });
    _ctrl.fetchVehicleTypes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _typesWorker.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Pagination via scroll notifications — NestedScrollView owns the inner
  /// scrollable, so a dedicated [ScrollController] is unnecessary.
  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification && n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
      _ctrl.loadMorePublicVehicles();
    }
    return false;
  }

  void _onCategoryTap(StickyCategory item) {
    final value = item.id == _allOptionId ? null : item.id;
    if (value == _category) return;
    setState(() {
      _category = value;
      // The previous L1/L2 selections belong to the previous root; drop
      // them so the three filters can't contradict each other.
      _subCategory = null;
      _type = null;
    });
    _refresh();
  }

  /// Toggle behavior — tapping the active chip clears the sub_category
  /// filter so the user can broaden back to the whole root category.
  /// Always clears the L2 [_type] because a different L1 means the old
  /// segment leaf no longer applies.
  void _onSubCategoryTap(VehicleType child) {
    final next = _subCategory == child.value ? null : child.value;
    setState(() {
      _subCategory = next;
      _type = null;
    });
    _refresh();
  }

  /// Toggle behavior — tapping the active L2 chip clears the [_type]
  /// filter so the listing broadens back to the whole sub_category.
  void _onTypeTap(VehicleType leaf) {
    final next = _type == leaf.value ? null : leaf.value;
    setState(() => _type = next);
    _refresh();
  }

  /// Direct children of the currently selected root — the L1 vehicle
  /// types (`MOTORCYCLE`, `SUV`, …). Empty when no root is picked or
  /// the root has no children — the chip row hides in both cases.
  List<VehicleType> get _activeSubCategories {
    if (_category == null) return const <VehicleType>[];
    final root = _types.firstWhere(
      (t) => t.value == _category,
      orElse: () => VehicleType(value: '', label: ''),
    );
    return root.children;
  }

  /// Direct children of the currently selected L1 sub-category — the
  /// L2 segment leaves (`STANDARD_SCOOTER`, `SPORTS_BIKE`, …). Empty
  /// when no sub-category is picked or it has no children, in which
  /// case the second chip strip hides.
  List<VehicleType> get _activeTypes {
    if (_subCategory == null) return const <VehicleType>[];
    final sub = _activeSubCategories.firstWhere(
      (s) => s.value == _subCategory,
      orElse: () => VehicleType(value: '', label: ''),
    );
    return sub.children;
  }

  // ─── Active-filter breadcrumb helpers ────────────────────────────
  // Drive the badge at the top of the filter area so the user always
  // sees the current selection path and can clear all three levels in
  // one tap. Each label resolves against [_types] so the breadcrumb
  // always reads the same as the chips.

  bool get _hasActiveFilters =>
      _category != null || _subCategory != null || _type != null;

  String? get _categoryLabel {
    if (_category == null) return null;
    final root = _types.firstWhere(
      (t) => t.value == _category,
      orElse: () => VehicleType(value: '', label: ''),
    );
    if (root.value.isEmpty) return _category;
    // Mirror the sticky-header rename so the breadcrumb matches the chip.
    return root.value == 'COMMERCIAL' ? 'Commercial Vehicle' : root.label;
  }

  String? get _subCategoryLabel {
    if (_subCategory == null) return null;
    final sub = _activeSubCategories.firstWhere(
      (s) => s.value == _subCategory,
      orElse: () => VehicleType(value: '', label: ''),
    );
    return sub.value.isEmpty ? _subCategory : sub.label;
  }

  String? get _typeLabel {
    if (_type == null) return null;
    final leaf = _activeTypes.firstWhere(
      (l) => l.value == _type,
      orElse: () => VehicleType(value: '', label: ''),
    );
    return leaf.value.isEmpty ? _type : leaf.label;
  }

  List<String> get _activeFilterPath => [
        if (_categoryLabel != null) _categoryLabel!,
        if (_subCategoryLabel != null) _subCategoryLabel!,
        if (_typeLabel != null) _typeLabel!,
      ];

  void _clearAllFilters() {
    setState(() {
      _category = null;
      _subCategory = null;
      _type = null;
    });
    _refresh();
  }

  Future<void> _refresh() async {
    await _ctrl.fetchPublicVehicles(
      category: _category,
      // L1 vehicle-type pick → `sub_category=`. The server expands it to
      // every L2 segment under that vehicle type. Sending it as `type=`
      // would hit the segment slot and return empty.
      subCategory: _subCategory,
      // L2 segment-leaf pick → `type=`. Only sent when the user has
      // drilled down to a specific segment under the chosen L1.
      type: _type,
      condition: widget.initialCondition,
      pincode: _pincode,
      q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = <StickyCategory>[
      StickyCategory(
        id: _allOptionId,
        // Vehicle-screen label override — kept inline so the shared
        // `AppStrings.all` ("All") used by every other Discover surface is
        // untouched.
        name: 'All Vehicles',
        imageUrl: AppImageAssets.all,
      ),
      ..._types.map((t) {
        // Server returns "Commercial" (1 word) for the COMMERCIAL root,
        // while every other root label is 2 words ("Two Wheeler", "Three
        // Wheeler", "Four Wheeler"). The sticky-header delegate renders
        // 2-word labels on two lines and 1-word labels on one with a
        // FittedBox scale-down — the lone "Commercial" then sits at the
        // top of an oversized 2-line slot and looks visually clipped vs
        // its neighbours. Promote it to "Commercial Vehicle" so the
        // last tab matches the rest.
        final name = t.value == 'COMMERCIAL' ? 'Commercial Vehicle' : t.label;
        return StickyCategory(id: t.value, name: name, imageUrl: t.icon);
      }),
    ];
    final selectedId = _category ?? _allOptionId;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(gradient: _bgGradient),
                    child: BannerCarousel(
                      images: _bannerImages,
                      onBack: () => Get.back(),
                      statusBarHeight: statusBarHeight,
                      backgroundColor: Colors.transparent,
                      bottomBorderSide: const BorderSide(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    singleLineLabel: false,
                    categories: stickyCategories,
                    selectedId: selectedId,
                    onCategoryTap: _onCategoryTap,
                    onBack: () => Get.back(),
                    backgroundGradient: _bgGradient,
                    expandedLabelColor: AppColors.white,
                  ),
                ),
              ],
              body: RefreshIndicator(
                onRefresh: _refresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: Column(
                    children: [
                      // Active-filter breadcrumb — always visible once
                      // any level is set, gives a one-tap clear-all.
                      if (_hasActiveFilters)
                        _ActiveFiltersBar(
                          path: _activeFilterPath,
                          onClear: _clearAllFilters,
                        ),
                      if (_activeSubCategories.isNotEmpty)
                        _FilterStrip(
                          label: 'Category',
                          subs: _activeSubCategories,
                          selectedValue: _subCategory,
                          onSelected: _onSubCategoryTap,
                        ),
                      // L2 segment-leaf strip — only appears once the
                      // user picks an L1 sub-category that has children
                      // (e.g. Scooter → Standard Scooter / Maxi Scooter
                      // / Retro Scooter). A subtle tint distinguishes it
                      // as a refinement of L1.
                      if (_activeTypes.isNotEmpty)
                        _FilterStrip(
                          label: 'Type',
                          subs: _activeTypes,
                          selectedValue: _type,
                          onSelected: _onTypeTap,
                          isRefinement: true,
                        ),
                      Expanded(
                        child: Obx(() {
                          final state = _ctrl.publicVehiclesState.value;
                          if (state.status == Status.LOADING && _ctrl.publicVehicles.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (state.status == Status.ERROR && _ctrl.publicVehicles.isEmpty) {
                            return _ErrorView(
                              message: state.message ?? AppStrings.somethingWentWrong.tr,
                              onRetry: _refresh,
                            );
                          }
                          if (_ctrl.publicVehicles.isEmpty) {
                            return _EmptyView(onRefresh: _refresh);
                          }
                          final rows = buildNativeAdRows(_ctrl.publicVehicles.length);
                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              SizeConfig.size12,
                              SizeConfig.size12,
                              SizeConfig.size12,
                              SizeConfig.size16,
                            ),
                            itemCount: rows.length + (_ctrl.publicHasMore.value ? 1 : 0),
                            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
                            itemBuilder: (_, i) {
                              if (i >= rows.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }
                              final row = rows[i];
                              if (row.isAd) {
                                return NativeAdSlot(
                                  adOrdinal: row.adOrdinal,
                                  keyPrefix: 'vehicle_listing_native_ad',
                                );
                              }
                              final v = _ctrl.publicVehicles[row.contentIndex];
                              return VehicleDiscoverCard(
                                vehicle: v,
                                onTap: () => _openDetail(v),
                                onBook: () => _openDetail(v),
                                onChat: () => _openDetail(v),
                                onShare: () => _shareVehicle(v),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(Vehicle v) {
    if (v.id == null) return;
    Get.to(() => VehicleDetailScreen(vehicleId: v.id!));
  }

  /// Opens the native share sheet with the vehicle's BlueEra deep link
  /// and a "Brand Model Variant" label (falls back gracefully).
  Future<void> _shareVehicle(Vehicle v) async {
    final label = [v.brand, v.model, v.variant]
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim())
        .join(' ');
    final name = label.isNotEmpty ? label : 'this vehicle';
    final shareLink = vehicleDeepLink(vehicleId: v.id);

    await ShareService.instance.openShareSheet(
      text: "Check out $name on BlueEra:\n$shareLink",
      subject: name,
    );
  }

  /// Opens the add-vehicle flow. When the screen was reached from a
  /// "New / Old Vehicle Sales" category, [VehicleListingScreen.initialCondition]
  /// fixes the listing as NEW/USED so we skip the chooser; otherwise we ask.
  Future<void> _onAddVehicle() async {
    var condition = widget.initialCondition;
    // if (condition == null) {
    //   condition = await showVehicleConditionDialog(context);
    //   if (condition == null || !mounted) return;
    // }
    logs("businessCategoryGlobal ${businessCategoryGlobal}");
    if (businessCategoryGlobal.toLowerCase() == "vehicle rental") {
      condition = VehicleCondition.used;
    } else {
      condition = VehicleCondition.isNew;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddVehicleFlowScreen(condition: condition!),
        fullscreenDialog: true,
      ),
    );
    if (created == true) {
      await _refresh();
    }
  }
}

/// Breadcrumb of the currently-applied filter path
/// (e.g. "Two Wheeler › Scooter › Standard Scooter") with a single
/// trailing close button that clears every level in one tap. Hidden
/// when no filter is set, so it never costs vertical space at rest.
class _ActiveFiltersBar extends StatelessWidget {
  final List<String> path;
  final VoidCallback onClear;

  const _ActiveFiltersBar({required this.path, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size10,
        SizeConfig.size12,
        SizeConfig.size8,
      ),
      child: Row(
        children: [
          CustomText(
            'Filters:',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(width: SizeConfig.size8),
          Flexible(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size10,
                SizeConfig.size6,
                SizeConfig.size6,
                SizeConfig.size6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: CustomText(
                      path.join(' › '),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size4),
                  InkWell(
                    onTap: onClear,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section-labeled chip strip. Wraps [_SubCategoryBar] with a small
/// uppercase header so the user can tell L1 ("Category") from L2
/// ("Type") at a glance. Pass [isRefinement] for the L2 strip — it
/// switches to a subtle tinted background so it visually nests under
/// the L1 strip above.
class _FilterStrip extends StatelessWidget {
  final String label;
  final List<VehicleType> subs;
  final String? selectedValue;
  final ValueChanged<VehicleType> onSelected;
  final bool isRefinement;

  const _FilterStrip({
    required this.label,
    required this.subs,
    required this.selectedValue,
    required this.onSelected,
    this.isRefinement = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isRefinement ? const Color(0xFFF4F8FC) : AppColors.white,
      padding: EdgeInsets.only(top: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: CustomText(
              label.toUpperCase(),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryTextColor,
              letterSpacing: 0.6,
            ),
          ),
          _SubCategoryBar(
            subs: subs,
            selectedValue: selectedValue,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

/// Horizontal-scrolling strip of L1 vehicle-type chips (the children of
/// the active root). Labels mirror what the server returns as
/// `sub_category_label` on each vehicle, so the filter and the list rows
/// read the same.
class _SubCategoryBar extends StatelessWidget {
  final List<VehicleType> subs;
  final String? selectedValue;
  final ValueChanged<VehicleType> onSelected;

  static const double _stripHeight = 52;

  const _SubCategoryBar({
    required this.subs,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      height: _stripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size8,
        ),
        itemCount: subs.length,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
        itemBuilder: (_, i) {
          final sub = subs[i];
          return _SubCategoryChip(
            label: sub.label,
            selected: sub.value == selectedValue,
            onTap: () => onSelected(sub),
          );
        },
      ),
    );
  }
}

class _SubCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryColor : const Color(0xFFDDE3EC),
          ),
        ),
        alignment: Alignment.center,
        child: CustomText(
          label,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.mainTextColor,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.10),
        Icon(Icons.directions_car_filled_rounded,
            size: 64, color: AppColors.primaryColor.withValues(alpha: 0.4)),
        SizedBox(height: SizeConfig.size12),
        CustomText(
          AppStrings.noVehiclesMatchFilters.tr,
          textAlign: TextAlign.center,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          AppStrings.adjustSearchOrClearFilter.tr,
          textAlign: TextAlign.center,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.10),
        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade400),
        SizedBox(height: SizeConfig.size12),
        CustomText(
          message,
          textAlign: TextAlign.center,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size16),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppStrings.retry.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
