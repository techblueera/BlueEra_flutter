import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CreateBusinessAccountNewStepOne extends StatefulWidget {
  CreateBusinessAccountNewStepOne({super.key});

  @override
  State<CreateBusinessAccountNewStepOne> createState() =>
      _CreateBusinessAccountNewStepOneState();
}

class _CreateBusinessAccountNewStepOneState extends State<CreateBusinessAccountNewStepOne> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  final authController = Get.find<AuthController>();
  String? _imagePath;
  bool isServiceOrManufacturing =  false;

  /// Chosen category is the pharmacy / medical-store one, which by law trades
  /// on a drug licence — so step one asks for that licence number.
  bool isPharmacyCategory = false;

  /// Whether a brand / branch name has to be collected here.
  ///
  /// Two reasons it can be true, and they are separate:
  ///  * a GST number was verified — the business name is then locked to the
  ///    GST trade name, so the branch is the only thing distinguishing one
  ///    listing of that GSTIN from another, and the backend keys uniqueness off
  ///    the (GST number + branch) PAIR rather than the GSTIN alone;
  ///  * the business is a Finance one, where the branch is required outright.
  ///
  /// See docs/finance-gst-branch-ui-integration.md §0/§1/§4.
  bool needsBrandOrBranchName = false;

  @override
  initState(){
    super.initState();
    if ([
      BusinessType.Service,
      BusinessType.Manufacturing,
      BusinessType.Healthcare,
      BusinessType.Motel,
      BusinessType.Siksha
    ].contains(authController.selectedTypeOfBusiness)){
      isServiceOrManufacturing = true;
    }

    // Match on the category's slug (`tag_id`) first — that is the stable
    // identifier the rest of the app routes pharmacy screens on. The display
    // name is only a fallback for a backend that ever renames the slug.
    final categorySlug = (authController.selectedCategorySlugId ?? '').toUpperCase();
    final categoryName = (authController.selectedCategoryName ?? '').toUpperCase();
    isPharmacyCategory =
        categorySlug == PHARMACY || categoryName.contains(PHARMACY);

    // `hasVerifiedGst` (and not `isHaveGstApprove`) is the real "the GSTIN came
    // back verified" signal: the GST screen pre-sets `isHaveGstApprove` to true
    // merely to pre-select "Yes I have" when GST is compulsory.
    needsBrandOrBranchName = authController.hasVerifiedGst ||
        authController.selectedTypeOfBusiness == BusinessType.Finance;

    log('is Service or manufacturer -- $isServiceOrManufacturing');
    log('is pharmacy -- $isPharmacyCategory | needs branch -- $needsBrandOrBranchName');
    // _prefillGuestData();
  }

  /// Pre-fills the business name + logo from the existing guest user (if any)
  /// so a guest upgrading to a business account doesn't re-enter what they
  /// already gave. Best-effort only — any failure leaves the fields empty and
  /// the normal manual-entry flow is unaffected. Skipped when GST auto-fill is
  /// active so it never overrides the verified trade name / logo.
  // Future<void> _prefillGuestData() async {
  //   final guest = await authController.getGuestUserDetail();
  //   if (!mounted || guest?.user == null) return;
  //
  //   final name = guest!.user?.name ?? '';
  //   if (name.isNotEmpty &&
  //       !authController.isHaveGstApprove.value &&
  //       authController.businessNameTextController.text.trim().isEmpty) {
  //     authController.businessNameTextController.text = name;
  //     authController.businessName.value = name;
  //   }
  //
  //   final imageUrl = guest.user?.profileImage ?? '';
  //   if (imageUrl.isNotEmpty && (_imagePath?.isEmpty ?? true)) {
  //     final localPath = await downloadImageToTempFile(imageUrl);
  //     if (!mounted || localPath == null) return;
  //     setState(() {
  //       _imagePath = localPath;
  //       UserSession().imagePath = localPath;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
      ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.only(
                  left: SizeConfig.size8,
                  right: SizeConfig.size8,
                  top: SizeConfig.size15,
                  bottom: SizeConfig.size40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Business logo
                    CustomFormCard(
                        child: Column(
                      children: [
                        InkWell(
                          onTap: () => _selectImage(context),
                          child: Container(
                            padding: EdgeInsets.all(SizeConfig.size2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1.0,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.whiteF3,
                              child: _imagePath?.isNotEmpty == true
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image(
                                        image: FileImage(File(_imagePath!))
                                          ..evict(),
                                      ),
                                    )
                                  : LocalAssets(
                                      imagePath: AppIconAssets.user_out_line,
                                      imgColor: AppColors.secondaryTextColor,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: SizeConfig.size8),
                        InkWell(
                          onTap: () => _selectImage(context),
                          child: CustomText(
                            AppStrings.uploadYourPhotoLogo,
                            color: AppColors.mainTextColor,
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    )),

                    /// Category and Sub Category
                    if(authController.selectedTypeOfBusiness != BusinessType.Both)
                    ...[
                      SizedBox(
                        height: SizeConfig.paddingXSL,
                      ),
                      CustomFormCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                  AppStrings.youHaveChosen,
                                  fontSize: SizeConfig.large,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mainTextColor
                              ),
                              SizedBox(
                                height: SizeConfig.paddingS,
                              ),
                              Container(
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10.0)
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CustomText(
                                            "Business - ",
                                            color: AppColors.secondaryTextColor,
                                            fontSize: SizeConfig.small,
                                            fontWeight: FontWeight.w400
                                        ),
                                        Expanded(
                                          child: CustomText(
                                              authController.selectedTypeOfBusiness?.name,
                                              color: AppColors.primaryColor,
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400
                                          ),
                                        )
                                      ],
                                    ),
                                    SizedBox(height: SizeConfig.paddingXSmall),
                                    Row(
                                      children: [
                                        CustomText(
                                            "${AppStrings.category.tr} - ",
                                            color: AppColors.secondaryTextColor,
                                            fontSize: SizeConfig.small,
                                            fontWeight: FontWeight.w400
                                        ),
                                        Expanded(
                                          child: CustomText(
                                              authController.selectedCategoryName?.replaceAll('\n', ' '),
                                              color: AppColors.primaryColor,
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400
                                          ),
                                        )
                                      ],
                                    ),

                                    if(authController.selectedSubCategoryData!=null)...[
                                      SizedBox(height: SizeConfig.paddingXSmall),
                                      Row(
                                        children: [
                                          CustomText(
                                              "${AppStrings.subCategory.tr} - ",
                                              color: AppColors.secondaryTextColor,
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400
                                          ),
                                          Expanded(
                                            child: CustomText(
                                                authController.selectedSubCategoryData?.name,
                                                color: AppColors.primaryColor,
                                                fontSize: SizeConfig.small,
                                                fontWeight: FontWeight.w400
                                            ),
                                          )
                                        ],
                                      ),
                                    ]

                                  ],
                                ),
                              ),


                              // RichText(
                              //   text: TextSpan(
                              //     style: TextStyle(
                              //         color: AppColors.secondaryTextColor, // Default grey text
                              //         fontSize: SizeConfig.small,
                              //         fontWeight: FontWeight.w400
                              //     ),
                              //     children: [
                              //       TextSpan(text: "${AppStrings.category.tr} - "),
                              //       TextSpan(
                              //         text: authController.selectedCategoryData?.name,
                              //         style: TextStyle(
                              //             color: AppColors.primaryColor, // Default grey text
                              //             fontSize: SizeConfig.small,
                              //             fontWeight: FontWeight.w400
                              //         ),
                              //       ),
                              //       TextSpan(text: "  >  ${AppStrings.subCategory.tr} - "),
                              //       TextSpan(
                              //         text: authController.selectedSubCategoryData?.name,
                              //         style:  TextStyle(
                              //             color: AppColors.primaryColor, // Default grey text
                              //             fontSize: SizeConfig.small,
                              //             fontWeight: FontWeight.w400
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),


                              // SizedBox(
                              //   height: SizeConfig.paddingM,
                              // ),


                              /// Business Specialization
                              // CommonTextField(
                              //   textEditController: authController
                              //       .subCategorySpecializationTextController,
                              //   hintText:AppStrings.businessSpecializationHint,
                              //   title: AppStrings.businessSpecializationOptional,
                              //   maxLine: 1,
                              //   maxLength: 24,
                              //   keyBoardType: TextInputType.text,
                              //   textInputAction: TextInputAction.done,
                              //   isValidate: false,
                              //   inputFormatters: [
                              //     FilteringTextInputFormatter.allow(RegExp(
                              //         RegularExpressionUtils
                              //             .alphabetPatternSpace)),
                              //     NoLeadingSpaceFormatter(),
                              //     NoConsecutiveSpacesFormatter(),
                              //   ],
                              //   // we will handle validation manually
                              //   onChange: (val) {
                              //     String newVal = val;
                              //     authController
                              //         .categorySpecializationText.value = val;
                              //     // Allow only alphabets + spaces
                              //     if (!RegExp(r'^[a-zA-Z ]*$')
                              //         .hasMatch(newVal)) {
                              //       authController.errorMessage.value =
                              //           AppStrings.specialCharactersNotAllowed.tr;
                              //     } else if (newVal.isEmpty) {
                              //       authController.errorMessage.value =
                              //           AppStrings.pleaseEnterBusinessSpecialization.tr;
                              //     } else if (newVal.length < 8) {
                              //       authController.errorMessage.value =
                              //           AppStrings.min8CharactersRequired.tr;
                              //     } else if (newVal.length > 24) {
                              //       authController.errorMessage.value =
                              //           AppStrings.max24CharactersAllowed.tr;
                              //     } else {
                              //       authController.errorMessage.value = "";
                              //     }
                              //
                              //   },
                              // ),

                              // SizedBox(height: SizeConfig.size5),
                              //
                              // // 👇 Error/Helper Message
                              // Obx(() => authController
                              //     .errorMessage.value.isNotEmpty &&
                              //     (authController.categorySpecializationText
                              //         .value.isNotEmpty)
                              //     ? Align(
                              //   alignment: Alignment.centerLeft,
                              //   child: CustomText(
                              //     authController.errorMessage.value,
                              //     color: Colors.red,
                              //     fontSize: 12,
                              //     textAlign: TextAlign.left,
                              //   ),
                              // )
                              //     : SizedBox()),
                              //
                              // // 👇 Counter (bottom right)
                              // Align(
                              //   alignment: Alignment.centerRight,
                              //   child: Obx(() => CustomText(
                              //     "${authController.categorySpecializationText.value.length}/24",
                              //     color: Colors.grey,
                              //     fontSize: 12,
                              //   )),
                              // ),

                            ],
                          )
                      ),
                    ],

                    SizedBox(
                      height: SizeConfig.paddingXSL,
                    ),

                    /// Business Details
                    CustomFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            AppStrings.businessDetailsTitle,
                            fontSize: SizeConfig.extraLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainTextColor
                          ),
                          SizedBox(
                            height: SizeConfig.paddingS,
                          ),

                          ///ENTER ORG/COMPANY NAME...
                          Obx(() {
                            return IgnorePointer(
                              ignoring: (authController.isHaveGstApprove.value) ? true : false,
                              child: CommonTextField(
                                textEditController:
                                authController.businessNameTextController,
                                // inputLength: AppConstants.inputCharterLimit30,
                                maxLength: AppConstants.inputCharterLimit30,
                                keyBoardType: TextInputType.text,
                                regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,

                                title: AppStrings.businessName,
                                hintText: AppConstants.businessName,
                                isValidate: true,
                                onChange: (val) {
                                  authController.businessName.value = val;
                                  setState(() {});
                                },

                                validator: (value) {
                                  if (authController.businessName.value.isEmpty) {
                                    return AppStrings.enterBusinessName.tr;
                                  } else if (authController.businessName.value.length <
                                      5) {
                                    return AppStrings.minFiveCharactersRequired.tr;
                                  }
                                  return null;
                                },
                              ),
                            );
                          }),
                          SizedBox(
                            height: SizeConfig.paddingXSL,
                          ),
                          if (!authController.isHaveGstApprove.value)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Obx(() => CustomText(
                                "${authController.businessName.value.length}/${AppConstants.inputCharterLimit30}",
                                color: AppColors.grey9B,
                                fontSize: SizeConfig.small,
                              )),
                            ),

                          /// BRAND / BRANCH NAME (GST-verified or Finance)
                          if (needsBrandOrBranchName) ...[
                            SizedBox(
                              height: SizeConfig.paddingM,
                            ),
                            CommonTextField(
                              textEditController: authController
                                  .brandOrBranchNameTextController,
                              maxLength:
                                  ValidationMethod.brandOrBranchNameMaxLength,
                              isCounterVisible: true,
                              keyBoardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              title: AppStrings.brandOrBranchName,
                              hintText: AppStrings.brandOrBranchNameHint,
                              autovalidateMode: _autoValidate,
                              // Passing `inputFormatters` REPLACES the widget's
                              // default list, so the leading/consecutive-space
                              // rules are re-stated here — they are what keeps
                              // words to a single separating space.
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(
                                    RegularExpressionUtils
                                        .brandOrBranchNamePattern)),
                                // UppercaseTextFormatter(),
                                NoLeadingSpaceFormatter(),
                                NoConsecutiveSpacesFormatter(),
                                LengthLimitingTextInputFormatter(
                                    ValidationMethod.brandOrBranchNameMaxLength),
                              ],
                              validator:
                                  ValidationMethod.validateBrandOrBranchName,
                            ),
                            CustomText(
                              AppStrings.brandOrBranchNameHelper,
                              fontSize: SizeConfig.small,
                              color: AppColors.grey9B,
                            ),
                          ],

                          SizedBox(
                            height: SizeConfig.paddingM,
                          ),

                          ///DOB selection
                          CustomText(
                            AppStrings.dateOfIncorporation,
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor
                          ),
                          SizedBox(
                            height: SizeConfig.paddingXSL,
                          ),
                          Obx(() {
                            return IgnorePointer(
                              ignoring:
                              (authController.isHaveGstApprove.value) ? true : false,
                              child: NewDatePicker(
                                selectedDay: authController.selectedDay?.value,
                                selectedMonth: authController.selectedMonth?.value,
                                selectedYear: authController.selectedYear?.value,
                                onDayChanged: (value) {
                                  authController.selectedDay?.value = value ?? 0;
                                },
                                onMonthChanged: (value) {
                                  authController.selectedMonth?.value = value ?? 0;
                                },
                                onYearChanged: (value) {
                                  authController.selectedYear?.value = value ?? 0;
                                },
                              ),
                            );
                          }),

                          if (authController.selectedTypeOfBusiness == BusinessType.Product) ...[
                            SizedBox(
                              height: SizeConfig.paddingM,
                            ),
                            CustomText(
                              AppStrings.natureOfBusiness,
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor
                            ),
                            SizedBox(
                              height: SizeConfig.paddingXSL,
                            ),
                            CommonDropdownDialog<NatureOfBusiness>(
                              items: NatureOfBusiness.values,
                              selectedValue: authController.selectedNatureOfBusiness,
                              hintText: AppStrings.selectNatureOfBusiness,
                              displayValue: (profession) => profession.displayName,
                              title: AppStrings.natureOfBusiness,
                              onChanged: (value) {
                                setState(() {
                                  authController.selectedNatureOfBusiness = value;
                                });
                              },
                            ),
                            if (authController.selectedNatureOfBusiness == NatureOfBusiness.OTHERS) ...[
                              SizedBox(height: SizeConfig.size20),
                              CommonTextField(
                                textEditController:
                                authController.otherNatureOfBusinessTextController,
                                inputLength: AppConstants.inputCharterLimit100,
                                keyBoardType: TextInputType.text,
                                regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                                titleColor: Colors.black,
                                hintText: AppStrings.pleaseSpecifyIfOther,
                                autovalidateMode: _autoValidate,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppStrings.enterOtherNatureOfBusiness.tr;
                                  }
                                  return null;
                                },
                              ),
                            ],

                            // SizedBox(height: SizeConfig.paddingL),
                          ],

                          if (isServiceOrManufacturing) ...[

                            // Number Of Employees
                            SizedBox(
                              height: SizeConfig.paddingM,
                            ),
                            CustomText(
                              AppStrings.numberOfEmployees,
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor
                            ),
                            SizedBox(
                              height: SizeConfig.paddingXSL,
                            ),
                            CommonDropdownDialog<String>(
                              items: authController.employeeRangeOptions,
                              selectedValue: authController.selectedNumberOfEmployees,
                              hintText: AppStrings.numberOfEmployeesHintText,
                              displayValue: (v) => v,
                              title: AppStrings.numberOfEmployees,
                              onChanged: (value) {
                                setState(() {
                                  authController.selectedNumberOfEmployees = value;
                                });
                              },
                            ),

                            // Number Of Branch
                            SizedBox(
                              height: SizeConfig.paddingM,
                            ),
                            CustomText(
                              AppStrings.numberOfBranchOrUnit,
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor
                            ),
                            SizedBox(
                              height: SizeConfig.paddingXSL,
                            ),
                            CommonDropdownDialog<String>(
                              items: authController.branchUnitOptions,
                              selectedValue: authController.selectedNumberOfBranch,
                              hintText: AppStrings.numberOfBranchOrUnitHintText,
                              displayValue: (v) => v,
                              title: AppStrings.numberOfBranchOrUnit,
                              onChanged: (value) {
                                setState(() {
                                  authController.selectedNumberOfBranch = value;
                                });
                              },
                            ),

                          ],

                          /// MEDICAL STORE / SHOP LICENSE (Pharmacy only)
                          if (isPharmacyCategory) ...[
                            SizedBox(
                              height: SizeConfig.paddingM,
                            ),
                            CommonTextField(
                              textEditController: authController
                                  .medicalStoreLicenseTextController,
                              maxLength: AppConstants.inputCharterLimit30,
                              keyBoardType: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              title: AppStrings.medicalStoreLicenseNumber,
                              hintText: AppStrings.medicalStoreLicenseNumberHint,
                              autovalidateMode: _autoValidate,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(
                                    RegularExpressionUtils
                                        .medicalStoreLicensePattern)),
                                UppercaseTextFormatter(),
                                NoLeadingSpaceFormatter(),
                                NoConsecutiveSpacesFormatter(),
                                LengthLimitingTextInputFormatter(
                                    AppConstants.inputCharterLimit30),
                              ],
                              validator:
                                  ValidationMethod.validateMedicalStoreLicense,
                            ),
                          ],


                          SizedBox(
                            height: SizeConfig.size20,
                          ),


                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Material(
          elevation: 8.0,
          child: Container(
            color: AppColors.white,
            child: Padding(
                    padding: EdgeInsets.symmetric(
                 horizontal: SizeConfig.size15,
                        vertical: SizeConfig.size15),
                    child: SafeArea(
                      child: Obx(() {
                        final loading = authController
                                .addUserResponse.value.status ==
                            Status.LOADING;
                        return SizedBox(
                          width: double.infinity,
                          height: SizeConfig.size44,
                          child: ElevatedButton.icon(
                            onPressed: loading ? null : _onSubmit,
                            icon: loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            label: Text(
                              loading
                                  ? '${AppStrings.submit.tr}…'
                                  : AppStrings.submit.tr,
                              style: TextStyle(
                                fontFamily: AppConstants.OpenSans,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              disabledBackgroundColor: AppColors.primaryColor
                                  .withValues(alpha: 0.5),
                              padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size12,
                                horizontal: SizeConfig.size16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    SizeConfig.size8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
          ),
        ),
    );
  }

  Future<void> _selectImage(BuildContext context) async {
    final String? selected = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.uploadProfilePicture,
    );

    if (selected?.isNotEmpty ?? false) {
      _imagePath = selected;
      UserSession().imagePath = selected;
      setState(() {});
    }
  }

  final locationController = Get.put(LocationController());

  Future<void> _onSubmit() async {
    if (_imagePath?.isEmpty ?? true) {
      _selectImage(context);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
      return;
    }

    if (isServiceOrManufacturing) {
      if (authController.selectedNumberOfEmployees == null) {
        commonSnackBar(message: AppStrings.pleaseEnterNumberOfEmployees.tr);
        return;
      }if (authController.selectedNumberOfBranch == null) {
        commonSnackBar(message: AppStrings.pleaseEnterNumberOfBranchOrUnit.tr);
        return;
      }
    }

    print("Selected Business Type: ${authController.selectedTypeOfBusiness}");

    // 2️⃣ Business name required
    if (authController.businessNameTextController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.pleaseEnterBusinessName.tr);
    return;
    }

    // ---------- FILE + REQUEST BELOW NO CHANGE ----------
    final imageFile = (UserSession().imagePath != null)
        ? File(UserSession().imagePath!)
        : null;

    dio.MultipartFile? imageByPart;
    if (imageFile?.path.isNotEmpty ?? false) {
      String fileName = imageFile?.path.split('/').last ?? "";
      imageByPart = await dio.MultipartFile.fromFile(
        imageFile!.path,
        filename: fileName,
      );
    }
    final locationData = await locationController.checkPermissionAndSetData(
      preferNativeGeocoding: true,
    );
    if (locationData != null) {
      log("Business Type    : ${authController.selectedTypeOfBusiness}");
      log("Category Slug Id  : ${authController.selectedCategorySlugId}");
      log('sub category --- ${authController.selectedSubCategoryData?.sId}');
      Map<String, dynamic> requestData = {
        ApiKeys.logo_image: imageByPart,
        ApiKeys.business_name: authController.businessNameTextController.text,
        ApiKeys.business_location: jsonEncode({
          ApiKeys.lat: locationData.lat.toString(),
          ApiKeys.lon: locationData.long.toString(),
        }),
        ApiKeys.pincode: locationData.pinCode,
        ApiKeys.address: locationData.fullAddress,
        ApiKeys.type_of_business: authController.selectedTypeOfBusiness?.name,
        ApiKeys.nature_of_business: authController.selectedNatureOfBusiness?.name,
        ApiKeys.type: authController.selectedCategorySlugId,
        ApiKeys.date_of_incorporation: {
          ApiKeys.date: authController.selectedDay?.value,
          ApiKeys.month: authController.selectedMonth?.value,
          ApiKeys.year: authController.selectedYear?.value
        },
        // Category logic based on "both"
        // ApiKeys.category_Of_Business:
        //     (authController.selectedTypeOfBusiness == BusinessType.Both)
        //         ? "68a80b766fdb4e82b42b77c0"
        //         : authController.selectedCategoryData?.id,
        ApiKeys.category_Of_Business: authController.selectedCategorySlugId,
        if (authController.selectedTypeOfBusiness == BusinessType.Both)
          ApiKeys.category_other:
              authController.businessOtherCategoryTextController.text,

        if (authController.selectedSubCategoryData?.sId?.isNotEmpty ?? false)
          ApiKeys.sub_category_Of_Business: authController.selectedSubCategoryData?.sId,

        if ((authController.gstVerifyModel?.value.success ?? false) &&
            (authController.gstVerifyModel?.value.data?.gstin?.isNotEmpty ??
                false))
          ApiKeys.gst_have: true,

        if ((authController.gstVerifyModel?.value.success ?? false) &&
            (authController.gstVerifyModel?.value.data?.gstin?.isNotEmpty ??
                false))
          ApiKeys.gst_number: authController.gstVerifyModel?.value.data?.gstin,

        // Brand / branch name. Sent whenever it was collected — for a GST
        // business it is half of the (GST number + branch) uniqueness key the
        // backend enforces, and for a Finance business the profile is rejected
        // without it. See docs/finance-gst-branch-ui-integration.md §1/§4.
        if (needsBrandOrBranchName)
          ApiKeys.branch:
              authController.brandOrBranchNameTextController.text.trim(),

        if (isPharmacyCategory)
          ApiKeys.license_number:
              authController.medicalStoreLicenseTextController.text.trim(),
        ApiKeys.gst_verified: ((authController.gstVerifyModel?.value.success ??
                    false) &&
                (authController.gstVerifyModel?.value.data?.gstin?.isNotEmpty ??
                    false))
            ? true
            : false,

        if(isServiceOrManufacturing && authController.selectedNumberOfEmployees!=null)
         ApiKeys.number_of_Employees: authController.selectedNumberOfEmployees,

        if(isServiceOrManufacturing && authController.selectedNumberOfBranch!=null)
         ApiKeys.number_of_branch: authController.selectedNumberOfBranch,


        // if (authController
        //     .subCategorySpecializationTextController.text.isNotEmpty)
        //   ApiKeys.specification:
        //       authController.subCategorySpecializationTextController.text.trim(),
      };

      await authController.addBusinessUser(reqData: requestData);
    } else {
      commonSnackBar(
          message:
              AppStrings.enableLocationPermission.tr);
      return;
    }
  }
}
