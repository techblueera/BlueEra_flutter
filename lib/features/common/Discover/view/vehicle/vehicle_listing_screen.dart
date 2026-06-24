import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
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
/// vehicle service per `lib/docs/FLUTTER_INTEGRATION_GUIDE.md` §1) and
/// supports the same filters the API documents: free-text query,
/// category, sub-category and pincode. Pagination is infinite-scroll
/// driven, so we keep on calling [VehicleController.loadMorePublicVehicles]
/// while the scroll is within 300px of the bottom and `hasMore` is
/// true.
class VehicleListingScreen extends StatefulWidget {
  /// Optional pre-applied category — wired up so the Discover home tile
  /// for "Cars", "Bikes", etc. can drop the user into a pre-filtered
  /// listing without an extra dropdown tap.
  final String? initialCategory;
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
  String? _subCategory;
  int? _pincode;

  /// Server-driven taxonomy from `GET /vehicles/types`. A tab's
  /// [VehicleType.value] is sent as the `category` filter, which is exactly
  /// what create/update writes to a vehicle's `category` field.
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

  // Vehicle-themed banners — shared with AllVehicleServiceScreen so every
  // vehicle entry-point in Discover shows the same hero imagery.
  final List<String> _bannerImages = const [
    'https://img.freepik.com/free-photo/red-car-with-trunk-that-says-toyota-it_1340-39044.jpg?w=1380',
    'https://img.freepik.com/free-photo/black-suv-car-front-view_114579-4153.jpg?w=1380',
    'https://img.freepik.com/free-photo/big-truck-road_181624-37941.jpg?w=1380',
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
      // The old sub-category belongs to the previous parent; drop it so
      // the two filters can't contradict each other.
      _subCategory = null;
    });
    _refresh();
  }

  /// Toggle behavior — tapping the active chip clears the sub-category
  /// filter so the user can broaden back to the whole parent category.
  void _onSubCategoryTap(VehicleType child) {
    final next = _subCategory == child.value ? null : child.value;
    setState(() => _subCategory = next);
    _refresh();
  }

  /// Children of the currently selected parent type. Empty when no parent
  /// is picked or the parent is a leaf — the chip row hides in both cases.
  List<VehicleType> get _activeSubTypes {
    if (_category == null) return const <VehicleType>[];
    final parent = _types.firstWhere(
      (t) => t.value == _category,
      orElse: () => VehicleType(value: '', label: ''),
    );
    return parent.children;
  }

  Future<void> _refresh() async {
    await _ctrl.fetchPublicVehicles(
      category: _category,
      subCategory: _subCategory,
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
        name: AppStrings.all.tr,
        imageUrl: AppImageAssets.all,
      ),
      ..._types.map(
        (t) => StickyCategory(id: t.value, name: t.label),
      ),
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
                      if (_activeSubTypes.isNotEmpty)
                        _SubCategoryBar(
                          subs: _activeSubTypes,
                          selectedValue: _subCategory,
                          onSelected: _onSubCategoryTap,
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

/// Horizontal-scrolling strip of L2 sub-category chips. Labels mirror what
/// the server stores as `sub_category_label` on each vehicle, so the filter
/// and the list rows read the same.
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
