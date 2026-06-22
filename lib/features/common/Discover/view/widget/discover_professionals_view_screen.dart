import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/widget/profession_enquiry_sheet.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_project_card_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
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

/// Public entry point. Pass [professionalConsData] when you already hold the
/// model (Discover lists), or just a [userId] to have the screen fetch it on
/// open (visit flow).
class DiscoverProfessionalsViewScreen extends StatefulWidget {
  final ProfessionalConsData? professionalConsData;
  final String? userId;

  const DiscoverProfessionalsViewScreen({
    super.key,
    this.professionalConsData,
    this.userId,
  });

  @override
  State<DiscoverProfessionalsViewScreen> createState() =>
      _DiscoverProfessionalsViewScreenState();
}

class _DiscoverProfessionalsViewScreenState
    extends State<DiscoverProfessionalsViewScreen> {
  ProfessionalConsData? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _data = widget.professionalConsData;
    if (_data == null && (widget.userId?.isNotEmpty ?? false)) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final controller = Get.isRegistered<DiscoverController>()
        ? Get.find<DiscoverController>()
        : Get.put(DiscoverController());
    final result = await controller.getProfessionalByUserId(widget.userId!);
    if (!mounted) return;
    setState(() {
      _data = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data != null) {
      return _ProfessionalsContent(professionalConsData: data);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.mainTextColor),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 48, color: AppColors.secondaryTextColor),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    AppStrings.noDataFound.tr,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfessionalsContent extends StatelessWidget {
  final ProfessionalConsData professionalConsData;

  const _ProfessionalsContent({required this.professionalConsData});

  @override
  Widget build(BuildContext context) {
    final data = professionalConsData;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _buildBottomBar(context, data),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _withGaps(
            <Widget?>[
              _HeaderSection(data: data),
              if (_hasPricing(data)) _PricingSection(data: data),
              if (_hasIntroVideo(data)) _IntroVideoSection(data: data),
              _ServicesSection(data: data),
              _PortfolioSection(data: data),
              _CertificatesSection(data: data),
              _GallerySection(data: data),
              _ReviewsSection(),
              _ContactSection(data: data),
              if (_hasSocialLinks(data)) _SocialLinksSection(data: data),
              if (_hasWebsite(data))
                WebsitePreviewCard(url: data.contact!.website!),
              if (_hasLocationCoords(data)) _LocationSection(data: data),
              _WorkingHoursSection(data: data),
              SizedBox(height: SizeConfig.size100),
            ],
            gap: SizeConfig.paddingXS,
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context, ProfessionalConsData data) {
    if (data.userId == userId) return null;
    return Container(
      // Soft shadow that throws upward — visually lifts the bar off the
      // scroll content and signals it's a fixed action surface. Same
      // values as self_employee_view_screen's fixed bottom button so
      // both screens share the same elevation rhythm.
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: SizeConfig.paddingS,
        right: SizeConfig.paddingS,
        bottom: SizeConfig.paddingM,
        top: SizeConfig.paddingXSL,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: PositiveCustomBtn(
                onTap: () {
                  final chatViewController = Get.find<ChatViewController>();
                  chatViewController.checkChatConnectionAndOpenChat(
                    userId: data.userId ?? '',
                    route: AppConstants.route_discover,
                  );
                },
                title: AppStrings.chat.tr,
              ),
            ),
            SizedBox(width: SizeConfig.paddingS),
            Expanded(
              child: PositiveCustomBtn(
                onTap: () => ProfessionEnquirySheet.open(context, data),
                title: AppStrings.bookInquiryLabel.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER SECTION (merged cover banner + avatar overlap + profile info)
// Mirrors `SelfEmployeeViewScreen._buildHeaderSection`. Single banner that
// extends behind the status bar, avatar overlaps the banner's bottom edge,
// then name + title pill + stat chips + tagline + languages render flush
// underneath without their own card wrapper.
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _HeaderSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final profileImage = data.userDetails?.profileImage ?? '';
    final statusBarHeight = MediaQuery.of(context).padding.top;

    Widget gradientFallback() => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover banner + overlapping avatar + top action overlay.
          // Heights match self_employee_view_screen so both screens share
          // the same negative-space rhythm under the status bar.
          SizedBox(
            height: 230 + statusBarHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner image — extends behind status bar; gradient
                // fallback on missing/broken image.
                SizedBox(
                  height: 190 + statusBarHeight,
                  width: double.infinity,
                  child: profileImage.isEmpty
                      ? gradientFallback()
                      : CachedNetworkImage(
                          imageUrl: profileImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => gradientFallback(),
                          errorWidget: (_, __, ___) => gradientFallback(),
                        ),
                ),

                // Top bar overlay: back + share. Sits above the banner
                // image so glyphs need a translucent dark bg to stay
                // legible against bright photos.
                Positioned(
                  top: statusBarHeight + 4,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _coverIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _coverIconButton(
                        icon: Icons.share_outlined,
                        onTap: () {
                          // Share entry point — the discover model has no
                          // share URL today, so this is a no-op until the
                          // backend exposes one. Kept visible for layout
                          // parity with self_employee_view_screen.
                        },
                      ),
                    ],
                  ),
                ),

                // Profile avatar — overlaps the banner's bottom edge by
                // half its height (80×80 with 2px white ring + soft
                // shadow). Absolute positioning means the title row
                // below starts at a fixed Y regardless of banner height.
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CachedAvatarWidget(
                      imageUrl: profileImage,
                      size: SizeConfig.size80,
                      borderColor: Colors.transparent,
                      borderRadius: SizeConfig.size40,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile info — flush under the cover, no card wrapper. Same
          // 16/12/16/16 padding as self_employee_view_screen so the
          // optical rhythm matches.
          _buildProfileInfoContent(),
        ],
      ),
    );
  }

  Widget _buildProfileInfoContent() {
    final name = data.userDetails?.name ?? data.basicDetails?.fullName ?? '';
    final title = (data.basicDetails?.professionalTitle ?? '').trim();
    final tagline = (data.basicDetails?.shortTagline ?? '').trim();
    final location = (data.basicDetails?.location ?? '').trim();
    final expText = _formatExperience(data.about?.totalExperience);
    final languages = data.basicDetails?.languagesSpoken ?? const <String>[];
    final hasName = name.trim().isNotEmpty;
    final hasTitle = title.isNotEmpty;
    final hasTagline = tagline.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + professional-title pill on one row. The pill mirrors
          // `service.profession` from self_employee_view_screen.
          Row(
            children: [
              if (hasName)
                Expanded(
                  child: CustomText(
                    _capitalize(name),
                    fontSize: SizeConfig.extraLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
              if (hasName && hasTitle) SizedBox(width: SizeConfig.size8),
              if (hasTitle)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size8,
                    vertical: SizeConfig.size3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: CustomText(
                    title,
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          SizedBox(height: SizeConfig.size6),

          // Stat chips — rating placeholder, experience, location. Wrap
          // so long location strings don't force ellipsis on experience.
          Wrap(
            spacing: SizeConfig.size12,
            runSpacing: SizeConfig.size4,
            children: [
              _statChip(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                label: AppStrings.newLabel.tr,
              ),
              if (expText.isNotEmpty)
                _statChip(
                  icon: Icons.work_outline,
                  iconColor: AppColors.primaryColor,
                  label: expText,
                ),
              if (location.isNotEmpty)
                _statChip(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.primaryColor,
                  label: location,
                ),
            ],
          ),

          // Tagline — collapses to dialog on overflow, like the
          // self_employee bio.
          if (hasTagline) ...[
            SizedBox(height: SizeConfig.size8),
            ExpandableText(
              text: tagline,
              trimLines: 3,
              expandMode: ExpandMode.dialog,
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontFamily: AppConstants.OpenSans,
                fontWeight: FontWeight.w400,
                fontSize: SizeConfig.medium,
                height: 1.5,
              ),
            ),
          ],

          // Languages spoken — small primary-tinted pills with a
          // translate glyph prefix. Skipped entirely when empty.
          if (languages.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.translate_rounded,
                    size: SizeConfig.size14,
                    color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size4),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: languages
                        .map(
                          (lang) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustomText(
                              lang,
                              fontSize: SizeConfig.size11,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _coverIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.appBackgroundColor, size: 18),
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
    if (y > 0 && m > 0) return '${y}y ${m}m ${AppStrings.yearsMonthsExp.tr}';
    if (y > 0) return '${y}y ${AppStrings.yearsExp.tr}';
    return '${m}m ${AppStrings.monthsExp.tr}';
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
      return _emptyCard(AppStrings.ourServices.tr, AppStrings.noServicesListedYet.tr,
          icon: Icons.miscellaneous_services_outlined);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.miscellaneous_services_outlined, AppStrings.ourServices.tr),
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
      return _emptyCard(AppStrings.projectsLabel.tr, AppStrings.noProjectsAddedYet.tr,
          icon: Icons.folder_open_outlined);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.folder_open_outlined, AppStrings.projectsLabel.tr),
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
      return _emptyCard(AppStrings.certificatesAndAwards.tr, AppStrings.noCertificatesAddedYet.tr,
          icon: Icons.workspace_premium_outlined);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.workspace_premium_outlined, AppStrings.certificatesAndAwards.tr),
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
                      cert.title ?? AppStrings.unknown.tr,
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
      return _emptyCard(AppStrings.gallery.tr, AppStrings.noPhotosAvailableMsg.tr,
          icon: Icons.photo_library_outlined);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.photo_library_outlined, AppStrings.gallery.tr),
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
    return _emptyCard(AppStrings.reviewsTitle.tr, AppStrings.noReviewsYet.tr,
        icon: Icons.rate_review_outlined);
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
      return _emptyCard(AppStrings.contactUs.tr, AppStrings.noContactDetailsMsg.tr,
          icon: Icons.phone_outlined);
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
      return _emptyCard(AppStrings.workingHours.tr, AppStrings.noWorkingHoursAddedYet.tr,
          icon: Icons.access_time_outlined);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.access_time_outlined, AppStrings.workingHours.tr),
            SizedBox(height: SizeConfig.paddingXS),
            Container(
              padding: EdgeInsets.all(SizeConfig.paddingS),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _dayRow(AppStrings.monday.tr, schedule.monday),
                  _dayRow(AppStrings.tuesday.tr, schedule.tuesday),
                  _dayRow(AppStrings.wednesday.tr, schedule.wednesday),
                  _dayRow(AppStrings.thursday.tr, schedule.thursday),
                  _dayRow(AppStrings.friday.tr, schedule.friday),
                  _dayRow(AppStrings.saturday.tr, schedule.saturday),
                  _dayRow(AppStrings.sunday.tr, schedule.sunday),
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
        : AppStrings.closedDay.tr;
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
// PRICING SECTION (engagement model + rate + consultation modes)
// ─────────────────────────────────────────────────────────────────────────────
class _PricingSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _PricingSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final pricing = data.pricing;
    if (pricing == null) return const SizedBox.shrink();

    final amount = pricing.amount;
    final type = (pricing.type ?? '').trim();
    final currency = (pricing.currency ?? 'INR').trim();
    final mode = (pricing.consultationMode ?? '').trim();

    // Bail early if every field is empty — don't render an empty card.
    if (amount == null && type.isEmpty && mode.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.paddingS),
        decoration: BoxDecoration(
          // Brand-blue gradient — the only section on the page that
          // departs from the white-card baseline. Pricing is the page's
          // conversion anchor, so it's allowed to be louder.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withValues(alpha: 0.10),
              AppColors.primaryColor.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.payments_outlined, AppStrings.pricingAndEngagement.tr),
            SizedBox(height: SizeConfig.paddingS),
            // Hero rate — currency glyph kept smaller than the amount
            // so the number reads as the headline.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (amount != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CustomText(
                      _currencySymbol(currency),
                      fontSize: SizeConfig.size20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  CustomText(
                    '$amount',
                    fontSize: SizeConfig.size28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  if (type.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: CustomText(
                        '/${type.toLowerCase()}',
                        fontSize: SizeConfig.size13,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ] else if (type.isNotEmpty)
                  CustomText(
                    type,
                    fontSize: SizeConfig.size18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
              ],
            ),
            // Consultation modes as outlined pills with a glyph that
            // matches the modality (online → camera, offline → handshake,
            // hybrid → swap).
            if (mode.isNotEmpty) ...[
              SizedBox(height: SizeConfig.paddingS),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _splitModes(mode)
                    .map((m) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_iconForMode(m),
                                  size: SizeConfig.size14,
                                  color: AppColors.primaryColor),
                              SizedBox(width: SizeConfig.size4),
                              CustomText(
                                m,
                                fontSize: SizeConfig.size12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  /// API may return one mode ("Online") or a composite ("Online/Offline",
  /// "Online, Hybrid"). Split on `/` and `,` so each modality renders as
  /// its own pill with its own glyph.
  List<String> _splitModes(String mode) {
    return mode
        .split(RegExp(r'[/,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  IconData _iconForMode(String mode) {
    final m = mode.toLowerCase();
    if (m.contains('online')) return Icons.videocam_outlined;
    if (m.contains('offline') || m.contains('in-person')) {
      return Icons.handshake_outlined;
    }
    if (m.contains('hybrid')) return Icons.swap_horiz_rounded;
    return Icons.business_center_outlined;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTRO VIDEO SECTION (cinematic 16:9 thumbnail → external launch)
// ─────────────────────────────────────────────────────────────────────────────
class _IntroVideoSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _IntroVideoSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final url = (data.userDetails?.introVideo ?? '').trim();
    if (url.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
                Icons.play_circle_outline, AppStrings.introductionVideo.tr),
            SizedBox(height: SizeConfig.paddingXS),
            // Tile is its own InkWell so the entire 16:9 area is the
            // tap target (not just the play button). Opens externally so
            // YouTube URLs hand off to the YouTube app where available.
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final uri = url.startsWith('http') ? url : 'https://$url';
                  launchUrl(Uri.parse(uri),
                      mode: LaunchMode.externalApplication);
                },
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient placeholder — diagonal brand→black so
                      // the play button has contrast at every position.
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryColor.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      // Subtle vignette so the play button doesn't fight
                      // a bright corner of the gradient on smaller screens.
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: RadialGradient(
                            radius: 0.9,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.primaryColor,
                            size: 36,
                          ),
                        ),
                      ),
                      // Bottom-left affordance label so the tile reads
                      // unambiguously as "tap to play" even when the user
                      // is moving fast.
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded,
                                  color: AppColors.white,
                                  size: SizeConfig.size12),
                              SizedBox(width: SizeConfig.size4),
                              CustomText(
                                AppStrings.watchVideo.tr,
                                color: AppColors.white,
                                fontSize: SizeConfig.size11,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
// SOCIAL LINKS SECTION (branded chips → external launch)
// ─────────────────────────────────────────────────────────────────────────────
class _SocialLinksSection extends StatelessWidget {
  final ProfessionalConsData data;
  const _SocialLinksSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = data.userDetails?.socialLinks;
    if (s == null) return const SizedBox.shrink();

    final items = <_SocialItem>[
      // Order: LinkedIn first because it's the primary professional
      // signal, then content/audience platforms, then catch-all website.
      if ((s.linkedin ?? '').trim().isNotEmpty)
        _SocialItem(
          icon: Icons.work_outline,
          color: const Color(0xFF0A66C2),
          label: 'LinkedIn',
          url: s.linkedin!.trim(),
        ),
      if ((s.youtube ?? '').trim().isNotEmpty)
        _SocialItem(
          icon: Icons.play_circle_outline,
          color: const Color(0xFFFF0000),
          label: 'YouTube',
          url: s.youtube!.trim(),
        ),
      if ((s.instagram ?? '').trim().isNotEmpty)
        _SocialItem(
          icon: Icons.camera_alt_outlined,
          color: const Color(0xFFE4405F),
          label: 'Instagram',
          url: s.instagram!.trim(),
        ),
      if ((s.twitter ?? '').trim().isNotEmpty)
        _SocialItem(
          icon: Icons.alternate_email,
          color: const Color(0xFF1DA1F2),
          label: 'Twitter',
          url: s.twitter!.trim(),
        ),
      if ((s.website ?? '').trim().isNotEmpty)
        _SocialItem(
          icon: Icons.public,
          color: AppColors.primaryColor,
          label: AppStrings.websiteLabel.tr,
          url: s.website!.trim(),
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.share_outlined, AppStrings.connectLabel.tr),
            SizedBox(height: SizeConfig.paddingS),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map(_socialChip).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Each token uses its platform's brand color at low opacity (8% fill,
  /// 25% border) — recognizable at a glance without overwhelming the
  /// page's primary-blue palette.
  Widget _socialChip(_SocialItem item) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final uri =
              item.url.startsWith('http') ? item.url : 'https://${item.url}';
          launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: item.color, size: SizeConfig.size18),
              SizedBox(width: SizeConfig.size6),
              CustomText(
                item.label,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w600,
                color: item.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialItem {
  final IconData icon;
  final Color color;
  final String label;
  final String url;
  const _SocialItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.url,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Filters out null entries from [children] and inserts a [gap] of vertical
/// space ONLY between consecutive rendered widgets. The previous design
/// stacked a static `SizedBox(height: paddingXS)` between every sibling,
/// so when 2–3 conditional sections (socials / website preview / map)
/// collapsed, an empty 2–3× paddingXS dead zone appeared between Contact
/// Us and Working Hours. Skipping nulls eliminates that dead zone without
/// each section having to know about its neighbours.
List<Widget> _withGaps(List<Widget?> children, {required double gap}) {
  final result = <Widget>[];
  bool first = true;
  for (final child in children) {
    if (child == null) continue;
    if (!first) result.add(SizedBox(height: gap));
    result.add(child);
    first = false;
  }
  return result;
}

// Per-section "should we render?" predicates. Living at file scope so the
// build call site can use them inline as `if (_hasX(data)) _XSection(...)`.
// They mirror the data-presence checks each section already does
// internally — duplicated here on purpose so the parent column can omit
// the section entry (and its gap) entirely instead of relying on the
// section returning `SizedBox.shrink()`.

bool _hasPricing(ProfessionalConsData d) {
  final p = d.pricing;
  if (p == null) return false;
  return p.amount != null ||
      (p.type ?? '').trim().isNotEmpty ||
      (p.consultationMode ?? '').trim().isNotEmpty;
}

bool _hasIntroVideo(ProfessionalConsData d) =>
    (d.userDetails?.introVideo ?? '').trim().isNotEmpty;

bool _hasSocialLinks(ProfessionalConsData d) {
  final s = d.userDetails?.socialLinks;
  if (s == null) return false;
  return (s.linkedin ?? '').trim().isNotEmpty ||
      (s.youtube ?? '').trim().isNotEmpty ||
      (s.instagram ?? '').trim().isNotEmpty ||
      (s.twitter ?? '').trim().isNotEmpty ||
      (s.website ?? '').trim().isNotEmpty;
}

bool _hasWebsite(ProfessionalConsData d) =>
    (d.contact?.website ?? '').trim().isNotEmpty;

bool _hasLocationCoords(ProfessionalConsData d) {
  final c = d.contact?.location?.coordinates;
  if (c == null || c.length < 2) return false;
  final a = double.tryParse(c[0].toString()) ?? 0.0;
  final b = double.tryParse(c[1].toString()) ?? 0.0;
  return !(a == 0.0 && b == 0.0);
}

Widget _sectionHeader(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, color: AppColors.primaryColor, size: SizeConfig.size20),
      SizedBox(width: SizeConfig.paddingXS),
      ServiceHomeTitleWidget(title: title),
    ],
  );
}

/// Empty-state card for a profile section.
///
/// The optional [icon] is passed explicitly so this works after section
/// titles are localized — the previous implementation switched on the
/// title text, which broke once `.tr` returned the localized (e.g.
/// Hindi) string. Callers that already know the icon should pass it;
/// the legacy English-title fallback below covers the few call sites
/// that don't pass an explicit icon yet.
Widget _emptyCard(String title, String message, {IconData? icon}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
    child: CommonCardWidget(
      cardMargin: 0,
      child: Column(
        children: [
          _sectionHeader(
            icon ?? _iconForSection(title),
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
  // Fallback only — the switch matches the English-locale labels that
  // [AppStrings.<section>.tr] would resolve to. Pass [icon] explicitly
  // in [_emptyCard] for locale-safe icon selection.
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
