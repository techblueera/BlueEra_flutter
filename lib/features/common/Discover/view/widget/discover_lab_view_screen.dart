import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_profiles_list_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/category_selector_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/lab_header_view.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/lab_home_gallery_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_header_title_widget.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/empty_health_camp_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiscoverLabViewScreen extends StatefulWidget {
  final LabProfileListItem detailsData;

  const DiscoverLabViewScreen({super.key, required this.detailsData});

  @override
  State<DiscoverLabViewScreen> createState() => _DiscoverLabViewScreenState();
}

class _DiscoverLabViewScreenState extends State<DiscoverLabViewScreen> {
  @override
  Widget build(BuildContext context) {
    final d = widget.detailsData;
    final profile = d.fullDetails?.profile;
    final tests = d.fullDetails?.tests ?? <Tests>[];
    final galleries = d.fullDetails?.galleries ?? <Galleries>[];
    final contact = d.fullDetails?.contactInfo;
    final facility = d.fullDetails?.facility;
    return Scaffold(
      appBar: CommonBackAppBar(
        title: d.name,
      ),
      bottomNavigationBar: d.fullDetails?.profile?.userId != userId
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 12.0, right: 12, bottom: 15, top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: PositiveCustomBtn(
                          onTap: () async {
                            final chatViewController =
                                Get.find<ChatViewController>();
                            chatViewController.checkChatConnectionAndOpenChat(
                              userId: d.fullDetails?.profile?.userId ?? '',
                            );
                          },
                          title: AppStrings.chat),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: PositiveCustomBtn(
                          onTap: () {
                            commonSnackBar(message: 'Coming Soon....');
                          },
                          title: AppStrings.bookInquiry),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labViewHeader(d),

              SizedBox(height: SizeConfig.size16),
              CategorySelector(labID: d.id,),

              SizedBox(height: SizeConfig.size16),
              EmptyHealthCampWidget(
                isOwnProfile: false,
                labId: d.id,
              ),

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
              _contact(contact, isWide, d.fullDetails?.profile),
            ],
          ),
        );
      }),
    );
  }

  Widget labViewHeader(LabProfileListItem data) {
    Profile? profile = data.fullDetails?.profile;

    final size = MediaQuery.of(context).size;

    return CommonCardWidget(
      padding: 0,
      cardMargin: 0,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // --- HEADER SECTION (Banner & Logo) ---
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image
                if (profile?.coverUrl?.isNotEmpty ?? false)
                  Container(
                    width: double.infinity,
                    height: size.height * 0.17,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      image: DecorationImage(
                          image: NetworkImage(profile?.coverUrl ?? ""),
                          fit: BoxFit.cover),
                    ),
                  ),

                // Logo Image
                Positioned(
                  bottom: 0,
                  left: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                      image: DecorationImage(
                          image: NetworkImage((profile?.coverUrl ?? "")),
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- FORM SECTION ---
          ServiceHomeHeaderTitleWidget(
            title: profile?.name ?? "",
            description: "",
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 12),
            child: allServices(data.fullDetails?.facility, context),
          ),

        ],
      ),
    );
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
      child: CustomText(
        text,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _popularServices(List<Tests> tests, Profile? profile) {
    if (tests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ServiceHomeTitleWidget(
          title: AppStrings.ourPopularServices,
        ),
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
          ServiceHomeTitleWidget(
            title: AppStrings.ourAllServices,
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

  Widget _contact(ContactInfo? contact, bool isWide, Profile? data) {
    final loc = contact?.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 5. Contact Section
        SizedBox(height: SizeConfig.size16),
        _buildContactCard(contact, data ?? Profile()),
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

  Widget _buildContactCard(ContactInfo? profile, Profile data) {
    return CommonCardWidget(
      padding: 5,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 6),
            child: ServiceHomeTitleWidget(
              title: AppStrings.contactUs,
            ),
          ),
          const SizedBox(height: 10),
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
                if (data.coverUrl?.isNotEmpty ?? false)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                      image: DecorationImage(
                          image: NetworkImage(data.coverUrl ?? ''),
                          fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 10),
                CustomText(data.name,
                    fontSize: 16, fontWeight: FontWeight.bold),

                const SizedBox(height: 5),

                ExpandableText(text:   data.description ?? "",),
                const Divider(height: 15),

                // Contact List
                _contactItem(AppIconAssets.website_click,
                    profile?.websiteUrl ?? "", AppColors.primaryColor),
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
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: CustomText(label, color: AppColors.mainTextColor)),
        ],
      ),
    );
  }
}
