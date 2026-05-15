import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/widget/common_cart_icon.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
    deleteIfRegistered<GroceryController>();
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
        userId: widget.userId,
        groceryCatKey: _argArrGroceryCatKey
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          isCustomTitleWidget: () => PopupMenuButton<GroceryCategoryWithInventoryModel>(
            offset: const Offset(0, 30),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (GroceryCategoryWithInventoryModel value) {
              setState(() {
                _argArrGroceryCatName = value.name ?? '';
              });

              // Categories Dairy, Beverages, vegetables, fruit
              updateGroceryCategory(value.key??'', isInitial: true);
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
                    overflow:
                    TextOverflow.ellipsis, // Handle long names safely
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
                              child: CircularProgressIndicator(strokeWidth: 1),
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
                            ? AppColors.primaryColor // Use your AppColors for consistency
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
        child: Obx(() => _groceryController
            .groceryNestedCategoryWithInventoryLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _groceryController
            .groceryNestedCategoryWithInventoryList.isEmpty
            ? Center(child: Text(AppStrings.groceryViewNoCategoriesFoundPlain.tr))
            : MasonryGridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          padding: EdgeInsets.only(
            left: SizeConfig.size8,
            right: SizeConfig.size8,
            top: SizeConfig.size15,
            bottom: SizeConfig.size30,
          ),
          itemCount: _groceryController
              .groceryNestedCategoryWithInventoryList.length,
          itemBuilder: (context, index) {
            var item = _groceryController
                .groceryNestedCategoryWithInventoryList[index];

            return InkWell(
              onTap: () {
                Get.toNamed(
                  RouteHelper.getMyGroceryProductsScreenRoute(),
                  arguments: {
                    ApiKeys.userId: widget.userId,
                    ApiKeys.argGroceries: item.children,
                  },
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.whiteFE,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: item.image ?? '',
                          height: SizeConfig.size120,
                          width: double.maxFinite,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => SizedBox(
                            height: SizeConfig.size120,
                            width: SizeConfig.size120,
                            child: LocalAssets(
                              imagePath:
                              AppIconAssets.place_holder_image,
                              boxFix: BoxFit.cover,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              LocalAssets(
                                imagePath:
                                AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CustomText(
                      item.name ?? '',
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CustomText(
                      item.children
                          ?.map((e) => e.name)
                          .toList()
                          .join(', ') ??
                          '',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size6,
                        vertical: SizeConfig.size4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        color: AppColors.boxBg,
                      ),
                      child: CustomText(
                        '${item.children?.length ?? 0} ${AppStrings.groceryViewCategory.tr}',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )),
      ),

      // body: SafeArea(
      //   child: Obx(() => _groceryController
      //           .groceryNestedCategoryWithInventoryLoading.value
      //       ? const Center(child: CircularProgressIndicator())
      //       : _groceryController
      //               .groceryNestedCategoryWithInventoryList.isEmpty
      //           ? const Center(child: Text('No categories found'))
      //           : Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //
      //               if(_groceryFilter!=null)
      //                 ...[
      //                   SizedBox(height: SizeConfig.paddingXSL),
      //                   HorizontalTabSelector<String>(
      //                     horizontalMargin: SizeConfig.size8,
      //                     tabs: _groceryFilter!,
      //                     selectedIndex: _groceryFilter!.indexWhere((value) => value == _argArrGroceryCatKey),
      //                     onTabSelected: (index, value) {
      //                       setState(() {});
      //                       updateGroceryCategory(value, isInitial: false);
      //                     },
      //                     labelBuilder: (label) => label,
      //                   )
      //                 ],
      //
      //               Expanded(
      //                 child: MasonryGridView.count(
      //                     crossAxisCount: 2,
      //                     crossAxisSpacing: 6,
      //                     mainAxisSpacing: 6,
      //                     padding: EdgeInsets.only(
      //                       left: SizeConfig.size8,
      //                       right: SizeConfig.size8,
      //                       top: SizeConfig.size15,
      //                       bottom: SizeConfig.size30,
      //                     ),
      //                     itemCount: _groceryController
      //                         .groceryNestedCategoryWithInventoryList.length,
      //                     itemBuilder: (context, index) {
      //                       var item = _groceryController
      //                           .groceryNestedCategoryWithInventoryList[index];
      //
      //                       return InkWell(
      //                         onTap: () {
      //                           Get.toNamed(
      //                             RouteHelper.getGroceryProductsScreenRoute(),
      //                             arguments: {
      //                               ApiKeys.userId: widget.userId,
      //                               ApiKeys.argGroceries: item.children,
      //                             },
      //                           );
      //                         },
      //                         borderRadius: BorderRadius.circular(10),
      //                         child: CustomFormCard(
      //                           padding: EdgeInsets.all(SizeConfig.size10),
      //                           child: Column(
      //                             crossAxisAlignment: CrossAxisAlignment.start,
      //                             mainAxisAlignment: MainAxisAlignment.start,
      //                             children: [
      //                               ClipRRect(
      //                                 borderRadius: BorderRadius.circular(10),
      //                                 child: Container(
      //                                   decoration: BoxDecoration(
      //                                     borderRadius: BorderRadius.circular(10),
      //                                     color: AppColors.whiteFE,
      //                                   ),
      //                                   child: CachedNetworkImage(
      //                                     imageUrl: item.image ?? '',
      //                                     height: SizeConfig.size120,
      //                                     width: double.maxFinite,
      //                                     fit: BoxFit.cover,
      //                                     placeholder: (context, url) => SizedBox(
      //                                       height: SizeConfig.size120,
      //                                       width: SizeConfig.size120,
      //                                       child: LocalAssets(
      //                                         imagePath:
      //                                             AppIconAssets.place_holder_image,
      //                                         boxFix: BoxFit.cover,
      //                                       ),
      //                                     ),
      //                                     errorWidget: (context, url, error) =>
      //                                         LocalAssets(
      //                                       imagePath:
      //                                           AppIconAssets.place_holder_image,
      //                                       boxFix: BoxFit.cover,
      //                                     ),
      //                                   ),
      //                                 ),
      //                               ),
      //                               SizedBox(height: SizeConfig.size10),
      //                               CustomText(
      //                                 item.name ?? '',
      //                                 fontSize: SizeConfig.large,
      //                                 fontWeight: FontWeight.w600,
      //                                 color: AppColors.mainTextColor,
      //                                 maxLines: 1,
      //                                 overflow: TextOverflow.ellipsis,
      //                               ),
      //                               SizedBox(height: SizeConfig.size8),
      //                               CustomText(
      //                                 item.children
      //                                         ?.map((e) => e.name)
      //                                         .toList()
      //                                         .join(', ') ??
      //                                     '',
      //                                 fontSize: SizeConfig.small,
      //                                 fontWeight: FontWeight.w400,
      //                                 color: AppColors.secondaryTextColor,
      //                                 maxLines: 1,
      //                                 overflow: TextOverflow.ellipsis,
      //                               ),
      //                               SizedBox(height: SizeConfig.size10),
      //                               Container(
      //                                 padding: EdgeInsets.symmetric(
      //                                   horizontal: SizeConfig.size6,
      //                                   vertical: SizeConfig.size4,
      //                                 ),
      //                                 decoration: BoxDecoration(
      //                                   borderRadius: BorderRadius.circular(4.0),
      //                                   color: AppColors.boxBg,
      //                                 ),
      //                                 child: CustomText(
      //                                   '${item.children?.length ?? 0} Category',
      //                                   fontSize: SizeConfig.small,
      //                                   fontWeight: FontWeight.w600,
      //                                   color: AppColors.secondaryTextColor,
      //                                 ),
      //                               ),
      //                             ],
      //                           ),
      //                         ),
      //                       );
      //                     },
      //                   ),
      //               ),
      //             ],
      //           )),
      // ),

    );
  }
}
