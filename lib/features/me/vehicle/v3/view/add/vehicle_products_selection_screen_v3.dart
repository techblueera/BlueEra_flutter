import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/vehicle_colour_condition_sheet_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/widgets/vehicle_basket_fab_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/add/widgets/vehicle_trim_select_card_v3.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Products of a category — the screen a category tap lands on, and the
/// vehicle twin of [GroceryProductsSelectionScreen]: a left category rail, a
/// grid of products on the right, "+" to add, floating cart to publish.
///
/// "Products" here are **trims**, from `GET /products/search?categoryId=`.
/// That parameter resolves the whole SUBTREE (§4 of the integration guide), so
/// tapping a brand lists every trim beneath it without walking down to a model
/// first — which is what lets one tap go straight from the category list to
/// products, the way grocery does.
///
/// The left rail is the tapped category's children, so a merchant can move
/// sideways between sibling categories without going back. A leaf has none, so
/// it lists itself.
class VehicleProductsSelectionScreenV3 extends StatefulWidget {
  /// The category that was tapped.
  final VehicleCategoryV3 category;

  const VehicleProductsSelectionScreenV3({super.key, required this.category});

  @override
  State<VehicleProductsSelectionScreenV3> createState() =>
      _VehicleProductsSelectionScreenV3State();
}

class _VehicleProductsSelectionScreenV3State
    extends State<VehicleProductsSelectionScreenV3> {
  final controller = getOrPut(() => VehicleV3Controller());

  /// Left rail: the tapped category's children, or itself when it's a leaf.
  List<VehicleCategoryV3> _categories = const [];

  /// Observable on purpose. [CommonGenericLeftSideCategoryList] evaluates
  /// `isSelected` INSIDE an `Obx` — that's how it repaints one row without
  /// rebuilding the list — so the selection it reads has to be reactive.
  /// Backing it with plain `setState` state made the Obx subscribe to nothing
  /// and GetX threw "improper use of a GetX". Grocery and medical pass their
  /// controller's `.value` here for the same reason.
  final Rxn<VehicleCategoryV3> _selected = Rxn<VehicleCategoryV3>();

  List<VehicleTrimV3> _trims = const [];
  bool _loadingCategories = true;
  bool _loadingTrims = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    // Children aren't in the picker's payload — `/categories?level=&parentId=`
    // is a flat read — so fetch one level down for the rail.
    final children = widget.category.children.isNotEmpty
        ? widget.category.children
        : await controller.fetchChildCategories(
            parentId: widget.category.id,
            level: (widget.category.level ?? 0) + 1,
          );
    if (!mounted) return;
    final rail = children.isNotEmpty ? children : [widget.category];
    _selected.value = rail.first;
    setState(() {
      _categories = rail;
      _loadingCategories = false;
    });
    _loadTrims();
  }

  Future<void> _loadTrims() async {
    final category = _selected.value;
    if (category == null) return;
    setState(() => _loadingTrims = true);
    final trims = await controller.fetchTrims(categoryId: category.id);
    if (!mounted) return;
    setState(() {
      _trims = trims;
      _loadingTrims = false;
    });
  }

  void _onCategoryTap(VehicleCategoryV3 category) {
    if (_selected.value?.id == category.id) return;
    // The Rx repaints the rail; setState repaints the title and the grid,
    // which aren't inside an Obx.
    _selected.value = category;
    setState(() {});
    _loadTrims();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: _selected.value?.name.isNotEmpty == true
            ? _selected.value!.name
            : widget.category.name,
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_loadingCategories)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _leftCategoryList(),
                  Expanded(child: _rightContent()),
                ],
              ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: VehicleBasketFabV3(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftCategoryList() {
    return CommonGenericLeftSideCategoryList<VehicleCategoryV3>(
      items: _categories,
      placeholderAssetPath: 'assets/images/vehicle_showroom.png',
      getIcon: (item) => item.image,
      getLabel: (item) => item.name,
      // Read inside the widget's own Obx — hence the `.value`.
      isSelected: (item) => _selected.value?.id == item.id,
      onTap: (item, index) => _onCategoryTap(item),
    );
  }

  Widget _rightContent() {
    if (_loadingTrims) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_trims.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(SizeConfig.size20),
        child: EmptyStateWidget(
          message:
              'No vehicles in ${_selected.value?.name ?? 'this category'} yet.',
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final cardWidth = (constraints.maxWidth - spacing) / 2;
          return GridView.builder(
            itemCount: _trims.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              // Tuned to the card: 4:3 image + two text lines + the price row.
              childAspectRatio: cardWidth / (cardWidth * 1.55),
            ),
            padding: EdgeInsets.only(
              bottom: controller.basket.isEmpty
                  ? SizeConfig.size20
                  : SizeConfig.size80,
            ),
            itemBuilder: (_, i) => VehicleTrimSelectCardV3(
              trim: _trims[i],
              controller: controller,
              width: cardWidth,
              // Same sheet the add-landing rails use, so both routes into the
              // basket ask for colour + condition the same way.
              onAdd: () => showVehicleColourConditionSheetV3(
                context: context,
                trim: _trims[i],
                controller: controller,
              ),
            ),
          );
        },
      ),
    );
  }
}
