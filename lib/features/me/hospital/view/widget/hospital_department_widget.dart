import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/ipd/hospital_ipd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/opd/hospital_opd_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalBookingScreen extends StatelessWidget {
  final bool isReadOnly;
  final controller = Get.find<HospitalServiceAiController>();

  HospitalBookingScreen({this.isReadOnly = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- DEPARTMENT CATEGORY CHIPS ---
        CommonCardWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ServiceHomeTitleWidget(
                    title: AppStrings.opdDoctors,
                  ),
                  if (!isReadOnly)
                    IconButton(
                      onPressed: () => Get.to(const HospitalOpdScreen()),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                ],
              ),
              SizedBox(height: 10),

              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                          controller.filteredOpdDepartments.length, (index) {
                        final dept = controller.filteredOpdDepartments[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: CustomText(
                              dept.name ?? "",
                              // White text when selected, dark text when unselected for contrast
                              color: controller.selectedDeptIndex.value == index
                                  ? AppColors.white
                                  : AppColors.secondaryTextColor,
                              fontSize: SizeConfig.small,
                            ),
                            showCheckmark: false,

                            selectedColor: AppColors.primaryColor,
                            backgroundColor: Colors.transparent,
                            // Background stays clear when not selected
                            selected:
                                controller.selectedDeptIndex.value == index,
                            onSelected: (val) {
                              if (val)
                                controller.selectedDeptIndex.value = index;
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
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                          ),
                        );
                      }),
                    ),
                  )),
              SizedBox(height: 10),

              // --- HORIZONTAL LIST VIEW ---
              Obx(() {
                final items = controller.currentCategoryItems;
                if (items.isEmpty)
                  return SizedBox(
                    height: 280,
                    child: isReadOnly
                        ? Center(child: CustomText(AppStrings.noDataFound))
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: List.generate(
                              3,
                              (_) => _buildDummyDoctorCard(
                                label: AppStrings.hospitalViewAddOpdDoctors.tr,
                                onTap: () => Get.to(const HospitalOpdScreen()),
                              ),
                            ),
                          ),
                  );

                return Container(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return DoctorOrBedCard(
                        title: item.name ?? "",
                        subtitle: item.timing,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ServiceHomeTitleWidget(
                    title: AppStrings.ipdTitle,
                  ),
                  if (!isReadOnly)
                    IconButton(
                      onPressed: () => Get.to(const HospitalIpdScreen()),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                ],
              ),

              SizedBox(height: 10),
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                          controller.filteredIpdDepartments.length, (index) {
                        final dept = controller.filteredIpdDepartments[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: CustomText(
                              dept.name ?? "",
                              // Change text color based on selection state
                              color: controller.selectedIpdDeptIndex.value == index
                                  ? AppColors.white
                                  : AppColors.secondaryTextColor,
                              fontSize: SizeConfig.small,
                            ),
                            showCheckmark: false,
                            selectedColor: AppColors.primaryColor,
                            // Use transparent background for unselected to show the border clearly
                            backgroundColor: Colors.transparent,
                            selected:
                                controller.selectedIpdDeptIndex.value == index,
                            onSelected: (val) {
                              if (val)
                                controller.selectedIpdDeptIndex.value = index;
                            },
                            // Customizing the border and shape
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color:
                                  controller.selectedIpdDeptIndex.value == index
                                      ? AppColors.primaryColor
                                      : Colors.grey.shade700,
                              // Border color for unselected chips
                              width: 1,
                            ),
                            // Removes default material padding/shadows to match your clean UI
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }),
                    ),
                  )),
              SizedBox(height: 10),

              // --- HORIZONTAL LIST VIEW ---
              Obx(() {
                final items = controller.currentCategoryItemsIpd;
                if (items.isEmpty)
                  return SizedBox(
                    height: 280,
                    child: isReadOnly
                        ? Center(child: CustomText(AppStrings.noDataFound))
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: List.generate(
                              3,
                              (_) => _buildDummyDoctorCard(
                                label: AppStrings.hospitalViewAddIpdWards.tr,
                                onTap: () => Get.to(const HospitalIpdScreen()),
                              ),
                            ),
                          ),
                  );

                return Container(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return DoctorOrBedCard(
                        title: item.name ?? "",
                        subtitle: "",
                        imageUrl: item.imageUrl,
                        description: item.description ?? "",
                        tag: "${item.bedCount ?? 0} ${AppStrings.beds.tr}",
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

Widget _buildDummyDoctorCard({required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: Colors.grey[400], size: 40),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    ),
  );
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
              // height: 140,
              // Height of the text area
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                color: Colors.black.withOpacity(0.5),

              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    title,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
                    child: CustomText(tag, color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    description,
                    color: Colors.white,
                    fontSize:SizeConfig.small,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
