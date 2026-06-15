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

/// Step 2 of the NEW flow — pricing + EMI, vehicle information and
/// special offers. Mirrors the `new2` reference screen.
class NewVehicleSpecsStep extends VehicleFormStep {
  final VehicleController controller;
  const NewVehicleSpecsStep({
    super.key,
    required super.draft,
    required this.controller,
  });

  @override
  VehicleFormStepState<NewVehicleSpecsStep> createState() =>
      _NewVehicleSpecsStepState();
}

class _NewVehicleSpecsStepState
    extends VehicleFormStepState<NewVehicleSpecsStep> {
  VehicleController get _c => widget.controller;

  late final TextEditingController _exShowroomCtrl =
      TextEditingController(text: _money(draft.exShowroomPrice));
  late final TextEditingController _onRoadCtrl =
      TextEditingController(text: _money(draft.onRoadPrice));
  late final TextEditingController _downPaymentCtrl =
      TextEditingController(text: _money(draft.downPayment));
  late final TextEditingController _monthlyEmiCtrl =
      TextEditingController(text: _money(draft.monthlyEmi));
  late final TextEditingController _engineCtrl = TextEditingController(
      text: draft.engineCapacityCc?.toString() ?? '');
  late final TextEditingController _mileageCtrl =
      TextEditingController(text: draft.mileage ?? '');
  late final TextEditingController _descCtrl =
      TextEditingController(text: draft.description ?? '');

  String? _exShowroomErr, _downErr, _emiErr;

  static String _money(double? v) => v == null ? '' : v.toStringAsFixed(0);

  double? _parseNum(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  void dispose() {
    for (final c in [
      _exShowroomCtrl,
      _onRoadCtrl,
      _downPaymentCtrl,
      _monthlyEmiCtrl,
      _engineCtrl,
      _mileageCtrl,
      _descCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  bool validateAndSave() {
    draft.exShowroomPrice = _parseNum(_exShowroomCtrl.text);
    draft.onRoadPrice = _parseNum(_onRoadCtrl.text);
    draft.downPayment = _parseNum(_downPaymentCtrl.text);
    draft.monthlyEmi = _parseNum(_monthlyEmiCtrl.text);
    draft.engineCapacityCc = int.tryParse(
        _engineCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    draft.mileage = _mileageCtrl.text.trim();
    draft.description = _descCtrl.text.trim();

    setState(() {
      _exShowroomErr = draft.exShowroomPrice == null
          ? AppStrings.exShowroomPriceRequiredErr.tr
          : null;
      _downErr = (draft.emiAvailable && draft.downPayment == null)
          ? AppStrings.downPaymentRequiredErr.tr
          : null;
      _emiErr = (draft.emiAvailable && draft.monthlyEmi == null)
          ? AppStrings.monthlyEmiRequiredErr.tr
          : null;
    });

    return _exShowroomErr == null && _downErr == null && _emiErr == null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pricingCard(),
        _infoCard(),
        _offersCard(),
      ],
    );
  }

  Widget _pricingCard() {
    return VehicleSectionCard(
      title: AppStrings.vehiclePricingLabel.tr,
      children: [
        VehicleFieldLabel(AppStrings.exShowroomPriceLabel.tr),
        _priceField(_exShowroomCtrl, onChange: () {
          if (_exShowroomErr != null) setState(() => _exShowroomErr = null);
        }),
        VehicleErrorText(_exShowroomErr),
        SizedBox(height: SizeConfig.size12),
        VehicleFieldLabel(AppStrings.onRoadPriceLabel.tr),
        _priceField(_onRoadCtrl),
        SizedBox(height: SizeConfig.size12),
        VehicleYesNoField(
          label: AppStrings.emiAvailableLabel.tr,
          value: draft.emiAvailable,
          onChanged: (v) => setState(() {
            draft.emiAvailable = v;
            if (!v) _downErr = _emiErr = null;
          }),
        ),
        if (draft.emiAvailable) ...[
          SizedBox(height: SizeConfig.size12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleFieldLabel(AppStrings.downPaymentLabel.tr),
                    _priceField(_downPaymentCtrl, onChange: () {
                      if (_downErr != null) setState(() => _downErr = null);
                    }),
                    VehicleErrorText(_downErr),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleFieldLabel(AppStrings.monthlyEmiLabel.tr),
                    _priceField(_monthlyEmiCtrl, onChange: () {
                      if (_emiErr != null) setState(() => _emiErr = null);
                    }),
                    VehicleErrorText(_emiErr),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _infoCard() {
    return VehicleSectionCard(
      title: AppStrings.vehicleInformationLabel.tr,
      children: [
        Row(children: [
          Expanded(
            child: CommonDropdownDialog<VehicleFuelType>(
              items: VehicleFuelType.values,
              selectedValue: draft.fuelType,
              dialogTitle: AppStrings.fuelTypeLabel.tr,
              title: AppStrings.fuelTypeLabel.tr,
              hintText: AppStrings.selectHint.tr,
              displayValue: (e) => e.wire,
              onChanged: (v) => setState(() => draft.fuelType = v),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CommonDropdownDialog<VehicleTransmission>(
              items: VehicleTransmission.values,
              selectedValue: draft.transmission,
              dialogTitle: AppStrings.transmissionLabel.tr,
              title: AppStrings.transmissionLabel.tr,
              hintText: AppStrings.selectTransmissionHint.tr,
              displayValue: (e) => e.wire,
              onChanged: (v) => setState(() => draft.transmission = v),
            ),
          ),
        ]),
        SizedBox(height: SizeConfig.size12),
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VehicleFieldLabel(AppStrings.engineCapacityLabel.tr),
                CommonTextField(
                  textEditController: _engineCtrl,
                  hintText: AppStrings.engineCapacityHint.tr,
                  keyBoardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  isValidate: false,
                  isOptionalFiled: true,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VehicleFieldLabel(AppStrings.mileageLabel.tr),
                CommonTextField(
                  textEditController: _mileageCtrl,
                  hintText: AppStrings.mileageHintExample.tr,
                  isValidate: false,
                  isOptionalFiled: true,
                ),
              ],
            ),
          ),
        ]),
        SizedBox(height: SizeConfig.size12),
        VehicleFieldLabel(AppStrings.describeSellingLabel.tr),
        CommonTextField(
          textEditController: _descCtrl,
          hintText: AppStrings.describeHint.tr,
          maxLine: 4,
          minLines: 3,
          maxLength: 2000,
          isCounterVisible: true,
          isValidate: false,
          isOptionalFiled: true,
        ),
      ],
    );
  }

  Widget _offersCard() {
    return VehicleSectionCard(
      title: AppStrings.specialOffersLabel.tr,
      children: [
        Obx(() {
          final offers = _c.optionSets.value?.specialOffers ??
              const <VehicleOption>[];
          return VehicleMultiChips(
            options: offers,
            selectedValues: draft.specialOffers,
            onChanged: (sel) => setState(() => draft.specialOffers = sel),
          );
        }),
      ],
    );
  }

  Widget _priceField(TextEditingController c, {VoidCallback? onChange}) {
    return CommonTextField(
      textEditController: c,
      hintText: AppStrings.priceHintExample.tr,
      keyBoardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ],
      isValidate: false,
      isOptionalFiled: true,
      onChange: onChange == null ? null : (_) => onChange(),
    );
  }
}
