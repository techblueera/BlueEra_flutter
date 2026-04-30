import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/common_back_app_bar.dart';

class ProductNestedCategoryScreen extends StatefulWidget {
  final List<ProductNestedCategoryResponse> argArrProductSuperCat;
  final String argArrProductCatId;
  final String argArrProductCatName;

  const ProductNestedCategoryScreen({
    super.key,
    required this.argArrProductSuperCat,
    required this.argArrProductCatId,
    required this.argArrProductCatName,
  });

  @override
  State<ProductNestedCategoryScreen> createState() =>
      _ProductNestedCategoryScreenState();
}

class _ProductNestedCategoryScreenState
    extends State<ProductNestedCategoryScreen> {
  late String _argArrProductCatName;
  late String _argArrProductCatId;
  late List<ProductNestedCategoryResponse> _argArrProductSuperCat;
  List<ProductNestedCategoryResponse> _filteredChildren = [];

  @override
  void initState() {
    _argArrProductSuperCat = widget.argArrProductSuperCat;
    _argArrProductCatName = widget.argArrProductCatName;
    _argArrProductCatId = widget.argArrProductCatId;
    _applyFilter(_argArrProductCatId);
    super.initState();
  }

  void _applyFilter(String id) {
    final match = _argArrProductSuperCat.firstWhereOrNull(
      (cat) => cat.sId == id,
    );
    _argArrProductCatId = id;
    _filteredChildren = match?.children ?? [];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () =>
            PopupMenuButton<ProductNestedCategoryResponse>(
              offset: const Offset(0, 30),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (ProductNestedCategoryResponse value) {
                setState(() {
                  _argArrProductCatName = value.name ?? '';
                });
                _argArrProductCatId = value.sId ?? '';
                _applyFilter(value.sId ?? '');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: CustomText(
                      _argArrProductCatName,
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
                return _argArrProductSuperCat.map((choice) {
                  return PopupMenuItem<ProductNestedCategoryResponse>(
                    value: choice,
                    child: Row(
                      children: [
                        (isNetworkImage(choice.image))
                            ? SvgPicture.network(
                                choice.image ?? '',
                                width: SizeConfig.size20,
                                height: SizeConfig.size20,
                                fit: BoxFit.contain,
                              )
                            : LocalAssets(
                                imagePath: choice.image ?? '',
                                width: SizeConfig.size20,
                                height: SizeConfig.size20,
                                boxFix: BoxFit.contain,
                              ),
                        SizedBox(width: SizeConfig.size8),
                        CustomText(
                          choice.name?.tr,
                          color: choice.sId == _argArrProductCatId
                              ? Colors.green
                              : Colors.black,
                          fontWeight: choice.sId == _argArrProductCatId
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
        child: _filteredChildren.isEmpty
            ? const Center(child: Text('No subcategories found.'))
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
                itemCount: _filteredChildren.length,
                itemBuilder: (context, index) {
                  var item = _filteredChildren[index];

                  return InkWell(
                    onTap: () {
                      Get.toNamed(
                        RouteHelper.getStoreProductSelectionScreenRoute(),
                        arguments: {
                          ApiKeys.argProducts: item.children,
                          ApiKeys.argArrProductCatName: item.name,
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
                                    )),
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
                            item.name,
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
              ),
      ),
    );
  }
}
