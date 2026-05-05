import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_project_card_widget.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_contact_us_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_profile_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_service_offered.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_certificates_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_timing_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class ProfessionalsHomeScreen extends StatelessWidget {
  ProfessionalsHomeScreen({super.key});

  final viewProfileController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  final controller = Get.find<AiProfessionalsController>();

  void _navigateToEdit(Widget screen) async {
    await Get.to(() => screen);
    controller.professionalsFullDetailsController();
  }

  @override
  Widget build(BuildContext context) {
    // No Material / SingleChildScrollView here — this screen is
    // embedded inside the parent professionals dashboard's
    // CustomScrollView, so its sections need to flow into the parent
    // scroll. Wrapping its own scrollable would (a) bound the inner
    // content to a fixed height and (b) prevent the parent's sticky-
    // tab overlay from engaging on scroll.
    return Obx(() {
      final data = controller.getProfessionalServiceRes?.value.data;
      if (data == null) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size40),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      return Padding(
        padding: EdgeInsets.all(SizeConfig.paddingXS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expertise
            _buildExpertiseSection(data),
            SizedBox(height: SizeConfig.size14),

            // Our Services
            _buildServicesSection(data),
            SizedBox(height: SizeConfig.size14),

            // Portfolio / Case Studies
            _buildPortfolioSection(data),
            SizedBox(height: SizeConfig.size14),

            // Certificate & Awards
            _buildCertificatesSection(data),
            SizedBox(height: SizeConfig.size14),

            // Gallery
            _buildGallerySection(data, context),
            SizedBox(height: SizeConfig.size14),

            // // Testimonials
            // _buildTestimonialsSection(),
            // SizedBox(height: SizeConfig.size14),

            // Contact Us + Map (merged into a single card)
            _buildContactSection(data),
            SizedBox(height: SizeConfig.size14),

            // Working Hours
            _buildTimingsSection(data),
          ],
        ),
      );
    });
  }

  // ============================================================
  // SECTION HEADER WITH EDIT
  // ============================================================

  Widget _sectionHeader(String title, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: ServiceHomeTitleWidget(title: title)),
          if (onEdit != null)
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: LocalAssets(
                  imagePath: AppIconAssets.pen_line,
                  imgColor: AppColors.primaryColor,
                  height: 18,
                  width: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY-STATE CARD
  // ============================================================
  // Refined empty card used by every section instead of a greyscaled
  // dummy preview + harsh "NA" badge. Soft primary-tinted gradient
  // backdrop, a contextual circular icon, helpful section-specific
  // copy, and an inline filled "Add" pill that fires the same edit
  // flow the section header's pencil triggers — so the entire card
  // becomes the call-to-action instead of a "no data" placeholder.

  Widget _emptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAdd,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.07),
                AppColors.primaryColor.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Contextual icon disc — primary-tinted circle that
              // anchors the card and gives each section its own
              // visual cue (briefcase / certificate / camera etc.).
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 22, color: AppColors.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppConstants.OpenSans,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Filled "Add" pill — same primary color as the card's
              // accent so it reads as a single design system, not a
              // floating button on a placeholder.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        fontFamily: AppConstants.OpenSans,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
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

  // ============================================================
  // EXPERTISE
  // ============================================================

  Widget _buildExpertiseSection(ProfessionalProfileData data) {
    final expertise = data.about?.expertise ?? [];
    final hasData = expertise.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Expertise",
              onEdit: () =>
                  _navigateToEdit(ProfessionalProfileScreen())),
          if (hasData)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: expertise
                  .expand((item) => item.split(','))
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.3)),
                        ),
                        child: CustomText(tag,
                            fontSize: SizeConfig.small,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500),
                      ))
                  .toList(),
            )
          else
            _emptyStateCard(
              icon: Icons.psychology_alt_rounded,
              title: 'Showcase your expertise',
              subtitle:
                  'List the skills clients should know you for.',
              actionLabel: 'Add',
              onAdd: () => _navigateToEdit(ProfessionalProfileScreen()),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // OUR SERVICES
  // ============================================================

  Widget _buildServicesSection(ProfessionalProfileData data) {
    final services = data.servicesOffered ?? [];
    final hasData = services.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Our Services",
              onEdit: () =>
                  _navigateToEdit(ProfessionalServiceOffered())),
          if (hasData)
            ...services.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(s,
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor),
                      ),
                    ],
                  ),
                ))
          else
            _emptyStateCard(
              icon: Icons.checklist_rounded,
              title: 'List the services you offer',
              subtitle: 'Tell clients what they can hire you for.',
              actionLabel: 'Add',
              onAdd: () => _navigateToEdit(ProfessionalServiceOffered()),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PORTFOLIO / CASE STUDIES
  // ============================================================

  Widget _buildPortfolioSection(ProfessionalProfileData data) {
    final portfolio = data.portfolio ?? [];
    final hasData = portfolio.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Portfolio / Case Studies",
              onEdit: () => _navigateToEdit(PortfolioScreen())),
          if (hasData)
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: Get.width * 0.85,
                    padding: EdgeInsets.zero,
                    child: PortfolioProjectCardWidget(
                      isShowMore: false,
                      project: portfolio[index],
                    ),
                  );
                },
              ),
            )
          else
            _emptyStateCard(
              icon: Icons.collections_bookmark_rounded,
              title: 'Showcase your work',
              subtitle:
                  'Add case studies clients can browse before reaching out.',
              actionLabel: 'Add',
              onAdd: () => _navigateToEdit(PortfolioScreen()),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CERTIFICATES & AWARDS
  // ============================================================

  Widget _buildCertificatesSection(ProfessionalProfileData data) {
    final certs = data.certificates ?? [];
    final hasData = certs.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Certificate & Awards",
              onEdit: () =>
                  _navigateToEdit(ProfessionalsCertificatesScreen())),
          if (hasData)
            SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: certs.length,
                itemBuilder: (context, index) {
                  final cert = certs[index];
                  return Container(
                    width: 240,
                    margin: EdgeInsets.only(right: SizeConfig.size12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: cert.fileKey ?? "",
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey[300]),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                    child: Icon(Icons.emoji_events,
                                        size: 40, color: Colors.grey)),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.1),
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                  stops: const [0.5, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding:
                                  EdgeInsets.all(SizeConfig.size12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    cert.title ?? "Certificate",
                                    color: Colors.white,
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (cert.description != null &&
                                      cert.description!
                                          .isNotEmpty) ...[
                                    SizedBox(
                                        height: SizeConfig.size4),
                                    CustomText(
                                      cert.description!,
                                      color: Colors.white,
                                      fontSize: SizeConfig.small,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
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
                },
              ),
            )
          else
            _emptyStateCard(
              icon: Icons.emoji_events_rounded,
              title: 'Highlight your credentials',
              subtitle:
                  'Add certifications and awards to build trust at a glance.',
              actionLabel: 'Add',
              onAdd: () =>
                  _navigateToEdit(ProfessionalsCertificatesScreen()),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Widget _buildGallerySection(
      ProfessionalProfileData data, BuildContext context) {
    final urls = data.gallery?.signedUrls ?? [];
    final hasData = urls.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Gallery",
              onEdit: () =>
                  _navigateToEdit(ProfessionalsCertificatesScreen())),
          if (hasData)
            _buildGalleryGrid(urls, context)
          else
            _emptyStateCard(
              icon: Icons.photo_library_rounded,
              title: 'Build your gallery',
              subtitle:
                  'Upload photos that show your craft in action.',
              actionLabel: 'Add',
              onAdd: () =>
                  _navigateToEdit(ProfessionalsCertificatesScreen()),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(
      List<String> signedUrls, BuildContext context) {
    final count = signedUrls.length;
    final hasMore = count > 4;

    Widget imageTile(int index, {double? height}) {
      return InkWell(
        onTap: () => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: signedUrls,
            initialIndex: index,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: signedUrls[index],
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey[200]),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    }

    Widget viewMoreOverlay(int index) {
      return InkWell(
        onTap: () => _openFullGallery(context, signedUrls),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: signedUrls[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey[200]),
              ),
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: CustomText(
                    "+${count - 3}",
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 1 image: full width
    if (count == 1) {
      return imageTile(0, height: 200);
    }

    // 2 images: side by side
    if (count == 2) {
      return SizedBox(
        height: 160,
        child: Row(
          children: [
            Expanded(child: imageTile(0, height: 160)),
            const SizedBox(width: 6),
            Expanded(child: imageTile(1, height: 160)),
          ],
        ),
      );
    }

    // 3 images: 1 left + 2 right stacked
    if (count == 3) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(flex: 1, child: imageTile(0, height: 200)),
            const SizedBox(width: 6),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: imageTile(1)),
                  const SizedBox(height: 6),
                  Expanded(child: imageTile(2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4 images: 2x2 grid
    // 4+ images: 2x2 grid with "+N" overlay on last tile
    return SizedBox(
      height: 260,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: imageTile(0)),
                const SizedBox(width: 6),
                Expanded(child: imageTile(1)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(child: imageTile(2)),
                const SizedBox(width: 6),
                Expanded(
                    child: hasMore ? viewMoreOverlay(3) : imageTile(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullGallery(BuildContext context, List<String> urls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullGalleryScreen(imageUrls: urls),
      ),
    );
  }

  // ============================================================
  // TESTIMONIALS
  // ============================================================


  // ============================================================
  // CONTACT US
  // ============================================================

  Widget _buildContactSection(ProfessionalProfileData data) {
    final contact = data.contact;
    final hasData = contact != null &&
        ((contact.website ?? '').isNotEmpty ||
            (contact.phone ?? '').isNotEmpty ||
            (contact.email ?? '').isNotEmpty);

    final lat = double.tryParse(
            data.contact?.location?.coordinates?[0].toString() ?? '') ??
        0.0;
    final lng = double.tryParse(
            data.contact?.location?.coordinates?[1].toString() ?? '') ??
        0.0;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Contact Us",
              onEdit: () =>
                  _navigateToEdit(ProfessionalContactUsScreen())),
          if (hasData)
            Container(
              padding: EdgeInsets.all(SizeConfig.size12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((contact.website ?? "").isNotEmpty)
                    _contactRow(AppIconAssets.website_click,
                        contact.website!,
                        isLink: true),
                  if ((contact.phone ?? "").isNotEmpty)
                    _contactRow(
                        AppIconAssets.phone_outline, contact.phone!),
                  if ((contact.email ?? "").isNotEmpty)
                    _contactRow(
                        AppIconAssets.email, contact.email!),
                  if ((contact.address ?? "").isNotEmpty)
                    _contactRow(AppIconAssets.location_new,
                        contact.address!,
                        color: AppColors.secondaryTextColor),
                ],
              ),
            )
          else
            _emptyStateCard(
              icon: Icons.contact_mail_rounded,
              title: 'Add your contact details',
              subtitle:
                  'Make it easy for clients to reach you by phone, email or web.',
              actionLabel: 'Add',
              onAdd: () => _navigateToEdit(ProfessionalContactUsScreen()),
            ),
          // Map sits inside the same card so contact details and the
          // pin read as one unified block instead of two separated
          // sheets.
          SizedBox(height: SizeConfig.size8),
          BusinessLocationWidget(
            locationText: data.basicDetails?.fullName,
            latitude: lat,
            longitude: lng,
            businessName: '',
            padding: 0,
            isTitleShow: false,
          ),
        ],
      ),
    );
  }

  Widget _contactRow(String icon, String text,
      {bool isLink = false, Color? color}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: isLink ? null : AppColors.mainTextColor,
            height: 20,
            width: 20,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: InkWell(
              onTap: isLink ? () => launchUrl(Uri.parse(text)) : null,
              child: CustomText(
                text,
                color: color ?? AppColors.black,
                decoration: isLink
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WORKING HOURS
  // ============================================================

  Widget _buildTimingsSection(ProfessionalProfileData data) {
    final timings = data.timings;
    final hasData = timings?.schedule != null;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Working Hours",
              onEdit: () =>
                  _navigateToEdit(ProfessionalsTimingScreen())),
          if (hasData)
            _buildTimingsGrid(timings!)
          else
            _emptyStateCard(
              icon: Icons.schedule_rounded,
              title: 'Set your working hours',
              subtitle:
                  'Tell clients when you\'re available so bookings come at the right time.',
              actionLabel: 'Add',
              onAdd: () => _navigateToEdit(ProfessionalsTimingScreen()),
            ),
        ],
      ),
    );
  }

  Widget _buildTimingsGrid(Timings timings) {
    final schedule = timings.schedule;
    Widget item(
        String day, bool? open, String? openTime, String? closeTime) {
      final isOpen = open == true;
      final text = isOpen ? "$openTime - $closeTime" : "Closed";
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(day, fontWeight: FontWeight.w500),
            CustomText(
              text,
              color: isOpen ? Colors.green : Colors.red,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        item("Monday", schedule?.monday?.isOpen,
            schedule?.monday?.openTime, schedule?.monday?.closeTime),
        item("Tuesday", schedule?.tuesday?.isOpen,
            schedule?.tuesday?.openTime, schedule?.tuesday?.closeTime),
        item(
            "Wednesday",
            schedule?.wednesday?.isOpen,
            schedule?.wednesday?.openTime,
            schedule?.wednesday?.closeTime),
        item(
            "Thursday",
            schedule?.thursday?.isOpen,
            schedule?.thursday?.openTime,
            schedule?.thursday?.closeTime),
        item("Friday", schedule?.friday?.isOpen,
            schedule?.friday?.openTime, schedule?.friday?.closeTime),
        item(
            "Saturday",
            schedule?.saturday?.isOpen,
            schedule?.saturday?.openTime,
            schedule?.saturday?.closeTime),
        item("Sunday", schedule?.sunday?.isOpen,
            schedule?.sunday?.openTime, schedule?.sunday?.closeTime),
      ],
    );
  }
}

// ============================================================
// FULL GALLERY SCREEN
// ============================================================

class _FullGalleryScreen extends StatelessWidget {
  final List<String> imageUrls;

  const _FullGalleryScreen({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          "${AppStrings.gallery} (${imageUrls.length})",
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: imageUrls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => navigatePushTo(
              context,
              ImageViewScreen(
                subTitle: AppStrings.imageViewer,
                appBarTitle: AppStrings.imageViewer,
                imageUrls: imageUrls,
                initialIndex: index,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
