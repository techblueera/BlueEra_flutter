import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/common_back_app_bar.dart';

class GroceryCategoryScreen extends StatefulWidget {
  final List<CollapsibleGridModel> argArrGrocerySuperCat;
  final String argArrGroceryCatKey;
  final String argArrGroceryCatName;
  final bool isMyGrocery;

  const GroceryCategoryScreen(
      {super.key,
      required this.argArrGrocerySuperCat,
      required this.argArrGroceryCatKey,
      required this.argArrGroceryCatName,
      required this.isMyGrocery});

  @override
  State<GroceryCategoryScreen> createState() => _GroceryCategoryScreenState();
}

class _GroceryCategoryScreenState extends State<GroceryCategoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final _groceryController = getOrPut(() => GroceryController());
  late bool _isMyGrocery;
  late String _argArrGroceryCatName;
  late String _argArrGroceryCatKey;
  late List<CollapsibleGridModel> _argArrGrocerySuperCat;

  @override
  void initState() {
    _isMyGrocery = widget.isMyGrocery;
    _argArrGroceryCatName = widget.argArrGroceryCatName;
    _argArrGroceryCatKey = widget.argArrGroceryCatKey;
    _argArrGrocerySuperCat = widget.argArrGrocerySuperCat;
    _groceryController.fetchGroceryNestedCategory(widget.argArrGroceryCatKey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.whiteF3,
        appBar: CommonBackAppBar(
            // title: _argArrGroceryCatName,
            isCustomTitleWidget: () => PopupMenuButton<CollapsibleGridModel>(
                  offset: const Offset(0, 30),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (CollapsibleGridModel value) {
                    print("Selected: $value");
                    setState(() {
                      _argArrGroceryCatName = value.name;
                      _argArrGroceryCatKey = value.slugId;
                    });

                    _groceryController
                        .fetchGroceryNestedCategory(_argArrGroceryCatKey);
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
                    return _argArrGrocerySuperCat.map((choice) {
                      return PopupMenuItem<CollapsibleGridModel>(
                        value: choice,
                        child: Row(
                          children: [
                            (isNetworkImage(choice.icon))
                                ? SvgPicture.network(
                                    choice.icon,
                                    width: SizeConfig.size20,
                                    height: SizeConfig.size20,
                                    fit: BoxFit.contain,
                                  )
                                : LocalAssets(
                                    imagePath: choice.icon,
                                    width: SizeConfig.size20,
                                    height: SizeConfig.size20,
                                    boxFix: BoxFit.contain,
                                  ),
                            SizedBox(width: SizeConfig.size8),
                            CustomText(
                              choice.name.tr,
                              color: choice == _argArrGroceryCatKey
                                  ? Colors.green
                                  : Colors.black,
                              fontWeight: choice == _argArrGroceryCatKey
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )
                          ],
                        ),
                      );
                    }).toList();
                  },
                )),
        body: SafeArea(
            child: Obx(() => _groceryController
                    .groceryNestedCategoryLoading.value
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount:
                        _groceryController.groceryNestedCategoryList.length,
                    padding: EdgeInsets.only(
                      left: SizeConfig.size8,
                      right: SizeConfig.size8,
                      top: SizeConfig.size15,
                      bottom: SizeConfig.size30,
                    ),
                    itemBuilder: (context, index) {
                      var item =
                          _groceryController.groceryNestedCategoryList[index];

                      return Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size10),
                        child: InkWell(
                          onTap: () {
                            final route = _isMyGrocery
                                ? RouteHelper.getGrocerySubCategoryScreenRoute()
                                : RouteHelper.getGroceryListingScreenRoute();

                            Get.toNamed(
                              route,
                              arguments: {
                                ApiKeys.argGroceries: item.children,
                                // ApiKeys.argSelectedGroceryData: clickedLevel2Model,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: CustomFormCard(
                            padding: EdgeInsets.all(SizeConfig.size10),
                            child: Row(
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
                                      width: SizeConfig.size120,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => SizedBox(
                                          height: SizeConfig.size120,
                                          width: SizeConfig.size120,
                                          child: LocalAssets(
                                              imagePath: AppIconAssets
                                                  .place_holder_image)),
                                      errorWidget: (context, url, error) =>
                                          LocalAssets(
                                              imagePath: AppIconAssets
                                                  .place_holder_image),
                                    ),
                                  ),
                                ),
                                SizedBox(width: SizeConfig.size10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CustomText(item.name,
                                          fontSize: SizeConfig.large,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.mainTextColor,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      SizedBox(height: SizeConfig.size8),
                                      CustomText(
                                          item.children
                                              ?.map((e) => e.name)
                                              .toList()
                                              .join(', '),
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.secondaryTextColor,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      SizedBox(height: SizeConfig.size8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: SizeConfig.size6,
                                            vertical: SizeConfig.size4),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                            color: AppColors.boxBg),
                                        child: CustomText(
                                          '${item.children?.length} Category',
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ))

            // child: Obx(()=> _groceryController.groceryNestedCategoryLoading.value
            //     ? Center(child: CircularProgressIndicator())
            //     : ListView(
            //   shrinkWrap: true,
            //   physics: const BouncingScrollPhysics(),
            //   padding: EdgeInsets.only(bottom: SizeConfig.size40),
            //   children: (_groceryController.groceryNestedCategoryList).map((level1Category) {
            //     final title = level1Category.name ?? "";
            //     final level2Categories = level1Category.children ?? [];
            //
            //     if (level2Categories.isEmpty) {
            //       return const SizedBox.shrink();
            //     }
            //
            //     return CollapsibleGridSection(
            //       title: title,
            //       items: level2Categories,
            //       itemLabelBuilder: (item) => item.name ?? "",
            //       itemIconBuilder: (item) => item.image ?? "",
            //       onTap: (clickedLevel2Model) {
            //
            //         final route = isMyGrocery
            //             ? RouteHelper.getGrocerySubCategoryScreenRoute()
            //             : RouteHelper.getGroceryListingScreenRoute();
            //
            //         Get.toNamed(
            //           route,
            //           arguments: {
            //             ApiKeys.argGroceries: level2Categories,
            //             ApiKeys.argSelectedGroceryData: clickedLevel2Model,
            //           },
            //         );
            //       },
            //     );
            //   }).toList(),
            // )
            // ),

            ));
  }
}
