import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/regular_expression.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_drop_down-dialoge.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/auth/controller/auth_controller.dart';
import '../../../../common/auth/model/personal_profession_model.dart';
import '../../../auth/controller/view_personal_details_controller.dart';
import '../../controller/perosonal__create_profile_controller.dart';
class UpdatePersonalProfessionDialog extends StatefulWidget {
  const UpdatePersonalProfessionDialog({super.key});

  @override
  State<UpdatePersonalProfessionDialog> createState() => _UpdatePersonalProfessionDialogState();
}

class _UpdatePersonalProfessionDialogState extends State<UpdatePersonalProfessionDialog> {
  final personalCreateProfileController =
  Get.find<PersonalCreateProfileController>();
  final viewProfileController = Get.find<ViewPersonalDetailsController>();
  bool isProfileCreateStatus = false;
  final authController = Get.find<AuthController>();
  final designationController = TextEditingController();
  final specializationController = TextEditingController();
  final professionOthersController = TextEditingController();
  final sectorTextController = TextEditingController();
  final _skillWorkerSpecificationTextController = TextEditingController();
  final _contentCraterTextController = TextEditingController();
  final _CourseTextController = TextEditingController();
  final _SeniorTextController = TextEditingController();
  final _ExpertiseTextController = TextEditingController();
  final _companyNameTextController = TextEditingController();
  final _ngoNameTextController = TextEditingController();
  final _artTypeController = TextEditingController();
  final politicalPartyController = TextEditingController();
  final departmentNameController = TextEditingController();
  final subDivision = TextEditingController();

  String? selectedProfession;
  final formKey = GlobalKey<FormState>();
  @override
  void initState() {
    // TODO: implement initState
    apiCalling();
    WidgetsBinding.instance.addPostFrameCallback((_){
      assignPrefessionValue();
    });
    Future.delayed(Duration(seconds: 1), () {
      setState(() {});
    });
    super.initState();
  }
  apiCalling() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ///GETTING PROFESSION DATA LIST...
      await authController.getAllProfessionController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Update Profession Details",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),

              const SizedBox(height: 16),

