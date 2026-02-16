import 'dart:math';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart'
    hide Timings;
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_project_card_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverProfessionalsViewScreen extends StatelessWidget {
  final ProfessionalConsData professionalConsData;

  DiscoverProfessionalsViewScreen(
      {super.key, required this.professionalConsData});

  @override
  Widget build(BuildContext context) {
    final data = professionalConsData;
    final images = _extractPortfolioMedia(data, type: "image");

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: data.basicDetails?.professionalTitle,
      ),
      body: Padding(
        padding: EdgeInsets.all(SizeConfig.paddingXS),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///FOOD HOTEL....
              CommonCardWidget(
                cardMargin: 0,
                padding: 0,
                child: _buildHeaderSection(context),
              ),
              SizedBox(height: SizeConfig.size20),

              CommonCardWidget(
                cardMargin: 0,
                padding: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 10.0, bottom: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Our Services"),
                      _buildServicesFromAbout(data),
                    ],
                  ),
                ),
              ),

              SizedBox(height: SizeConfig.size20),
              CommonCardWidget(
                cardMargin: 0,
                padding: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 0.0, bottom: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (images.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.only(
                              left: 10.0,
                            ),
                            child: _buildSectionTitle("Project Images")),
                      if (data.portfolio?.isNotEmpty ?? false)
                        _buildProjectHorizontal(data),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size20),

              // SizedBox(height: SizeConfig.size20),
              CommonCardWidget(
                cardMargin: 0,
                padding: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((data.certificates ?? []).isNotEmpty)
                      _buildSectionTitle("Certificate & Awards"),
                    if ((data.certificates ?? []).isNotEmpty)
                      _buildCertificates(data.certificates!),
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.size20),
              CommonCardWidget(
                cardMargin: 0,
                padding: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((data.gallery?.signedUrls ?? []).isNotEmpty)
                      _buildSectionTitle("Gallery"),
                    if ((data.gallery?.signedUrls ?? []).isNotEmpty)
                      _buildGallery(data.gallery?.signedUrls ?? [], context),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size20),
              CommonCardWidget(
                cardMargin: 0,
                padding: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Contact Us"),
                    _buildContact(data),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size12),
              // const SizedBox(height: 20),
              // Map Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BusinessLocationWidget(
                    locationText: data.basicDetails?.fullName,
                    latitude: double.parse(
                        data.contact?.location?.coordinates?[0].toString() ??
                            "0.0"),
                    longitude: double.parse(
                        data.contact?.location?.coordinates?[1].toString() ??
                            "0.0"),
                    businessName: "",
                    padding: 10,
                    isTitleShow: true),
              ),
              SizedBox(height: SizeConfig.size12),
              CommonCardWidget(
                cardMargin: 0,
                padding: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Working Hours"),
                    _buildTimings(data.timings),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    String _capitalizeFirstLetter(String text) {
      if (text.isEmpty) return '';
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }
    final banner = professionalConsData.basicDetails?.profilePhotoUrl ??
        '';
    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Banner + Profile + Edit + Share ===
          Container(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner (dark gradient or user banner)
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
                    child: banner.isNotEmpty
                        ? Image.network(banner, fit: BoxFit.cover)
                        : CachedNetworkImage(
                      imageUrl: banner,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: SizeConfig.size32,
                        height: SizeConfig.size32,
                        color: Colors.grey[300],
                      ),
                      errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: SizeConfig.size32 / 2),
                    ),
                  ),
                ),

                // Profile Image
                Positioned(
                  left: 20,
                  top: 90,
                  child: CommonProfileImage(
                    imagePath:
                    banner ??
                        "",
                    onImageUpdate: (image) async {},
                    dialogTitle: AppStrings.uploadProfilePicture,
                    //radius: 36,
                    showProfileBorder: true,
                    isOwnProfile: false,
                  ),
                ),
              ],
            ),
          ),

          // === Name + Role ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomText(
                  _capitalizeFirstLetter(
                    professionalConsData.basicDetails?.fullName ??
                        '',
                  ),
                  fontSize: SizeConfig.size24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
          ),

          // === Bio Section ===
        professionalConsData.about?.description?.isNotEmpty ??
                  false
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                  child: ExpandableText(
                    text: professionalConsData.about?.description ??
                        "",
                    trimLines: 3,
                    style: TextStyle(
                      color: AppColors.mainTextColor,
                      fontSize: 14,
                      wordSpacing: 0.4,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w400,
                      height:
                          1.5, // 👈 increases vertical gap between lines (default is ~1.0)
                    ),
                    expandMode: ExpandMode.dialog,
                    dialogTitle: AppStrings.bio,
                  ),
                )
              : SizedBox(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
      child: CustomText(
        title,
        fontWeight: FontWeight.w600,
        fontSize: SizeConfig.size16,
      ),
    );
  }

  Widget _buildServicesFromAbout(ProfessionalConsData data) {
    final desc =
        data.about?.majorProjectsDescription ?? data.about?.description ?? "";
    if (desc.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomText(
        desc,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  List<String> _extractPortfolioMedia(ProfessionalConsData data,
      {required String type}) {
    final list = <String>[];
    for (final p in data.portfolio ?? []) {
      for (final m in p.media ?? []) {
        if ((m.type ?? "").toLowerCase() == type && (m.url ?? "").isNotEmpty) {
          list.add(m.url!);
        }
      }
    }
    return list;
  }

  Widget _buildProjectHorizontal(ProfessionalConsData data) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.portfolio?.length,
        itemBuilder: (context, index) {
          return Container(
            width: Get.width,
            padding: EdgeInsets.zero,
            child: PortfolioProjectCardWidget(
              isShowMore: false,
              project: data.portfolio?[index] ?? ProfessionalPortfolio(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCertificates(List<Certificates> certs) {
    final items = certs;

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 260, // Height of the card area
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: 0),
        itemBuilder: (context, index) {
          final cert = items[index];
          return Container(
            width: 240, // Width as per design aspect ratio
            margin: EdgeInsets.only(right: SizeConfig.size12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // 1. Background Image
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: cert.fileKey ?? "",
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[300]),
                      errorWidget: (context, url, error) => Image.asset(
                          'assets/images/placeholder.png',
                          fit: BoxFit.cover),
                    ),
                  ),

                  // 2. Gradient Overlay for Text Readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Text Content Overlaid at the Bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.all(SizeConfig.size12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            cert.title ?? "Certificate Name",
                            color: Colors.white,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: SizeConfig.size4),
                          CustomText(
                            cert.description ?? "Description goes here...",
                            color: Colors.white,
                            fontSize: SizeConfig.small,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }

  Widget _buildGallery(List<String> signedUrls, BuildContext context) {
    final all = List<String>.from(signedUrls);
    all.shuffle(Random());
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(signedUrls.length > 10 ? 10 : signedUrls.length,
          (index) {
        // Logic to replicate the pattern in your image:
        // Large Vertical (index 0), Two small (index 1,2), Large Horizontal (index 3)...
        int crossAxisCellCount = 2;
        num mainAxisCellCount = 2;

        if (index % 6 == 0 || index % 6 == 5) {
          // Large Vertical Tiles
          crossAxisCellCount = 2;
          mainAxisCellCount = 3;
        } else if (index % 6 == 3) {
          // Large Full-Width Horizontal Tile
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else {
          // Standard Small Squares
          crossAxisCellCount = 2;
          mainAxisCellCount = 1.5;
        }

        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          child: InkWell(
            onTap: () {
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: AppStrings.imageViewer,
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: signedUrls,
                  initialIndex: index,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                signedUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContact(ProfessionalConsData data) {
    final contact = data.contact;
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((contact?.website ?? "").isNotEmpty)
            _contactRow(AppIconAssets.website_click, contact!.website!,
                isLink: true),
          if ((contact?.phone ?? "").isNotEmpty)
            _contactRow(AppIconAssets.phone_outline, contact!.phone!),
          if ((contact?.email ?? "").isNotEmpty)
            _contactRow(AppIconAssets.email, contact!.email!),
          if ((contact?.address ?? "").isNotEmpty)
            _contactRow(AppIconAssets.location_new, contact!.address!,
                color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  Widget _contactRow(String icon, String text,
      {bool isLink = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: isLink == false ? AppColors.mainTextColor : null,
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
                decoration:
                    isLink ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimings(Timings? timings) {
    final monday = timings?.schedule?.monday;
    final tuesday = timings?.schedule?.tuesday;
    final wednesday = timings?.schedule?.wednesday;
    final thursday = timings?.schedule?.thursday;
    final friday = timings?.schedule?.friday;
    final saturday = timings?.schedule?.saturday;
    final sunday = timings?.schedule?.sunday;

    Widget item(String day, bool? open, String? openTime, String? closeTime) {
      final isOpen = open == true;
      final text = isOpen ? "$openTime - $closeTime" : "Closed";
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(day, fontWeight: FontWeight.w500),
          CustomText(
            text,
            color: isOpen ? Colors.green : Colors.red,
          ),
        ],
      );
    }

    return Column(
      children: [
        item("Monday", monday?.isOpen, monday?.openTime, monday?.closeTime),
        item("Tuesday", tuesday?.isOpen, tuesday?.openTime, tuesday?.closeTime),
        item("Wednesday", wednesday?.isOpen, wednesday?.openTime,
            wednesday?.closeTime),
        item("Thursday", thursday?.isOpen, thursday?.openTime,
            thursday?.closeTime),
        item("Friday", friday?.isOpen, friday?.openTime, friday?.closeTime),
        item("Saturday", saturday?.isOpen, saturday?.openTime,
            saturday?.closeTime),
        item("Sunday", sunday?.isOpen, sunday?.openTime, sunday?.closeTime),
      ],
    );
  }
}
