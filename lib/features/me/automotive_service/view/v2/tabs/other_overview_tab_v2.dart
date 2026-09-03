import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/me/automotive_service/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/automotive_service/view/management/management_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_career_jobs/other_job_listing_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_contact_us/other_branch_details_form_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_contact_us/other_branch_only_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_service_gallery/other_service_photos_screen.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart'
    hide Location;
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/api/apiService/api_keys.dart';
import '../../../../../../widgets/common_business_live_photo.dart';
import '../../../../../business/widgets/business_contact_map_card.dart';
import '../../../../../business/widgets/business_joined_profile_card.dart';
import '../../../../../business/widgets/website_overview_card.dart';
import '../../../../others/view/timing_screen.dart';

/// Overview tab for the redesigned other-business "me" profile.
///
/// Mirrors the hospital v2 overview structure: cover banner first, then
/// management, gallery, career/jobs CTA, contact, location, share
/// banner, and the QR-code card pinned at the bottom of the tab.
class OtherOverviewTabV2 extends StatelessWidget {
  final AutomotiveBusinessProfileFullController controller;

  const OtherOverviewTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Obx(() {
      final data = controller.businessProfile.value;
      final coordinates = data?.profile?.location?.coordinates;
      final hasCoords = coordinates != null &&
          coordinates.length >= 2 &&
          (double.tryParse(coordinates[0].toString()) ?? 0.0) != 0.0 &&
          (double.tryParse(coordinates[1].toString()) ?? 0.0) != 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size10),
          Padding(
            padding: EdgeInsets.only(
              left: SizeConfig.size20,
            ),
            child: BusinessJoinedProfileCard(
                businessController: businessController),
          ),
          SizedBox(height: SizeConfig.size12),

          // ── Management ──
          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size30, right: SizeConfig.size12),
            child: CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: AppStrings.otherManagementTitle.tr,
                    actionLabel: AppStrings.viewAll,
                    onAction: () => Get.to(() => const ManagementScreen())
                        ?.then((_) => controller.getBusinessProfileFull()),
                  ),
                  const SizedBox(height: 10),
                  if ((data?.management?.isNotEmpty ?? false))
                    _ManagementList(items: data!.management!)
                  else
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_management.png',
                      ctaLabel: AppStrings.otherManagementTitle.tr,
                      ctaIcon: Icons.groups_outlined,
                      onTap: () => Get.to(() => const ManagementScreen())
                          ?.then((_) => controller.getBusinessProfileFull()),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: SizeConfig.size10),

          // ── Career / Jobs ──
          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size30, right: SizeConfig.size12),
            child: CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: AppStrings.otherJobsTitle.tr,
                    actionLabel: AppStrings.viewAll,
                    onAction: () => Get.to(() => const OtherJobListingScreen())
                        ?.then((_) => controller.getBusinessProfileFull()),
                  ),
                  const SizedBox(height: 10),
                  EmptySectionPlaceholder(
                    imageAsset: 'assets/images/other_job.png',
                    ctaLabel: AppStrings.otherJobsTitle.tr,
                    ctaIcon: Icons.work_outline,
                    onTap: () => Get.to(() => const OtherJobListingScreen())
                        ?.then((_) => controller.getBusinessProfileFull()),
                  ),
                ],
              ),
            ),
          ),

          // SizedBox(height: SizeConfig.size10),

          Padding(
              padding: EdgeInsets.only(
                  left: SizeConfig.size30, right: SizeConfig.size12),
              child: CommonBusinessLivePhoto(controller: businessController)),

          SizedBox(height: SizeConfig.size10),

          // ── Gallery ──
          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size30, right: SizeConfig.size12),
            child: CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: AppStrings.gallery.tr,
                    actionLabel: AppStrings.otherAddEdit.tr,
                    onAction: () => Get.to(() => OtherServicePhotosPhotoScreen())
                        ?.then((_) => controller.getBusinessProfileFull()),
                  ),
                  const SizedBox(height: 10),
                  if ((data?.gallery?.isNotEmpty ?? false))
                    _Gallery(galleryList: data!.gallery!)
                  else
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_gallery.png',
                      ctaLabel: AppStrings.gallery.tr,
                      onTap: () => Get.to(() => OtherServicePhotosPhotoScreen())
                          ?.then((_) => controller.getBusinessProfileFull()),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size10),

          // ── Timings ──
          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size30, right: SizeConfig.size12),
            child: _TimingCard(
              timings: data?.timings,
              onEditTap: () => Get.to(() => TimingScreen())
                  ?.then((_) => controller.getBusinessProfileFull()),
            ),
          ),

          // SizedBox(height: SizeConfig.size10),
          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size30),
            child: Obx(() {
              final details =
                  businessController.businessProfileDetails.value?.data;
              return BusinessContactMapCard(businessProfileDetails: details);
            }),
          ),
          // // ── Contact Us ──
          // Padding(
          //   padding: EdgeInsets.only(
          //       left: SizeConfig.size20, top: SizeConfig.size10),
          //   child: CommonCardWidget(
          //     padding: 10,
          //     cardMargin: 0,
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         _SectionHeader(
          //           title: AppStrings.contactUs.tr,
          //           actionLabel: AppStrings.otherAddEdit.tr,
          //           onAction: () => Get.to(() => OtherContactUs())
          //               ?.then((_) => controller.getBusinessProfileFull()),
          //         ),
          //         const SizedBox(height: 10),
          //         if ((data?.contactUs?.isNotEmpty ?? false))
          //           _ContactUs(
          //             contacts: data!.contactUs!.first,
          //           )
          //         else
          //           EmptySectionPlaceholder(
          //             imageAsset: 'assets/images/other_gallery.png',
          //             ctaLabel: AppStrings.contactUs.tr,
          //             ctaIcon: Icons.contact_phone_outlined,
          //             onTap: () => Get.to(() => OtherContactUs())
          //                 ?.then((_) => controller.getBusinessProfileFull()),
          //           ),
          //       ],
          //     ),
          //   ),
          // ),
          //
          // SizedBox(height: SizeConfig.size10),
          //
          // if (hasCoords)
          //   Padding(
          //     padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          //     child: ClipRRect(
          //       borderRadius: BorderRadius.circular(12),
          //       child: BusinessLocationWidget(
          //         locationText:
          //             data?.contactUs?.firstOrNull?.branch?.location?.name,
          //         latitude: double.parse(coordinates[0].toString()),
          //         longitude: double.parse(coordinates[1].toString()),
          //         businessName: data?.profile?.profileName ?? '',
          //         padding: 10,
          //         isTitleShow: true,
          //       ),
          //     ),
          //   ),

          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size12, left: SizeConfig.size30),
            child: WebsiteOverviewCard(
              websiteUrl: businessController
                  .businessProfileDetails.value?.data?.websiteUrl,
              onSave: (url) => businessController
                  .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size30, right: SizeConfig.size12),
            child: const ProfileShareBanner(),
          ),
          // SizedBox(height: SizeConfig.size10),

          // ── QR Code (mirrors the hospital QR card) ──
          Obx(() {
            final details =
                businessController.businessProfileDetails.value?.data;
            if (details == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(
                  left: SizeConfig.size30, right: SizeConfig.size12),
              child: BusinessQrCodeWidget(data: details),
            );
          }),

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ServiceHomeTitleWidget(title: title),
        InkWell(
          onTap: onAction,
          child: CustomText(
            actionLabel.tr,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ManagementList extends StatelessWidget {
  final List<Management> items;
  const _ManagementList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final m = items[i];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: AppColors.whiteE5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: m.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child:
                              Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            m.name ?? '',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((m.position ?? '').isNotEmpty)
                            CustomText(
                              m.position ?? '',
                              color: AppColors.whiteE5,
                              fontSize: 12,
                              maxLines: 1,
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
}

class _Gallery extends StatelessWidget {
  final List<Gallery> galleryList;
  const _Gallery({required this.galleryList});

  @override
  Widget build(BuildContext context) {
    final allImages = <String>[];
    for (final g in galleryList) {
      if (g.imageUrls != null) allImages.addAll(g.imageUrls!);
    }
    if (allImages.isEmpty) return const SizedBox.shrink();
    return _GalleryLayout(images: allImages);
  }
}

class _GalleryLayout extends StatelessWidget {
  final List<String> images;
  const _GalleryLayout({required this.images});

  @override
  Widget build(BuildContext context) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;
    const double height = 220;
    const double gap = 4;

    void open(int i) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImageViewScreen(
              subTitle: AppStrings.imageViewer,
              appBarTitle: AppStrings.imageViewer,
              imageUrls: images,
              initialIndex: i,
            ),
          ),
        );

    Widget tile(int i, {bool overlay = false}) => GestureDetector(
          onTap: () => open(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: display[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
                if (overlay && extra > 0)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text('+$extra',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        );

    if (display.length == 1) {
      return SizedBox(height: height, width: double.infinity, child: tile(0));
    }
    if (display.length == 2) {
      return SizedBox(
        height: height,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(child: tile(1)),
        ]),
      );
    }
    if (display.length == 3) {
      return SizedBox(
        height: height,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(
            child: Column(children: [
              Expanded(child: tile(1)),
              const SizedBox(height: gap),
              Expanded(child: tile(2)),
            ]),
          ),
        ]),
      );
    }
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              Expanded(child: tile(0)),
              const SizedBox(width: gap),
              Expanded(child: tile(1)),
            ]),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(children: [
              Expanded(child: tile(2)),
              const SizedBox(width: gap),
              Expanded(child: tile(3, overlay: extra > 0)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ContactUs extends StatelessWidget {
  final ContactUsOtherProfile contacts;
  const _ContactUs({required this.contacts});

  @override
  Widget build(BuildContext context) {
    final branch = contacts.branch;
    final firstDept = (contacts.departments?.isNotEmpty ?? false)
        ? contacts.departments!.first
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_outlined,
                      size: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CustomText(
                      branch?.name ?? '',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => OtherBranchOnlyScreen(
                      schoolContactUsData: SchoolContactUsData(
                        id: contacts.id,
                        branch: Branch(
                          name: contacts.branch?.name,
                          location: SchoolLocation(
                            name: contacts.branch?.location?.name,
                            coordinates:
                                contacts.branch?.location?.coordinates ?? [],
                          ),
                          website: contacts.branch?.website,
                        ),
                        departments: contacts.departments ?? [],
                        schoolId: contacts.id,
                        v: contacts.v,
                      ),
                    )),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.primaryColor),
                          SizedBox(width: 4),
                          CustomText(AppStrings.edit,
                              fontSize: 12, color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (branch?.website != null && branch!.website!.isNotEmpty)
                _row(AppIconAssets.website_click, branch.website!,
                    AppColors.primaryColor,
                    isLink: true),
              if (firstDept != null) ...[
                if (firstDept.phone != null && firstDept.phone!.isNotEmpty)
                  _row(AppIconAssets.phone_outline, firstDept.phone!,
                      AppColors.mainTextColor),
                if (firstDept.email != null && firstDept.email!.isNotEmpty)
                  _row(AppIconAssets.email, firstDept.email!,
                      AppColors.mainTextColor),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => Get.to(() => OtherBranchDetailsFormScreen()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, size: 16, color: AppColors.primaryColor),
                SizedBox(width: 6),
                CustomText(AppStrings.addMore,
                    fontSize: 13,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String icon, String text, Color textColor,
      {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: isLink == false ? AppColors.mainTextColor : null,
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: isLink ? () => launchUrl(Uri.parse(text)) : null,
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  final Timings? timings;
  final VoidCallback onEditTap;

  const _TimingCard({required this.timings, required this.onEditTap});

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  DayTiming? _slotFor(String day) {
    switch (day) {
      case 'Monday':
        return timings?.monday;
      case 'Tuesday':
        return timings?.tuesday;
      case 'Wednesday':
        return timings?.wednesday;
      case 'Thursday':
        return timings?.thursday;
      case 'Friday':
        return timings?.friday;
      case 'Saturday':
        return timings?.saturday;
      case 'Sunday':
        return timings?.sunday;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      padding: 12,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.otherTimingTitle.tr,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              _TimingEditPill(onTap: onEditTap),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          ..._weekDays.map((day) {
            final slot = _slotFor(day);
            return _TimingRow(
              day: day,
              isOpen: slot?.isOpen ?? false,
              openTime: slot?.openTime ?? '10:00',
              closeTime: slot?.closeTime ?? '10:00',
            );
          }),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  final String day;
  final bool isOpen;
  final String openTime;
  final String closeTime;

  const _TimingRow({
    required this.day,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: CustomText(
              day,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
          _TimingStatusBadge(isOpen: isOpen),
          const Spacer(),
          if (isOpen) ...[
            _TimingChip(time: openTime),
            const SizedBox(width: 6),
            CustomText('-', fontSize: 12, color: AppColors.grey99),
            const SizedBox(width: 6),
            _TimingChip(time: closeTime),
          ],
        ],
      ),
    );
  }
}

class _TimingStatusBadge extends StatelessWidget {
  final bool isOpen;
  const _TimingStatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final bg = isOpen
        ? AppColors.greenShade.withValues(alpha: 0.12)
        : AppColors.greyE6;
    final fg = isOpen ? AppColors.greenShade : AppColors.grey83;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        isOpen ? 'Open' : 'Closed',
        fontSize: 11,
        color: fg,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TimingChip extends StatelessWidget {
  final String time;
  const _TimingChip({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.whiteE0),
      ),
      alignment: Alignment.center,
      child: CustomText(
        time,
        fontSize: 12,
        color: AppColors.grey83,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _TimingEditPill extends StatelessWidget {
  final VoidCallback onTap;
  const _TimingEditPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 13, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.edit.tr,
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
