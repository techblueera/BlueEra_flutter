import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/vehicle_super_category_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/widgets/vehicle_listing_card_v3.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The seller's full list of vehicles, with pause / resume / delete.
///
/// Reads `GET /inventory/my`, which unlike the public reads **includes
/// inactive listings** — that is the whole reason this screen exists rather
/// than reusing the buyer list.
class MyVehicleListingsScreenV3 extends StatefulWidget {
  final String businessId;

  /// Category ids to restrict the list to — the tapped branch of the
  /// with-inventory tree plus everything under it.
  ///
  /// Filtering happens **client-side** because `/inventory/my` accepts only
  /// `page`, `limit` and `condition`; there is no category parameter to send.
  /// Empty means "everything".
  final Set<String> categoryIds;

  /// Shown in the app bar when [categoryIds] is set.
  final String? categoryName;

  const MyVehicleListingsScreenV3({
    super.key,
    required this.businessId,
    this.categoryIds = const {},
    this.categoryName,
  });

  @override
  State<MyVehicleListingsScreenV3> createState() =>
      _MyVehicleListingsScreenV3State();
}

class _MyVehicleListingsScreenV3State extends State<MyVehicleListingsScreenV3> {
  final VehicleV3Controller _controller = getOrPut(() => VehicleV3Controller());
  final ScrollController _scrollController = ScrollController();

  /// null = all; otherwise a [VehicleListingCondition] value.
  String? _conditionFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMoreListings(condition: _conditionFilter);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _applyFilter(String? condition) async {
    setState(() => _conditionFilter = condition);
    await _controller.fetchMyListings(condition: condition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: widget.categoryName?.trim().isNotEmpty == true
            ? widget.categoryName!.trim()
            : 'Your vehicles',
        isShadowShow: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add vehicle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'OpenSans',
          ),
        ),
        onPressed: () async {
          await Get.to(() => const VehicleSuperCategoryScreenV3());
          if (_controller.listingsNeedRefresh) {
            _controller.listingsNeedRefresh = false;
            await _controller.loadDashboard(widget.businessId);
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _filterRow(),
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size10,
      ),
      child: Row(
        children: [
          _filterChip('All', null),
          SizedBox(width: SizeConfig.size8),
          _filterChip('New', VehicleListingCondition.isNew),
          SizedBox(width: SizeConfig.size8),
          _filterChip('Used', VehicleListingCondition.used),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? condition) {
    final selected = _conditionFilter == condition;
    return InkWell(
      onTap: () => _applyFilter(condition),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.greyE5,
          ),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color:
              selected ? AppColors.primaryColor : AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  /// The tapped category's listings, matched on the leaf `modelCategory` the
  /// enriched listing carries against the branch's subtree ids.
  List<VehicleListingV3> _visible(List<VehicleListingV3> all) {
    if (widget.categoryIds.isEmpty) return all;
    return all
        .where((l) => widget.categoryIds.contains(l.modelCategory?.id ?? ''))
        .toList();
  }

  Widget _list() {
    return Obx(() {
      final listings = _visible(_controller.myListings);
      final loading = _controller.listingsStatus.value == Status.LOADING;

      if (loading && listings.isEmpty) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (listings.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message: widget.categoryIds.isEmpty
                ? 'Nothing here yet. Add your first vehicle.'
                : 'No vehicles in this category yet.',
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => _controller.fetchMyListings(
          condition: _conditionFilter,
        ),
        child: ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size16,
            SizeConfig.size4,
            SizeConfig.size16,
            // Clears the FAB.
            SizeConfig.size80,
          ),
          itemCount: listings.length + (_controller.isLoadingMore.value ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
          itemBuilder: (_, i) {
            if (i >= listings.length) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return _row(listings[i]);
          },
        ),
      );
    });
  }

  Widget _row(VehicleListingV3 listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VehicleListingCardV3(listing: listing, showStatus: true),
        Padding(
          padding: EdgeInsets.only(top: SizeConfig.size6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _action(
                icon: listing.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                label: listing.isActive ? 'Pause' : 'Resume',
                onTap: () => _controller.toggleListingActive(listing),
              ),
              SizedBox(width: SizeConfig.size12),
              _action(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: AppColors.red00,
                onTap: () => _confirmDelete(listing),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tint = color ?? AppColors.secondaryTextColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: tint),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ],
        ),
      ),
    );
  }

  /// Delete is a soft delete server-side, but it still removes the listing
  /// from every buyer surface — worth a confirm.
  Future<void> _confirmDelete(VehicleListingV3 listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text('Delete this listing?'),
        content: Text(
          '${listing.title} will no longer be visible to buyers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.red00)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteListing(listing);
    }
  }
}
