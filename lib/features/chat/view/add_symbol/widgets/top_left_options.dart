import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controller/add_chat_symbol_controller.dart';
import '../../contacts/view/be_available_contacts_list.dart';

class TopLeftOptions extends StatefulWidget {
  const TopLeftOptions({super.key});

  @override
  State<TopLeftOptions> createState() => _TopLeftOptionsState();
}

class _TopLeftOptionsState extends State<TopLeftOptions> {
  final c = Get.find<AddChatSymbolController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _durationSelector(),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _visibilitySelector(),
        ],
      );
    });
  }

  Widget _durationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.timer_outlined,
                  size: 16, color: Color(0xFF667EEA)),
            ),
            const SizedBox(width: 10),
            CustomText(
              AppStrings.durationLabel.tr,
              color: const Color(0xFF2D3142),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            const Spacer(),
            CustomText(
              '${c.selectedDays.value} ${c.selectedDays.value == 1 ? AppStrings.dayUnit.tr : AppStrings.daysUnit.tr}',
              color: const Color(0xFF667EEA),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: Row(
            children: List.generate(7, (index) {
              final day = index + 1;
              return Expanded(
                child: Obx(() {
                  final selected = c.selectedDays.value == day;
                  return GestureDetector(
                    onTap: () => c.selectedDays.value = day,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: index < 6 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF667EEA)
                            : const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF667EEA).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: CustomText(
                          "$day",
                          color: selected
                              ? Colors.white
                              : const Color(0xFF2D3142).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _visibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF11998E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.visibility_rounded,
                  size: 16, color: Color(0xFF11998E)),
            ),
            const SizedBox(width: 10),
            CustomText(
              AppStrings.privacyLabel.tr,
              color: const Color(0xFF2D3142),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Segmented privacy control
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F8),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _privacyChip(
                icon: Icons.public_rounded,
                label: AppStrings.publicLabel.tr,
                value: PostVisibility.public,
              ),
              _privacyChip(
                icon: Icons.lock_rounded,
                label: AppStrings.privateLabel.tr,
                value: PostVisibility.private,
              ),
              _privacyChip(
                icon: Icons.people_rounded,
                label: AppStrings.customLabel.tr,
                value: PostVisibility.custom,
              ),
            ],
          ),
        ),

        // Custom contacts section
        if (c.visibility.value == PostVisibility.custom) ...[
          const SizedBox(height: 14),
          Obx(() {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF11998E).withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        '${c.onExceptContactSelectedList.length} ${c.onExceptContactSelectedList.length == 1 ? AppStrings.contactExcluded.tr : AppStrings.contactsExcluded.tr}',
                        color: const Color(0xFF2D3142).withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => BeAvailableContactsList(
                                preSelectedUsers:
                                    c.onExceptContactSelectedList,
                                maxSelectionCount: 5,
                                tagPersonsSelection: true,
                                isFromAddMember: true,
                                onSelectedPersons: (selectedPersonsList) {
                                  c.onExceptContactSelectedList.value =
                                      selectedPersonsList;
                                },
                              ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF11998E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_add_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              CustomText(
                                AppStrings.chooseLabel.tr,
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _privacyChip({
    required IconData icon,
    required String label,
    required PostVisibility value,
  }) {
    return Expanded(
      child: Obx(() {
        final isSelected = c.visibility.value == value;
        return GestureDetector(
          onTap: () => c.visibility.value = value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? const Color(0xFF11998E)
                      : const Color(0xFF2D3142).withValues(alpha: 0.4),
                ),
                const SizedBox(width: 5),
                CustomText(
                  label,
                  color: isSelected
                      ? const Color(0xFF2D3142)
                      : const Color(0xFF2D3142).withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF2D3142).withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
