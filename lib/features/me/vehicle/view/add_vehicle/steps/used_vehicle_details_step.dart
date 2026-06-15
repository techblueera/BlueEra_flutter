import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/widgets/vehicle_form_widgets.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Step 2 of the USED flow — expected price + negotiable, vehicle
/// information (km driven, fuel, transmission, engine, mileage, colour,
/// insurance) and the RC / pollution / service toggles. Mirrors the
/// `old2` reference screen.
class UsedVehicleDetailsStep extends VehicleFormStep {
  const UsedVehicleDetailsStep({super.key, required super.draft});

  @override
  VehicleFormStepState<UsedVehicleDetailsStep> createState() =>
      _UsedVehicleDetailsStepState();
}

class _UsedVehicleDetailsStepState
    extends VehicleFormStepState<UsedVehicleDetailsStep> {
  late final TextEditingController _expectedPriceCtrl =
      TextEditingController(text: _money(draft.expectedPrice));
  late final TextEditingController _kmDrivenCtrl =
      TextEditingController(text: draft.kmDriven?.toString() ?? '');
  late final TextEditingController _engineCtrl = TextEditingController(
      text: draft.engineCapacityCc?.toString() ?? '');
  late final TextEditingController _mileageCtrl =
      TextEditingController(text: draft.mileage ?? '');
  late final TextEditingController _colorCtrl =
      TextEditingController(text: draft.color ?? '');
  late final TextEditingController _descCtrl =
      TextEditingController(text: draft.description ?? '');

  String? _expectedErr, _kmErr;

  static String _money(double? v) => v == null ? '' : v.toStringAsFixed(0);

  double? _parseNum(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  void dispose() {
    for (final c in [
      _expectedPriceCtrl,
      _kmDrivenCtrl,
      _engineCtrl,
      _mileageCtrl,
      _colorCtrl,
      _descCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  bool validateAndSave() {
    draft.expectedPrice = _parseNum(_expectedPriceCtrl.text);
    draft.kmDriven =
        int.tryParse(_kmDrivenCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    draft.engineCapacityCc =
        int.tryParse(_engineCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    draft.mileage = _mileageCtrl.text.trim();
    draft.color = _colorCtrl.text.trim();
    draft.description = _descCtrl.text.trim();

    setState(() {
      _expectedErr = draft.expectedPrice == null
          ? AppStrings.expectedPriceRequiredErr.tr
          : null;
      _kmErr =
          draft.kmDriven == null ? AppStrings.kmDrivenRequiredErr.tr : null;
    });

    return _expectedErr == null && _kmErr == null;
  }

  Future<void> _pickInsuranceDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.insuranceValidTill ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => draft.insuranceValidTill = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VehicleSectionCard(
          children: [
            VehicleFieldLabel(AppStrings.expectedPriceLabel.tr),
            CommonTextField(
              textEditController: _expectedPriceCtrl,
              hintText: AppStrings.priceHintExample.tr,
              keyBoardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              isValidate: false,
              isOptionalFiled: true,
              onChange: (_) {
                if (_expectedErr != null) setState(() => _expectedErr = null);
              },
            ),
            VehicleErrorText(_expectedErr),
            SizedBox(height: SizeConfig.size12),
            VehicleYesNoField(
              label: AppStrings.negotiableLabel.tr,
              value: draft.isNegotiable,
              onChanged: (v) => setState(() => draft.isNegotiable = v),
            ),
          ],
        ),
        VehicleSectionCard(
          title: AppStrings.vehicleInformationLabel.tr,
          children: [
            VehicleFieldLabel(AppStrings.kilometresDrivenLabel.tr),
            CommonTextField(
              textEditController: _kmDrivenCtrl,
              hintText: AppStrings.kmDrivenHint.tr,
              keyBoardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              isValidate: false,
              isOptionalFiled: true,
              onChange: (_) {
                if (_kmErr != null) setState(() => _kmErr = null);
              },
            ),
            VehicleErrorText(_kmErr),
            SizedBox(height: SizeConfig.size12),
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleFieldLabel(AppStrings.color.tr),
                    CommonTextField(
                      textEditController: _colorCtrl,
                      hintText: AppStrings.color.tr,
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
                    VehicleFieldLabel(AppStrings.insuranceValidTillLabel.tr),
                    _dateField(),
                  ],
                ),
              ),
            ]),
          ],
        ),
        VehicleSectionCard(
          children: [
            VehicleYesNoField(
              label: AppStrings.rcAvailableLabel.tr,
              value: draft.rcAvailable,
              onChanged: (v) => setState(() => draft.rcAvailable = v),
            ),
            SizedBox(height: SizeConfig.size12),
            VehicleYesNoField(
              label: AppStrings.pollutionCertificateLabel.tr,
              value: draft.pollutionCertificate,
              onChanged: (v) =>
                  setState(() => draft.pollutionCertificate = v),
            ),
            SizedBox(height: SizeConfig.size12),
            VehicleYesNoField(
              label: AppStrings.serviceHistoryLabel.tr,
              value: draft.serviceHistory,
              onChanged: (v) => setState(() => draft.serviceHistory = v),
            ),
            SizedBox(height: SizeConfig.size12),
            VehicleFieldLabel(AppStrings.describeSellingLabel.tr),
            CommonTextField(
              textEditController: _descCtrl,
              hintText: AppStrings.describeHint.tr,
              maxLine: 4,
              minLines: 3,
              maxLength: 500,
              isCounterVisible: true,
              isValidate: false,
              isOptionalFiled: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateField() {
    final date = draft.insuranceValidTill;
    final text =
        date == null ? AppStrings.selectDateHint.tr : DateFormat('dd/MM/yyyy').format(date);
    return GestureDetector(
      onTap: _pickInsuranceDate,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size15,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDE3EC)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: CustomText(
                text,
                fontSize: 14,
                color: date == null
                    ? Colors.grey
                    : AppColors.mainTextColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
