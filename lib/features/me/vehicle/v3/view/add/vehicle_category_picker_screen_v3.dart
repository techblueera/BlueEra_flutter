import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/vehicle_products_selection_screen_v3.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1–3 of the seller journey: **type → brand → model**.
///
/// One screen for all three levels because the catalog is the same shape at
/// every level — it pushes a copy of itself for the next one, so the back
/// stack is the breadcrumb and a seller can retreat one level at a time. On
/// reaching a model (level 2, the leaf) it hands off to the trim picker.
///
/// Pass [rootCategory] to enter at the brand step — the dashboard's type rail
/// does that so tapping "4 Wheeler" doesn't ask for the type again.
class VehicleCategoryPickerScreenV3 extends StatefulWidget {
  /// Node whose children this screen lists. Null lists level 0.
  final VehicleCategoryV3? rootCategory;

  const VehicleCategoryPickerScreenV3({super.key, this.rootCategory});

  @override
  State<VehicleCategoryPickerScreenV3> createState() =>
      _VehicleCategoryPickerScreenV3State();
}

class _VehicleCategoryPickerScreenV3State
    extends State<VehicleCategoryPickerScreenV3> {
  final VehicleV3Controller _controller = getOrPut(() => VehicleV3Controller());

  List<VehicleCategoryV3> _items = const [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// The level being *listed* — 0 at the root, then one deeper per push.
  int get _level {
    final parentLevel = widget.rootCategory?.level;
    if (widget.rootCategory == null) return 0;
    return (parentLevel ?? 0) + 1;
  }

  String get _title {
    switch (_level) {
      case 0:
        return 'Choose vehicle type';
      case 1:
        return 'Choose brand';
      default:
        return 'Choose model';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final parent = widget.rootCategory;
    if (parent == null) {
      await _controller.fetchRootCategories();
      if (!mounted) return;
      setState(() {
        _items = List<VehicleCategoryV3>.from(_controller.rootCategories);
        _loading = false;
      });
      return;
    }
    // A nested read may already have handed us the children — skip the call
    // when it did.
    final children = parent.children.isNotEmpty
        ? parent.children
        : await _controller.fetchChildCategories(
            parentId: parent.id,
            level: _level,
          );
    if (!mounted) return;
    setState(() {
      _items = children;
      _loading = false;
    });
  }

  List<VehicleCategoryV3> get _visible {
    if (_query.trim().isEmpty) return _items;
    final q = _query.trim().toLowerCase();
    return _items
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.key.toLowerCase().contains(q))
        .toList();
  }

  /// Tapping a category shows **its products**, at any level.
  ///
  /// `GET /products/search?categoryId=` resolves the whole subtree, so a brand
  /// lists every trim beneath it — there is no need to walk down to a model
  /// first. That is what makes this the same two-step as grocery: category
  /// list → products → add to cart, rather than the four-screen catalog walk
  /// this used to run (brand → model → trim → colour → form), which also
  /// published on its own path instead of feeding the basket.
  void _onTap(VehicleCategoryV3 category) {
    Get.to(() => VehicleProductsSelectionScreenV3(category: category));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: _title, isShadowShow: false),
      body: SafeArea(
        child: Column(
          children: [
            _searchField(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    // Local filtering, not `/categories/search`: one level is a short list
    // that is already in memory, so a round trip per keystroke would be
    // slower and offline-fragile for no gain.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size12,
        SizeConfig.size16,
        SizeConfig.size8,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.greyE5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.greyE5),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final items = _visible;
    if (items.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          message: _query.trim().isEmpty
              // §9: there is no "request a missing model" flow in v3, so an
              // empty branch is genuinely a dead end for the seller.
              ? 'Nothing in this part of the catalog yet.'
              : 'No match for "${_query.trim()}".',
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size8,
        SizeConfig.size16,
        SizeConfig.size24,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size8),
      itemBuilder: (_, i) => _tile(items[i]),
    );
  }

  Widget _tile(VehicleCategoryV3 category) {
    return InkWell(
      onTap: () => _onTap(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: category.image.isEmpty
                    ? Container(
                        color: AppColors.whiteF3,
                        child: Icon(Icons.directions_car_filled_outlined,
                            size: 20, color: AppColors.secondaryTextColor),
                      )
                    : CachedNetworkImage(
                        imageUrl: category.image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.whiteF3),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.whiteF3,
                          child: Icon(Icons.directions_car_filled_outlined,
                              size: 20, color: AppColors.secondaryTextColor),
                        ),
                      ),
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: CustomText(
                category.name,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }
}
