import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/user_grocery_controller.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_bill_details.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class Rider {
  final String name;
  final String imageUrl;
  final double rating;
  final int reviews;
  final String distance;
  final int orderMatch;
  final int unavailableItems;
  final String orderTag;
  final bool showBookNow;
  final String contactNumber;

  Rider({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.orderMatch,
    required this.unavailableItems,
    required this.orderTag,
    required this.contactNumber,
    this.showBookNow = false,
  });
}

class GroceryConfirmScreen extends StatefulWidget {
  const GroceryConfirmScreen({super.key});

  @override
  State<GroceryConfirmScreen> createState() => _GroceryConfirmScreenState();
}

class _GroceryConfirmScreenState extends State<GroceryConfirmScreen> {
  final controller = getOrPut(() => UserGroceryController());

  final List<Rider> riders = [
    Rider(
      name: "Sanjib Sarkar",
      imageUrl: "https://picsum.photos/200/300?random=1",
      rating: 4.8,
      reviews: 48,
      distance: "1.2",
      orderMatch: 80,
      unavailableItems: 5,
      orderTag: "Second Order",
      contactNumber: '6542672648',
      showBookNow: false, // First card has only a "Call" button
    ),
    Rider(
      name: "Sanjib Sarkar",
      imageUrl: "https://picsum.photos/200/300?random=2",
      rating: 4.8,
      reviews: 48,
      distance: "1.2",
      orderMatch: 90,
      unavailableItems: 2,
      orderTag: "Second Order",
      contactNumber: '6542672648',
      showBookNow: true, // Second card has "Call" and "Book Now"
    ),
    // Add more rider data here...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.yourCart,
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size15,
                horizontal: SizeConfig.size8
            ),
            child: Column(
              children: [
                GroceryBillDetails(controller: controller),

                SizedBox(height: SizeConfig.paddingXSL),

                ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: riders.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return RiderCard(rider: riders[index]);
                  },
                )

              ],
            ),
          )
      ),
    );
  }
}

class RiderCard extends StatelessWidget {
  final Rider rider;

  const RiderCard({super.key, required this.rider});

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
              rider.imageUrl,
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
                        rider.name,
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
                    rating: rider.rating,
                    reviews: rider.reviews,
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
                    "${rider.orderMatch} % Order Match",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size4),

                  // Unavailable Items and Check button
                  Row(
                    children: [
                      CustomText(
                        "${rider.unavailableItems} Items Unavailable",
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
                      rider.orderTag,
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
                      if (rider.showBookNow) ...[
                        CustomBtn(
                          height: SizeConfig.size24,
                          width: SizeConfig.size40,
                          onTap: ()=> openDialer(rider.contactNumber),
                          title: AppStrings.call,
                          textColor: AppColors.secondaryTextColor,
                          bgColor: Colors.transparent,
                          borderColor: AppColors.secondaryTextColor,
                          radius: 6.0,
                        ),
                        SizedBox(width: SizeConfig.size6),
                        // Filled "Book Now" button
                        CustomBtn(
                          height: SizeConfig.size24,
                          width: SizeConfig.size70,
                          onTap: () {},
                          title: "Book Now",
                          bgColor: AppColors.primaryColor,
                          radius: 6.0,
                        ),
                      ] else ...[
                        // Filled "Call" button
                        CustomBtn(
                          height: SizeConfig.size24,
                          width: SizeConfig.size40,
                          onTap: ()=> openDialer(rider.contactNumber),
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
