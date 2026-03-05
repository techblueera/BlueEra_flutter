import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddLabTestScreen extends StatefulWidget {
  final PathologyTest? testToEdit;
  final String collection;

  const AddLabTestScreen(
      {super.key, this.testToEdit, required this.collection});

  @override
  State<AddLabTestScreen> createState() => _AddLabTestScreenState();
}

class _AddLabTestScreenState extends State<AddLabTestScreen> {
  late final LabTestController controller;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController reportHoursController;
  late TextEditingController guidanceController;
  late TextEditingController methodController;
  late TextEditingController feesController;
  late TextEditingController priceController;

  TestCategory? selectedCategory;
  List<TestParameter> selectedParameters = [];
  String? selectedSpecimen;
  String? selectedCollectionMethod;
  String? selectedGender;
  bool applicableForChild = false;
  bool prescriptionRequired = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<LabTestController>()) {
      controller = Get.put(LabTestController(), permanent: true);
    } else {
      controller = Get.find<LabTestController>();
    }
    nameController = TextEditingController(text: widget.testToEdit?.testName);
    descriptionController =
        TextEditingController(text: widget.testToEdit?.description);
    reportHoursController = TextEditingController(
        text: widget.testToEdit?.estimatedReportHours?.toString());
    guidanceController =
        TextEditingController(text: widget.testToEdit?.beforeTestGuidance);
    methodController =
        TextEditingController(text: widget.testToEdit?.testMethod);
    feesController =
        TextEditingController(text: widget.testToEdit?.testFees?.toString());
    priceController = TextEditingController(
        text: widget.testToEdit?.customerPrice?.toString());

    if (widget.testToEdit != null) {
      if (widget.testToEdit!.testCategory is TestCategory) {
        selectedCategory = widget.testToEdit!.testCategory;
      } else if (widget.testToEdit!.testCategory is String) {
        selectedCategory = controller.categories
            .firstWhereOrNull((c) => c.id == widget.testToEdit!.testCategory);
      }

      if (widget.testToEdit!.testParameters != null) {
        for (var p in widget.testToEdit!.testParameters!) {
          if (p is TestParameter) {
            selectedParameters.add(p);
          } else if (p is String) {
            var param = controller.parameters
                .firstWhereOrNull((param) => param.id == p);
            if (param != null) selectedParameters.add(param);
          }
        }
      }

      selectedSpecimen = widget.testToEdit!.specimen;
      selectedCollectionMethod = widget.testToEdit!.specimenCollectionMethod;
      selectedGender = widget.testToEdit!.gender;
      applicableForChild = widget.testToEdit!.applicableForChild ?? false;
      prescriptionRequired = widget.testToEdit!.prescriptionRequired ?? false;
    }
  }

  bool get isRadiology => widget.collection == "Radiology";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.testToEdit == null ? AppStrings.addTest.tr : AppStrings.editTest.tr),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(SizeConfig.size16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonTextField(
                  textEditController: nameController,
                  title: AppStrings.testName.tr,
                  hintText: AppStrings.egText.tr,
                  isValidate: true,
                  onChange: (val){
                    setState(() {

                    });
                  },
                ),
                SizedBox(height: SizeConfig.size16),
                CommonDropdownDialog<TestCategory>(
                  items: controller.categories,
                  selectedValue: selectedCategory,
                  title: AppStrings.testCategory.tr,
                  hintText: AppStrings.selectCategory.tr,
                  displayValue: (value) => value.name ?? '',
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                SizedBox(height: SizeConfig.size16),
                AiDescriptionField(
                  label: AppStrings.description,
                  hintText: AppStrings.tellUsMoreAboutTest.tr,
                  controller: descriptionController,
                  rxValue: controller.descriptionTest,
                  // Your RX variable from the controller
                  aiType: "Diagnostic Laboratory",
                  aiData: {
                    "test_name": nameController.text,
                    "test_category": selectedCategory?.name
                  },
                ),

                SizedBox(height: SizeConfig.size16),
                _buildParameterSelection(),
                if (!isRadiology) ...[
                  SizedBox(height: SizeConfig.size16),
                  CommonDropdownDialog<String>(
                    items: controller.specimenList,
                    selectedValue: selectedSpecimen,
                    title: AppStrings.specimen.tr,
                    hintText: AppStrings.selectSpecimen.tr,
                    displayValue: (value) => value,
                    onChanged: (value) {
                      setState(() {
                        selectedSpecimen = value;
                      });
                    },
                  ),
                  SizedBox(height: SizeConfig.size16),
                  CommonDropdownDialog<String>(
                    items: controller.collectionMethods,
                    selectedValue: selectedCollectionMethod,
                    title: AppStrings.specimenCollectionMethod.tr,
                    hintText: AppStrings.selectMethod.tr,
                    displayValue: (value) => value,
                    onChanged: (value) {
                      setState(() {
                        selectedCollectionMethod = value;
                      });
                    },
                  ),
                ],
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: reportHoursController,
                  title: AppStrings.estimatedReportHours.tr,
                  hintText: "E.g. 24",
                  keyBoardType: TextInputType.number,
                ),
                SizedBox(height: SizeConfig.size16),
                CommonDropdownDialog<String>(
                  items: controller.genderList,
                  selectedValue: selectedGender,
                  title: AppStrings.gender.tr,
                  hintText: AppStrings.selectGender.tr,
                  displayValue: (value) => value,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                ),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: guidanceController,
                  title: AppStrings.beforeTestGuidance.tr,
                  hintText: AppStrings.enterGuidance.tr,
                  maxLine: 3,
                ),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: methodController,
                  title: AppStrings.testMethodOptional.tr,
                  hintText: AppStrings.egText.tr,
                ),
                SizedBox(height: SizeConfig.size16),
                _buildSwitchRow(AppStrings.applicableForChild.tr, applicableForChild,
                    (val) {
                  setState(() {
                    applicableForChild = val;
                  });
                }),
                SizedBox(height: SizeConfig.size8),
                _buildSwitchRow(AppStrings.prescriptionRequired.tr, prescriptionRequired,
                    (val) {
                  setState(() {
                    prescriptionRequired = val;
                  });
                }),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: feesController,
                  title: AppStrings.testFeesMrp.tr,
                  hintText: "E.g. 1000",
                  keyBoardType: TextInputType.number,
                  isValidate: true,
                ),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: priceController,
                  title: AppStrings.customerPrice.tr,
                  hintText: "E.g. 800",
                  keyBoardType: TextInputType.number,
                  isValidate: true,
                ),
                SizedBox(height: SizeConfig.size32),
                Obx(() => CustomBtn(
                      onTap: _submitForm,
                      isValidate: true,
                      title: widget.testToEdit == null ? AppStrings.post.tr : AppStrings.update.tr,
                      isLoading: controller.isLoading.value,
                    )),
                SizedBox(height: SizeConfig.size60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParameterSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(AppStrings.testParameters.tr,
            fontWeight: FontWeight.w600, fontSize: SizeConfig.size14),
        SizedBox(height: SizeConfig.size8),
        CommonDropdownDialog<TestParameter>(
          items: controller.parameters,
          selectedValue: null,
          title: AppStrings.selectParameter.tr,
          hintText: AppStrings.egParameters.tr,
          displayValue: (value) => value.name ?? '',
          onChanged: (value) {
            if (value != null &&
                !selectedParameters.any((p) => p.id == value.id)) {
              setState(() {
                selectedParameters.add(value);
              });
            }
          },
        ),
        if (selectedParameters.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: SizeConfig.size8),
            child: Wrap(
              spacing: 8,
              children: selectedParameters
                  .map((p) => Chip(
                        label: CustomText(p.name ?? '', fontSize: 12),
                        onDeleted: () {
                          setState(() {
                            selectedParameters.remove(p);
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSwitchRow(
      String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(title,
            fontWeight: FontWeight.w600, fontSize: SizeConfig.size14),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (selectedCategory == null) {
        commonSnackBar(message: AppStrings.pleaseSelectCategory.tr);
        return;
      }

      final test = PathologyTest(
        id: widget.testToEdit?.id,
        testName: nameController.text,
        testCategory: selectedCategory!.id,
        description: descriptionController.text,
        laboratoryId: labIDGlobal,
        testParameters: selectedParameters.map((p) => p.id).toList(),
        specimen: isRadiology ? null : selectedSpecimen,
        specimenCollectionMethod: isRadiology ? null : selectedCollectionMethod,
        estimatedReportHours: int.tryParse(reportHoursController.text) ?? 0,
        gender: selectedGender,
        beforeTestGuidance: guidanceController.text,
        testMethod: methodController.text,
        applicableForChild: applicableForChild,
        prescriptionRequired: prescriptionRequired,
        testFees: int.tryParse(feesController.text) ?? 0,
        customerPrice: int.tryParse(priceController.text) ?? 0,
        collection: widget.collection,
      );

      bool success;
      if (widget.testToEdit == null) {
        success = await controller.createTest(test);
      } else {
        success = await controller.updateTest(test);
      }

      if (success) {
        Get.back();
      }
    }
  }
}
