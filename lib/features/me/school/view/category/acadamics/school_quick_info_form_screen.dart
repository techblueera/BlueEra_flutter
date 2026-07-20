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

const List<String> kBoardOptions = [
  'CBSE',
  'ICSE',
  'State Board',
  'IB',
  'IGCSE',
  'NIOS',
  'Other',
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
  final RxList<String> _boards = <String>[].obs;
  final RxList<String> _mediums = <String>[].obs;
  // final TextEditingController _feesController = TextEditingController();
  // final RxnInt _fees = RxnInt();
  final TextEditingController _numberOfStudentsController =
      TextEditingController();
  final RxnInt _numberOfStudents = RxnInt();

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
    _boards.assignAll(data?.boards ?? const []);
    _mediums.assignAll(data?.mediumOfInstruction ?? const []);
    // _fees.value = data?.fees;
    // _feesController.text = data?.fees?.toString() ?? '';
    _numberOfStudents.value = data?.numberOfStudents;
    _numberOfStudentsController.text = data?.numberOfStudents?.toString() ?? '';
  }

  @override
  void dispose() {
    // _feesController.dispose();
    _numberOfStudentsController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _classRange.value != null &&
      _boards.isNotEmpty &&
      _mediums.isNotEmpty &&
      (_numberOfStudents.value ?? -1) >= 0;

  Future<void> _onSave() async {
    final ok = await _controller.updateSchoolQuickInfo(
      classRange: _classRange.value!,
      boards: _boards.toList(),
      mediumOfInstruction: _mediums.toList(),
      // fees: _fees.value ?? 0,
      numberOfStudents: _numberOfStudents.value ?? 0,
    );
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: "School Quick Info",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size12),
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

                  // ── Board (multi-select) ──
                  CustomText("Board", fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size8),
                  Obx(() => CommonDropdown<String>(
                        items: kBoardOptions
                            .where((b) => !_boards.contains(b))
                            .toList(),
                        selectedValue: null,
                        hintText: "e.g. CBSE",
                        displayValue: (v) => v,
                        onChanged: (val) {
                          if (val != null && !_boards.contains(val)) {
                            _boards.add(val);
                          }
                        },
                      )),

                  SizedBox(height: SizeConfig.size10),

                  Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _boards
                            .map((b) => CommonChip(
                                  label: b,
                                  onDeleted: () => _boards.remove(b),
                                ))
                            .toList(),
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
                  // CustomText("Fees", fontSize: SizeConfig.small),
                  // SizedBox(height: SizeConfig.size8),
                  // CommonTextField(
                  //   textEditController: _feesController,
                  //   hintText: "e.g. 25000",
                  //   keyBoardType: TextInputType.number,
                  //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  //   onChange: (val) {
                  //     _fees.value = int.tryParse(val);
                  //   },
                  // ),
                  // SizedBox(height: SizeConfig.size24),

                  // ── No of Students ──
                  CustomText("No of Students", fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size8),
                  CommonTextField(
                    textEditController: _numberOfStudentsController,
                    hintText: "e.g. 500",
                    keyBoardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChange: (val) {
                      _numberOfStudents.value = int.tryParse(val);
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