              professionUI(),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: CustomText("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomBtn(
                      height: 40,
                      radius: 10,
                      bgColor: AppColors.primaryColor,
                      title: "Save",
                      isValidate: filedValidation(),
                      onTap: filedValidation()
                          ? () async {
                        // Navigator.pop(context);
                        await saveProfessionDetails();
                      }
                          : null,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  filedValidation() {
    bool isValid = true;

    if (personalCreateProfileController.isImageUpdated.value) isValid = true;

    if (personalCreateProfileController.selectedProfession.value ==
        AppConstants.Others &&
        professionOthersController.text.isEmpty) isValid = false;
    if ((personalCreateProfileController.selectedProfession.value ==
        PRIVATE_JOB) &&
        sectorTextController.text.isEmpty) isValid = false;

    return isValid;
  }
  clearTextFiled() {
    designationController.clear();
    professionOthersController.clear();
    politicalPartyController.clear();


  }
  void assignPrefessionValue(){
    personalCreateProfileController.selectedProfession.value =
        viewProfileController.personalProfileDetails.value.user?.profession ??
            "OTHERS";
    selectedProfession =
        personalCreateProfileController.selectedProfession.value;
    if (viewProfileController.personalProfileDetails.value.user?.profession ==
        OTHERS) {
      professionOthersController.text = viewProfileController
          .personalProfileDetails.value.user?.specilization ??
          "";
    }

    ///SELF EMPLOYEE
    if (selectedProfession == SELF_EMPLOYED) {
      personalCreateProfileController.selectedSubProfession.value =
          viewProfileController
              .personalProfileDetails.value.user?.designation ??
              "OTHERS";

      personalCreateProfileController.selectedSubProfessionObj.value =
          SubcategoriesFiledName(
              tagId: viewProfileController
                  .personalProfileDetails.value.user?.designation,
              name: viewProfileController
                  .personalProfileDetails.value.user?.designation);

      specializationController.text = viewProfileController
          .personalProfileDetails.value.user?.specilization ??
          "";
    }

    ///PRIVATE JOB
    if (selectedProfession == PRIVATE_JOB) {
      sectorTextController.text =
          viewProfileController.personalProfileDetails.value.user?.sector ??
              "";
    }

    ///SKILL WORKER..
    if (selectedProfession == SKILLED_WORKER) {
      _skillWorkerSpecificationTextController.text = viewProfileController
          .personalProfileDetails.value.user?.specilization ??
          "";
    }

    ///CONTENT CREATER
    if (selectedProfession == CONTENT_CREATOR) {
      _contentCraterTextController.text = viewProfileController
          .personalProfileDetails.value.user?.specilization ??
          "";
    }

    ///POLITICIAN
    if (selectedProfession == POLITICIAN) {
      politicalPartyController.text = viewProfileController
          .personalProfileDetails.value.user?.department ??
          "";
    }

    ///GOVT PSU
    if (selectedProfession == GOVTPSU) {
      departmentNameController.text = viewProfileController
          .personalProfileDetails.value.user?.department ??
          "";
      subDivision.text = viewProfileController
          .personalProfileDetails.value.user?.subDivision ??
          "";
    }

    ///NGO
    if (selectedProfession == REG_UNION) {
      _ngoNameTextController.text = viewProfileController
          .personalProfileDetails.value.user?.department ??
          "";
    }

    ///ARTIST
    if (selectedProfession == ARTIST) {
      personalCreateProfileController.selectedSubProfession.value =
          viewProfileController
              .personalProfileDetails.value.user?.art?.artName ??
              "OTHERS";

      personalCreateProfileController.selectedSubProfessionObj.value =
          SubcategoriesFiledName(
              tagId: viewProfileController
                  .personalProfileDetails.value.user?.art?.artName,
              name: viewProfileController
                  .personalProfileDetails.value.user?.art?.artName);

      _artTypeController.text = viewProfileController
          .personalProfileDetails.value.user?.art?.artType ??
          "";
    }
    designationController.text = viewProfileController
        .personalProfileDetails.value.user?.designation ??
        "";
    personalCreateProfileController.selectedProfessionObj.value =
        ProfessionTypeData(
            tagId: selectedProfession,
            name: selectedProfession?.toLowerCase());
setState(() {

});
  }

  Widget professionUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            CustomText(
              AppStrings.selectYourProfession,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.paddingXSL),
        GetBuilder<AuthController>(
            builder: (authController) {
              print("lsdkcmlskmdc ${selectedProfession} ${selectedProfession==POLITICIAN} ${POLITICIAN}");
              final dataList = authController
                  .professionTypeDataList
                  .where((e) =>
              e.tagId ==
                  personalCreateProfileController
                      .selectedProfession.value)
                  .toList();
              if (dataList.isNotEmpty) {
                authController.clearSubCategoryData();

                authController.subcategoriesFiledNameList
                    .addAll(dataList
                    .first.subcategoriesFiledName ??
                    []);
              }
              return CommonDropdownDialog<ProfessionTypeData>(
                items: authController.professionTypeDataList,
                selectedValue: personalCreateProfileController
                    .selectedProfessionObj.value,
                hintText: AppConstants.selectProfession,
                title: AppStrings.selectYourProfession,
                displayValue: (profession) =>
                profession.name ?? "",
                onChanged: (value) {
                  personalCreateProfileController
                      .selectedSubProfessionObj.value = null;

                  authController.clearSubCategoryData();

                  personalCreateProfileController
                      .selectedProfession
                      .value = value?.tagId;
                  personalCreateProfileController
                      .selectedProfessionObj.value = value;
                  selectedProfession = value?.name?.toUpperCase();
                  authController.subcategoriesFiledNameList
                      .addAll(value?.subcategoriesFiledName ??
                      []);
                  clearTextFiled();
                  setState(() {});
                },
              );
            }),

        SizedBox(height: SizeConfig.size18),

        if (personalCreateProfileController
            .selectedProfession.value ==
            AppConstants.Others) ...[
          CommonTextField(
            hintText: AppStrings.enterProfessionIfOthers,
            title: AppStrings.specifyProfession,
            isValidate: false,
            textEditController:
            professionOthersController,
          ),
          SizedBox(height: SizeConfig.size18),
        ],
        if (personalCreateProfileController
            .selectedProfession.value ==
            SELF_EMPLOYED) ...[
          // SizedBox(
          //   height: SizeConfig.size20,
          // ),

          ///selectYourProfession
          Align(
            alignment: Alignment.centerLeft,
            child: CustomText(
              AppStrings.selectWorkType,
              fontSize: SizeConfig.medium,
            ),
          ),
          SizedBox(
            height: SizeConfig.size10,
          ),
          Obx(() {
            return CommonDropdownDialog<
                SubcategoriesFiledName>(
              items: authController
                  .subcategoriesFiledNameList,
              title: AppStrings.selectWorkType,
              selectedValue:
              personalCreateProfileController
                  .selectedSubProfessionObj.value,
              hintText: AppStrings.professionExample,
              displayValue: (selfEmployment) =>
              selfEmployment.name ?? "",
              onChanged: (value) {
                personalCreateProfileController
                    .selectedSubProfessionObj
                    .value = value;
                personalCreateProfileController
                    .selectedSubProfession
                    .value = value?.tagId;
                filedValidation();
              },
            );
          }),
          SizedBox(
            height: SizeConfig.size15,
          ),
          CommonTextField(
            textEditController: specializationController,
            inputLength: 24,
            // maxLength: 24,
            isValidate: false,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            titleColor: Colors.black,
            hintText: AppStrings.pleaseSpecifyWorkType,
          ),
          SizedBox(
            height: SizeConfig.size15,
          ),
        ],
        if ((selectedProfession == SKILLED_WORKER)) ...[
          CommonTextField(
            textEditController:
            _skillWorkerSpecificationTextController,
            inputLength: 24,
            title: AppStrings.typeWorkSpecification,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            hintText:AppStrings.workExample,
            isValidate: false,
          ),
          SizedBox(
            height: SizeConfig.size20,
          ),
        ],
        if ((selectedProfession == CONTENT_CREATOR)) ...[
          CommonTextField(
            isValidate: false,

            textEditController:
            _contentCraterTextController,
            // inputLength: 13,
            inputLength: 24,
            title: AppStrings.typeYourSpecification,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            hintText: AppStrings.specificationExample,
          ),
          SizedBox(
            height: SizeConfig.size20,
          ),
        ],

        if ((selectedProfession == REG_UNION)) ...[
          CommonTextField(
            isValidate: false,
            textEditController: _ngoNameTextController,
            inputLength: 40,
            title: AppStrings.typeNGOName,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            hintText:AppStrings.ngoExample,
          ),
          SizedBox(
            height: SizeConfig.size20,
          ),
        ],
        if ((selectedProfession == INDUSTRIALIST)) ...[
          SizedBox(
            height: SizeConfig.size20,
          ),
          CommonTextField(
            isValidate: false,

            textEditController:
            _companyNameTextController,
            // inputLength: 13,
            inputLength: 24,
            title: AppStrings.typeCompanyName,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            hintText: AppStrings.companyExample,
          ),
        ],

        if ((selectedProfession == HOMEMAKER)) ...[
          CommonTextField(
            isValidate: false,

            textEditController: _ExpertiseTextController,
            // inputLength: 13,
            inputLength: 24,
            title: AppStrings.typeExpertise,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            hintText:AppStrings.expertiseExample1,
          ),
          SizedBox(
            height: SizeConfig.size20,
          ),
        ],
        if ((selectedProfession ==
            SENIOR_CITIZEN)) ...[
          SizedBox(
            height: SizeConfig.size20,
          ),
          CommonTextField(
            isValidate: false,
            textEditController: _SeniorTextController,
            inputLength: 24,
            title: AppStrings.typeExpertise,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            hintText:AppStrings.expertiseExample2,
          ),
        ],
        if ((selectedProfession == STUDENT)) ...[
          CommonTextField(
            isValidate: false,
            textEditController: _CourseTextController,
            inputLength: 24,
            title: AppStrings.whichClassStudy,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            hintText: AppStrings.studyExample,
          ),
          SizedBox(
            height: SizeConfig.size20,
          ),
        ],

        if ((selectedProfession == ARTIST)) ...[
          ///selectYourProfession
          Align(
            alignment: Alignment.centerLeft,
            child: CustomText(
              AppStrings.selectArtSkill,
              fontSize: SizeConfig.medium,
            ),
          ),
          SizedBox(
            height: SizeConfig.size10,
          ),
          CommonDropdownDialog<SubcategoriesFiledName>(
            items:
            authController.subcategoriesFiledNameList,
            title: AppStrings.selectArtSkill,
            selectedValue: personalCreateProfileController
                .selectedSubProfessionObj.value,
            hintText: AppStrings.artExample,
            displayValue: (selfEmployment) =>
            selfEmployment.name ?? "",
            onChanged: (value) {
              personalCreateProfileController
                  .selectedSubProfessionObj.value = value;
              personalCreateProfileController
                  .selectedSubProfession
                  .value = value?.tagId;
            },
          ),
          SizedBox(
            height: SizeConfig.size20,
          ),

          if (personalCreateProfileController
              .selectedSubProfessionObj.value !=
              null) ...[
            CommonTextField(
              isValidate: false,

              textEditController: _artTypeController,
              // inputLength: 13,
              inputLength: 24,
              keyBoardType: TextInputType.text,
              regularExpression: RegularExpressionUtils
                  .alphabetSpacePattern,
              titleColor: Colors.black,
              hintText: AppStrings.pleaseSpecifyArtType,
            ),
            SizedBox(
              height: SizeConfig.size20,
            ),
          ],
        ],

        if (selectedProfession == 'Private Job') ...[
          CommonTextField(
            textEditController: sectorTextController,
            inputLength: 24,
            keyBoardType: TextInputType.text,
            // isValidate: false,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern,
            title: AppStrings.sector,
            hintText: AppStrings.sectorExample,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.enterSector.tr;
              }
              if (value.trim().length > 24) {
                return AppStrings.sectorMaxLength.tr;
              }
              return null;
            },
          ),
          SizedBox(height: SizeConfig.size18),
        ],

        if ((selectedProfession == POLITICIAN)) ...[
          CommonTextField(
            title: AppStrings.politicalParty,
            inputLength: 24,
            hintText:
            AppStrings.enterPoliticalParty,
            textEditController: politicalPartyController,
            isValidate: false,
          ),
          SizedBox(height: SizeConfig.size18),
        ],
        if (selectedProfession == GOVTPSU) ...[
          CommonTextField(
            title: AppStrings.departmentName,
            textEditController: departmentNameController,
            inputLength: 24,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern_,
            titleColor: Colors.black,
            hintText: AppStrings.departmentExample,
            isValidate: false,
          ),
          SizedBox(height: SizeConfig.size18),
        ],
        if ((selectedProfession == GOVTPSU)) ...[
          CommonTextField(
            title: AppStrings.subDivision,
            textEditController: subDivision,
            inputLength: 24,
            isValidate: false,
            keyBoardType: TextInputType.text,
            regularExpression: RegularExpressionUtils
                .alphabetSpacePattern_,
            titleColor: Colors.black,
            hintText: AppStrings.subDivisionExample,
          ),
          SizedBox(height: SizeConfig.size18),
        ],
        if ((selectedProfession != SELF_EMPLOYED) &&
            (selectedProfession != SKILLED_WORKER) &&
            (selectedProfession != ARTIST) &&
            (selectedProfession != CONTENT_CREATOR) &&
            (selectedProfession != HOMEMAKER) &&
            (selectedProfession !=
                SENIOR_CITIZEN) &&
            (selectedProfession != FARMER) &&
            (selectedProfession != STUDENT) &&
            (selectedProfession != OTHERS)) ...[
          CommonTextField(
            title: AppStrings.designation,
            inputLength: 24,
            isValidate: false,
            hintText:AppStrings.enterDesignation,
            textEditController: designationController,
            onChange: (val) {
              // filedValidation();
            },
          ),
          SizedBox(height: SizeConfig.size18),
        ],
      ],
    );
  }

  Future<void> saveProfessionDetails() async {
    final selectedProf = personalCreateProfileController.selectedProfession.value;

    // Decide designation
    final designation = selectedProf == SELF_EMPLOYED
        ? personalCreateProfileController.selectedSubProfessionObj.value?.name ?? ""
        : designationController.text.trim();

    // Base params always sent
    Map<String, dynamic> params = {
      ApiKeys.profession: selectedProf ?? "",
      ApiKeys.designation: designation,
    };

    // Add only the required field based on profession type

    switch (selectedProf) {
      case SELF_EMPLOYED:
        params[ApiKeys.specilization] = specializationController.text.trim();
        break;

      case CONTENT_CREATOR:
        params[ApiKeys.specilization] = _contentCraterTextController.text.trim();
        break;

      case SKILLED_WORKER:
        params[ApiKeys.specilization] = _skillWorkerSpecificationTextController.text.trim();
        break;
    case POLITICIAN:
        params[ApiKeys.political_party] = politicalPartyController
        .text
        .trim();
        break;

      case OTHERS:
        params[ApiKeys.specilization] = professionOthersController.text.trim();
        break;

      case PRIVATE_JOB:
        params[ApiKeys.sector] = sectorTextController.text.trim();
        break;

      case REG_UNION:
        params[ApiKeys.department] = _ngoNameTextController.text.trim();
        break;

      case GOVTPSU:
        params.addAll({
          ApiKeys.department: departmentNameController.text.trim(),
          ApiKeys.subDivision: subDivision.text.trim(),
        });
        break;

      case ARTIST:
        params[ApiKeys.art] = jsonEncode({
          ApiKeys.artName: personalCreateProfileController
              .selectedSubProfessionObj.value?.name ??
              "",
          ApiKeys.artType: _artTypeController.text.trim(),
        });
        break;
    }
    log("sdkjncsjkldc ${params}");

    // Call update API
    await personalCreateProfileController.updateUserProfileDetails(
      params: params,
    );
  }

}
