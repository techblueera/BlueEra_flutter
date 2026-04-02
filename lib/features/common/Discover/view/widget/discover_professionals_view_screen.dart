import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_project_card_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverProfessionalsViewScreen extends StatelessWidget {
  final ProfessionalConsData professionalConsData;

  const DiscoverProfessionalsViewScreen(
      {super.key, required this.professionalConsData});

  @override
  Widget build(BuildContext context) {
    final data = professionalConsData;

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: data.basicDetails?.professionalTitle,
      ),
      bottomNavigationBar: _buildBottomBar(data),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            _HeaderSection(data: data),

            SizedBox(height: SizeConfig.paddingXS),

            /// ABOUT / SERVICES
            _ServicesSection(data: data),

            SizedBox(height: SizeConfig.paddingXS),

            /// PORTFOLIO / PROJECTS
            _PortfolioSection(data: data),

            SizedBox(height: SizeConfig.paddingXS),

            /// CERTIFICATES & AWARDS
            _CertificatesSection(data: data),

            SizedBox(height: SizeConfig.paddingXS),

            /// GALLERY
            _GallerySection(data: data),

            SizedBox(height: SizeConfig.paddingXS),

            /// REVIEWS (placeholder)
            _ReviewsSection(),

            SizedBox(height: SizeConfig.paddingXS),

            /// CONTACT US
            _ContactSection(data: data),

            SizedBox(height: SizeConfig.paddingXS),

            /// WEBSITE PREVIEW
            WebsitePreviewCard(url: data.contact?.website ?? ''),

            SizedBox(height: SizeConfig.paddingXS),

            /// LOCATION MAP
            _LocationSection(data: data),

            SizedBox(height: SizeConfig.paddingXS),

            /// WORKING HOURS
            _WorkingHoursSection(data: data),

            SizedBox(height: SizeConfig.size100),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomBar(ProfessionalConsData data) {
    if (data.userId == userId) return null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeConfig.paddingS,
          right: SizeConfig.paddingS,
          bottom: SizeConfig.paddingM,
          top: SizeConfig.paddingXSL,
        ),
        child: Row(
          children: [
            Expanded(
              child: PositiveCustomBtn(
                onTap: () {
                  final chatViewController = Get.find<ChatViewController>();
                  chatViewController.checkChatConnectionAndOpenChat(
                    userId: data.userId ?? '',
                  );
                },
                title: "Chat",
              ),
            ),
            SizedBox(width: SizeConfig.paddingS),
            Expanded(
              child: PositiveCustomBtn(
                onTap: () => commonSnackBar(message: 'Coming Soon....'),
                title: "Book Inquiry",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _HeaderSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final profileImage = data.userDetails?.profileImage ?? '';
    final name = data.userDetails?.name ?? data.basicDetails?.fullName ?? '';
    final title = data.basicDetails?.professionalTitle ?? '';
    final tagline = data.basicDetails?.shortTagline ?? '';
    final location = data.basicDetails?.location ?? '';
    final experience = data.about?.totalExperience;
    final expText = _formatExperience(experience);

    return CommonCardWidget(
      cardMargin: 0,
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + Profile image
          SizedBox(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A1A1A), Color(0xFF2B2B2B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: profileImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profileImage,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const SizedBox.shrink(),
                          )
                        : null,
                  ),
                ),
                // Profile avatar
                Positioned(
                  left: 20,
                  top: 90,
                  child: CommonProfileImage(
                    imagePath: profileImage,
                    onImageUpdate: (image) async {},
                    dialogTitle: AppStrings.uploadProfilePicture,
                    showProfileBorder: true,
                    isOwnProfile: false,
                  ),
                ),
              ],
            ),
          ),

          // Name & title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  _capitalize(name),
                  fontSize: SizeConfig.size18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                if (title.isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    title,
                    fontSize: SizeConfig.size14,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
                if (tagline.isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    tagline,
                    fontSize: SizeConfig.size12,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: SizeConfig.paddingS),

          // Stats row: Rating, Experience, Location
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
            child: Row(
              children: [
                // Rating
                _statChip(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  label: "New",
                ),
                SizedBox(width: SizeConfig.paddingS),
                // Experience
                if (expText.isNotEmpty)
                  _statChip(
                    icon: Icons.work_outline,
                    iconColor: AppColors.primaryColor,
                    label: expText,
                  ),
                if (expText.isNotEmpty) SizedBox(width: SizeConfig.paddingS),
                // Location
                if (location.isNotEmpty)
                  Expanded(
                    child: _statChip(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.primaryColor,
                      label: location,
                      maxLines: 1,
                    ),
                  ),
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
    int maxLines = 1,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: SizeConfig.size16, color: iconColor),
        SizedBox(width: SizeConfig.size4),
        Flexible(
          child: CustomText(
            label,
            fontSize: SizeConfig.size12,
            color: AppColors.secondaryTextColor,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatExperience(TotalExperience? exp) {
    if (exp == null) return '';
    final y = exp.years ?? 0;
    final m = exp.months ?? 0;
    if (y == 0 && m == 0) return '';
    if (y > 0 && m > 0) return '${y}y ${m}m exp';
    if (y > 0) return '${y}y exp';
    return '${m}m exp';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICES SECTION (with View More)
// ─────────────────────────────────────────────────────────────────────────────
class _ServicesSection extends StatefulWidget {
  final ProfessionalConsData data;
  const _ServicesSection({required this.data});

  @override
  State<_ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<_ServicesSection> {
  bool _expanded = false;
  static const int _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final desc = widget.data.about?.majorProjectsDescription ??
        widget.data.about?.description ??
        '';

    if (desc.isEmpty) {
      return _emptyCard("Our Services", "No services listed yet.");
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.miscellaneous_services_outlined, "Our Services"),
            SizedBox(height: SizeConfig.paddingXS),
            ExpandableText(
              text: desc,
              trimLines: _expanded ? 100 : _maxVisible,
              isReadMoreNewLine: false,
              expandMode: ExpandMode.dialog,
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w400,
                fontFamily: AppConstants.OpenSans,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PORTFOLIO SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _PortfolioSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _PortfolioSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final portfolio = data.portfolio ?? [];
    if (portfolio.isEmpty) {
      return _emptyCard("Projects", "No projects added yet.");
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.folder_open_outlined, "Projects"),
            SizedBox(height: SizeConfig.paddingXS),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: Get.width * 0.85,
                    child: PortfolioProjectCardWidget(
                      isShowMore: false,
                      project: portfolio[index],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CERTIFICATES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _CertificatesSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _CertificatesSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final certs = data.certificates ?? [];
    if (certs.isEmpty) {
      return _emptyCard("Certificates & Awards", "No certificates added yet.");
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.workspace_premium_outlined, "Certificates & Awards"),
            SizedBox(height: SizeConfig.paddingXS),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: certs.length,
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.paddingS),
                itemBuilder: (context, index) {
                  final cert = certs[index];
                  return _certCard(cert);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _certCard(Certificates cert) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: cert.fileKey ?? '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey[400], size: 40),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      cert.title ?? "Unknown",
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.size14,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((cert.description ?? '').isNotEmpty) ...[
                      SizedBox(height: SizeConfig.size2),
                      CustomText(
                        cert.description!,
                        color: Colors.white70,
                        fontSize: SizeConfig.size11,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GALLERY SECTION (Social-style grid)
// ─────────────────────────────────────────────────────────────────────────────
class _GallerySection extends StatelessWidget {
  final ProfessionalConsData data;
  const _GallerySection({required this.data});

  @override
  Widget build(BuildContext context) {
    final urls = data.gallery?.signedUrls ?? [];
    if (urls.isEmpty) {
      return _emptyCard("Gallery", "No photos available.");
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.photo_library_outlined, "Gallery"),
            SizedBox(height: SizeConfig.paddingXS),
            SocialGalleryGrid(imageUrls: urls),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEWS SECTION (placeholder for future API)
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _emptyCard("Reviews", "No reviews yet. Be the first to review!");
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT SECTION (clickable phone, email, website)
// ─────────────────────────────────────────────────────────────────────────────
class _ContactSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _ContactSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final contact = data.contact;
    final hasAny = (contact?.phone ?? '').isNotEmpty ||
        (contact?.email ?? '').isNotEmpty ||
        (contact?.website ?? '').isNotEmpty ||
        (contact?.address ?? '').isNotEmpty;

    if (!hasAny) {
      return _emptyCard("Contact Us", "No contact details available.");
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.phone_outlined, AppStrings.contactUs.tr),
            SizedBox(height: SizeConfig.paddingXS),
            Container(
              padding: EdgeInsets.all(SizeConfig.paddingS),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  if ((contact?.phone ?? '').isNotEmpty)
                    _contactRow(
                      AppIconAssets.phone_outline,
                      contact!.phone!,
                      onTap: () => _launchPhone(contact.phone!),
                    ),
                  if ((contact?.email ?? '').isNotEmpty)
                    _contactRow(
                      AppIconAssets.email,
                      contact!.email!,
                      onTap: () => _launchEmail(contact.email!),
                    ),
                  if ((contact?.website ?? '').isNotEmpty)
                    _contactRow(
                      AppIconAssets.website_click,
                      contact!.website!,
                      isLink: true,
                      onTap: () => _launchUrl(contact.website!),
                    ),
                  if ((contact?.address ?? '').isNotEmpty)
                    _contactRow(
                      AppIconAssets.location_new,
                      contact!.address!,
                    ),
                ],
              ),
            ),
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
                color: isLink
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
                fontSize: SizeConfig.size13,
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

  void _launchPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    launchUrl(Uri(scheme: 'tel', path: clean));
  }

  void _launchEmail(String email) {
    launchUrl(Uri(scheme: 'mailto', path: email));
  }

  void _launchUrl(String url) {
    final uri = url.startsWith('http') ? url : 'https://$url';
    launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _LocationSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _LocationSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final coords = data.contact?.location?.coordinates;
    if (coords == null || coords.length < 2) return const SizedBox.shrink();

    final lat = double.tryParse(coords[0].toString()) ?? 0.0;
    final lon = double.tryParse(coords[1].toString()) ?? 0.0;
    if (lat == 0.0 && lon == 0.0) return const SizedBox.shrink();

    return BusinessLocationWidget(
      locationText: data.basicDetails?.fullName,
      latitude: lat,
      longitude: lon,
      businessName: '',
      padding: SizeConfig.paddingXSL,
      isTitleShow: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKING HOURS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _WorkingHoursSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _WorkingHoursSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final schedule = data.timings?.schedule;
    if (schedule == null) {
      return _emptyCard("Working Hours", "No working hours added yet.");
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.access_time_outlined, "Working Hours"),
            SizedBox(height: SizeConfig.paddingXS),
            Container(
              padding: EdgeInsets.all(SizeConfig.paddingS),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _dayRow("Monday", schedule.monday),
                  _dayRow("Tuesday", schedule.tuesday),
                  _dayRow("Wednesday", schedule.wednesday),
                  _dayRow("Thursday", schedule.thursday),
                  _dayRow("Friday", schedule.friday),
                  _dayRow("Saturday", schedule.saturday),
                  _dayRow("Sunday", schedule.sunday),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayRow(String day, dynamic dayData) {
    final isOpen = dayData?.isOpen == true;
    final text = isOpen
        ? "${dayData?.openTime ?? ''} - ${dayData?.closeTime ?? ''}"
        : "Closed";
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            day,
            fontSize: SizeConfig.size13,
            color: AppColors.secondaryTextColor,
          ),
          CustomText(
            text,
            fontSize: SizeConfig.size13,
            color: isOpen ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionHeader(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, color: AppColors.primaryColor, size: SizeConfig.size20),
      SizedBox(width: SizeConfig.paddingXS),
      ServiceHomeTitleWidget(title: title),
    ],
  );
}

Widget _emptyCard(String title, String message) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
    child: CommonCardWidget(
      cardMargin: 0,
      child: Column(
        children: [
          _sectionHeader(
            _iconForSection(title),
            title,
          ),
          SizedBox(height: SizeConfig.paddingM),
          EmptyStateWidget(
            message: message,
            imageSize: SizeConfig.size60,
          ),
          SizedBox(height: SizeConfig.paddingS),
        ],
      ),
    ),
  );
}

IconData _iconForSection(String title) {
  switch (title) {
    case "Our Services":
      return Icons.miscellaneous_services_outlined;
    case "Projects":
      return Icons.folder_open_outlined;
    case "Certificates & Awards":
      return Icons.workspace_premium_outlined;
    case "Gallery":
      return Icons.photo_library_outlined;
    case "Reviews":
      return Icons.rate_review_outlined;
    case "Contact Us":
      return Icons.phone_outlined;
    case "Working Hours":
      return Icons.access_time_outlined;
    default:
      return Icons.info_outline;
  }
}
