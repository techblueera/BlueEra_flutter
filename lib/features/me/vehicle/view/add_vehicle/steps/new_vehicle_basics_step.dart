import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/widgets/vehicle_form_widgets.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1 of the NEW flow — vehicle type drill-down (category →
/// sub-category → type), brand / model / variant, availability and
/// delivery time. Mirrors the `new1` reference screen.
class NewVehicleBasicsStep extends VehicleFormStep {
  final VehicleController controller;
  const NewVehicleBasicsStep({
    super.key,
    required super.draft,
    required this.controller,
  });

  @override
  VehicleFormStepState<NewVehicleBasicsStep> createState() =>
      _NewVehicleBasicsStepState();
}

class _NewVehicleBasicsStepState
    extends VehicleFormStepState<NewVehicleBasicsStep> {
  VehicleController get _c => widget.controller;

  late final TextEditingController _brandCtrl =
      TextEditingController(text: draft.brand ?? '');
  late final TextEditingController _modelCtrl =
      TextEditingController(text: draft.model ?? '');
  late final TextEditingController _variantCtrl =
      TextEditingController(text: draft.variant ?? '');

  String? _catErr, _subErr, _typeErr, _brandErr, _modelErr, _availErr, _delErr;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _variantCtrl.dispose();
    super.dispose();
  }

  @override
  bool validateAndSave() {
    draft.brand = _brandCtrl.text.trim();
    draft.model = _modelCtrl.text.trim();
    draft.variant = _variantCtrl.text.trim();

    setState(() {
      _catErr = draft.category == null ? AppStrings.selectMainCategoryErr.tr : null;
      _subErr =
          draft.subCategory == null ? AppStrings.selectVehicleCategoryErr.tr : null;
      _typeErr = draft.type == null ? AppStrings.selectVehicleTypeErr.tr : null;
      _brandErr =
          draft.brand!.isEmpty ? AppStrings.nameRequiredErr.tr : null;
      _modelErr =
          draft.model!.isEmpty ? AppStrings.nameRequiredErr.tr : null;
      _availErr =
          draft.availability == null ? AppStrings.selectAvailabilityErr.tr : null;
      _delErr =
          draft.deliveryTime == null ? AppStrings.selectDeliveryTimeErr.tr : null;
    });

    return [_catErr, _subErr, _typeErr, _brandErr, _modelErr, _availErr, _delErr]
        .every((e) => e == null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _taxonomyCard(),
        _detailsCard(),
        _availabilityCard(),
      ],
    );
  }

  Widget _taxonomyCard() {
    return VehicleSectionCard(
      title: AppStrings.mainCategoryLabel.tr,
      children: [
        Obx(() => VehicleTaxonomySection(
              // .toList() actually reads the RxList so Obx subscribes —
              // passing the RxList object alone registers no observable.
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
    );
  }

  Widget _detailsCard() {
    return VehicleSectionCard(
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
      ],
    );
  }

  Widget _availabilityCard() {
    return VehicleSectionCard(
      title: AppStrings.availabilityFieldLabel.tr,
      children: [
        Obx(() {
          final opts = _c.optionSets.value;
          final availability = opts?.availability ?? const <VehicleOption>[];
          final delivery = opts?.deliveryTime ?? const <VehicleOption>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VehicleChoiceChips<VehicleOption>(
                items: availability,
                value: availability
                    .firstWhereOrNull((o) => o.value == draft.availability),
                labelOf: (o) => o.label,
                onSelected: (o) => setState(() {
                  draft.availability = o.value;
                  _availErr = null;
                }),
              ),
              VehicleErrorText(_availErr),
              SizedBox(height: SizeConfig.size14),
              VehicleFieldLabel(AppStrings.deliveryTimeFieldLabel.tr),
              VehicleChoiceChips<VehicleOption>(
                items: delivery,
                value: delivery
                    .firstWhereOrNull((o) => o.value == draft.deliveryTime),
                labelOf: (o) => o.label,
                onSelected: (o) => setState(() {
                  draft.deliveryTime = o.value;
                  _delErr = null;
                }),
              ),
              VehicleErrorText(_delErr),
            ],
          );
        }),
      ],
    );
  }
}
