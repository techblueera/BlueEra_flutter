import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/category_selector_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/empty_blood_test_add_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/empty_health_camp_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/lab_header_view.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_description_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_contact_us_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/lab_service_photos_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/facility_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabFullDetailsScreen extends StatefulWidget {
  const LabFullDetailsScreen({super.key});

  @override
  State<LabFullDetailsScreen> createState() => _LabFullDetailsScreenState();
}

class _LabFullDetailsScreenState extends State<LabFullDetailsScreen> {
  late final LabFullDetailsController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<LabFullDetailsController>()) {
      controller = Get.put(LabFullDetailsController(), permanent: true);
    } else {
      controller = Get.find<LabFullDetailsController>();
    }
    controller.fetchFullDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = controller.details.value;
        final profile = d?.profile;
        final tests = d?.tests ?? <Tests>[];
        final galleries = d?.galleries ?? <Galleries>[];
        final contact = d?.contactInfo;
        final facility = d?.facility;
        return LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return SingleChildScrollView(
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabHeaderView(
                  controller: controller,
                ),

                // Description section - show empty state if no description
                SizedBox(height: SizeConfig.size12),
                if ((profile?.description ?? '').isEmpty)
                  _emptySection(
                    title: AppStrings.description.tr,
                    subtitle: AppStrings.labAddDescriptionForLab.tr,
                    icon: Icons.description_outlined,
                    onEdit: () => Get.to(() => const LabDescriptionScreen())
                        ?.then((_) => controller.fetchFullDetails()),
                  )
                else
                  CommonCardWidget(
                    padding: 10,
                    cardMargin: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(AppStrings.description.tr,
                                fontWeight: FontWeight.w700),
                            _editButton(
                              onTap: () =>
                                  Get.to(() => const LabDescriptionScreen())
                                      ?.then((_) =>
                                          controller.fetchFullDetails()),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size8),
                        CustomText(
                          profile?.description ?? '',
                          fontSize: 14,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: SizeConfig.size12),
                BloodTestEmptyState(),
                SizedBox(height: SizeConfig.size12),
                CategorySelector(),

                SizedBox(height: SizeConfig.size12),
                EmptyHealthCampWidget(),

                SizedBox(height: SizeConfig.size12),
                // Popular services - show empty state if no tests
                if (tests.isEmpty)
                  _emptySection(
                    title: AppStrings.ourPopularServices.tr,
                    subtitle: AppStrings.labAddTestsToShowcase.tr,
                    icon: Icons.medical_services_outlined,
                    onEdit: null,
                  )
                else
                  CommonCardWidget(
                      padding: 10,
                      cardMargin: 0,
                      child: _popularServices(tests, profile)),

                // Facility section - show empty state if no facility data
                SizedBox(height: SizeConfig.size16),
                if (_isFacilityEmpty(facility))
                  _emptySection(
                    title: AppStrings.facility.tr,
                    subtitle: AppStrings.labAddFacilityDetails.tr,
                    icon: Icons.local_hospital_outlined,
                    onEdit: () => Get.to(() => FacilityScreen())
                        ?.then((_) => controller.fetchFullDetails()),
                  )
                else
                  CommonCardWidget(
                    padding: 10,
                    cardMargin: 0,
                    child: _allServices(facility),
                  ),

                // Gallery section
                SizedBox(height: SizeConfig.size16),
                _buildGallerySection(galleries, context),

                // Contact section - show empty state if no contact
                SizedBox(height: SizeConfig.size16),
                if (contact == null)
                  _emptySection(
                    title: AppStrings.contactUs.tr,
                    subtitle: AppStrings.labAddContactInfo.tr,
                    icon: Icons.contact_phone_outlined,
                    onEdit: () => Get.to(() => LabContactUsScreen())
                        ?.then((_) => controller.fetchFullDetails()),
                  )
                else
                  _contact(contact, isWide),

                const BusinessShareBanner(),

                SizedBox(height: kBottomNavigationBarHeight + 30),
              ],
            ),
          );
        });
      }),
    );
  }

  bool _isFacilityEmpty(Facility? facility) {
    if (facility == null) return true;
    return facility.wheelchairAssistance != true &&
        facility.doctorConsultationTieUp != true &&
        facility.insuranceCashlessSupport != true &&
        facility.homeSampleCollection != true &&
        facility.digitalReport != true &&
        (facility.other?.isEmpty ?? true);
  }

  Widget _emptySection({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onEdit,
  }) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(title, fontWeight: FontWeight.w700),
              if (onEdit != null) _editButton(onTap: onEdit),
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          Center(
            child: Column(
              children: [
                Icon(icon, size: 40, color: AppColors.greyA5),
                SizedBox(height: SizeConfig.size8),
                CustomText(
                  subtitle,
                  fontSize: 13,
                  color: AppColors.greyA5,
                  textAlign: TextAlign.center,
                ),
                if (onEdit != null) ...[
                  SizedBox(height: SizeConfig.size12),
                  InkWell(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomText(
                        AppStrings.create.tr,
                        fontSize: 13,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: SizeConfig.size8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined,
                size: 14, color: AppColors.primaryColor),
            SizedBox(width: 4),
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

  Widget _popularServices(List<Tests> tests, Profile? profile) {
    if (tests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(AppStrings.ourPopularServices.tr, fontWeight: FontWeight.w700),
        SizedBox(height: SizeConfig.size8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) {
              final t = tests[i];
              return Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(t.testName ?? "",
                        fontSize: SizeConfig.small, maxLines: 2),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
            itemCount: tests.length.clamp(0, 10),
          ),
        ),
      ],
    );
  }

  Widget _allServices(Facility? facility) {
    final chips = <String>[];
    if (facility?.wheelchairAssistance == true)
      chips.add("wheelchair_assistance".tr);
    if (facility?.doctorConsultationTieUp == true)
      chips.add("doctor_consultation_tie_up".tr);
    if (facility?.insuranceCashlessSupport == true)
      chips.add("insurance_cashless_support".tr);
    if (facility?.homeSampleCollection == true)
      chips.add("home_sample_collection".tr);
    if (facility?.digitalReport == true) chips.add("digital_report".tr);
    final other = (facility?.other ?? [])
        .map((e) => e.label ?? '')
        .where((e) => e.toString().isNotEmpty)
        .toList();
    return SizedBox(
      width: Get.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.facility.tr, fontWeight: FontWeight.w700),
              _editButton(
                onTap: () => Get.to(() => FacilityScreen())
                    ?.then((_) => controller.fetchFullDetails()),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...chips.map((c) => _chip(c)),
              ...other.map((c) => _chip(c)),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToGalleryEdit() {
    Get.to(() => LabServicePhotosPhotoScreen())
        ?.then((_) => controller.fetchFullDetails());
  }

  Widget _buildGallerySection(
      List<Galleries> galleries, BuildContext context) {
    final List<String> allImages = galleries
            .expand((photo) => photo.imageUrls ?? <String>[])
            .toList();
    final hasData = allImages.isNotEmpty;

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                    child: ServiceHomeTitleWidget(title: AppStrings.gallery)),
                InkWell(
                  onTap: _navigateToGalleryEdit,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          if (hasData)
            _buildGalleryGrid(allImages, context)
          else
            _emptyGalleryPlaceholder(),
        ],
      ),
    );
  }

  Widget _emptyGalleryPlaceholder() {
    return InkWell(
      onTap: _navigateToGalleryEdit,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.image, size: 28, color: Color(0xFFBDBDBD)),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(List<String> signedUrls, BuildContext context) {
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
        onTap: () => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: signedUrls,
            initialIndex: 0,
          ),
        ),
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

    // 3 images: 1 left vertical + 2 right stacked
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

    // 4+ images: 2x2 grid, with "+N" overlay on last tile if more than 4
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

  Widget _contact(ContactInfo? contact, bool isWide) {
    final loc = contact?.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContactCard(contact),
        SizedBox(height: SizeConfig.size16),

        BusinessLocationWidget(
            locationText: "",
            latitude: double.parse(loc?.coordinates?[1].toString() ?? "0.0"),
            longitude: double.parse(loc?.coordinates?[0].toString() ?? "0.0"),
            businessName: loc?.name ?? "",
            padding: 0,
            isTitleShow: true),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: CustomText(text, fontSize: SizeConfig.small),
    );
  }

  Widget _buildContactCard(ContactInfo? profile) {
    return CommonCardWidget(
      padding: 5,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 6, right: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(AppStrings.contactUs, fontWeight: FontWeight.bold),
                _editButton(
                  onTap: () => Get.to(() => LabContactUsScreen())
                      ?.then((_) => controller.fetchFullDetails()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and Hotel Name
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                      image: (controller.details.value?.profile?.logoUrl?.isNotEmpty ?? false)
                          ? DecorationImage(
                              image: NetworkImage(controller.details.value!.profile!.logoUrl!),
                              fit: BoxFit.cover)
                          : DecorationImage(
                              image: AssetImage(AppIconAssets.place_holder_image),
                              fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 10),
                CustomText(controller.details.value?.profile?.name,
                    fontSize: 20, fontWeight: FontWeight.bold),

                const SizedBox(height: 5),
                CustomText(
                  controller.details.value?.profile?.description ?? "",
                  color: Colors.grey,
                  fontSize: 14,
                ),
                const Divider(height: 30),

                // Contact List
                _contactItem(AppIconAssets.website_click,
                    profile?.websiteUrl ?? "", Colors.blue),
                _contactItem(
                    AppIconAssets.principal, AppStrings.reception.tr, Colors.grey[700]!),
                _contactItem(AppIconAssets.email, profile?.email ?? "",
                    AppColors.secondaryTextColor),
                _contactItem(AppIconAssets.phone_outline,
                    profile?.phoneNo ?? "", AppColors.secondaryTextColor),
                _contactItem(AppIconAssets.location_new,
                    profile?.location?.name ?? "", Colors.grey[700]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(label, fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}
