import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/tiffin_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/tiffin_meal_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/tiffin_bottom_sheet.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/primary_outline_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// class TiffinMenuManagementScreen extends StatelessWidget {
//    TiffinMenuManagementScreen({super.key});
//
//   final TiffinController controller = Get.find<TiffinController>();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(
//             vertical: 16.0,
//             horizontal: 8.0,
//         ),
//         child: Column(
//           children: [
//             _buildHeaderInput(),
//             const SizedBox(height: 16),
//             _buildMealCategoryCard(
//               title: "Morning Tiffin / Lunch",
//               subtitle: "Served 7AM - 2PM",
//               bgColor: const Color(0xFFFCFFD7), // Light Yellow
//               image: AppIconAssets.morningBreakfastIcon,
//               iconColor: Colors.orange,
//             ),
//             const SizedBox(height: 10),
//             _buildMealCategoryCard(
//               title: "Break-Fast",
//               subtitle: "Served 6AM - 10AM",
//               bgColor: const Color(0xFFFFF5EE), // Light Peach
//               image: AppIconAssets.morningLunchIcon,
//               iconColor: Colors.deepOrange,
//             ),
//             const SizedBox(height: 10),
//             _buildMealCategoryCard(
//               title: "Evening Tiffin / Dinner",
//               subtitle: "Served 5PM - 10PM",
//               bgColor: const Color(0xFFF0F8FF), // Light Blue
//               image: AppIconAssets.nightDinnerIcon,
//               iconColor: Colors.blue,
//             ),
//             const SizedBox(height: 40 + kBottomNavigationBarHeight),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // --- Header Input Field ---
//   Widget _buildHeaderInput() {
//     return CustomFormCard(
//       padding: const EdgeInsets.all(10.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CustomText(
//               'Name Of Food Centre',
//               fontWeight: FontWeight.w400,
//               color: AppColors.mainTextColor,
//              fontSize: SizeConfig.medium,
//           ),
//           SizedBox(height: 8.0),
//           Row(
//             children: [
//               const Expanded(
//                 child: CommonTextField(
//                   hintText: "E.g. Gupta Food Centre",
//                 ),
//               ),
//               const SizedBox(width: 10),
//               CustomBtn(
//                 width: SizeConfig.size90,
//                 height: SizeConfig.size40,
//                 title: 'Submit',
//                 onTap: (){},
//                 bgColor: AppColors.primaryColor,
//                 radius: 10,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMealCategoryCard({
//     required String title,
//     required String subtitle,
//     required Color bgColor,
//     required String image,
//     required Color iconColor,
//   }) {
//     return CustomFormCard(
//       padding: const EdgeInsets.all(10.0),
//       color: bgColor,
//       border: Border.all(color: AppColors.greyE5),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               LocalAssets(
//                   imagePath: image,
//                   height: SizeConfig.size40,
//                   width: SizeConfig.size40
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CustomText(
//                         title,
//                         fontWeight: FontWeight.w600,
//                         fontSize: SizeConfig.large,
//                         color: AppColors.mainTextColor,
//                     ),
//                     SizedBox(height: 2.0),
//                     CustomText(
//                       subtitle,
//                       fontWeight: FontWeight.w400,
//                       fontSize: SizeConfig.small,
//                       color: AppColors.secondaryTextColor,
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(width: 6.0),
//               Container(
//                 decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: AppColors.greyE5),
//                     borderRadius: BorderRadius.circular(10.0)
//                 ),
//                   padding: const EdgeInsets.symmetric(
//                      vertical: 8.0,
//                      horizontal: 10.0,
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       const CustomText(
//                           "Go Live",
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12.0,
//                           color: AppColors.secondaryTextColor
//                       ),
//                       SizedBox(width: 4.0),
//                       CustomSwitch(
//                         value: true,
//                         onChanged: (val) {
//                           controller.anyFoodHabitRestriction.value = !controller.anyFoodHabitRestriction.value;
//                         },
//                         containerHeight: SizeConfig.size24,
//                         containerWidth: SizeConfig.size50,
//                         circleSize: SizeConfig.size18,
//                       ),
//                     ],
//                   )
//               )
//             ],
//           ),
//           const SizedBox(height: 10),
//           _buildProductItemCard(Get.context!),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildProductItemCard(BuildContext context) {
//     return CustomFormCard(
//       padding: const EdgeInsets.all(10),
//       border: Border.all(color: AppColors.greyE5),
//       child: SizedBox(
//         height: 120,
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Product Image
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Stack(
//                 children: [
//                   LocalAssets(
//                     imagePath: AppImageAssets.homeMadeFoodBanner,
//                     height: 120,
//                     width: 100,
//                     boxFix: BoxFit.cover,
//                   ),
//
//                   Positioned.fill(
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: BackdropFilter(
//                           filter: ImageFilter.blur(
//                             sigmaX: 4.0,
//                             sigmaY: 4.0,
//                           ),
//                           child: Container(
//                             color: AppColors.black.withValues(alpha: 0.1),
//                           ),
//                         ),
//                       )
//                   ),
//
//                   Positioned(
//                     left: 6.0,
//                     top: 6.0,
//                     child: Container(
//                       decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6.0),
//                           color: AppColors.white
//                       ),
//                       padding: const EdgeInsets.all(2.0),
//                       child: Container(
//                         decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(2.0),
//                             border: Border.all(
//                                 color: AppColors.greenE0,
//                                 // color: AppColors.green00,
//                                 width: 1.0
//                             )
//                         ),
//                         padding: const EdgeInsets.all(2.0),
//                         child: Container(
//                           height: 8.0,
//                           width: 8.0,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: AppColors.greenE0,
//                             // color: AppColors.green00,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//
//             // Product Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const CustomText(
//                       "2 Idli + Sambar + Chutney + Lorem Ipsum",
//                       fontWeight: FontWeight.w600,
//                       fontSize: 16.0,
//                       color: AppColors.secondaryTextColor,
//                       maxLines: 2,
//                      overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       _buildTag("Boiled"),
//                       const SizedBox(width: 6),
//                       _buildTag("Tiffin/Lunch"),
//                     ],
//                   ),
//                   Spacer(),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 const CustomText(
//                                     "₹1,499",
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 14.0,
//                                     color: AppColors.secondaryTextColor
//                                 ),
//                                 const SizedBox(width: 4),
//                                 const CustomText(
//                                     "₹98,000",
//                                     fontWeight: FontWeight.w400,
//                                     fontSize: 12.0,
//                                     color: AppColors.secondaryTextColor),
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             DiscountBadge(
//                                 discountText: "50% Off",
//                                 borderColor: AppColors.secondaryTextColor.withValues(alpha: 0.2),
//                                 backgroundColor: AppColors.secondaryTextColor.withValues(alpha: 0.1),
//                                 iconColor: AppColors.secondaryTextColor,
//                                 textColor: AppColors.secondaryTextColor,
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//
//                       // Create Button
//                       PrimaryOutlineButton(
//                         onPressed: ()=> TiffinBottomSheet.show(context),
//                         icon: Icons.add,
//                         label: 'Create',
//                       )
//
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTag(String label) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(color: AppColors.greyE5),
//       ),
//       child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
//     );
//   }
//
//   Widget createButton({VoidCallback? onPressed}) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         decoration: BoxDecoration(
//           gradient: const RadialGradient(
//             center: Alignment.center,
//             radius: 1.5,
//             colors: [
//               Color(0x00FFFFFF),  // fully transparent in center
//               Color(0xFFB8DFFF),  // very light blue at corners
//             ],
//             stops: [0.4, 1.0],
//           ),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: AppColors.primaryColor,
//             width: 1.0,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.add,
//               color: AppColors.primaryColor,
//               size: 22,
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               'Create',
//               style: TextStyle(
//                 color: AppColors.primaryColor,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 letterSpacing: 0.3,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
// }

class TiffinMenuManagementScreen extends StatelessWidget {
  TiffinMenuManagementScreen({super.key});

  final TiffinController controller = Get.find<TiffinController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx( (){

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              _buildHeaderInput(),
              const SizedBox(height: 16),
              _buildMealCategoryCard(
                context:  context,
                mealType: MealType.morningTiffin,
                title: "Morning Tiffin / Lunch",
                subtitle: "Served 7AM - 2PM",
                bgColor:  const Color(0xFFFCFFD7),
                image:    AppIconAssets.morningBreakfastIcon,
              ),
              const SizedBox(height: 10),
              _buildMealCategoryCard(
                context:  context,
                mealType: MealType.breakfast,
                title:    "Break-Fast",
                subtitle: "Served 6AM - 10AM",
                bgColor:  const Color(0xFFFFF5EE),
                image:    AppIconAssets.morningLunchIcon,
              ),
              const SizedBox(height: 10),
              _buildMealCategoryCard(
                context:  context,
                mealType: MealType.eveningDinner,
                title:    "Evening Tiffin / Dinner",
                subtitle: "Served 5PM - 10PM",
                bgColor:  const Color(0xFFF0F8FF),
                image:    AppIconAssets.nightDinnerIcon,
              ),
              const SizedBox(height: 40 + kBottomNavigationBarHeight),
            ],
          ),
        );
       }

      ),
    );
  }

  Widget _buildMealCategoryCard({
    required BuildContext context,
    required MealType mealType,
    required String title,
    required String subtitle,
    required Color bgColor,
    required String image,
  }) {
    return Obx(() {
      final meal= controller.mealData[mealType]?.value;

      return CustomFormCard(
        padding: const EdgeInsets.all(10.0),
        color:   bgColor,
        border:  Border.all(color: AppColors.greyE5),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                LocalAssets(imagePath: image, height: SizeConfig.size40, width: SizeConfig.size40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(title, fontWeight: FontWeight.w600, fontSize: SizeConfig.large, color: AppColors.mainTextColor),
                      const SizedBox(height: 2.0),
                      CustomText(subtitle, fontWeight: FontWeight.w400, fontSize: SizeConfig.small, color: AppColors.secondaryTextColor),
                    ],
                  ),
                ),
                const SizedBox(width: 6.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.greyE5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  child: Row(
                    children: [
                      const CustomText("Go Live", fontWeight: FontWeight.w600, fontSize: 12.0, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 4.0),
                      CustomSwitch(
                        value: meal?.isLive ?? false,
                        onChanged: (val) {
                          if (meal?.hasData == true) {
                            controller.toggleGoLive(mealType, val);
                          }
                        },
                        containerHeight: SizeConfig.size24,
                        containerWidth:  SizeConfig.size50,
                        circleSize:      SizeConfig.size18,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),


            // ✅ No data — show dummy card with Create button
            if (meal == null || !meal.hasData)
              _buildDummyCard(context, mealType)

            // ✅ Has data — show real card with Edit button
            else
              _buildProductItemCard(context, meal),
          ],
        ),
      );
    });
  }

  // ✅ Dummy card — shown before any meal is created
  Widget _buildDummyCard(BuildContext context, MealType mealType) {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      border: Border.all(color: AppColors.greyE5),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dummy blurred image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.homeMadeFoodBanner,
                    height: 120, width: 100, boxFix: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(color: AppColors.black.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  _buildVegIndicator(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText(
                    "2 Idli + Sambar + Chutney",
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTag("Boiled"),
                      const SizedBox(width: 6),
                      _buildTag("Tiffin/Lunch"),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                CustomText("₹159", fontWeight: FontWeight.w700, fontSize: 14.0, color: AppColors.secondaryTextColor),
                                SizedBox(width: 4),
                                CustomText("₹200", fontWeight: FontWeight.w400, fontSize: 12.0, color: AppColors.secondaryTextColor),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DiscountBadge(
                              discountText: "20% Off",
                              borderColor:     AppColors.secondaryTextColor.withValues(alpha: 0.2),
                              backgroundColor: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                              iconColor:  AppColors.secondaryTextColor,
                              textColor:  AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // ✅ Create button
                      PrimaryOutlineButton(
                        onPressed: () {
                          controller.openCreateSheet(mealType);
                          TiffinBottomSheet.show(context);
                        },
                        icon:  Icons.add,
                        label: 'Create',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Real card — shown after meal is created/fetched from API
  Widget _buildProductItemCard(BuildContext context, TiffinMealModel meal) {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      border: Border.all(color: AppColors.greyE5),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // ✅ Network image from API or placeholder
                  meal.imageUrl != null
                      ? CachedNetworkImage(imageUrl: meal.imageUrl!, height: 120, width: 100, fit: BoxFit.cover)
                      : LocalAssets(imagePath: AppImageAssets.homeMadeFoodBanner, height: 120, width: 100, boxFix: BoxFit.cover),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(color: AppColors.black.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  _buildVegIndicator(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    meal.tiffinName,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (meal.selectedCookingMethod.isNotEmpty) _buildTag(meal.selectedCookingMethod),
                      if (meal.selectedFoodType.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildTag(meal.selectedFoodType),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CustomText('₹${meal.sellingPrice}', fontWeight: FontWeight.w700, fontSize: 14.0, color: AppColors.secondaryTextColor),
                                const SizedBox(width: 4),
                                CustomText('₹${meal.mrpPrice}', fontWeight: FontWeight.w400, fontSize: 12.0, color: AppColors.secondaryTextColor),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DiscountBadge(
                              discountText:    _calculateDiscount(meal.mrpPrice, meal.sellingPrice),
                              borderColor:     AppColors.secondaryTextColor.withValues(alpha: 0.2),
                              backgroundColor: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                              iconColor:  AppColors.secondaryTextColor,
                              textColor:  AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // ✅ Edit button — prefill form with real data
                      PrimaryOutlineButton(
                        onPressed: () {
                          controller.openEditSheet(meal);
                          TiffinBottomSheet.show(context);
                        },
                        icon:  Icons.edit,
                        label: 'Edit',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Veg indicator dot
  Widget _buildVegIndicator() {
    return Positioned(
      left: 6.0, top: 6.0,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6.0), color: AppColors.white),
        padding: const EdgeInsets.all(2.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.0),
            border: Border.all(color: AppColors.greenE0, width: 1.0),
          ),
          padding: const EdgeInsets.all(2.0),
          child: Container(
            height: 8.0, width: 8.0,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.greenE0),
          ),
        ),
      ),
    );
  }

  String _calculateDiscount(String mrp, String selling) {
    final mrpVal     = double.tryParse(mrp)     ?? 0;
    final sellingVal = double.tryParse(selling) ?? 0;
    if (mrpVal == 0) return '0% Off';
    final discount = ((mrpVal - sellingVal) / mrpVal * 100).toStringAsFixed(0);
    return '$discount% Off';
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }

  Widget _buildHeaderInput() {
    return CustomFormCard(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Name Of Food Centre',
            fontWeight: FontWeight.w400,
            color: AppColors.mainTextColor,
            fontSize: SizeConfig.medium,
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              const Expanded(
                child: CommonTextField(
                  hintText: "E.g. Gupta Food Centre",
                ),
              ),
              const SizedBox(width: 10),
              CustomBtn(
                width: SizeConfig.size90,
                height: SizeConfig.size40,
                title: 'Submit',
                onTap: (){},
                bgColor: AppColors.primaryColor,
                radius: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }
}