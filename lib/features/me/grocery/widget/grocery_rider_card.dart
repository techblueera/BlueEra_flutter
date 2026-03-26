import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/GetBlueeraPiolotModel.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_rider_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class GroceryRiderCard extends StatelessWidget {
  final String orderId;
  final Riders rider;

  GroceryRiderCard({super.key, required this.rider, required this.orderId});

  final controller = getOrPut(() => GroceryRiderConsumerController());

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.0)
      ),
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Rider Image
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
            child: Image.network(
              rider.user?.profileImage??'',
              height: SizeConfig.size180,
              width: SizeConfig.size140,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: SizeConfig.size160,
                  width: SizeConfig.size140,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.grey),
                );
              },
            ),
          ),


          // Rider Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Chat Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        rider.user?.name,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      InkWell(
                        onTap: () {
                          // _handleCallAction(contactNo);
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: SizeConfig.size6),
                          padding: EdgeInsets.all(SizeConfig.size5),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.secondaryTextColor),
                          ),
                          child: LocalAssets(
                              imagePath: AppIconAssets.chat,
                              imgColor: AppColors.secondaryTextColor,
                              height: SizeConfig.size14,
                              width: SizeConfig.size14
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: SizeConfig.size5),

                  // Rating, Reviews, and Distance
                  CommonRatingRow(
                    rating: (rider.riderData?.ratings?.average ?? 0).toDouble(),
                    reviews: (rider.riderData?.ratings?.count ?? 0).toInt(),
                    distance: rider.distance,
                  ),

                  SizedBox(height: SizeConfig.size8),

                  DashedBorderContainer(
                    borderColor: AppColors.greyE5,
                    strokeWidth: 1,
                    dashLength: 2,
                    child: SizedBox(
                      height: 1,
                      width: double.maxFinite,
                    ),
                  ),

                  SizedBox(height: SizeConfig.size8),

                  // Order Match Percentage
                  CustomText(
                    "80 % Order Match",
                    // "${rider.orderMatch} % Order Match",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size4),

                  // Unavailable Items and Check button
                  Row(
                    children: [
                      CustomText(
                        "5 Items Unavailable",
                        // "${rider.unavailableItems} Items Unavailable",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(width: SizeConfig.size8),
                      GestureDetector(
                        onTap: () {
                          // Handle "Check" tap
                        },
                        child: CustomText(
                          "Check",
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  // Order Tag
                  Container(
                    padding: EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.secondaryTextColor),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: CustomText(
                      'Second Order',
                      // rider.orderTag,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size12),

                  // Dynamic Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (rider.user?.contactNo?.isNotEmpty??false) ...[
                        if(rider.user?.contactNo?.isNotEmpty??false)
                          ...[
                            CustomBtn(
                              height: SizeConfig.size24,
                              width: SizeConfig.size40,
                              onTap: ()=> openDialer(rider.user?.contactNo??''),
                              title: AppStrings.call,
                              textColor: AppColors.secondaryTextColor,
                              bgColor: Colors.transparent,
                              borderColor: AppColors.secondaryTextColor,
                              radius: 6.0,
                            ),
                            SizedBox(width: SizeConfig.size6),
                          ],

                        // Filled "Book Now" button
                        CustomBtn(
                          height: SizeConfig.size24,
                          width: SizeConfig.size70,
                          onTap: () {
                            controller.executeOrderProcess(
                              orderId: orderId,
                              riderId: rider.riderData?.id ?? ''
                           );
                          },
                          title: "Book Now",
                          bgColor: AppColors.primaryColor,
                          radius: 6.0,
                        ),
                      ] else ...[
                        CustomBtn(
                          height: SizeConfig.size24,
                          width: SizeConfig.size40,
                          onTap: ()=> openDialer(rider.user?.contactNo??''),
                          title: AppStrings.call,
                          textColor: AppColors.secondaryTextColor,
                          bgColor: Colors.transparent,
                          borderColor: AppColors.secondaryTextColor,
                          radius: 6.0,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}