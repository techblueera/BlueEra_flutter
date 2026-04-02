import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/common_back_app_bar.dart';

class ProductNestedCategoryWithInventoryScreen extends StatefulWidget {
  final String userId;
  final List<ProductCategoryWithInventoryModel> argProductCategoryWithInventory;
  final String argProductCatKey;
  final String argProductCatName;

  const ProductNestedCategoryWithInventoryScreen({
    super.key,
    required this.userId,
    required this.argProductCategoryWithInventory,
    required this.argProductCatKey,
    required this.argProductCatName,
  });

  @override
  State<ProductNestedCategoryWithInventoryScreen> createState() =>
      _ProductNestedCategoryWithInventoryScreenState();
}

class _ProductNestedCategoryWithInventoryScreenState
    extends State<ProductNestedCategoryWithInventoryScreen> {
  final _inventoryController = getOrPut(() => InventoryController());
  late String _argProductCatName;
  late String _argProductCatKey;
  late List<ProductCategoryWithInventoryModel> _argProductCategoryWithInventory;

  @override
  void initState() {
    _argProductCategoryWithInventory = widget.argProductCategoryWithInventory;
    _argProductCatName = widget.argProductCatName;
    updateProductCategory(widget.argProductCatKey);
    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<InventoryController>();
    super.dispose();
  }

  void updateProductCategory(String incomingKey) {
    _argProductCatKey = incomingKey;
    _inventoryController.fetchProductNestedCategoryWithInventory(
      categoryKey: _argProductCatKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () =>
            PopupMenuButton<ProductCategoryWithInventoryModel>(
          offset: const Offset(0, 30),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (ProductCategoryWithInventoryModel value) {
            setState(() {
              _argProductCatName = value.name ?? '';
            });
            updateProductCategory(value.key ?? '');
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CustomText(
                  _argProductCatName,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
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
            return _argProductCategoryWithInventory.map((choice) {
              final String iconPath = choice.image ?? '';
              final bool isUrl = isNetworkImage(iconPath);

              return PopupMenuItem<ProductCategoryWithInventoryModel>(
                value: choice,
                child: Row(
                  children: [
                    SizedBox(
                      width: SizeConfig.size20,
                      height: SizeConfig.size20,
                      child: isUrl
                          ? CachedNetworkImage(
                              imageUrl: iconPath,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  LocalAssets(
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
                      color: choice.key == _argProductCatKey
                          ? AppColors.primaryColor
                          : AppColors.black,
                      fontWeight: choice.key == _argProductCatKey
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ),
      body: SafeArea(
        child: Obx(() => _inventoryController.productNestedCategoryLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _inventoryController.productNestedCategoryList.isEmpty
                ? const Center(child: Text('No categories found'))
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
                    itemCount: _inventoryController
                        .productNestedCategoryList.length,
                    itemBuilder: (context, index) {
                      var item = _inventoryController
                          .productNestedCategoryList[index];

                      return InkWell(
                        onTap: () {
                          Get.toNamed(
                            RouteHelper.getMyProductProductsScreenRoute(),
                            arguments: {
                              ApiKeys.userId: widget.userId,
                              ApiKeys.argProductCategories: item.children,
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
                                  '${item.children?.length ?? 0} Category',
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
    );
  }
}
