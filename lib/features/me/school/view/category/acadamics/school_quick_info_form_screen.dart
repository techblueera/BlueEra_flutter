import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

const List<String> kClassRangeOptions = [
  'Nursery - KG',
  'Class 1 - 5',
  'Class 1 - 8',
  'Class 1 - 10',
  'Class 1 - 12',
  'Class 6 - 10',
  'Class 6 - 12',
  'Class 9 - 12',
  'Class 11 - 12',
];

const List<String> kRatioOptions = [
  '1:5',
  '1:10',
  '1:15',
  '1:20',
  '1:25',
  '1:30',
  '1:35',
  '1:40',
];

const List<String> kMediumOptions = [
  'English',
  'Hindi',
  'Gujarati',
  'Marathi',
  'Tamil',
  'Telugu',
  'Kannada',
  'Bengali',
  'Punjabi',
  'Urdu',
  'Sanskrit',
];

class SchoolQuickInfoFormScreen extends StatefulWidget {
  const SchoolQuickInfoFormScreen({super.key});

  @override
  State<SchoolQuickInfoFormScreen> createState() =>
      _SchoolQuickInfoFormScreenState();
}

class _SchoolQuickInfoFormScreenState extends State<SchoolQuickInfoFormScreen> {
  final SchoolAboutUsController _controller =
      Get.find<SchoolAboutUsController>();

  final Rxn<String> _classRange = Rxn<String>();
  final Rxn<String> _ratio = Rxn<String>();
  final RxList<String> _mediums = <String>[].obs;
  final TextEditingController _feesController = TextEditingController();
  final RxnInt _fees = RxnInt();

  @override
  void initState() {
    super.initState();
    _hydrateFromController();
    _controller.fetchSchoolQuickInfo().then((_) => _hydrateFromController());
  }

  void _hydrateFromController() {
    final data = _controller.schoolDetailsData?.value;
    _classRange.value =
        (data?.classRange?.isNotEmpty ?? false) ? data!.classRange : null;
    _ratio.value = (data?.studentTeacherRatio?.isNotEmpty ?? false)
        ? data!.studentTeacherRatio
        : null;
    _mediums.assignAll(data?.mediumOfInstruction ?? const []);
    _fees.value = data?.fees;
    _feesController.text = data?.fees?.toString() ?? '';
  }

  @override
  void dispose() {
    _feesController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _classRange.value != null &&
      _ratio.value != null &&
      _mediums.isNotEmpty &&
      (_fees.value ?? -1) >= 0;

  Future<void> _onSave() async {
    final ok = await _controller.updateSchoolQuickInfo(
      classRange: _classRange.value!,
      studentTeacherRatio: _ratio.value!,
      mediumOfInstruction: _mediums.toList(),
      fees: _fees.value ?? 0,
    );
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: "School Quick Info",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: SingleChildScrollView(
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Class Range ──
                  CustomText("Class Range", fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size8),
                  Obx(() => CommonDropdown<String>(
                        items: kClassRangeOptions,
                        selectedValue: _classRange.value,
                        hintText: "e.g. Class 1 - 12",
                        displayValue: (v) => v,
                        onChanged: (val) => _classRange.value = val,
                      )),

                  SizedBox(height: SizeConfig.size24),

                  // ── Student-Teacher Ratio ──
                  CustomText("Student-Teacher Ratio",
                      fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size8),
                  Obx(() => CommonDropdown<String>(
                        items: kRatioOptions,
                        selectedValue: _ratio.value,
                        hintText: "e.g. 1:20",
                        displayValue: (v) => v,
                        onChanged: (val) => _ratio.value = val,
                      )),

                  SizedBox(height: SizeConfig.size24),

                  // ── Medium of Instruction (multi-select) ──
                  CustomText("Medium of Instruction",
                      fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size8),
                  Obx(() => CommonDropdown<String>(
                        items: kMediumOptions
                            .where((m) => !_mediums.contains(m))
                            .toList(),
                        selectedValue: null,
                        hintText: "e.g. English",
                        displayValue: (v) => v,
                        onChanged: (val) {
                          if (val != null && !_mediums.contains(val)) {
                            _mediums.add(val);
                          }
                        },
                      )),

                  SizedBox(height: SizeConfig.size10),

                  Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _mediums
                            .map((medium) => CommonChip(
                                  label: medium,
                                  onDeleted: () => _mediums.remove(medium),
                                ))
                            .toList(),
                      )),

                  SizedBox(height: SizeConfig.size24),

                  // ── Fees ──
                  CustomText("Fees", fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size8),
                  CommonTextField(
                    textEditController: _feesController,
                    hintText: "e.g. 25000",
                    keyBoardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChange: (val) {
                      _fees.value = int.tryParse(val);
                    },
                  ),

                  SizedBox(height: SizeConfig.size24),

                  // ── Save ──
                  Obx(() {
                    final valid = _isFormValid;
                    final saving = _controller.isQuickInfoSaving.value;
                    return CustomBtn(
                      onTap: (valid && !saving) ? _onSave : null,
                      title: saving ? AppStrings.saving.tr : AppStrings.save,
                      isValidate: valid && !saving,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
