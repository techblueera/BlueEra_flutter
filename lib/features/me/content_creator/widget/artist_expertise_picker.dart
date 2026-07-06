import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/content_creator/controller/earn_artist_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// API-fed multi-select for the artist's `expertise[]`, shown inside the
/// Overview "Expertise" edit sheet. The suggestion list comes from
/// `predefined-artist-expertise/{category}?type=` (loaded by the controller);
/// the user can also add custom entries. Commits via `PUT earn-artists/{id}`.
///
/// Deliberately mirrors `ServiceSelectionScreen` (self-profession) so the two
/// pickers read the same: numbered rows, a live "N / Total" pill, an add-custom
/// affordance, and a count-stamped Update CTA.
class ArtistExpertisePicker extends StatefulWidget {
  final EarnArtistController controller;

  const ArtistExpertisePicker({super.key, required this.controller});

  @override
  State<ArtistExpertisePicker> createState() => _ArtistExpertisePickerState();
}

class _ArtistExpertisePickerState extends State<ArtistExpertisePicker> {
  EarnArtistController get _c => widget.controller;

  /// Predefined suggestions plus any custom entries the user already picked,
  /// in a stable order so the 01/02/… indices never shuffle between rebuilds.
  List<String> _combinedOptions() {
    final result = List<String>.from(_c.expertiseSuggestions);
    for (final item in _c.selectedExpertise) {
      if (!result.contains(item)) result.add(item);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            if (_c.isExpertiseLoading.value) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size32),
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryColor),
                ),
              );
            }
            final options = _combinedOptions();
            if (options.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size24),
                child: Center(
                  child: CustomText(
                    AppStrings.noOptionsAvailableYet.tr,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              );
            }
            return _buildPicker(options);
          }),
          SizedBox(height: SizeConfig.size10),
          _buildAddCustomButton(),
          SizedBox(height: SizeConfig.paddingL),
          _buildUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildPicker(List<String> options) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderStrip(total: options.length),
          for (int i = 0; i < options.length; i++)
            _buildRow(
              index: i + 1,
              label: options[i],
              isSelected: _c.selectedExpertise.contains(options[i]),
              showDivider: i != options.length - 1,
              onTap: () => _toggle(options[i]),
            ),
        ],
      ),
    );
  }

  void _toggle(String option) {
    if (_c.selectedExpertise.contains(option)) {
      _c.selectedExpertise.remove(option);
    } else {
      _c.selectedExpertise.add(option);
    }
  }

  Widget _buildHeaderStrip({required int total}) {
    return Obx(() {
      final selected = _c.selectedExpertise.length;
      final any = selected > 0;
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size10,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFBFE),
          border: Border(
            bottom: BorderSide(color: Color(0xFFE6E8EE), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.expertise.tr.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppConstants.OpenSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryTextColor,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8, vertical: 2),
              decoration: BoxDecoration(
                color: any
                    ? AppColors.primaryColor.withValues(alpha: 0.10)
                    : const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: any
                      ? AppColors.primaryColor.withValues(alpha: 0.25)
                      : const Color(0xFFE6E8EE),
                  width: 0.6,
                ),
              ),
              child: Text(
                '$selected / $total',
                style: TextStyle(
                  fontFamily: AppConstants.OpenSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: any
                      ? AppColors.primaryColor
                      : AppColors.secondaryTextColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRow({
    required int index,
    required String label,
    required bool isSelected,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.06)
                : Colors.transparent,
            border: showDivider
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFEDEFF4), width: 0.6),
                  )
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor.withValues(alpha: 0.7),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CustomText(
                  label,
                  fontSize: SizeConfig.medium,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.mainTextColor,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          key: ValueKey('checked'),
                          size: 14,
                          color: Colors.white)
                      : const SizedBox.shrink(key: ValueKey('unchecked')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ADD-CUSTOM AFFORDANCE ──────────────────────────────────────────────
  Widget _buildAddCustomButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showAddCustomDialog,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
              width: 0.6,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 16, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                AppStrings.addCustomOption.tr,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCustomDialog() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: SizeConfig.size16,
          right: SizeConfig.size16,
          top: SizeConfig.size16,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + SizeConfig.size24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(AppStrings.addCustomOption.tr,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor),
            SizedBox(height: SizeConfig.size12),
            CommonTextField(
              textEditController: ctrl,
              hintText: AppStrings.expertise.tr,
            ),
            SizedBox(height: SizeConfig.paddingL),
            CustomBtn(
              radius: SizeConfig.size10,
              bgColor: AppColors.primaryColor,
              title: AppStrings.add.tr,
              onTap: () {
                final v = ctrl.text.trim();
                if (v.isEmpty) return;
                if (!_c.expertiseSuggestions.contains(v)) {
                  _c.expertiseSuggestions.add(v);
                }
                if (!_c.selectedExpertise.contains(v)) {
                  _c.selectedExpertise.add(v);
                }
                Navigator.pop(sheetCtx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── UPDATE CTA ─────────────────────────────────────────────────────────
  Widget _buildUpdateButton() {
    return Obx(() {
      final selected = _c.selectedExpertise.length;
      final isLoading = _c.isUpdating.value;
      return CustomBtn(
        radius: SizeConfig.size10,
        bgColor: AppColors.primaryColor,
        title: isLoading
            ? null
            : (selected > 0
                ? '${AppStrings.update.tr} · $selected ${AppStrings.selectedCountSuffix.tr}'
                : AppStrings.update.tr),
        isLoading: isLoading,
        onTap: () async {
          if (_c.selectedExpertise.isEmpty) {
            commonSnackBar(message: AppStrings.pleaseAddYourExpertise.tr);
            return;
          }
          final ok = await _c.updateArtist({
            'expertise': _c.selectedExpertise.toList(),
          });
          if (ok) Get.back();
        },
      );
    });
  }
}
