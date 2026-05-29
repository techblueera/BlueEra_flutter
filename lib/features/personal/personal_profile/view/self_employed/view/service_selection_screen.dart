import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/widget/add_service_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final SelfWorkServiceController controller;
  final String professionCategory;
  final String selectedCategoryKey;
  final List<String> preSelectedOptions;

  const ServiceSelectionScreen({
    super.key,
    required this.controller,
    required this.professionCategory,
    required this.selectedCategoryKey,
    required this.preSelectedOptions,
  });

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  late List<String> _tempSelectedOptions;
  late SelfWorkServiceController _controller;
  late String _selectedCategoryKey;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _selectedCategoryKey = widget.selectedCategoryKey;
    _tempSelectedOptions = List.from(widget.preSelectedOptions);

    // Skip the predefined-options fetch when the list is already
    // hydrated — keeps reopening the same category instant.
    final currentList = _controller.allCategoryMap[_selectedCategoryKey];
    if (currentList == null || currentList.isEmpty) {
      _controller.fetchServiceSelectionOptions(
        professionCategory: widget.professionCategory,
        selectedServiceKey: _selectedCategoryKey,
      );
    }
  }

  void _toggleSelection(String option) {
    setState(() {
      if (_tempSelectedOptions.contains(option)) {
        _tempSelectedOptions.remove(option);
      } else {
        _tempSelectedOptions.add(option);
      }
    });
  }

  /// Predefined list + any user-added custom entries already picked.
  /// Returned in a stable order so the 01/02/… indices never shuffle
  /// between rebuilds.
  List<String> _combinedOptions() {
    final base =
        _controller.allCategoryMap[_selectedCategoryKey] ?? <String>[].obs;
    final result = List<String>.from(base);
    for (final item in _tempSelectedOptions) {
      if (!result.contains(item)) result.add(item);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            if (_controller.isServiceSelectionLoading.value) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size32),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryColor),
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
          _buildAddMoreButton(),
          SizedBox(height: SizeConfig.paddingL),
          _buildUpdateButton(),
        ],
      ),
    );
  }

  // ─── PICKER ──────────────────────────────────────────────────
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
              isSelected: _tempSelectedOptions.contains(options[i]),
              showDivider: i != options.length - 1,
              onTap: () => _toggleSelection(options[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderStrip({required int total}) {
    final selected = _tempSelectedOptions.length;
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
              AppStrings.selectedCountSuffix.tr.toUpperCase(),
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
            padding:
                EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: 2),
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
              // 01 / 02 / … — tracks the parent section-card rhythm.
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
                        : AppColors.secondaryTextColor
                            .withValues(alpha: 0.7),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CustomText(
                  label,
                  fontSize: SizeConfig.medium,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
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
                        : AppColors.secondaryTextColor
                            .withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('checked'),
                          size: 14,
                          color: Colors.white,
                        )
                      : const SizedBox.shrink(key: ValueKey('unchecked')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ADD-MORE AFFORDANCE ─────────────────────────────────────
  /// Distinct from the numbered rows so it never reads as "option #N+1".
  /// Tapping opens [AddServiceBottomSheet]; new entries land both in
  /// `_tempSelectedOptions` (pre-checked) and the controller's
  /// predefined list so they persist across sheet opens.
  Widget _buildAddMoreButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddServiceBottomSheet(
            onUpload: (newServices) {
              final mainList =
                  _controller.allCategoryMap[_selectedCategoryKey];
              if (mainList != null) mainList.addAll(newServices);
              setState(() => _tempSelectedOptions.addAll(newServices));
            },
          ),
        ),
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
              Icon(Icons.add_rounded,
                  size: 16, color: AppColors.primaryColor),
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

  // ─── UPDATE CTA ──────────────────────────────────────────────
  Widget _buildUpdateButton() {
    return Obx(() {
      final selected = _tempSelectedOptions.length;
      final isLoading = _controller.isUpdateServiceLoading.value;
      return CustomBtn(
        radius: SizeConfig.size10,
        bgColor: AppColors.primaryColor,
        title: isLoading
            ? null
            : (selected > 0
                ? '${AppStrings.update.tr} · $selected ${AppStrings.selectedCountSuffix.tr}'
                : AppStrings.update.tr),
        isLoading: isLoading,
        onTap: _onUpdate,
      );
    });
  }

  /// Commits the local selection into the controller, validates that
  /// at least one option was picked, and pushes the right API payload
  /// shape based on which category this sheet is editing.
  void _onUpdate() {
    _controller.updateSelection(_selectedCategoryKey, _tempSelectedOptions);

    final categoryConfig = {
      SelfWorkServiceController.keyServicesOffered: (
        msg: AppStrings.pleaseSelectAtLeastOneServiceOffered.tr,
        apiKey: ApiKeys.servicesOffered,
      ),
      SelfWorkServiceController.keyTypeOfWork: (
        msg: AppStrings.pleaseAddTypesOfInstallations.tr,
        apiKey: ApiKeys.typesOfWork,
      ),
      SelfWorkServiceController.keyExpertise: (
        msg: AppStrings.pleaseAddYourExpertise.tr,
        apiKey: ApiKeys.expertise,
      ),
      SelfWorkServiceController.keyWorkCategories: (
        msg: AppStrings.pleaseSelectWorkCategories.tr,
        apiKey: ApiKeys.workCategories,
      ),
      SelfWorkServiceController.keyWhyChooseMe: (
        msg: AppStrings.pleaseAddWhyChooseMePoints.tr,
        apiKey: ApiKeys.whyChooseMe,
      ),
    };

    final config = categoryConfig[_selectedCategoryKey];
    if (config == null) return;

    final selectedDataList =
        _controller.selectedCategoryMap[_selectedCategoryKey] ??
            <String>[].obs;
    if (selectedDataList.isEmpty) {
      commonSnackBar(message: config.msg);
      return;
    }

    _controller.updateEarnServiceData(
      params: {config.apiKey: selectedDataList},
    );
  }
}
