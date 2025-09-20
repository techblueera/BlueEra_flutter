import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final ViewBusinessDetailsController _ratingController =
      ViewBusinessDetailsController();
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                     CustomText(
                      widget.reviewFor==AppConstants.business?
                      'How would you rate this\nbusiness?':'How would you rate this\n user?',
                      textAlign: TextAlign.center,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: SvgPicture.asset(
                              _getRatingImage(index),
                              width: 32,
                              height: 32,
                              placeholderBuilder: (_) => const Icon(
                                Icons.star_border,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Write a Feedback (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        controller: _feedbackController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText:
                              'E.g. "Great service, quick\nresponse, highly recommended!"',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null

                            : () {
                                _submitFeedback(widget.reviewFor);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2399F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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
          userId: widget.businessId,
          rating: selectedRating,
          comment: _feedbackController.text.trim(),
        );


        if (success && mounted) {
          Navigator.of(context).pop();
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
