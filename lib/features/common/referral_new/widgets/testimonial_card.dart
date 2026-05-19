import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral_new/model/referral_testimonial_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Refined testimonial card — keeps the existing business-card hierarchy
/// from the BDM mockups (photo • name/role • quote • website • company)
/// and adds a few subtle visual signals so it doesn't read as a plain
/// rectangle:
///
///   • Decorative oversized quote glyph in the upper-right (low opacity,
///     primary tint) — pure decoration, ignored by screen readers.
///   • Soft 1px outer hairline + a thin primary accent strip on the left.
///   • Avatar wrapped in a faint primary ring so the profile picture
///     reads as the focal element regardless of source-image contrast.
class TestimonialCard extends StatelessWidget {
  final ReferralTestimonial testimonial;
  final double? width;
  final VoidCallback? onTap;
  final bool expanded;

  const TestimonialCard({
    super.key,
    required this.testimonial,
    this.width,
    this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFEEF1F8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // Left accent strip
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: Container(color: AppColors.primaryColor),
                ),
                // Decorative quote glyph
                Positioned(
                  top: 6,
                  right: 12,
                  child: Text(
                    '“',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    SizeConfig.size12 + 4,
                    SizeConfig.size12,
                    SizeConfig.size12,
                    SizeConfig.size12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _avatarHeader(),
                      SizedBox(height: SizeConfig.paddingM / 2),
                      CustomText(
                        testimonial.quote,
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        maxLines: expanded ? 6 : 3,
                        overflow: TextOverflow.ellipsis,
                        height: 1.4,
                      ),
                      if (testimonial.website != null &&
                          testimonial.website!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_rounded,
                                  size: 12,
                                  color: AppColors.primaryColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: CustomText(
                                  testimonial.website!,
                                  fontSize: SizeConfig.extraSmall,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.storefront_outlined,
                              size: 14,
                              color: AppColors.secondaryTextColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: CustomText(
                              testimonial.company,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: testimonial.profileImage,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 40, height: 40, color: AppColors.whiteE5),
              errorWidget: (_, __, ___) => Container(
                width: 40,
                height: 40,
                color: AppColors.whiteE5,
                child: Icon(Icons.person,
                    color: AppColors.secondaryTextColor, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                testimonial.name,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              CustomText(
                testimonial.role,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
