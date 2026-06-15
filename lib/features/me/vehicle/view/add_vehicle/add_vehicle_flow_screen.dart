import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_draft.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/steps/new_vehicle_basics_step.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/steps/new_vehicle_specs_step.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/steps/photos_location_step.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/steps/used_vehicle_basics_step.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/steps/used_vehicle_details_step.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/widgets/vehicle_form_widgets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Host screen for the 3-page add-vehicle flow. Branches its pages off
/// [condition] (NEW vs USED), keeps every page alive via an
/// [IndexedStack] (so input survives back/next without re-entry), and
/// owns the shared [VehicleDraft]. Pops `true` once the vehicle is
/// created so the caller can refresh.
class AddVehicleFlowScreen extends StatefulWidget {
  final String condition; // VehicleCondition.isNew / .used

  const AddVehicleFlowScreen({super.key, required this.condition});

  @override
  State<AddVehicleFlowScreen> createState() => _AddVehicleFlowScreenState();
}

class _AddVehicleFlowScreenState extends State<AddVehicleFlowScreen> {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);

  late final VehicleDraft _draft = VehicleDraft(condition: widget.condition);
  late final List<GlobalKey<VehicleFormStepState>> _stepKeys;
  late final List<Widget> _steps;
  late final List<String> _titles;

  int _step = 0;

  bool get _isNew => widget.condition == VehicleCondition.isNew;

  @override
  void initState() {
    super.initState();
    // Server-controlled pickers — cached, so these are cheap if already
    // loaded elsewhere in the app.
    _ctrl.fetchVehicleTypes();
    _ctrl.fetchConditions();
    _ctrl.fetchOptions();

    _stepKeys =
        List.generate(3, (_) => GlobalKey<VehicleFormStepState>());

    if (_isNew) {
      _steps = [
        NewVehicleBasicsStep(
            key: _stepKeys[0], draft: _draft, controller: _ctrl),
        NewVehicleSpecsStep(
            key: _stepKeys[1], draft: _draft, controller: _ctrl),
        PhotosLocationStep(
            key: _stepKeys[2], draft: _draft, controller: _ctrl),
      ];
      _titles = [
        AppStrings.selectVehicleTitle.tr,
        AppStrings.specificationsOffersTitle.tr,
        AppStrings.photosLocationContactTitle.tr,
      ];
    } else {
      _steps = [
        UsedVehicleBasicsStep(
            key: _stepKeys[0], draft: _draft, controller: _ctrl),
        UsedVehicleDetailsStep(key: _stepKeys[1], draft: _draft),
        PhotosLocationStep(
            key: _stepKeys[2], draft: _draft, controller: _ctrl),
      ];
      _titles = [
        AppStrings.vehicleInformationTitle.tr,
        AppStrings.vehicleDetailsTitle.tr,
        AppStrings.photosLocationContactTitle.tr,
      ];
    }
  }

  bool get _isLastStep => _step == _steps.length - 1;

  void _onBack() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  Future<void> _onNext() async {
    final valid = _stepKeys[_step].currentState?.validateAndSave() ?? false;
    if (!valid) return;
    if (_isLastStep) {
      await _submit();
    } else {
      setState(() => _step += 1);
    }
  }

  Future<void> _submit() async {
    final created = await _ctrl.createVehicle(
      draft: _draft.toVehicle(),
      imageFiles: _draft.photoFiles,
      videoFiles: _draft.videoFiles,
    );
    if (created != null && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cap the form width on tablets / large screens and centre it;
    // phones use the natural full width.
    final isWide = MediaQuery.of(context).size.width >= 720;

    Widget capWidth(Widget child) => isWide
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: child,
            ),
          )
        : child;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: AppColors.mainTextColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        title: CustomText(
          _titles[_step],
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _ProgressBar(value: (_step + 1) / _steps.length),
        ),
      ),
      body: SafeArea(
        child: capWidth(
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              SizeConfig.size12,
              SizeConfig.size12,
              SizeConfig.size16,
            ),
            child: IndexedStack(
              index: _step,
              // sizing: every page builds; only the active one is shown.
              sizing: StackFit.loose,
              children: _steps,
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(capWidth),
    );
  }

  Widget _bottomBar(Widget Function(Widget) capWidth) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size10,
          SizeConfig.size16,
          SizeConfig.size12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEDEFF4))),
        ),
        child: capWidth(Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: CustomText(
                    AppStrings.back.tr,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size12),
            ],
            Expanded(
              flex: 2,
              child: Obx(() {
                final saving = _ctrl.isSavingVehicle.value;
                return ElevatedButton(
                  onPressed: saving ? null : _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLastStep
                              ? AppStrings.submitListingLabel.tr
                              : AppStrings.next.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                );
              }),
            ),
          ],
        )),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value; // 0..1
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: const Color(0xFFE4EAF2),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(color: AppColors.primaryColor),
      ),
    );
  }
}
