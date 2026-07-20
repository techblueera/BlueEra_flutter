import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../widgets/common_back_app_bar.dart';

class GroceryNestedCategoryWithInventoryScreen extends StatefulWidget {
  final String userId;
  final List<GroceryCategoryWithInventoryModel> argGroceryCategoryWithInventory;
  final String argArrGroceryCatKey;
  final String argArrGroceryCatName;

  const GroceryNestedCategoryWithInventoryScreen({
    super.key,
    required this.userId,
    required this.argGroceryCategoryWithInventory,
    required this.argArrGroceryCatKey,
    required this.argArrGroceryCatName,
  });

  @override
  State<GroceryNestedCategoryWithInventoryScreen> createState() =>
      _GroceryNestedCategoryWithInventoryScreenState();
}

/// Three across — these tiles are chosen by sight, so showing more of the
/// shelf at once beats a bigger single tile.
const int _kColumns = 3;

/// A category tile's two-tone colour: a soft [fill] behind the tile and a
/// saturated [ink] for its label, badge and hairline.
class _ShelfTone {
  const _ShelfTone(this.fill, this.ink);

  final Color fill;
  final Color ink;
}

/// Aisle palette. Grocery categories carry strong colour associations and real
/// stores colour-code their signage, so tiles are tinted rather than uniformly
/// white — on a picker screen, colour is what the eye lands on before it reads
/// a word.
///
/// Deliberately food-derived (basil, citrus, berry, chilled, taro, clay)
/// rather than a generic UI ramp.
const List<_ShelfTone> _kShelfTones = [
  _ShelfTone(Color(0xFFE8F3EA), Color(0xFF2F6B3C)), // basil
  _ShelfTone(Color(0xFFFDF1DC), Color(0xFF8A5A16)), // citrus
  _ShelfTone(Color(0xFFFBE9EF), Color(0xFF9B2F52)), // berry
  _ShelfTone(Color(0xFFE6F1FB), Color(0xFF1F5C8F)), // chilled
  _ShelfTone(Color(0xFFF0ECFA), Color(0xFF59429B)), // taro
  _ShelfTone(Color(0xFFFBEBE4), Color(0xFF9C4A26)), // clay
];

/// Pick a tone from the category's own key, not its list position, so a
/// category keeps the same colour when the list is re-ordered or filtered —
/// that's what makes the colour learnable ("Vegetables is the green one").
///
/// Sums code units rather than using [String.hashCode], which Dart doesn't
/// guarantee to be stable across releases.
_ShelfTone _toneFor(String seed) {
  if (seed.isEmpty) return _kShelfTones.first;
  var sum = 0;
  for (final unit in seed.codeUnits) {
    sum = (sum + unit) % _kShelfTones.length;
  }
  return _kShelfTones[sum];
}

