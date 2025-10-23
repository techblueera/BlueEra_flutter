import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_icon_assets.dart';
import '../auth/controller/view_business_details_controller.dart';

class RatingFeedbackDialog extends StatefulWidget {
  final String businessId, reviewFor;

  const RatingFeedbackDialog(
      {super.key, required this.businessId, required this.reviewFor});

  @override
  State<RatingFeedbackDialog> createState() => _RatingFeedbackDialogState();
}

class _RatingFeedbackDialogState extends State<RatingFeedbackDialog> {
  int selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final ViewBusinessDetailsController _ratingController = ViewBusinessDetailsController();
  bool _isSubmitting = false;

  String _getRatingImage(int index) {
    if (selectedRating == 0) {
      // Initial default images
      switch (index) {
        case 0:
          return AppIconAssets.rating1;
        case 1:
          return AppIconAssets.rating2;
        case 2:
          return AppIconAssets.rating3;
        case 3:
          return AppIconAssets.rating4;
        case 4:
          return AppIconAssets.rating5;
        default:
          return AppIconAssets.filledstar;
      }
    } else {
      // When user selects a rating
      if (index < selectedRating) {
        return AppIconAssets.filledstar;
      } else {
        // Show original default images for unselected
        switch (index) {
          case 0:
            return AppIconAssets.rating1;
          case 1:
            return AppIconAssets.rating2;
          case 2:
            return AppIconAssets.rating3;
          case 3:
            return AppIconAssets.rating4;
          case 4:
            return AppIconAssets.rating5;
          default:
            return AppIconAssets.filledstar;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                     CustomText(
                      (widget.reviewFor == AppConstants.business) ?
                      'How would you rate this\nbusiness?' : 'How would you rate this\n user?',
                        textAlign: TextAlign.center,
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRating = index + 1;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: SvgPicture.asset(
                                _getRatingImage(index),
                                width: 40,
                                height: 40,
                                placeholderBuilder: (_) => const Icon(
                                  Icons.star_border,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CustomText(
                        'Write a Feedback (Optional)',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CommonTextField(
                      textEditController: _feedbackController,
                      hintText: 'E.g. "Great service, quick\nresponse, highly recommended!"',
                      isValidate: false,
                      maxLine: 4,
                      maxLength: 120,
                      isCounterVisible: true,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomBtn(
                            height: SizeConfig.size40,
                            onTap: () {
                              Get.back();
                            },
                            title: "Cancel",
                            textColor: AppColors.primaryColor,
                            isValidate: false,
                            bgColor: AppColors.white,
                            borderColor: AppColors.primaryColor,
                            radius: 10.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomBtn(
                            isLoading: _isSubmitting,
                            height: SizeConfig.size40,
                            onTap: _isSubmitting
                                ? null
                                : () {
                              _submitFeedback(widget.reviewFor);
                            },
                            title: "Submit",
                            bgColor: AppColors.primaryColor,
                            borderColor: AppColors.primaryColor,
                            radius: 10.0,
                          ),
                        ),
                      ],
                    )

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitFeedback(String ratingFrom) async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (ratingFrom == AppConstants.business) {
        final success = await _ratingController.submitBusinessRatingController(
          businessId: widget.businessId,
          rating: selectedRating,
          comment: _feedbackController.text.trim(),
        );

        if (success && mounted) {
          Navigator.of(context).pop(success);
        }
      } else if (ratingFrom == AppConstants.individual) {
        final success = await _ratingController.submitPersonalRating(
          userId: widget.businessId,
          rating: selectedRating,
          comment: _feedbackController.text.trim(),
        );

        if (success && mounted) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
