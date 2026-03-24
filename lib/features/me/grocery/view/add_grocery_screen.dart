import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AddGroceryScreen extends StatefulWidget {
  const AddGroceryScreen({super.key});

  @override
  State<AddGroceryScreen> createState() => _AddGroceryScreenState();
}

class _AddGroceryScreenState extends State<AddGroceryScreen> {
  final controller = getOrPut(() => GroceryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(),
      bottomNavigationBar: Material(
        elevation: 8.0,
        child: Container(
          color: AppColors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
            child: Obx(()=> SafeArea(
              child: CustomBtn(
                onTap: () {
                  Get.toNamed(RouteHelper.getAddGroceryVariantScreenRoute());
                },
                isValidate: true,
                radius: SizeConfig.size8,
                title: 'Post ${controller.selectedGroceries.length} Products',
                // isLoading: authController.isAddBusinessUserLoading.value
              ),
            )),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size20,
        ),
        child: Obx(() => MasonryGridView.count(
              itemCount: controller.selectedGroceries.length,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              itemBuilder: (_, i) =>
                  groceryCard(controller.selectedGroceries[i], i),
            )),
      ),
    );
  }

  Widget groceryCard(GroceryProductData p, int index) {
    final price = controller.getPriceDetails(p.variants?[0].pricing);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Container(
                  padding: EdgeInsets.only(top: 4.0),
                  height: SizeConfig.size150,
                  width: double.infinity,
                  child: (p.images!=null && p.images!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: p.images!.first.url??'',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  )
                      : LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                  top: SizeConfig.size2,
                  right: SizeConfig.size2,
                  child: _groceryPopUpMenu(index))
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 9.0, vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${p.name}",
                  fontSize: SizeConfig.small,
                  maxLines: 1,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(width: 0.5, color: AppColors.greyE5)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: CustomText(
                        '${p.variants?[0].quantity}',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: "${price.sellingRange}",
                  mrp: "${price.mrpRange}",
                  discount: "${price.discountRange}",
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size4),
        ],
      ),
    );
  }

  Widget _groceryPopUpMenu(int i) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        if (value == AppConstants.EDIT) {
          Get.back(result: true);
        } else if (value == AppConstants.REMOVE) {
          controller.selectedGroceries.removeAt(i);
          if (controller.selectedGroceries.length == 0) {
            Get.back(result: true);
          }
        }
      },
      icon: Container(
        padding: EdgeInsets.all(6),
        decoration:
            BoxDecoration(color: AppColors.blackMite, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(
          Icons.more_vert,
          size: SizeConfig.size12,
          color: AppColors.white,
        ),
      ),
      itemBuilder: (context) => groceryPopUpMenuItems(),
    );
  }

  // void showEditProductBottomSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return CommonDraggableBottomSheet(
  //         initialChildSize: 0.45,
  //         minChildSize: 0.3,
  //         maxChildSize: 0.95,
  //         backgroundColor: AppColors.whiteF1,
  //         boxShadow: [
  //           BoxShadow(
  //               color: AppColors.black.withValues(alpha: 0.1),
  //               blurRadius: 4.0,
  //               offset: Offset(0, -3))
  //         ],
  //         borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
  //         padding: EdgeInsets.only(
  //             top: SizeConfig.size10,
  //             bottom: kToolbarHeight),
  //         builder: (scrollController) {
  //           return SingleChildScrollView(
  //             controller: scrollController,
  //             child: Column(
  //               children: [
  //                 /// --- Top Drag Handle ---
  //                 Center(
  //                   child: Container(
  //                     width: 50,
  //                     height: 5,
  //                     margin: EdgeInsets.only(bottom: SizeConfig.size5),
  //                     decoration: BoxDecoration(
  //                       color: AppColors.secondaryTextColor,
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                 ),
  //
  //                 Padding(
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: SizeConfig.size12,
  //                   ),
  //                   child: Row(
  //                     children: [
  //                       Expanded(
  //                         child: CustomText(
  //                           "Edit Product",
  //                           fontSize: SizeConfig.medium,
  //                           color: AppColors.mainTextColor,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                       SizedBox(width: SizeConfig.size8),
  //                       IconButton(
  //                         onPressed: () => Get.back(),
  //                         icon: Icon(
  //                           Icons.close,
  //                           size: SizeConfig.size20,
  //                           color: AppColors.black,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 SizedBox(height: SizeConfig.size10),
  //                 ListView.separated(
  //                   // controller: scrollController,
  //                   itemCount: controller.selectedGroceries.length,
  //                   physics: NeverScrollableScrollPhysics(),
  //                   shrinkWrap: true,
  //                   padding: EdgeInsets.only(
  //                       bottom: SizeConfig.size12
  //                   ),
  //                   itemBuilder: (BuildContext context, int index) {
  //                     final groceryItem = controller.selectedGroceries[index];
  //                     return Padding(
  //                       padding: EdgeInsets.symmetric(
  //                         horizontal: SizeConfig.size12,
  //                       ),
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //
  //                           /// --- Image Carousel (Horizontal) ---
  //                           Container(
  //                             padding: EdgeInsets.all(10.0),
  //                             decoration: BoxDecoration(
  //                                 color: AppColors.primaryColor
  //                                     .withValues(alpha: 0.05),
  //                                 borderRadius: BorderRadius.circular(10.0)),
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                               SizedBox(
  //                               height: SizeConfig.size80,
  //                               child: (groceryItem.productInfo?.images?.isNotEmpty == true)
  //                                   ? ListView.separated(
  //                                 scrollDirection: Axis.horizontal,
  //                                 itemCount: groceryItem.productInfo!.images!.length,
  //                                 itemBuilder: (_, index) {
  //                                   final imgUrl =
  //                                       groceryItem.productInfo!.images![index].url ?? '';
  //
  //                                   return ClipRRect(
  //                                     borderRadius: BorderRadius.circular(10.0),
  //                                     child: SizedBox(
  //                                       height: SizeConfig.size80,
  //                                       width: SizeConfig.size80,
  //                                       child: CachedNetworkImage(
  //                                         imageUrl: imgUrl,
  //                                         fit: BoxFit.cover,
  //                                         placeholder: (_, __) => Container(
  //                                           color: Colors.grey.shade200,
  //                                           child: Center(
  //                                             child: CircularProgressIndicator(strokeWidth: 2),
  //                                           ),
  //                                         ),
  //                                         errorWidget: (_, __, ___) => LocalAssets(
  //                                           imagePath: AppIconAssets.place_holder_image,
  //                                           boxFix: BoxFit.cover,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   );
  //                                 },
  //                                 separatorBuilder: (_, __) => const SizedBox(width: 10),
  //                               )
  //                                   : ClipRRect(
  //                                 borderRadius: BorderRadius.circular(10),
  //                                 child: LocalAssets(
  //                                   imagePath: AppIconAssets.place_holder_image,
  //                                   boxFix: BoxFit.cover,
  //                                 ),
  //                               ),
  //                             ),
  //
  //                               SizedBox(height: SizeConfig.size10),
  //
  //                                 /// --- Product Title ---
  //                                 CustomText(
  //                                   groceryItem.productInfo?.name,
  //                                   fontSize: SizeConfig.medium,
  //                                   color: AppColors.mainTextColor,
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //
  //                                 SizedBox(height: SizeConfig.size8),
  //
  //                                 /// --- Price Row ---
  //                                 Row(
  //                                   crossAxisAlignment: CrossAxisAlignment.end,
  //                                   children: [
  //                                     Container(
  //                                       padding: EdgeInsets.all(4.0),
  //                                       decoration: BoxDecoration(
  //                                           color: AppColors.white,
  //                                           borderRadius:
  //                                               BorderRadius.circular(4.0),
  //                                           border: Border.all(
  //                                               color: AppColors.greyE5,
  //                                               width: 0.5)),
  //                                       child: CustomText(
  //                                         '${groceryItem.weight} ${groceryItem.unit}',
  //                                         fontSize: SizeConfig.small,
  //                                         color: AppColors.secondaryTextColor,
  //                                         fontWeight: FontWeight.w400,
  //                                       ),
  //                                     ),
  //                                     SizedBox(width: SizeConfig.size10),
  //                                     CustomText(
  //                                       "₹${groceryItem.pricing?[0].sellingPrice}",
  //                                       fontSize: SizeConfig.medium,
  //                                       color: AppColors.primaryColor,
  //                                       fontWeight: FontWeight.w700,
  //                                     ),
  //                                     SizedBox(width: SizeConfig.size8),
  //                                     CustomText(
  //                                       "₹${groceryItem.pricing?[0].mrp}",
  //                                       fontSize: SizeConfig.small,
  //                                       color: AppColors.secondaryTextColor,
  //                                       fontWeight: FontWeight.w400,
  //                                       decoration: TextDecoration.lineThrough,
  //                                       decorationColor:
  //                                           AppColors.secondaryTextColor,
  //                                     ),
  //                                     SizedBox(width: SizeConfig.size8),
  //                                     CustomText(
  //                                         "${calculateDiscount(
  //                                             groceryItem.pricing![0].sellingPrice.toString(),
  //                                             groceryItem.pricing![0].mrp.toString()
  //                                         ).toStringAsFixed(2)}% ${AppStrings.offCaps.tr}",
  //                                         fontSize: SizeConfig.small,
  //                                         color: AppColors.greenShade,
  //                                         fontWeight: FontWeight.w400),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //
  //                           SizedBox(height: SizeConfig.size16),
  //
  //                           /// --- Original MRP ---
  //                           CustomText(
  //                             "Original MRP",
  //                             fontSize: SizeConfig.medium,
  //                             color: AppColors.mainTextColor,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                           SizedBox(height: SizeConfig.size10),
  //                           Row(
  //                             children: [
  //                               Expanded(
  //                                 child: _TextFieldBox(
  //                                     title: 'Unit', hint: "E.g. 100G"),
  //                               ),
  //                               SizedBox(width: SizeConfig.size8),
  //                               Expanded(
  //                                 child: _TextFieldBox(
  //                                     title: 'Price', hint: "E.g. ₹1,999"),
  //                               ),
  //                             ],
  //                           ),
  //
  //                           SizedBox(height: SizeConfig.size16),
  //
  //                           /// --- Selling Price ---
  //                           CustomText(
  //                             "What Is Your Selling price",
  //                             fontSize: SizeConfig.medium,
  //                             color: AppColors.mainTextColor,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                           SizedBox(height: SizeConfig.size10),
  //                           Row(
  //                             children: [
  //                               Expanded(
  //                                 child: _TextFieldBox(
  //                                     title: 'Unit', hint: "E.g. 100G"),
  //                               ),
  //                               SizedBox(width: SizeConfig.size8),
  //                               Expanded(
  //                                 child: _TextFieldBox(
  //                                     title: 'Selling Price',
  //                                     hint: "E.g. ₹1,999"),
  //                               ),
  //                             ],
  //                           ),
  //
  //                           SizedBox(height: SizeConfig.size16),
  //
  //                           /// --- Expiry Date ---
  //                           CustomText(
  //                             "Expiry Date",
  //                             fontSize: SizeConfig.medium,
  //                             fontWeight: FontWeight.w400,
  //                             color: AppColors.mainTextColor,
  //                           ),
  //                           SizedBox(height: SizeConfig.size8),
  //                           NewDatePicker(
  //                             selectedDay: controller.selectedDay,
  //                             selectedMonth: controller.selectedMonth,
  //                             selectedYear: controller.selectedYear,
  //                             onDayChanged: (value) {
  //                                 controller.selectedDay = value;
  //                               // controller.validateForm();
  //                             },
  //                             onMonthChanged: (value) {
  //                                 controller.selectedMonth = value;
  //                                // controller.validateForm();
  //                             },
  //                             onYearChanged: (value) {
  //                                 controller.selectedYear = value;
  //                                 // controller.validateForm();
  //                             },
  //                           )
  //                         ],
  //                       ),
  //                     );
  //                   },
  //                   separatorBuilder: (BuildContext context, int index) {
  //                     return Padding(
  //                         padding:
  //                             EdgeInsets.symmetric(vertical: SizeConfig.size15),
  //                         child:
  //                             index != controller.selectedGroceries.length - 1
  //                                 ? CommonHorizontalDivider(
  //                                     color: AppColors.shadowColor,
  //                                   )
  //                                 : SizedBox());
  //                   },
  //                 ),
  //
  //                 SizedBox(height: SizeConfig.size20),
  //
  //                 /// --- Update Button ---
  //                 Padding(
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: SizeConfig.size12,
  //                   ),
  //                   child: CustomBtn(onTap: () {},
  //                       title: "Update",
  //                       bgColor: AppColors.primaryColor,
  //                   ),
  //                 )
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

}
