import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/lab_header_view.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/lab_home_gallery_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
                  schoolAboutUsController: controller,
                ),
                SizedBox(height: SizeConfig.size12),
                _basicTest(tests),
                SizedBox(height: SizeConfig.size16),
                CommonCardWidget(
                    padding: 10,
                    cardMargin: 0,
                    child: _popularServices(tests, profile)),
                SizedBox(height: SizeConfig.size16),
                CommonCardWidget(
                    padding: 10, cardMargin: 0, child: _allServices(facility)),
                SizedBox(height: SizeConfig.size16),
                LabHomeGalleryWidget(photos: galleries),
                // SizedBox(height: SizeConfig.size16),
                _contact(contact, isWide),
              ],
            ),
          );
        });
      }),
    );
  }

  Widget _basicTest(List<Tests> tests) {
    final List<Color> cardColors = [
      Color(0xFFFFFBEB), // Soft Yellow/Cream
      Color(0xFFF0FDF4), // Soft Green
      Color(0xFFEFF6FF), // Soft Blue
      Color(0xFFFAF5FF), // Soft Purple
    ];
    if (tests.isEmpty) return const SizedBox.shrink();
    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText("Test Report", fontWeight: FontWeight.w700),
          SizedBox(
            height: 200, // Adjusted height to accommodate the layout
            child: ListView.builder(
              itemCount: tests.length,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 0),
              itemBuilder: (BuildContext context, int index) {
                final t = tests[index];
                // Logic to repeat the 4 colors
                final backgroundColor = cardColors[index % cardColors.length];

                return Container(
                  width: 300,
                  // Fixed width for horizontal cards
                  margin: EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    // Subtle shadow to match the "lifted" look
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title and More Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                              t.testName ?? "Test Name",
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Icon(Icons.more_vert, color: Colors.black87),
                        ],
                      ),
                      SizedBox(height: 4),
                      CustomText(
                        t.description ?? "",
                        color: Colors.grey.shade600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: Colors.grey.shade300, height: 1),
                      ),

                      // Middle Row: Report Time and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _pill(
                              "Reports within ${t.estimatedReportHours ?? 24} hours",
                              Colors.white),
                          _pill("INR-${t.customerPrice ?? 0}", Colors.white,
                              isBold: true),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Bottom Row: Home Collection status
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.grey),
                          SizedBox(width: 8),
                          CustomText(
                            "Home sample collection available",
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

// Helper method for the styled pills
  }

  // Helper method for the styled pills
  Widget _pill(String text, Color bgColor, {bool isBold = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _popularServices(List<Tests> tests, Profile? profile) {
    if (tests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText("Our Popular Services", fontWeight: FontWeight.w700),
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
      chips.add("Wheelchair Assistance");
    if (facility?.doctorConsultationTieUp == true)
      chips.add("Doctor Consultation Tie-up");
    if (facility?.insuranceCashlessSupport == true)
      chips.add("Insurance / Cashless Support");
    if (facility?.homeSampleCollection == true)
      chips.add("Home Sample Collection");
    if (facility?.digitalReport == true) chips.add("Digital Report");
    final other = (facility?.other ?? [])
        .map((e) => e.label ?? '')
        .where((e) => e.toString().isNotEmpty)
        .toList();
    return SizedBox(
      width: Get.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText("Our All Services", fontWeight: FontWeight.w700),
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

  Widget _contact(ContactInfo? contact, bool isWide) {
    final loc = contact?.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 5. Contact Section
        SizedBox(height: SizeConfig.size16),
        _buildContactCard(contact),
        SizedBox(height: SizeConfig.size16),

        BusinessLocationWidget(
            locationText: "",
            latitude: double.parse(loc?.coordinates?[1].toString() ?? "0.0"),
            longitude: double.parse(loc?.coordinates?[0].toString() ?? "0.0"),
            businessName: loc?.name ?? "",
            padding: 0,
            isTitleShow: true),

        SizedBox(height: kBottomNavigationBarHeight + 30),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
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
            padding: const EdgeInsets.only(top: 8.0, left: 6),
            child: const CustomText("Contact Us", fontWeight: FontWeight.bold),
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
                if (controller.details.value?.profile?.logoUrl?.isNotEmpty ??
                    false)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                      image: DecorationImage(
                          image: NetworkImage(
                              controller.details.value?.profile?.logoUrl ?? ''),
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
                    AppIconAssets.principal, "Reception", Colors.grey[700]!),
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
