import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/ipd/hospital_ipd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/opd/hospital_opd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const double _kSectionHeight = 280;

class HospitalBookingScreen extends StatelessWidget {
  final bool isReadOnly;

  HospitalBookingScreen({super.key, this.isReadOnly = true});

  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSection(
          title: AppStrings.opdDoctors,
          openEditScreen: () => Get.to(() => const HospitalOpdScreen()),
          readDepartments: () => controller.filteredOpdDepartments,
          selectedRx: controller.selectedDeptIndex,
          readItems: () => controller.currentCategoryItems,
          chipBorderUnselected: Colors.grey.shade400,
          emptyItemsLabel: AppStrings.hospitalViewAddOpdDoctors.tr,
          emptyItemsIcon: Icons.medical_services_outlined,
          tagFor: (item) => "${item.timing ?? 0}",
        ),
        _buildSection(
          title: AppStrings.ipdTitle,
          openEditScreen: () => Get.to(() => const HospitalIpdScreen()),
          readDepartments: () => controller.filteredIpdDepartments,
          selectedRx: controller.selectedIpdDeptIndex,
          readItems: () => controller.currentCategoryItemsIpd,
          chipBorderUnselected: Colors.grey.shade700,
          emptyItemsLabel: AppStrings.hospitalViewAddIpdWards.tr,
          emptyItemsIcon: Icons.bed_outlined,
          tagFor: (item) => "${item.bedCount ?? 0} ${AppStrings.beds.tr}",
        ),
      ],
    );
  }

  /// Renders one department section (OPD or IPD). Both sections share the
  /// same shell: title + chip strip + horizontal card list (or one of two
  /// empty-state CTAs). Only the labels, target screens, reactive
  /// accessors, and per-card tag formatting differ — passed in as knobs.
  Widget _buildSection({
    required String title,
    required VoidCallback openEditScreen,
    required List Function() readDepartments,
    required RxInt selectedRx,
    required List Function() readItems,
    required Color chipBorderUnselected,
    required String emptyItemsLabel,
    required IconData emptyItemsIcon,
    required String Function(dynamic) tagFor,
  }) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ServiceHomeTitleWidget(title: title),
              if (!isReadOnly)
                IconButton(
                  onPressed: openEditScreen,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            final departments = readDepartments();
            final hasDepartments = departments.isNotEmpty;
            return Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(departments.length, (index) {
                        final dept = departments[index];
                        final isSelected = selectedRx.value == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: CustomText(
                              dept.name ?? "",
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.secondaryTextColor,
                              fontSize: SizeConfig.small,
                            ),
                            showCheckmark: false,
                            selectedColor: AppColors.primaryColor,
                            backgroundColor: Colors.transparent,
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) selectedRx.value = index;
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : chipBorderUnselected,
                              width: 1,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                if (!isReadOnly && hasDepartments)
                  _AddPillButton(
                    label: AppStrings.addDepartment.tr,
                    onTap: openEditScreen,
                  ),
              ],
            );
          }),
          const SizedBox(height: 10),
          Obx(() {
            final hasDepartments = readDepartments().isNotEmpty;
            final items = readItems();

            if (!hasDepartments) {
              return _emptyOrPlaceholder(
                ctaLabel: AppStrings.addDepartment.tr,
                ctaIcon: Icons.add_business_outlined,
                onTap: openEditScreen,
              );
            }
            if (items.isEmpty) {
              return _emptyOrPlaceholder(
                ctaLabel: emptyItemsLabel,
                ctaIcon: emptyItemsIcon,
                onTap: openEditScreen,
              );
            }
            return SizedBox(
              height: _kSectionHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return DoctorOrBedCard(
                    title: item.name ?? "",
                    imageUrl: item.imageUrl,
                    description: item.description ?? "",
                    tag: tagFor(item),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Read-only fallback when the section has nothing to show; otherwise an
  /// empty-state CTA that routes to the corresponding edit screen.
  ///
  /// The read-only variant used to reserve [_kSectionHeight] (280dp) so
  /// the layout was identical whether the section had data or not — but
  /// that meant an OPD/IPD section with no data pushed the next section
  /// ~280dp down for a single "No Data Found" line. In discover mode
  /// (read-only) shrink to just what the text needs so consecutive
  /// empty sections stack tightly.
  Widget _emptyOrPlaceholder({
    required String ctaLabel,
    required IconData ctaIcon,
    required VoidCallback onTap,
  }) {
    if (isReadOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CustomText(AppStrings.noDataFound)),
      );
    }
    return EmptySectionPlaceholder(
      imageAsset: AppImageAssets.hospitalIpd_ward,
      ctaLabel: ctaLabel,
      ctaIcon: ctaIcon,
      onTap: onTap,
    );
  }
}

/// Compact pill-shaped CTA placed at the trailing end of the OPD/IPD
/// chip rows so the user can add a new department without leaving the
/// section, even when other departments already exist.
class _AddPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14, color: AppColors.primaryColor),
              const SizedBox(width: 4),
              CustomText(
                label,
                color: AppColors.primaryColor,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorOrBedCard extends StatelessWidget {
  final String title;
  final String description;
  final String tag;
  final String? imageUrl;

  const DoctorOrBedCard({
    super.key,
    required this.title,
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
        color: Colors.grey[200],
        image: (imageUrl != null && imageUrl!.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : DecorationImage(
                image: AssetImage(AppIconAssets.place_holder_image),
                fit: BoxFit.cover,
              ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                color: Colors.black.withValues(alpha: 0.5),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomText(tag, color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    description,
                    color: Colors.white,
                    fontSize: SizeConfig.small,
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
