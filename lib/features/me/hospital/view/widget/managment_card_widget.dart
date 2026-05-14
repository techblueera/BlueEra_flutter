import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/management/hospital_management_screen.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagementCardListWidget extends StatelessWidget {
  final bool isReadOnly;

  const ManagementCardListWidget({super.key, this.isReadOnly = true});

  void _openManagement() => Get.to(const HospitalManagementScreen());

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HospitalServiceAiController>();

    return Obx(() {
      final managementList =
          controller.hospitalDataResModel?.value.data?.management ?? [];
      final isEmpty = managementList.isEmpty;

      if (isEmpty && isReadOnly) return const SizedBox.shrink();

      return CommonCardWidget(
        padding: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 15, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ServiceHomeTitleWidget(title: AppStrings.managementTrust),
                  if (!isReadOnly)
                    IconButton(
                      onPressed: _openManagement,
                      icon: Icon(
                        isEmpty
                            ? Icons.add_circle_outline
                            : Icons.edit_outlined,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: EmptySectionPlaceholder(
                  imageAsset: 'assets/images/other_management.png',
                  ctaLabel: AppStrings.hospitalViewAddManagement.tr,
                  ctaIcon: Icons.person_add_alt_1_outlined,
                  onTap: _openManagement,
                ),
              )
            else
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, bottom: 10),
                  itemCount: managementList.length,
                  itemBuilder: (context, index) =>
                      HospitalManagementCard(person: managementList[index]),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class HospitalManagementCard extends StatelessWidget {
  final HospitalManagement person;

  const HospitalManagementCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                person.imageUrl ?? "",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.person, size: 50)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      person.name ?? AppStrings.unknown.tr,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText(
                        person.position ?? AppStrings.staff.tr,
                        color: Colors.white70,
                        fontSize: 12,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
