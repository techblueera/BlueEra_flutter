import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/add_vehicle_flow_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The catalog "add product" picker that precedes the add-vehicle form:
/// Select Brand → Model → Variant (the seeded shared catalog). Choosing a
/// variant resolves its prefill payload and opens [AddVehicleFlowScreen]
/// pre-filled (and carrying `variant_id`, which `POST /vehicles/create`
/// requires). When the bike isn't in the catalog, the "request a new
/// model" fallback submits a missing-model request for admin review.
class VehicleCatalogPickerScreen extends StatefulWidget {
  final String condition; // VehicleCondition.isNew / .used

  const VehicleCatalogPickerScreen({super.key, required this.condition});

  @override
  State<VehicleCatalogPickerScreen> createState() =>
      _VehicleCatalogPickerScreenState();
}

enum _Stage { brand, model, variant }

class _VehicleCatalogPickerScreenState
    extends State<VehicleCatalogPickerScreen> {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);

  _Stage _stage = _Stage.brand;
  VehicleBrand? _brand;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.fetchCatalogBrands();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (_stage) {
      case _Stage.brand:
        return AppStrings.vehicleSelectBrandTitle.tr;
      case _Stage.model:
        return AppStrings.vehicleSelectModelTitle.tr;
      case _Stage.variant:
        return AppStrings.vehicleSelectVariantTitle.tr;
    }
  }

  /// Only the first stage pops the screen; deeper stages step back.
  bool get _canPop => _stage == _Stage.brand;

  /// Steps back one catalog stage (variant → model → brand).
  void _stepBack() {
    if (_stage == _Stage.variant) {
      setState(() {
        _stage = _Stage.model;
        _searchCtrl.clear();
      });
    } else if (_stage == _Stage.model) {
      setState(() {
        _stage = _Stage.brand;
        _searchCtrl.clear();
      });
    }
  }

  void _search(String q) {
    switch (_stage) {
      case _Stage.brand:
        _ctrl.fetchCatalogBrands(q: q);
        break;
      case _Stage.model:
        _ctrl.fetchCatalogModels(brandId: _brand?.id, q: q);
        break;
      case _Stage.variant:
        // Variants are a short per-model list — filter client-side only.
        setState(() {});
        break;
    }
  }

  void _onBrandTap(VehicleBrand b) {
    _brand = b;
    _searchCtrl.clear();
    setState(() => _stage = _Stage.model);
    _ctrl.fetchCatalogModels(brandId: b.id);
  }

  void _onModelTap(VehicleModelCatalog m) {
    _searchCtrl.clear();
    setState(() => _stage = _Stage.variant);
    _ctrl.fetchModelVariants(m.id);
  }

  Future<void> _onVariantTap(VehicleVariant v) async {
    final prefill = await _ctrl.fetchVariantPrefill(v.id);
    if (!mounted || prefill == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddVehicleFlowScreen(
          condition: widget.condition,
          prefill: prefill,
        ),
      ),
    );
    if (created == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _stepBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: CommonBackAppBar(
          title: _title,
          onBackTap: () {
            if (_canPop) {
              Navigator.of(context).pop();
            } else {
              _stepBack();
            }
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(SizeConfig.size12,
                    SizeConfig.size12, SizeConfig.size12, SizeConfig.size4),
                child: CommonTextField(
                  textEditController: _searchCtrl,
                  hintText: AppStrings.vehicleCatalogSearchHint.tr,
                  isValidate: false,
                  isOptionalFiled: true,
                  pIcon: const Icon(Icons.search, size: 20),
                  onChange: _search,
                ),
              ),
              Expanded(child: _stageBody()),
              _requestFallbackBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stageBody() {
    switch (_stage) {
      case _Stage.brand:
        return _list<VehicleBrand>(
          state: _ctrl.catalogBrandsState,
          itemsOf: () => _ctrl.catalogBrands,
          labelOf: (b) => b.name,
          onTap: _onBrandTap,
        );
      case _Stage.model:
        return _list<VehicleModelCatalog>(
          state: _ctrl.catalogModelsState,
          itemsOf: () => _ctrl.catalogModels,
          labelOf: (m) => m.name,
          onTap: _onModelTap,
        );
      case _Stage.variant:
        return _list<VehicleVariant>(
          state: _ctrl.catalogVariantsState,
          itemsOf: () {
            final q = _searchCtrl.text.trim().toLowerCase();
            final all = _ctrl.catalogVariants;
            if (q.isEmpty) return all;
            return all
                .where((v) => v.name.toLowerCase().contains(q))
                .toList()
                .obs;
          },
          labelOf: (v) => v.name,
          subtitleOf: (v) => v.exShowroomPrice != null
              ? '₹${v.exShowroomPrice!.toStringAsFixed(0)}'
              : null,
          onTap: _onVariantTap,
        );
    }
  }

  /// Generic Obx-driven selection list with loading / error / empty
  /// states, shared by all three stages.
  Widget _list<T>({
    required Rx<ApiResponse> state,
    required RxList<T> Function() itemsOf,
    required String Function(T) labelOf,
    required void Function(T) onTap,
    String? Function(T)? subtitleOf,
  }) {
    return Obx(() {
      if (state.value.status == Status.LOADING) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = itemsOf();
      if (items.isEmpty) {
        return Center(
          child: CustomText(
            AppStrings.noResultsFound.tr,
            fontSize: 14,
            color: AppColors.secondaryTextColor,
          ),
        );
      }
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size8,
            SizeConfig.size12, SizeConfig.size8),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size8),
        itemBuilder: (_, i) {
          final it = items[i];
          final subtitle = subtitleOf?.call(it);
          return InkWell(
            onTap: () => onTap(it),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDEFF4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          labelOf(it),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          SizedBox(height: SizeConfig.size2),
                          CustomText(
                            subtitle,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF9AA6B6)),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _requestFallbackBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size6,
            SizeConfig.size16, SizeConfig.size10),
        child: TextButton.icon(
          onPressed: _openRequestSheet,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: CustomText(
            AppStrings.vehicleCantFindRequest.tr,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  Future<void> _openRequestSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _RequestModelSheet(
        ctrl: _ctrl,
        initialBrand: _brand?.name,
      ),
    );
  }
}

/// Bottom sheet to request a catalog model that doesn't exist yet. On
/// submit it calls `VehicleController.requestMissingModel`, which queues a
/// missing-model request for admin review.
class _RequestModelSheet extends StatefulWidget {
  final VehicleController ctrl;
  final String? initialBrand;

  const _RequestModelSheet({required this.ctrl, this.initialBrand});

  @override
  State<_RequestModelSheet> createState() => _RequestModelSheetState();
}

class _RequestModelSheetState extends State<_RequestModelSheet> {
  late final TextEditingController _brandCtrl =
      TextEditingController(text: widget.initialBrand ?? '');
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final brand = _brandCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    if (brand.isEmpty || model.isEmpty) return;
    setState(() => _submitting = true);
    final ok = await widget.ctrl.requestMissingModel(
      brand: brand,
      model: model,
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.size16,
        right: SizeConfig.size16,
        top: SizeConfig.size18,
        bottom: MediaQuery.of(context).viewInsets.bottom + SizeConfig.size16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.vehicleRequestModelTitle.tr,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            AppStrings.vehicleRequestModelDesc.tr,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size16),
          CommonTextField(
            textEditController: _brandCtrl,
            title: AppStrings.brand.tr,
            hintText: AppStrings.brand.tr,
            isValidate: false,
          ),
          SizedBox(height: SizeConfig.size12),
          CommonTextField(
            textEditController: _modelCtrl,
            title: AppStrings.modelLabel.tr,
            hintText: AppStrings.modelLabel.tr,
            isValidate: false,
          ),
          SizedBox(height: SizeConfig.size12),
          CommonTextField(
            textEditController: _noteCtrl,
            title: AppStrings.vehicleRequestNoteHint.tr,
            hintText: AppStrings.vehicleRequestNoteHint.tr,
            isValidate: false,
            isOptionalFiled: true,
          ),
          SizedBox(height: SizeConfig.size18),
          CustomBtn(
            onTap: _submitting ? null : _submit,
            isValidate: true,
            radius: SizeConfig.size8,
            isLoading: _submitting,
            title: AppStrings.vehicleRequestSubmitLabel.tr,
          ),
        ],
      ),
    );
  }
}
