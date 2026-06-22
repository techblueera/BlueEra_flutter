import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_discover_card.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/add_vehicle_flow_screen.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_detail_screen.dart';
import 'package:BlueEra/features/me/vehicle/view/booking/vehicle_bookings_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
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

  /// Add-vehicle condition implied by the category the user came from.
  /// `VehicleCondition.isNew` for "New Vehicle Sales" (`Vehicle_Sales`),
  /// `VehicleCondition.used` for "Old Vehicle Sales" (`Vehicle_Rental`).
  /// When non-null the Add button skips the NEW/USED chooser and drops the
  /// user straight into the matching flow; when null it shows the chooser.
  final String? addCondition;

  const VehicleListingScreen({
    super.key,
    this.initialCategory,
    this.initialSubCategory,
    this.addCondition,
  });

  @override
  State<VehicleListingScreen> createState() => _VehicleListingScreenState();
}

class _VehicleListingScreenState extends State<VehicleListingScreen>
    with TickerProviderStateMixin {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String? _category;
  String? _subCategory;
  int? _pincode;

  late TabController _tabController;

  /// Tab order, populated from `GET /vehicles/types` — `null` == "All",
  /// followed by each top-level [VehicleType] (e.g. Passenger, Commercial).
  /// A tab's [VehicleType.value] is sent as the `category` filter, which is
  /// exactly what create/update writes to a vehicle's `category` field.
  List<VehicleType?> _tabTypes = const <VehicleType?>[null];

  /// Fires once `GET /vehicles/types` resolves so the TabBar can be rebuilt
  /// with the server taxonomy.
  late final Worker _typesWorker;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _subCategory = widget.initialSubCategory;
    // Seed from whatever the controller has cached so a revisit shows the
    // real tabs immediately; the worker fills them in on first load.
    _tabTypes = <VehicleType?>[null, ..._ctrl.vehicleTypes];
    _tabController = TabController(
      length: _tabTypes.length,
      initialIndex: _indexForCategory(_category),
      vsync: this,
    )..addListener(_handleTabChange);
    _typesWorker = ever<List<VehicleType>>(
      _ctrl.vehicleTypes,
      (types) => _rebuildTabs(types),
    );
    _ctrl.fetchVehicleTypes();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  /// Index of the tab whose type matches [cat]; 0 ("All") when absent.
  int _indexForCategory(String? cat) {
    if (cat == null) return 0;
    final i = _tabTypes.indexWhere((t) => t?.value == cat);
    return i < 0 ? 0 : i;
  }

  /// Swap the hardcoded tabs for the server taxonomy. Recreates the
  /// [TabController] (its length is fixed at construction) while preserving
  /// the current selection where the type still exists.
  void _rebuildTabs(List<VehicleType> types) {
    if (!mounted) return;
    final next = <VehicleType?>[null, ...types];
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    setState(() {
      _tabTypes = next;
      _tabController = TabController(
        length: next.length,
        initialIndex: _indexForCategory(_category),
        vsync: this,
      )..addListener(_handleTabChange);
    });
  }

  /// Fires on tab selection. Comparing against [_category] dedupes the
  /// double listener fire (mid-animation + settle) into a single refresh.
  void _handleTabChange() {
    if (_tabController.index >= _tabTypes.length) return;
    final value = _tabTypes[_tabController.index]?.value;
    if (value != _category) {
      setState(() {
        _category = value;
        // The old sub-category belongs to the previous parent; drop it so
        // the two filters can't contradict each other.
        _subCategory = null;
      });
      _refresh();
    }
  }

  @override
  void dispose() {
    _typesWorker.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _ctrl.loadMorePublicVehicles();
    }
  }

  Future<void> _refresh() async {
    await _ctrl.fetchPublicVehicles(
      category: _category,
      subCategory: _subCategory,
      pincode: _pincode,
      q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CommonBackAppBar(
          title: AppStrings.vehicle.tr,
          buildCustomActionWidget: () => IconButton(
            tooltip: AppStrings.bookingsTitle.tr,
            icon: Icon(Icons.receipt_long_outlined,
                color: AppColors.primaryColor),
            onPressed: () => Get.to(() => const VehicleBookingsScreen()),
          ),
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: Obx(() {
                  final state = _ctrl.publicVehiclesState.value;
                  if (state.status == Status.LOADING &&
                      _ctrl.publicVehicles.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == Status.ERROR &&
                      _ctrl.publicVehicles.isEmpty) {
                    return _ErrorView(
                      message: state.message ?? AppStrings.somethingWentWrong.tr,
                      onRetry: _refresh,
                    );
                  }
                  if (_ctrl.publicVehicles.isEmpty) {
                    return _EmptyView(onRefresh: _refresh);
                  }
                  final rows =
                      buildNativeAdRows(_ctrl.publicVehicles.length);
                  return ListView.separated(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size12,
                      SizeConfig.size12,
                      SizeConfig.size12,
                      SizeConfig.size16,
                    ),
                    itemCount:
                        rows.length + (_ctrl.publicHasMore.value ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        SizedBox(height: SizeConfig.size12),
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
  /// "New / Old Vehicle Sales" category, [VehicleListingScreen.addCondition]
  /// fixes the listing as NEW/USED so we skip the chooser; otherwise we ask.
  Future<void> _onAddVehicle() async {
    var condition = widget.addCondition;
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

  // ─── Filter bar (hospital-style TabBar, ref: HomeTabScaffold) ──────
  // Tabs come from `GET /vehicles/types`; labels are the server-provided
  // [VehicleType.label]. Scrolls once the taxonomy outgrows the bar.
  Widget _buildFilterBar() {
    final scrollable = _tabTypes.length > 4;
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: scrollable,
        tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.mainTextColor,
        indicatorColor: AppColors.primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          for (final t in _tabTypes)
            Tab(text: t == null ? AppStrings.all.tr : t.label),
        ],
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
