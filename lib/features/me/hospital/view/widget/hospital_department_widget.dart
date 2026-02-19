import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalBookingScreen extends StatelessWidget {
  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [


        // --- DEPARTMENT CATEGORY CHIPS ---
        CommonCardWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText("Doctors ",fontWeight: FontWeight.w600,fontSize: 20,),
              SizedBox(height: 10),

              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(controller.filteredOpdDepartments.length,
                          (index) {
                        final dept = controller.filteredOpdDepartments[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child:ChoiceChip(
                            label: CustomText(
                              dept.name ?? "",
                              // White text when selected, dark text when unselected for contrast
                              color: controller.selectedDeptIndex.value == index
                                  ? AppColors.white
                                  : Colors.black87,
                            ),
                            showCheckmark: false,
                            selectedColor: AppColors.primaryColor,
                            backgroundColor: Colors.transparent, // Background stays clear when not selected
                            selected: controller.selectedDeptIndex.value == index,
                            onSelected: (val) {
                              if (val) controller.selectedDeptIndex.value = index;
                            },
                            // Pill shape matching the design
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // Side border logic: Primary color when active, grey outline when inactive
                            side: BorderSide(
                              color: controller.selectedDeptIndex.value == index
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                            // Ensuring the chip doesn't take up extra vertical space
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        );
                      }),
                    ),
                  )),
              SizedBox(height: 10),

              // --- HORIZONTAL LIST VIEW ---
              Obx(() {
                final items = controller.currentCategoryItems;
                if (items.isEmpty) return Center(child: Text("No data available"));

                return Container(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // If OPD, item is Doctor. If IPD, item is Ward/Bed.

                      return DoctorOrBedCard(
                        title: item.name ?? "",
                        subtitle: item.timing,
                        // imageUrl: "",
                        imageUrl: item.imageUrl,
                        description: item.description ?? "",
                        tag: "${item.timing ?? 0}",

                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),


        // --- DEPARTMENT CATEGORY CHIPS ---
        CommonCardWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText("IPD ",fontWeight: FontWeight.w600,fontSize: 20,),
              SizedBox(height: 10),
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(controller.filteredIpdDepartments.length,
                          (index) {
                        final dept = controller.filteredIpdDepartments[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: CustomText(
                              dept.name ?? "",
                              // Change text color based on selection state
                              color: controller.selectedIpdDeptIndex.value == index
                                  ? AppColors.white
                                  : Colors.black54,
                            ),
                            showCheckmark: false,
                            selectedColor: AppColors.primaryColor,
                            // Use transparent background for unselected to show the border clearly
                            backgroundColor: Colors.transparent,
                            selected: controller.selectedIpdDeptIndex.value == index,
                            onSelected: (val) {
                              if (val) controller.selectedIpdDeptIndex.value = index;
                            },
                            // Customizing the border and shape
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: controller.selectedIpdDeptIndex.value == index
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade700, // Border color for unselected chips
                              width: 1,
                            ),
                            // Removes default material padding/shadows to match your clean UI
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }),
                    ),
                  )),
              SizedBox(height: 10),

              // --- HORIZONTAL LIST VIEW ---
              Obx(() {
                final items = controller.currentCategoryItemsIpd;
                if (items.isEmpty) return Center(child: Text("No data available"));

                return Container(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return DoctorOrBedCard(
                        title: item.name ?? "",
                        subtitle:"",
                        imageUrl: item.imageUrl,
                        description: item.description ?? "",
                        tag: "${item.bedCount ?? 0} Beds",
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class DoctorOrBedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String tag;
  final String? imageUrl;

  const DoctorOrBedCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.description,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200], // Fallback color
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(
                  imageUrl!,
                ),
                fit: BoxFit.cover,
              )
            : DecorationImage(
                image: AssetImage(AppIconAssets.place_holder_image),
                fit: BoxFit.cover,
              ),
      ),
      child: Stack(
        children: [
          // Dark Gradient for text readability
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 140,
              // Height of the text area
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // The Tag (e.g., Child Specialist or 25 Beds)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Heart Icon
          // Positioned(
          //   top: 10,
          //   right: 10,
          //   child: CircleAvatar(
          //     radius: 14,
          //     backgroundColor: Colors.white,
          //     child: Icon(Icons.favorite, color: Colors.red[400], size: 16),
          //   ),
          // ),
        ],
      ),
    );
  }
}
