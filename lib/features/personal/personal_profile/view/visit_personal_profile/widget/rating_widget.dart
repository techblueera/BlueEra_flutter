import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/widgets/rating_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/controller/overview_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RatingSummaryWidget extends StatefulWidget {
  final double rating;
  final int ratingPersonCount;
  final String userId;
  final String screenFromName;
  final String ratingForAccountName;
  final String businessId;

  const RatingSummaryWidget({
    Key? key,
    required this.rating,
    required this.userId,
    required this.screenFromName,
    required this.ratingPersonCount, required this.ratingForAccountName, required this.businessId,
  }) : super(key: key);

  @override
  State<RatingSummaryWidget> createState() => _RatingSummaryWidgetState();
}

class _RatingSummaryWidgetState extends State<RatingSummaryWidget> {
  bool _isExpanded = false;
  late OverviewController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (!Get.isRegistered<OverviewController>()) {
      controller = Get.put(OverviewController());
    } else {
      controller = Get.find<OverviewController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      elevation: 0,
      margin: const EdgeInsets.all(0),
      // margin: const EdgeInsets.all(12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          // tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(0),
          enabled:
              widget.screenFromName == AppConstants.chatScreen ? true : false,
          trailing: widget.screenFromName == AppConstants.chatScreen
              ? Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size20),
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.mainTextColor,
                  ),
                )
              : SizedBox(),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          title: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText("Personal Rating Summary",
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.medium15,
                    color: AppColors.secondaryTextColor),
                const SizedBox(height: 8),
                // Obx(() {
                //   return RatingSummary(
                //     counter: (controller.ratingDetails.value?.totalRatings ?? 0),
                //     average: (controller.ratingDetails.value?.avgRating ?? 0.0)
                //         .toDouble(),
                //     showAverage: false,
                //     counterFiveStars:
                //     controller.ratingDetails.value?.ratingCounts?[0].rating ??
                //         0,
                //     counterFourStars:
                //     controller.ratingDetails.value?.ratingCounts?[1].rating ??
                //         0,
                //     counterThreeStars:
                //     controller.ratingDetails.value?.ratingCounts?[2].rating ??
                //         0,
                //     counterTwoStars:
                //     controller.ratingDetails.value?.ratingCounts?[3].rating ??
                //         0,
                //     counterOneStars:
                //     controller.ratingDetails.value?.ratingCounts?[4].rating ??
                //         3,
                //     thickness: 5,
                //     color: AppColors.primaryColor,
                //   );
                // }),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      widget.rating.toStringAsFixed(1),
                      fontSize: SizeConfig.size30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < widget.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                        ),
                        CustomText(
                          "(${formatNumberLikePost(widget.ratingPersonCount)}) People",
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return InkWell(
                    onTap: () {
                      if (isGuestUser()) {
                        createProfileScreen();

                        return;
                      }
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return RatingFeedbackDialog(
                            businessId: widget.userId,
                            reviewFor: widget.ratingForAccountName,
                          );
                        },
                      );
                    },
                    child: LocalAssets(imagePath: AppIconAssets.star_rounded));
              }),
            ),
            SizedBox(
              height: SizeConfig.size20,
            ),
            // Expanded rating details
            // Column(
            //   children: List.generate(5, (index) {
            //     int stars = 5 - index;
            //     return Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 4),
            //       child: Row(
            //         children: [
            //           Text("$stars"),
            //           const SizedBox(width: 4),
            //           const Icon(Icons.star, color: Colors.amber, size: 18),
            //           const SizedBox(width: 8),
            //           Expanded(
            //             child: LinearProgressIndicator(
            //               value: (stars * 0.2), // dummy distribution
            //               backgroundColor: Colors.grey.shade200,
            //               valueColor:
            //               const AlwaysStoppedAnimation<Color>(Colors.amber),
            //             ),
            //           ),
            //           const SizedBox(width: 8),
            //           Text("${stars * 200}"), // dummy review count
            //         ],
            //       ),
            //     );
            //   }),
            // )
          ],
        ),
      ),
    );
  }
}
