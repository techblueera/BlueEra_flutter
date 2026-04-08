import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/management/hospital_management_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagementCardListWidget extends StatelessWidget {
  final bool isReadOnly;
  ManagementCardListWidget({super.key, this.isReadOnly = true});

  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final managementList =
          controller.hospitalDataResModel?.value.data?.management ?? [];
      final isEmpty = managementList.isEmpty;

      if (isEmpty && isReadOnly) return SizedBox.shrink();

      return CommonCardWidget(
        padding: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 15, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ServiceHomeTitleWidget(
                    title: AppStrings.managementTrust,
                  ),
                  if (!isReadOnly)
                    IconButton(
                      onPressed: () => Get.to(const HospitalManagementScreen()),
                      icon: Icon(
                        isEmpty ? Icons.add_circle_outline : Icons.edit_outlined,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),

            // Horizontal List
            SizedBox(
              height: 280,
              child: isEmpty
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16, bottom: 10),
                      children: List.generate(
                        3,
                        (_) => GestureDetector(
                          onTap: () => Get.to(const HospitalManagementScreen()),
                          child: Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[200],
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_outlined, color: Colors.grey[400], size: 40),
                                const SizedBox(height: 10),
                                Text(
                                  AppStrings.hospitalViewAddManagement.tr,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16, bottom: 10),
                      itemCount: managementList.length,
                      itemBuilder: (context, index) {
                        return HospitalManagementCard(person: managementList[index]);
                      },
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

  const HospitalManagementCard({Key? key, required this.person})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260, // Slightly wider based on your reference image
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                person.imageUrl ?? "",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.person, size: 50)),
              ),
            ),
            // Bottom Gradient Overlay
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                // height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
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
                    // Position Tag (Pill shape)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
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
