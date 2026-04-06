// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/popup_menu_builders.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/getx_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
// import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
// import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
// import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:get/get.dart';
//
// class AddGroceryScreen extends StatefulWidget {
//   const AddGroceryScreen({super.key});
//
//   @override
//   State<AddGroceryScreen> createState() => _AddGroceryScreenState();
// }
//
// class _AddGroceryScreenState extends State<AddGroceryScreen> {
//   final controller = getOrPut(() => GroceryController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CommonBackAppBar(),
//       bottomNavigationBar: Material(
//         elevation: 8.0,
//         child: Container(
//           color: AppColors.white,
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//                 horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
//             child: Obx(()=> SafeArea(
//               child: CustomBtn(
//                 onTap: () {
//                   Get.toNamed(RouteHelper.getAddGroceryVariantScreenRoute());
//                 },
//                 isValidate: true,
//                 radius: SizeConfig.size8,
//                 title: 'Continue with ${controller.selectedGroceries.length} Products',
//                 // title: 'Post ${controller.selectedGroceries.length} Products',
//               ),
//             )),
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: EdgeInsets.symmetric(
//           horizontal: SizeConfig.size8,
//           vertical: SizeConfig.size20,
//         ),
//         child: Obx(() => MasonryGridView.count(
//               itemCount: controller.selectedGroceries.length,
//               crossAxisCount: 2,
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 10,
//               itemBuilder: (_, i) =>
//                   groceryCard(controller.selectedGroceries[i], i),
//             )),
//       ),
//     );
//   }
//
//   Widget groceryCard(GroceryProductData p, int index) {
//     final price = controller.getPriceDetails(p.variants?[0].pricing);
//
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Stack(
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10.0),
//                 child: Container(
//                   padding: EdgeInsets.only(top: 4.0),
//                   height: SizeConfig.size150,
//                   width: double.infinity,
//                   child: (p.images!=null && p.images!.isNotEmpty)
//                       ? CachedNetworkImage(
//                     imageUrl: p.images!.first.url??'',
//                     fit: BoxFit.cover,
//                     placeholder: (context, url) => Container(
//                       color: Colors.grey.shade200,
//                       child: Center(
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     ),
//                     errorWidget: (context, url, error) => LocalAssets(
//                       imagePath: AppIconAssets.place_holder_image,
//                       boxFix: BoxFit.cover,
//                     ),
//                   )
//                       : LocalAssets(
//                     imagePath: AppIconAssets.place_holder_image,
//                     boxFix: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               Positioned(
//                   top: SizeConfig.size2,
//                   right: SizeConfig.size2,
//                   child: _groceryPopUpMenu(index))
//             ],
//           ),
//           Padding(
//             padding: EdgeInsets.symmetric(
//                 horizontal: 9.0, vertical: SizeConfig.size6),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CustomText(
//                   "${p.name}",
//                   fontSize: SizeConfig.small,
//                   maxLines: 1,
//                   color: AppColors.mainTextColor,
//                   overflow: TextOverflow.ellipsis,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 SizedBox(height: SizeConfig.size6),
//                 Row(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                           border:
//                               Border.all(color: AppColors.green00, width: 1),
//                           borderRadius: BorderRadius.circular(2)),
//                       padding: EdgeInsets.all(3.5),
//                       child: Container(
//                         height: 7,
//                         width: 7,
//                         decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(7),
//                             color: AppColors.green00),
//                       ),
//                     ),
//                     SizedBox(width: SizeConfig.size6),
//                     Container(
//                       decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(4),
//                           border:
//                               Border.all(width: 0.5, color: AppColors.greyE5)),
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                       child: CustomText(
//                         '${p.variants?[0].quantity}',
//                         fontSize: 11,
//                         color: AppColors.secondaryTextColor,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: SizeConfig.size6),
//                 PriceRow(
//                   sellingPrice: "${price.sellingRange}",
//                   mrp: "${price.mrpRange}",
//                   discount: "${price.discountRange}",
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: SizeConfig.size4),
//         ],
//       ),
//     );
//   }
//
//   Widget _groceryPopUpMenu(int i) {
//     return PopupMenuButton<String>(
//       padding: EdgeInsets.zero,
//       offset: const Offset(-6, 36),
//       color: AppColors.white,
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       onSelected: (value) async {
//         if (value == AppConstants.EDIT) {
//           Get.back(result: true);
//         } else if (value == AppConstants.REMOVE) {
//           controller.selectedGroceries.removeAt(i);
//           if (controller.selectedGroceries.length == 0) {
//             Get.back(result: true);
//           }
//         }
//       },
//       icon: Container(
//         padding: EdgeInsets.all(6),
//         decoration:
//             BoxDecoration(color: AppColors.blackMite, shape: BoxShape.circle),
//         alignment: Alignment.center,
//         child: Icon(
//           Icons.more_vert,
//           size: SizeConfig.size12,
//           color: AppColors.white,
//         ),
//       ),
//       itemBuilder: (context) => PopupMenuBuilders.groceryPopUpMenuItems(),
//     );
//   }
//
// }