class _GroceryNestedCategoryWithInventoryScreenState
    extends State<GroceryNestedCategoryWithInventoryScreen> {
  final _groceryController = getOrPut(() => GroceryController());
  late String _argArrGroceryCatName;
  late String _argArrGroceryCatKey;
  late List<GroceryCategoryWithInventoryModel> _argGroceryCategoryWithInventory;
  // List<String>? _groceryFilter;

  @override
  void initState() {
    _argGroceryCategoryWithInventory = widget.argGroceryCategoryWithInventory;
    _argArrGroceryCatName = widget.argArrGroceryCatName;

    updateGroceryCategory(widget.argArrGroceryCatKey, isInitial: true);
    super.initState();
  }

  @override
  void dispose() {
    // NOTE: this used to `deleteIfRegistered<GroceryController>()`, which tore
    // down the SHARED controller the grocery home screen is still bound to —
    // its Obx widgets kept observing the disposed instance, so later
    // `Get.find<GroceryController>()` calls resolved to a *different* object
    // and updates silently stopped reaching the home screen. This screen
    // doesn't own the controller, so it must not delete it.
    super.dispose();
  }

  void updateGroceryCategory(String incomingKey, {bool isInitial = false}) {
    _argArrGroceryCatKey = incomingKey;

    // if (isInitial) {
    //   if (_argArrGroceryCatKey == GroceryConstant.DAIRY_BEVERAGES) {
    //     _groceryFilter = [GroceryConstant.BEVERAGES, GroceryConstant.DAIRY];
    //     _argArrGroceryCatKey = GroceryConstant.BEVERAGES; // Default to first sub-cat
    //   } else if (_argArrGroceryCatKey == GroceryConstant.VEGETABLES_FRUIT) {
    //     _groceryFilter = [GroceryConstant.VEGETABLES, GroceryConstant.FRUITS];
    //     _argArrGroceryCatKey = GroceryConstant.VEGETABLES; // Default to first sub-cat
    //   } else {
    //     _groceryFilter = null; // Hide tabs for other categories
    //   }
    // }

    _groceryController.fetchGroceryNestedCategoryWithInventory(
        userId: widget.userId, groceryCatKey: _argArrGroceryCatKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () =>
            PopupMenuButton<GroceryCategoryWithInventoryModel>(
          offset: const Offset(0, 30),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (GroceryCategoryWithInventoryModel value) {
            setState(() {
              _argArrGroceryCatName = value.name ?? '';
            });

            // Categories Dairy, Beverages, vegetables, fruit
            updateGroceryCategory(value.key ?? '', isInitial: true);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CustomText(
                  _argArrGroceryCatName,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis, // Handle long names safely
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          itemBuilder: (BuildContext context) {
            return _argGroceryCategoryWithInventory.map((choice) {
              final String iconPath = choice.image ?? '';
              final bool isUrl = isNetworkImage(iconPath);

              return PopupMenuItem<GroceryCategoryWithInventoryModel>(
                value: choice,
                child: Row(
                  children: [
                    // 2. Handle Image logic with caching
                    SizedBox(
                      width: SizeConfig.size20,
                      height: SizeConfig.size20,
                      child: isUrl
                          ? CachedNetworkImage(
                              imageUrl: iconPath,
                              fit: BoxFit.contain,
                              // Show a small loader or empty space while downloading
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 10,
                                  height: 10,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 1),
                                ),
                              ),
                              // Use placeholder asset if network fails
                              errorWidget: (context, url, error) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.contain,
                              ),
                            )
                          : LocalAssets(
                              imagePath: iconPath,
                              boxFix: BoxFit.contain,
                            ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      choice.name?.tr,
                      color: choice == _argArrGroceryCatKey
                          ? AppColors
                              .primaryColor // Use your AppColors for consistency
                          : AppColors.black,
                      fontWeight: choice == _argArrGroceryCatKey
                          ? FontWeight.bold
                          : FontWeight.normal,
                    )
                  ],
                ),
              );
            }).toList();
          },
        ),
        // buildCustomActionWidget: () => (widget.userId == userId) ? SizedBox.shrink()
        //     : const AdminCartIcon(),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_groceryController
              .groceryNestedCategoryWithInventoryLoading.value) {
            return _loadingGrid();
          }
          final items =
              _groceryController.groceryNestedCategoryWithInventoryList;
          if (items.isEmpty) {
            return EmptyStateWidget(
              message: AppStrings.groceryViewNoCategoriesFoundPlain.tr,
            );
          }
          return MasonryGridView.count(
            // Three across: these tiles are picked by sight, so more of the
            // shelf visible at once beats a larger single tile. Masonry (not a
            // fixed aspect ratio) lets a two-line category name grow without
            // overflowing the narrower column.
            crossAxisCount: _kColumns,
            crossAxisSpacing: SizeConfig.size10,
            mainAxisSpacing: SizeConfig.size10,
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              SizeConfig.size12,
              SizeConfig.size12,
              SizeConfig.size30,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _categoryTile(items[index]),
          );
        }),
      ),
    );
  }

  /// One category tile.
  ///
  /// Built around the image because that's how a shop owner recognises a
  /// shelf — name second, and the sub-category count as a small badge in the
  /// image corner. At this column width there isn't room for the old
  /// comma-joined children list, and it was ellipsized to one line anyway, so
  /// the count carries that information instead.
  Widget _categoryTile(GroceryNestedCategoryModel item) {
    final childCount = item.children?.length ?? 0;
    // Seed on the stable key, falling back to the name, so the colour survives
    // re-ordering.
    final tone = _toneFor(item.key ?? item.name ?? '');

    return Material(
      color: tone.fill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Get.toNamed(
          RouteHelper.getMyGroceryProductsScreenRoute(),
          arguments: {
            ApiKeys.userId: widget.userId,
            ApiKeys.argGroceries: item.children,
          },
        ),
        borderRadius: BorderRadius.circular(16),
        // Ripple in the tile's own ink so the feedback belongs to the tile
        // rather than reading as a stray brand-blue splash.
        splashColor: tone.ink.withValues(alpha: 0.12),
        highlightColor: tone.ink.withValues(alpha: 0.06),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Hairline in the same ink at low alpha — separates adjacent tiles
            // of similar tone without adding a hard grey outline.
            border: Border.all(color: tone.ink.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Positioned.fill(child: _tilePlate(item.image)),
                    if (childCount > 0)
                      Positioned(
                        top: SizeConfig.size4,
                        right: SizeConfig.size4,
                        child: _countBadge(childCount, tone),
                      ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size8),
              CustomText(
                item.name ?? '',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                // Label in the tile's ink, not a generic text colour, so each
                // tile reads as one object.
                color: tone.ink,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size4),
            ],
          ),
        ),
      ),
    );
  }

  /// The white "plate" the product sits on — goods on a shelf. Keeping the
  /// image on white stops packaged shots from muddying into the tile's tint.
  ///
  /// `contain` (not `cover`) because at this size a cropped label is
  /// unrecognisable, which defeats the point of leading with the image.
  Widget _tilePlate(String? url) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(SizeConfig.size8),
      child: (url == null || url.isEmpty)
          ? LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.contain,
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.contain,
              ),
            ),
    );
  }

  /// How many sub-categories sit under this one. Sits on the plate corner so
  /// the footer is left to the name alone at this column width.
  Widget _countBadge(int count, _ShelfTone tone) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size6,
        vertical: SizeConfig.size2,
      ),
      decoration: BoxDecoration(
        color: tone.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        '$count',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
    );
  }

  /// Skeleton tiles rather than a centred spinner: the grid keeps its shape
  /// while loading, so content doesn't jump when it arrives. Cycling the same
  /// palette means the load state previews the real thing.
  Widget _loadingGrid() {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size30,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _kColumns,
        crossAxisSpacing: SizeConfig.size10,
        mainAxisSpacing: SizeConfig.size10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, index) {
        final tone = _kShelfTones[index % _kShelfTones.length];
        return Container(
          padding: EdgeInsets.all(SizeConfig.size8),
          decoration: BoxDecoration(
            color: tone.fill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size10),
              Container(
                height: SizeConfig.size8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: tone.ink.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
