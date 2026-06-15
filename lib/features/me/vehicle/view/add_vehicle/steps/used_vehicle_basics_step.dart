import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/widgets/vehicle_form_widgets.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Step 1 of the USED flow — type drill-down, brand / model / variant,
/// manufacturing & registration year, registration number, ownership
/// and physical condition grade. Mirrors the `old1` reference screen.
class UsedVehicleBasicsStep extends VehicleFormStep {
  final VehicleController controller;
  const UsedVehicleBasicsStep({
    super.key,
    required super.draft,
    required this.controller,
  });

  @override
  VehicleFormStepState<UsedVehicleBasicsStep> createState() =>
      _UsedVehicleBasicsStepState();
}

class _UsedVehicleBasicsStepState
    extends VehicleFormStepState<UsedVehicleBasicsStep> {
  VehicleController get _c => widget.controller;

  late final TextEditingController _brandCtrl =
      TextEditingController(text: draft.brand ?? '');
  late final TextEditingController _modelCtrl =
      TextEditingController(text: draft.model ?? '');
  late final TextEditingController _variantCtrl =
      TextEditingController(text: draft.variant ?? '');
  late final TextEditingController _regNoCtrl =
      TextEditingController(text: draft.registrationNo ?? '');

  late final List<int> _years;

  String? _catErr,
      _subErr,
      _typeErr,
      _brandErr,
      _modelErr,
      _mfgErr,
      _regYearErr,
      _regNoErr,
      _ownershipErr,
      _gradeErr;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _years = List<int>.generate(40, (i) => currentYear - i);
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _variantCtrl.dispose();
    _regNoCtrl.dispose();
    super.dispose();
  }

  @override
  bool validateAndSave() {
    draft.brand = _brandCtrl.text.trim();
    draft.model = _modelCtrl.text.trim();
    draft.variant = _variantCtrl.text.trim();
    draft.registrationNo = _regNoCtrl.text.trim();

    setState(() {
      _catErr = draft.category == null ? AppStrings.selectMainCategoryErr.tr : null;
      _subErr = draft.subCategory == null
          ? AppStrings.selectVehicleCategoryErr.tr
          : null;
      _typeErr = draft.type == null ? AppStrings.selectVehicleTypeErr.tr : null;
      _brandErr = draft.brand!.isEmpty ? AppStrings.nameRequiredErr.tr : null;
      _modelErr = draft.model!.isEmpty ? AppStrings.nameRequiredErr.tr : null;
      _mfgErr = draft.manufacturingYear == null
          ? AppStrings.manufacturingYearRequiredErr.tr
          : null;
      _regYearErr = draft.registrationYear == null
          ? AppStrings.registrationYearRequiredErr.tr
          : null;
      _regNoErr = draft.registrationNo!.isEmpty
          ? AppStrings.registrationNumberRequiredErr.tr
          : null;
      _ownershipErr =
          draft.ownership == null ? AppStrings.selectOwnershipErr.tr : null;
      _gradeErr = draft.conditionGrade == null
          ? AppStrings.selectConditionGradeErr.tr
          : null;
    });

    return [
      _catErr,
      _subErr,
      _typeErr,
      _brandErr,
      _modelErr,
      _mfgErr,
      _regYearErr,
      _regNoErr,
      _ownershipErr,
      _gradeErr,
    ].every((e) => e == null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VehicleSectionCard(
          title: AppStrings.mainCategoryLabel.tr,
          children: [
            Obx(() => VehicleTaxonomySection(
                  // .toList() actually reads the RxList so Obx subscribes.
                  types: _c.vehicleTypes.toList(),
                  draft: draft,
                  categoryError: _catErr,
                  subCategoryError: _subErr,
                  typeError: _typeErr,
                  onChanged: () => setState(() {
                    _catErr = _subErr = _typeErr = null;
                  }),
                )),
          ],
        ),
        VehicleSectionCard(
          children: [
            CommonTextField(
              textEditController: _brandCtrl,
              title: AppStrings.brand.tr,
              hintText: AppStrings.brand.tr,
              isValidate: false,
              isOptionalFiled: true,
              onChange: (_) {
                if (_brandErr != null) setState(() => _brandErr = null);
              },
            ),
            VehicleErrorText(_brandErr),
            SizedBox(height: SizeConfig.size12),
            CommonTextField(
              textEditController: _modelCtrl,
              title: AppStrings.modelLabel.tr,
              hintText: AppStrings.modelLabel.tr,
              isValidate: false,
              isOptionalFiled: true,
              onChange: (_) {
                if (_modelErr != null) setState(() => _modelErr = null);
              },
            ),
            VehicleErrorText(_modelErr),
            SizedBox(height: SizeConfig.size12),
            CommonTextField(
              textEditController: _variantCtrl,
              title: AppStrings.variantLabel.tr,
              hintText: AppStrings.variantHintExample.tr,
              isValidate: false,
              isOptionalFiled: true,
            ),
            SizedBox(height: SizeConfig.size12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: CommonDropdownDialog<int>(
                  items: _years,
                  selectedValue: draft.manufacturingYear,
                  dialogTitle: AppStrings.manufacturingYearLabel.tr,
                  title: AppStrings.manufacturingYearLabel.tr,
                  hintText: AppStrings.selectHint.tr,
                  displayValue: (y) => y.toString(),
                  errorText: _mfgErr,
                  onChanged: (y) => setState(() {
                    draft.manufacturingYear = y;
                    _mfgErr = null;
                  }),
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CommonDropdownDialog<int>(
                  items: _years,
                  selectedValue: draft.registrationYear,
                  dialogTitle: AppStrings.registrationYearLabel.tr,
                  title: AppStrings.registrationYearLabel.tr,
                  hintText: AppStrings.selectHint.tr,
                  displayValue: (y) => y.toString(),
                  errorText: _regYearErr,
                  onChanged: (y) => setState(() {
                    draft.registrationYear = y;
                    _regYearErr = null;
                  }),
                ),
              ),
            ]),
            SizedBox(height: SizeConfig.size12),
            VehicleFieldLabel(AppStrings.registrationNumberLabel.tr),
            CommonTextField(
              textEditController: _regNoCtrl,
              hintText: AppStrings.registrationNumberHint.tr,
              isCapitalize: true,
              isValidate: false,
              isOptionalFiled: true,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              onChange: (_) {
                if (_regNoErr != null) setState(() => _regNoErr = null);
              },
            ),
            VehicleErrorText(_regNoErr),
            SizedBox(height: SizeConfig.size12),
            Obx(() {
              final owners = _c.optionSets.value?.ownership ??
                  const <VehicleOption>[];
              final selected =
                  owners.firstWhereOrNull((o) => o.value == draft.ownership);
              return CommonDropdownDialog<VehicleOption>(
                items: owners,
                selectedValue: selected,
                dialogTitle: AppStrings.ownershipLabel.tr,
                title: AppStrings.ownershipLabel.tr,
                hintText: AppStrings.selectHint.tr,
                displayValue: (o) => o.label,
                errorText: _ownershipErr,
                onChanged: (o) => setState(() {
                  draft.ownership = o?.value;
                  _ownershipErr = null;
                }),
              );
            }),
          ],
        ),
        VehicleSectionCard(
          title: AppStrings.conditionGradeLabel.tr,
          children: [
            Obx(() {
              final grades = _c.optionSets.value?.conditionGrade ??
                  const <VehicleOption>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VehicleChoiceChips<VehicleOption>(
                    items: grades,
                    value: grades.firstWhereOrNull(
                        (o) => o.value == draft.conditionGrade),
                    labelOf: (o) => o.label,
                    onSelected: (o) => setState(() {
                      draft.conditionGrade = o.value;
                      _gradeErr = null;
                    }),
                  ),
                  VehicleErrorText(_gradeErr),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}
