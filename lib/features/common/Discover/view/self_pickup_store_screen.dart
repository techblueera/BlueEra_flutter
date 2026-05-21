// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/getx_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/core/widgets/custom_form_card.dart';
// import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
// import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
// import 'package:BlueEra/features/common/store/controller/store_controller.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:get/get.dart';
//
// class SelfPickupStoreScreen extends StatefulWidget {
//   const SelfPickupStoreScreen({super.key});
//
//   @override
//   State<SelfPickupStoreScreen> createState() => _SelfPickupStoreScreenState();
// }
//
// class _SelfPickupStoreScreenState extends State<SelfPickupStoreScreen> {
//   final AuthController _authController = Get.find<AuthController>();
//
//   void navigateToGroceryStore({
//     CategoryData? categoryData,
//     bool isGrocery = true,
//   }) {
//     final controller = getOrPut(() => NewStoreController());
//     if (categoryData != null) {
//       controller.selectedGroceryCategoryData.value = categoryData;
//     }
//     Get.toNamed(
//       RouteHelper.getGroceryStoresScreenRoute(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: SizeConfig.size8,
//       ),
//       child: CustomScrollView(
//
//         slivers: [
//
//           SliverToBoxAdapter(
//             child: CustomFormCard(
//               padding: EdgeInsets.all(SizeConfig.paddingXSL),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//
//                   CustomText(
//                       AppStrings.groceryNdStationary,
//                       fontSize: SizeConfig.medium,
//                       color: AppColors.mainTextColor,
//                       fontWeight: FontWeight.w400),
//
//                   SizedBox(height: SizeConfig.paddingXSL),
//
//                   _buildCategoryGrid(
//                     items: _authController.businessOnboardingGroceriesCategories,
//                     getName: (categoryItem) => categoryItem.name ?? '',
//                     getIcon: (categoryItem) => categoryItem.imageUrl ?? '',
//                     onTap: (categoryItem) {
//                       navigateToGroceryStore(
//                         categoryData: categoryItem,
//                         isGrocery: true
//                       );
//                     },
//                   ),
//
//                 ],
//               ),
//             ),
//           ),
//
//           _buildGap(),
//
//           SliverToBoxAdapter(
//             child: CustomFormCard(
//               padding: EdgeInsets.all(SizeConfig.paddingXSL),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//
//                 children: [
//
//                   CustomText(
//                       AppStrings.foodNearMe,
//                       fontSize: SizeConfig.medium,
//                       color: AppColors.mainTextColor,
//                       fontWeight: FontWeight.w400),
//
//                   SizedBox(height: SizeConfig.paddingXSL),
//
//                   _buildCategoryGrid(
//                     items: _authController.businessOnboardingFoodsCategories,
//                     getName: (item) => item.name ?? '',
//                     getIcon: (item) => item.imageUrl ?? '',
//                     onTap: (categoryItem) {
//                       navigateToGroceryStore(
//                           categoryData: categoryItem,
//                           isGrocery: false
//                       );
//                     },
//                   ),
//
//                 ],
//               ),
//             ),
//           ),
//
//           _buildGap(),
//
//           SliverToBoxAdapter(
//             child: CustomFormCard(
//               padding: EdgeInsets.all(SizeConfig.paddingXSL),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//
//                   CustomText(
//                       'Cloud Kitchen / Home Made Food',
//                       fontSize: SizeConfig.medium,
//                       color: AppColors.mainTextColor,
//                       fontWeight: FontWeight.w400),
//
//                   SizedBox(height: SizeConfig.paddingXSL),
//
//                   _buildCategoryGrid(
//                     items: cloudKitchenHomeMadeFood,
//                     getName: (item) => item.name,
//                     getIcon: (item) => item.icon,
//                     onTap: (item) {
//
//                     },
//                   ),
//
//                 ],
//               ),
//             ),
//           ),
//
//           _buildGap(gap: SizeConfig.paddingM)
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildGap({double? gap}){
//     return  SliverToBoxAdapter(
//       child: SizedBox(height: gap ?? SizeConfig.paddingXSL),
//     );
//   }
//
//   Widget _buildCategoryGrid<T>({
//     required List<T> items,
//     required Function(T) getName,
//     required Function(T) getIcon,
//     required Function(T) onTap,
//   }) {
//     return MasonryGridView.count(
//       shrinkWrap: true,
//       primary: false,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: items.length,
//       crossAxisCount: 3,
//       crossAxisSpacing: 6,
//       mainAxisSpacing: 6,
//       padding: EdgeInsets.zero,
//       itemBuilder: (context, index) {
//         var item = items[index];
//         return CommonServiceCard<T>(
//           service: item,
//           getName: (item) => getName(item),
//           getIcon: (item) => getIcon(item),
//           iconHeight: SizeConfig.size60,
//           boxShadow: [],
//           onTap: (item) => onTap(item),
//         );
//       },
//     );
//   }
//
// }
