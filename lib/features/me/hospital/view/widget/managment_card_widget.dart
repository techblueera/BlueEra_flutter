import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagementCardListWidget extends StatelessWidget {
  ManagementCardListWidget({super.key});

  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.hospitalDataResModel?.value.data?.management?.isNotEmpty ??
          false) {
        // Accessing management list from your response model
        final managementList =
            controller.hospitalDataResModel?.value.data?.management ?? [];
        return CommonCardWidget(
          padding: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 15, bottom: 10),
                child: ServiceHomeTitleWidget(
                  title: AppStrings.managementTrust,
                ),
              ),

              // Horizontal List
              SizedBox(
                height: 280, // Height to accommodate the card
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, bottom: 10),
                  itemCount: managementList.length,
                  itemBuilder: (context, index) {
                    return HospitalManagementCard(
                        person: managementList[index]);
                  },
                ),
              ),
            ],
          ),
        );
      }
      return SizedBox.shrink();
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
                      person.name ?? "Unknown",
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
                        person.position ?? "Staff",
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
