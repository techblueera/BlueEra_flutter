import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceProviderDetailScreen extends StatelessWidget {
  final ServiceData service;

  const ServiceProviderDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: service.profession ?? AppStrings.serviceDetails,
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            _HeaderSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// ABOUT
            _AboutSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// PRICING
            _PricingSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// TIMING
            _TimingSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// SERVICES OFFERED / FACILITIES
            _ServicesOfferedSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// WHY CHOOSE ME
            _WhyChooseMeSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// SKILLS / EXPERTISE
            _ExpertiseSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// EXPERIENCE
            _ExperienceSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// GALLERY
            _GallerySection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// REVIEWS
            _emptySection(
                Icons.rate_review_outlined,
                "Reviews",
                "No reviews yet. Be the first to review!"),

            SizedBox(height: SizeConfig.paddingXS),

            /// CONTACT
            _ContactSection(service: service),

            SizedBox(height: SizeConfig.paddingXS),

            /// WEBSITE PREVIEW
            WebsitePreviewCard(
              url: service.socialLinks?.website ?? '',
            ),

            SizedBox(height: SizeConfig.size100),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeConfig.paddingS,
          right: SizeConfig.paddingS,
          bottom: SizeConfig.paddingM,
          top: SizeConfig.paddingXSL,
        ),
        child: PositiveCustomBtn(
          onTap: () => commonSnackBar(message: 'Coming Soon....'),
          title: "Request Booking",
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  final ServiceData service;
  const _HeaderSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final profileImage = service.profileImage ?? '';

    return CommonCardWidget(
      cardMargin: 0,
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + avatar
          SizedBox(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    child: profileImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profileImage,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1A1A1A),
                                    Color(0xFF2B2B2B)
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1A1A1A),
                                  Color(0xFF2B2B2B)
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 90,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage.isEmpty
                          ? Icon(Icons.person,
                              size: 36, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name + profession
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        service.name ?? 'Unknown',
                        fontSize: SizeConfig.size18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    if ((service.profession ?? '').isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.paddingXS,
                          vertical: SizeConfig.size2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.secondaryTextColor, width: 0.5),
                        ),
                        child: CustomText(
                          service.profession!,
                          fontSize: SizeConfig.size11,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
                if ((service.designation ?? '').isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    service.designation!,
                    fontSize: SizeConfig.size13,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: SizeConfig.paddingS),

          // Stats: Rating, Reviews, Distance
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
            child: Row(
              children: [
                _statChip(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  label:
                      "${(service.rating ?? 0).toInt() == 0 ? 'New' : (service.rating ?? 0).toInt()}",
                ),
                SizedBox(width: SizeConfig.paddingS),
                _statChip(
                  icon: Icons.reviews_outlined,
                  iconColor: AppColors.primaryColor,
                  label: "${service.reviewCount ?? 0} reviews",
                ),
                if (service.distance != null) ...[
                  SizedBox(width: SizeConfig.paddingS),
                  _statChip(
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.primaryColor,
                    label: "${(service.distance ?? 0).toInt()} km",
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: SizeConfig.paddingS),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: SizeConfig.size16, color: iconColor),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          label,
          fontSize: SizeConfig.size12,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT
// ─────────────────────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  final ServiceData service;
  const _AboutSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final bio = service.bio ?? '';
    if (bio.isEmpty) {
      return _emptySection(Icons.info_outline, "About", "No bio available.");
    }
    return _sectionCard(
      icon: Icons.info_outline,
      title: "About",
      child: ExpandableText(
        text: bio,
        trimLines: 4,
        expandMode: ExpandMode.dialog,
        style: TextStyle(
          fontSize: SizeConfig.size13,
          color: AppColors.secondaryTextColor,
          fontFamily: AppConstants.OpenSans,
          height: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRICING
// ─────────────────────────────────────────────────────────────────────────────
class _PricingSection extends StatelessWidget {
  final ServiceData service;
  const _PricingSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final priceData = service.priceData;
    if (priceData == null) {
      return _emptySection(
          Icons.sell_outlined, "Pricing", "No pricing info available.");
    }

    final isRange = priceData.priceType == 'range';
    String priceDisplay;
    if (isRange) {
      final min = priceData.priceRange?.min ?? 0;
      final max = priceData.priceRange?.max ?? 0;
      priceDisplay = "₹${formatIndianNumber(min)} - ₹${formatIndianNumber(max)}";
    } else {
      priceDisplay = "₹${formatIndianNumber(priceData.singlePrice ?? 0)}";
    }

    return _sectionCard(
      icon: Icons.sell_outlined,
      title: "Pricing",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                priceDisplay,
                fontSize: SizeConfig.size18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.paddingXS),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.paddingXS,
                    vertical: SizeConfig.size2),
                decoration: BoxDecoration(
                  color: isRange ? AppColors.green1A : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CustomText(
                  priceData.priceType?.capitalizeFirst ?? '',
                  fontSize: SizeConfig.size11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          if ((priceData.perUnit ?? '').isNotEmpty) ...[
            SizedBox(height: SizeConfig.size4),
            CustomText(
              "Per ${priceData.perUnit}",
              fontSize: SizeConfig.size12,
              color: AppColors.secondaryTextColor,
            ),
          ],
          if ((priceData.minimumBookingAmount ?? 0) > 0) ...[
            SizedBox(height: SizeConfig.size4),
            CustomText(
              "Min. booking: ₹${priceData.minimumBookingAmount}",
              fontSize: SizeConfig.size12,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMING
// ─────────────────────────────────────────────────────────────────────────────
class _TimingSection extends StatelessWidget {
  final ServiceData service;
  const _TimingSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final timings = service.service?.timings ?? [];
    if (timings.isEmpty) {
      return _emptySection(
          Icons.access_time_outlined, "Timing", "No timings available.");
    }

    return _sectionCard(
      icon: Icons.access_time_outlined,
      title: "Timing",
      child: Column(
        children: timings.map((t) {
          return Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.size4),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: AppColors.green00),
                SizedBox(width: SizeConfig.paddingXS),
                CustomText(
                  "${t.start ?? '--'} - ${t.end ?? '--'}",
                  fontSize: SizeConfig.size13,
                  color: AppColors.secondaryTextColor,
                ),
                if (t.special == true) ...[
                  SizedBox(width: SizeConfig.paddingXS),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size4,
                        vertical: SizeConfig.size2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CustomText(
                      "Special",
                      fontSize: SizeConfig.size11,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICES OFFERED / FACILITIES
// ─────────────────────────────────────────────────────────────────────────────
class _ServicesOfferedSection extends StatefulWidget {
  final ServiceData service;
  const _ServicesOfferedSection({required this.service});

  @override
  State<_ServicesOfferedSection> createState() =>
      _ServicesOfferedSectionState();
}

class _ServicesOfferedSectionState extends State<_ServicesOfferedSection> {
  bool _showAll = false;
  static const int _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final facilities = widget.service.service?.facilities ?? [];
    final serviceOffered = widget.service.service?.serviceOffered ?? [];
    final items = serviceOffered.isNotEmpty ? serviceOffered : facilities;

    if (items.isEmpty) {
      return _emptySection(Icons.miscellaneous_services_outlined,
          "Services Offered", "No services listed.");
    }

    final displayItems =
        _showAll ? items : items.take(_maxVisible).toList();

    return _sectionCard(
      icon: Icons.miscellaneous_services_outlined,
      title: "Services Offered",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.green.shade600),
                  SizedBox(width: SizeConfig.paddingXS),
                  Expanded(
                    child: CustomText(
                      item,
                      fontSize: SizeConfig.size13,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (items.length > _maxVisible)
            InkWell(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Padding(
                padding: EdgeInsets.only(top: SizeConfig.size4),
                child: CustomText(
                  _showAll
                      ? "Show less"
                      : "View all ${items.length} services",
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WHY CHOOSE ME
// ─────────────────────────────────────────────────────────────────────────────
class _WhyChooseMeSection extends StatelessWidget {
  final ServiceData service;
  const _WhyChooseMeSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final items = service.service?.whyChooseMe ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      icon: Icons.thumb_up_outlined,
      title: "Why Choose Me",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.star_outline,
                        size: 16, color: Colors.amber.shade600),
                    SizedBox(width: SizeConfig.paddingXS),
                    Expanded(
                      child: CustomText(
                        item,
                        fontSize: SizeConfig.size13,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPERTISE / SKILLS
// ─────────────────────────────────────────────────────────────────────────────
class _ExpertiseSection extends StatelessWidget {
  final ServiceData service;
  const _ExpertiseSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final skills = service.skills ?? [];
    final expertise = service.service?.expertise ?? [];
    final items = skills.isNotEmpty ? skills : expertise;

    if (items.isEmpty) {
      return _emptySection(
          Icons.psychology_outlined, "Expertise", "No skills listed.");
    }

    return _sectionCard(
      icon: Icons.psychology_outlined,
      title: "Expertise",
      child: Wrap(
        spacing: SizeConfig.paddingXS,
        runSpacing: SizeConfig.paddingXS,
        children: items
            .map(
              (skill) => Container(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.paddingS,
                    vertical: SizeConfig.size4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomText(
                  skill,
                  fontSize: SizeConfig.size12,
                  color: AppColors.primaryColor,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPERIENCE
// ─────────────────────────────────────────────────────────────────────────────
class _ExperienceSection extends StatelessWidget {
  final ServiceData service;
  const _ExperienceSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final experiences = service.experiences ?? [];
    if (experiences.isEmpty) {
      return _emptySection(Icons.work_history_outlined, "Work Experience",
          "No experience listed.");
    }

    return _sectionCard(
      icon: Icons.work_history_outlined,
      title: "Work Experience",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: experiences
            .map(
              (exp) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: CustomText(
                        exp,
                        fontSize: SizeConfig.size13,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GALLERY (social-style grid)
// ─────────────────────────────────────────────────────────────────────────────
class _GallerySection extends StatelessWidget {
  final ServiceData service;
  const _GallerySection({required this.service});

  @override
  Widget build(BuildContext context) {
    final photos = service.serviceMedia?.photos ?? [];
    if (photos.isEmpty) {
      return _emptySection(
          Icons.photo_library_outlined, "Gallery", "No photos available.");
    }

    return _sectionCard(
      icon: Icons.photo_library_outlined,
      title: "Gallery",
      child: SocialGalleryGrid(imageUrls: photos),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT (clickable phone, email, website)
// ─────────────────────────────────────────────────────────────────────────────
class _ContactSection extends StatelessWidget {
  final ServiceData service;
  const _ContactSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final phone = service.contactNo ?? '';
    final email = service.email ?? '';
    final website = service.socialLinks?.website ?? '';
    final address = service.address ?? '';

    if (phone.isEmpty && email.isEmpty && website.isEmpty && address.isEmpty) {
      return _emptySection(Icons.phone_outlined, AppStrings.contactUs,
          "No contact details available.");
    }

    return _sectionCard(
      icon: Icons.phone_outlined,
      title: AppStrings.contactUs,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.paddingS),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            if (phone.isNotEmpty)
              _contactRow(
                AppIconAssets.phone_outline,
                phone,
                onTap: () {
                  final clean = phone.replaceAll(RegExp(r'\s+'), '');
                  launchUrl(Uri(scheme: 'tel', path: clean));
                },
              ),
            if (email.isNotEmpty)
              _contactRow(
                AppIconAssets.email,
                email,
                isLink: true,
                onTap: () => launchUrl(Uri(scheme: 'mailto', path: email)),
              ),
            if (website.isNotEmpty)
              _contactRow(
                AppIconAssets.website_click,
                website,
                isLink: true,
                onTap: () {
                  final uri =
                      website.startsWith('http') ? website : 'https://$website';
                  launchUrl(Uri.parse(uri),
                      mode: LaunchMode.externalApplication);
                },
              ),
            if (address.isNotEmpty)
              _contactRow(AppIconAssets.location_new, address),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(String icon, String text,
      {bool isLink = false, VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            LocalAssets(
              imagePath: icon,
              imgColor:
                  isLink ? AppColors.primaryColor : AppColors.mainTextColor,
              height: 20,
              width: 20,
            ),
            SizedBox(width: SizeConfig.paddingXS),
            Expanded(
              child: CustomText(
                text,
                fontSize: SizeConfig.size13,
                color: isLink
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
                decoration:
                    isLink ? TextDecoration.underline : TextDecoration.none,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionCard({
  required IconData icon,
  required String title,
  required Widget child,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
    child: CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: SizeConfig.size20, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.paddingXS),
              ServiceHomeTitleWidget(title: title),
            ],
          ),
          SizedBox(height: SizeConfig.paddingS),
          child,
        ],
      ),
    ),
  );
}

Widget _emptySection(IconData icon, String title, String message) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
    child: CommonCardWidget(
      cardMargin: 0,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon,
                  size: SizeConfig.size20, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.paddingXS),
              ServiceHomeTitleWidget(title: title),
            ],
          ),
          SizedBox(height: SizeConfig.paddingM),
          EmptyStateWidget(message: message, imageSize: SizeConfig.size60),
          SizedBox(height: SizeConfig.paddingS),
        ],
      ),
    ),
  );
}
