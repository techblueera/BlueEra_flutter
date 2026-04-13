import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class EarnServiceTestimonialCard extends StatelessWidget {
  final List<TestimonialItem> testimonials;

  const EarnServiceTestimonialCard({
    super.key,
    required this.testimonials,
  });

  @override
  Widget build(BuildContext context) {
    if (testimonials.isEmpty) return const SizedBox.shrink();

    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Testimonials',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: testimonials.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildTestimonialCard(testimonials[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(TestimonialItem item) {
    return Container(
      width: SizeConfig.screenWidth * 0.7,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CachedAvatarWidget(
                imageUrl: item.userImage,
                size: 36,
                borderRadius: 18,
                showProfileOnFullScreen: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      item.userName,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          starIndex < item.rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomText(
              item.review,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class TestimonialItem {
  final String userName;
  final String? userImage;
  final int rating;
  final String review;

  const TestimonialItem({
    required this.userName,
    this.userImage,
    required this.rating,
    required this.review,
  });
}
