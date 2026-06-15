import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_draft.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared visual building blocks for the add-vehicle multi-step flow.
/// All steps consume these so the NEW and USED flows look identical and
/// stay responsive (cards stretch to the available width; chips wrap).

// ─────────────────────────────────────────────────────────────────────
// Step contract
// ─────────────────────────────────────────────────────────────────────

/// Base class for a single page of the flow. Each step owns its own
/// controllers + inline error state and writes into the shared
/// [VehicleDraft]; the host calls [VehicleFormStepState.validateAndSave]
/// before advancing.
abstract class VehicleFormStep extends StatefulWidget {
  final VehicleDraft draft;
  const VehicleFormStep({super.key, required this.draft});
}

abstract class VehicleFormStepState<T extends VehicleFormStep>
    extends State<T> {
  VehicleDraft get draft => widget.draft;

  /// Validate the visible inputs, persist them into [draft] and return
  /// whether the step is complete enough to advance / submit.
  bool validateAndSave();
}

// ─────────────────────────────────────────────────────────────────────
// Layout primitives
// ─────────────────────────────────────────────────────────────────────

/// White rounded card grouping a set of fields, with an optional bold
/// section title (e.g. "Vehicle Pricing"). Always full-width so it is
/// responsive across phone / tablet widths.
class VehicleSectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final List<Widget> children;

  const VehicleSectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A001120),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size12),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      title!,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// Small grey caption shown above a field (matches the reference UI).
class VehicleFieldLabel extends StatelessWidget {
  final String text;
  const VehicleFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size6, top: SizeConfig.size4),
      child: CustomText(
        text,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
      ),
    );
  }
}

/// Inline red validation message under a field.
class VehicleErrorText extends StatelessWidget {
  final String? error;
  const VehicleErrorText(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size4, left: SizeConfig.size4),
      child: CustomText(error!, fontSize: 11.5, color: Colors.red),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Choice chips (single select)
// ─────────────────────────────────────────────────────────────────────

class VehicleChoiceChips<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const VehicleChoiceChips({
    super.key,
    required this.items,
    required this.value,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SizeConfig.size8,
      runSpacing: SizeConfig.size8,
      children: items.map((it) {
        final selected = it == value;
        return _PillChip(
          label: labelOf(it),
          selected: selected,
          onTap: () => onSelected(it),
        );
      }).toList(),
    );
  }
}

/// Multi-select chips (special offers). Collapses to [collapsedCount]
/// chips with a "+N More" toggle, mirroring the reference design.
class VehicleMultiChips extends StatefulWidget {
  final List<VehicleOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final int collapsedCount;

  const VehicleMultiChips({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.collapsedCount = 5,
  });

  @override
  State<VehicleMultiChips> createState() => _VehicleMultiChipsState();
}

class _VehicleMultiChipsState extends State<VehicleMultiChips> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.options;
    final showAll = _expanded || all.length <= widget.collapsedCount;
    final visible = showAll ? all : all.sublist(0, widget.collapsedCount);
    final hiddenCount = all.length - widget.collapsedCount;

    return Wrap(
      spacing: SizeConfig.size8,
      runSpacing: SizeConfig.size8,
      children: [
        ...visible.map((opt) {
          final selected = widget.selectedValues.contains(opt.value);
          return _PillChip(
            label: opt.label,
            selected: selected,
            leadingIcon: selected ? Icons.check : Icons.add,
            onTap: () {
              final next = List<String>.from(widget.selectedValues);
              selected ? next.remove(opt.value) : next.add(opt.value);
              widget.onChanged(next);
            },
          );
        }),
        if (!showAll && hiddenCount > 0)
          _PillChip(
            label: '+$hiddenCount ${AppStrings.addMoreLabel.tr}',
            selected: false,
            onTap: () => setState(() => _expanded = true),
          ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? leadingIcon;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor
              : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : const Color(0xFFDDE3EC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 14,
                color: selected ? Colors.white : AppColors.secondaryTextColor,
              ),
              SizedBox(width: SizeConfig.size4),
            ],
            CustomText(
              label,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Taxonomy drill-down (category → sub-category → type)
// ─────────────────────────────────────────────────────────────────────

/// The 3-tier vehicle-type picker shared by both flows' first step:
/// L1 category + L2 sub-category as chips, L3 type as a dropdown. Writes
/// the chosen wire values into [draft]; [onChanged] is invoked after any
/// selection so the host can `setState` (re-highlighting chips and
/// revealing the dependent tiers). [types] should be read inside an
/// `Obx` by the caller so it fills in when the taxonomy resolves.
class VehicleTaxonomySection extends StatelessWidget {
  final List<VehicleType> types;
  final VehicleDraft draft;
  final String? categoryError;
  final String? subCategoryError;
  final String? typeError;
  final VoidCallback onChanged;

  const VehicleTaxonomySection({
    super.key,
    required this.types,
    required this.draft,
    required this.onChanged,
    this.categoryError,
    this.subCategoryError,
    this.typeError,
  });

  @override
  Widget build(BuildContext context) {
    final category = types.firstWhereOrNull((t) => t.value == draft.category);
    final subs = category?.children ?? const <VehicleType>[];
    final sub = subs.firstWhereOrNull((s) => s.value == draft.subCategory);
    final leaves = sub?.children ?? const <VehicleType>[];
    final leaf = leaves.firstWhereOrNull((l) => l.value == draft.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VehicleChoiceChips<VehicleType>(
          items: types,
          value: category,
          labelOf: (t) => t.label,
          onSelected: (t) {
            draft.category = t.value;
            draft.subCategory = null;
            draft.type = null;
            onChanged();
          },
        ),
        VehicleErrorText(categoryError),
        if (subs.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size14),
          VehicleFieldLabel(AppStrings.vehicleCategoryLabel.tr),
          VehicleChoiceChips<VehicleType>(
            items: subs,
            value: sub,
            labelOf: (t) => t.label,
            onSelected: (t) {
              draft.subCategory = t.value;
              draft.type = null;
              onChanged();
            },
          ),
          VehicleErrorText(subCategoryError),
        ],
        if (leaves.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size14),
          CommonDropdownDialog<VehicleType>(
            items: leaves,
            selectedValue: leaf,
            dialogTitle: AppStrings.vehicleTypeLabel.tr,
            title: AppStrings.vehicleTypeLabel.tr,
            hintText: AppStrings.selectHint.tr,
            displayValue: (t) => t.label,
            errorText: typeError,
            onChanged: (t) {
              draft.type = t?.value;
              onChanged();
            },
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Yes / No selector (radio row)
// ─────────────────────────────────────────────────────────────────────

class VehicleYesNoField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const VehicleYesNoField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VehicleFieldLabel(label),
        Row(
          children: [
            _radio(AppStrings.yes.tr, true),
            SizedBox(width: SizeConfig.size20),
            _radio(AppStrings.no.tr, false),
          ],
        ),
      ],
    );
  }

  Widget _radio(String text, bool optionValue) {
    final selected = value == optionValue;
    return InkWell(
      onTap: () => onChanged(optionValue),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              text,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
