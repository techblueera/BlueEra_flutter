import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_card.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_detail_screen.dart';
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

  const VehicleListingScreen({
    super.key,
    this.initialCategory,
    this.initialSubCategory,
  });

  @override
  State<VehicleListingScreen> createState() => _VehicleListingScreenState();
}

class _VehicleListingScreenState extends State<VehicleListingScreen> {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String? _category;
  String? _subCategory;
  int? _pincode;

  static const _categories = ['CAR', 'BIKE', 'TRUCK', 'BUS', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _subCategory = widget.initialSubCategory;
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
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
        backgroundColor: AppColors.appBackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E88FF),
          foregroundColor: Colors.white,
          elevation: 0,
          title: CustomText(
            'Vehicles',
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
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
                      message: state.message ?? 'Something went wrong',
                      onRetry: _refresh,
                    );
                  }
                  if (_ctrl.publicVehicles.isEmpty) {
                    return _EmptyView(onRefresh: _refresh);
                  }
                  return ListView.separated(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size12,
                      SizeConfig.size12,
                      SizeConfig.size12,
                      SizeConfig.size16,
                    ),
                    itemCount: _ctrl.publicVehicles.length +
                        (_ctrl.publicHasMore.value ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        SizedBox(height: SizeConfig.size12),
                    itemBuilder: (_, i) {
                      if (i >= _ctrl.publicVehicles.length) {
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
                      final v = _ctrl.publicVehicles[i];
                      return VehicleCard(
                        vehicle: v,
                        onTap: () => _openDetail(v),
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

  // ─── Filter bar ────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: const Color(0xFF1E88FF),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        0,
        SizeConfig.size12,
        SizeConfig.size12,
      ),
      child: Column(
        children: [
          _searchField(),
          SizedBox(height: SizeConfig.size8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryChip(label: 'All', value: null),
                ..._categories
                    .map((c) => _categoryChip(label: _humanCat(c), value: c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _refresh(),
        decoration: InputDecoration(
          hintText: 'Search by name, brand, model…',
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchCtrl,
            builder: (_, v, __) {
              if (v.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _refresh();
                },
              );
            },
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _categoryChip({required String label, required String? value}) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        backgroundColor: Colors.white,
        selectedColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color:
              selected ? const Color(0xFF1E88FF) : AppColors.secondaryTextColor,
        ),
        side: BorderSide(
          color: selected ? const Color(0xFF1E88FF) : Colors.transparent,
          width: 1.4,
        ),
        onSelected: (_) {
          setState(() => _category = value);
          _refresh();
        },
      ),
    );
  }

  String _humanCat(String c) {
    switch (c) {
      case 'CAR':
        return 'Cars';
      case 'BIKE':
        return 'Bikes';
      case 'TRUCK':
        return 'Trucks';
      case 'BUS':
        return 'Buses';
      default:
        return 'Other';
    }
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
          'No vehicles match your filters',
          textAlign: TextAlign.center,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          'Try adjusting the search or clearing the category filter.',
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
            label: const Text('Retry'),
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
