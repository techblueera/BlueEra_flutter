import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/widgets/rating_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/controller/overview_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/regular_expression.dart';
import '../../../../../../widgets/commom_textfield.dart';
import '../../../../../../widgets/common_draggable_bottom_sheet.dart';



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
    required this.ratingPersonCount,
    required this.ratingForAccountName,
    required this.businessId,
  }) : super(key: key);

  @override
  State<RatingSummaryWidget> createState() => _RatingSummaryWidgetState();
}

class _RatingSummaryWidgetState extends State<RatingSummaryWidget> {
  late OverviewController controller;

  @override
  void initState() {
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
      elevation: 0.5,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size10),
      ),
      margin: EdgeInsets.only(left:SizeConfig.size8,right:SizeConfig.size8 ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            CustomText(
              "Rating Summary",
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.size18,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size12),

            // Average rating + stars + reviews
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rating number
                CustomText(
                  widget.rating.toStringAsFixed(1),
                  fontSize: SizeConfig.size50,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(width: SizeConfig.size10),

                // Stars + review count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        bool isFilled = index < widget.rating.round();
                        return Icon(
                          isFilled ? Icons.star : Icons.star_border,
                          color: AppColors.rating,
                          size: SizeConfig.size16,
                        );
                      }),
                    ),
                    SizedBox(height: 2),
                    CustomText(
                      "${formatNumberLikePost(widget.ratingPersonCount)} Reviews",
                      fontSize: SizeConfig.size14,
                      fontWeight: FontWeight.bold,

                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.mainTextColor,),
              ],
            ),

            SizedBox(height: SizeConfig.size10),

            // Interactive stars (for giving review)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      _openRateAndReviewSheet(context);
                    },
                    child: LocalAssets(imagePath: AppIconAssets.empty_star),
                  );
                }),
              ),
            ),
            SizedBox(height: SizeConfig.size20),
          ],
        ),
      ),
    );
  }

  void _openRateAndReviewSheet(BuildContext context) {
    showModalBottomSheet(
      isDismissible: true,
        context: context,
       // barrierDismissible: true,
        builder: (context) => RatingFeedbackDialog(businessId: widget.businessId,
          reviewFor: AppConstants.business,)
    );
  }
}


class RateAndReviewBottomSheet extends StatefulWidget {
  const RateAndReviewBottomSheet({super.key});

  @override
  State<RateAndReviewBottomSheet> createState() => _RateAndReviewBottomSheetState();
}

class _RateAndReviewBottomSheetState extends State<RateAndReviewBottomSheet> {
  int selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return CommonDraggableBottomSheet(
      // initialChildSize: 0.75,
      // minChildSize: 0.55,
      // maxChildSize: 0.9,
      builder: (scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size20,
              vertical: SizeConfig.size6,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate,
              child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar


                  // Title
                  Center(
                    child: CustomText(
                      "Rate And Review",
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.size18,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Star rating
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRating = index + 1;  // update rating
                            });
                          },
                          child: LocalAssets(
                            imagePath: index < selectedRating
                                ? AppIconAssets.fill_star      // filled star for selected
                                : AppIconAssets.empty_star,    // empty star for rest
                          ),
                        );
                      }),
                    )
                    ,
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Review input
                  CommonTextField(
                    textEditController: _reviewController,
                    inputLength: 250,

                    keyBoardType: TextInputType.multiline,
                    regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                    title: "Write Your Review (Optional)",
                    titleColor: AppColors.grayText,
                    maxLine: 5,
                    hintText:
                    'E.g. "Great service, quick response, highly recommended!"',
                    autovalidateMode: _autoValidate,
                    validator: (value) {
                      if (selectedRating == 0) {
                        return 'Please select a rating';
                      }
                      return null;
                    },

                  ),

                  SizedBox(height: SizeConfig.size20),

                  // Upload image/video
                  CustomText(
                    "Share Image or Video (Optional)",
                    fontSize: SizeConfig.size13,
                    color: AppColors.grayText,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  GestureDetector(
                    onTap: () {
                      // TODO: Handle upload
                    },
                    child: Container(
                      padding: EdgeInsets.all(SizeConfig.size14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.greyE5,
                        ),
                        borderRadius: BorderRadius.circular(SizeConfig.size10),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 1),     // 0px 1px
                            blurRadius: 2,                  // 2px
                            spreadRadius: 0,
                            color: AppColors.white, // #00000014
                          ),
                        ],
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                          'assets/diwali_card/upload.png',
                            color: AppColors.secondaryTextColor,

                          ),
                          SizedBox(width: SizeConfig.size10),
                          CustomText(
                            "Upload Image or Video",
                            color: AppColors.grayText,
                            fontSize: SizeConfig.size14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                          title: "Cancel",
                          onTap: () => Navigator.pop(context),
                          bgColor:  AppColors.white,

                          textColor: AppColors.primaryColor,
                          borderColor: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size12),
                      Expanded(
                        child: CustomBtn(
                          title: "Submit",
                          bgColor: AppColors.primaryColor,

                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              // Handle submission
                            } else {
                              setState(() {
                                _autoValidate = AutovalidateMode.always;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
