import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/lab_header_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
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
                // _cover(profile),
                LabHeaderView(
                  schoolAboutUsController: controller,
                ),
                SizedBox(height: SizeConfig.size12),
                // _about(profile, isWide),
                // SizedBox(height: SizeConfig.size12),
                _basicTest(tests),
                SizedBox(height: SizeConfig.size16),
                _popularServices(tests, profile),
                SizedBox(height: SizeConfig.size16),
                _allServices(facility),
                SizedBox(height: SizeConfig.size16),
                _gallery(galleries, isWide),
                SizedBox(height: SizeConfig.size16),
                _contact(contact, isWide),
              ],
            ),
          );
        });
      }),
    );
  }

  Widget _cover(Profile? profile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        (profile?.coverUrl ?? '').toString().replaceAll('`', ''),
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 160,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image, size: 40),
        ),
      ),
    );
  }

  Widget _about(Profile? profile, bool isWide) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(profile?.name ?? '',
                    fontSize: SizeConfig.size16, fontWeight: FontWeight.w700),
                SizedBox(height: SizeConfig.size6),
                CustomText(profile?.description ?? '',
                    maxLines: isWide ? 6 : 4, color: AppColors.black28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicTest(List<Tests> tests) {
    if (tests.isEmpty) return const SizedBox.shrink();
    final t = tests.first;
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText("Basic Blood Test", fontWeight: FontWeight.w700),
          SizedBox(height: SizeConfig.size6),
          Row(
            children: [
              Expanded(
                  child: CustomText(t.testName ?? "",
                      fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomText("LFT",
                    color: AppColors.primaryColor, fontSize: SizeConfig.small),
              )
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(t.description ?? "", color: AppColors.black28),
          SizedBox(height: SizeConfig.size8),
          Wrap(
            spacing: 8,
            children: [
              _pill("Price: ${t.customerPrice ?? 0}"),
              _pill("Fees: ${t.testFees ?? 0}"),
              _pill("Report: ${t.estimatedReportHours ?? 0}h"),
              _pill("Gender: ${t.gender ?? ''}"),
            ],
          ),
        ],
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
          height: 170,
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
    return Column(
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
    );
  }

  Widget _gallery(List<Galleries> galleries, bool isWide) {
    if (galleries.isEmpty) return const SizedBox.shrink();
    final images = (galleries.first.imageUrls ?? [])
        .map((u) => u.toString().replaceAll('`', ''))
        .toList();
    if (images.isEmpty) return const SizedBox.shrink();
    final cross = isWide ? 4 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText("Gallery", fontWeight: FontWeight.w700),
        SizedBox(height: SizeConfig.size8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: images.length,
          itemBuilder: (_, i) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade200)),
            );
          },
        ),
      ],
    );
  }

  Widget _contact(ContactInfo? contact, bool isWide) {
    final loc = contact?.location;
    final name = contact?.name ?? '';
    final phone = contact?.phoneNo ?? '';
    final email = contact?.email ?? '';
    final website = (contact?.websiteUrl ?? '').toString().replaceAll('`', '');
    final address = loc?.name ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText("Contact Us", fontWeight: FontWeight.w700),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.all(SizeConfig.size12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(name, fontWeight: FontWeight.w600),
              SizedBox(height: SizeConfig.size6),
              CustomText(address,
                  color: AppColors.black28, maxLines: isWide ? 3 : 2),
              SizedBox(height: SizeConfig.size8),
              CustomText(phone),
              CustomText(email),
              CustomText(website),
              SizedBox(height: SizeConfig.size12),
              Container(
                height: 160,
                decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.map, color: AppColors.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
      ),
      child: CustomText(text,
          fontSize: SizeConfig.small, color: AppColors.primaryColor),
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
}
