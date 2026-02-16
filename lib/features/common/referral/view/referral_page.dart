import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/common/referral/view/widgets/join_as_bdm_screen.dart';
import 'package:BlueEra/features/common/referral/view/widgets/join_bdm_document_verified_page.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/regular_expression.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../business/auth/controller/view_business_details_controller.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../../../personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import '../../../personal/personal_profile/view/my_documents/widget/generic_document_widget.dart';
import '../auth/model/referral_get_bdm_details_model.dart';
import '../controller/referral_controller.dart';


class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final controller = getOrPut(() => ReferralController());
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController());
  final viewBusinessProfileController = getOrPut(() =>
      ViewBusinessDetailsController());

  String referralCode() {
    if (accountTypeGlobal != "BUSINESS") {
      return viewProfileController
          .personalProfileDetails.value.user?.referral_code ?? '';
    } else {
      return
        viewBusinessProfileController.businessProfileDetails?.data
            ?.referral_code ?? "";
    }
  }

  String referralPoint() {
    if (accountTypeGlobal != "BUSINESS") {
      return viewProfileController
          .personalProfileDetails.value.user?.referral_points ?? '';
    } else {
      return
        viewBusinessProfileController.businessProfileDetails?.data
            ?.referral_points ?? "";
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadDetails();
  }

  void setReferral() {
    controller.mainReferralCode.text = referralCode();
  }

  void loadDetails() async {
    setReferral();

    await controller.getBdmDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Refer & Earn (Become BlueEra Assistant)",
        isShadowShow: false,
      ),
      body: Obx(() {
        ReferralGetBdmDetailsModel details = controller.referralBdmDetails
            .value;
        print("lsdkml;ksdmsdlf ${details.isReferralCodeSaved}");

        return
        //   (details.panDocumentUploaded==true
        //     &&details.aadharDocumentUploaded==true&&
        //     details.bankDetailsDocumentUploaded==true)?JoinBdmDocumentVerifiedPage(
        //   isEditable: details.isReferralCodeSaved??false,
        //   referralCode: referralCode(),
        // ):
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: (!(details.isPersonalInfoComplete ?? false))
                    ? SizeConfig.size250
                    : SizeConfig.size210,
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),

                    color: AppColors.white
                ),
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    Container(
                      height: 170,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.whiteE5
                      ),
                      child: Center(
                        child: Container(
                          height: SizeConfig.size50,
                          width: SizeConfig.size50,
                          decoration: BoxDecoration(
                            color: AppColors.black65,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_arrow,
                              color: AppColors.white,
                              size: SizeConfig.size30),
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),
                    if(!(details.isPersonalInfoComplete ?? false))
                      InkWell(
                        onTap: () {
                          Get.to(JoinAsBDMScreen());
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.primaryColor
                              )
                          ),
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: CustomText(
                              "Join As Business Development Manager (BDM)",
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,),
                          ),
                        ),
                      )
                  ],
                ),
              ),
              if(details.isPersonalInfoComplete ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      SizedBox(height: 10,),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white
                        ),
                        padding: EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.greenShade,),
                                SizedBox(width: 10,),
                                CustomText("Personal Details",
                                  color: AppColors.greenShade,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,)
                              ],
                            ),
                            SizedBox(height: 16,),
                            InkWell(
                              onTap: (){
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.aadharCard,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.aadhar,
                                      uploadSectionLabel:
                                      AppStrings.uploadAadharBothSide,
                                      backImage: true,
                                      textFieldLabel:
                                      'Enter Aadhaar Number',
                                      textFieldHint: 'E.g. 5678 1234 6679 9012',
                                      textFieldValidation:
                                      ValidationMethod.validateAadhaar,
                                      maxLength: 12,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                              child: Row(
                                children: [
                                  (details.aadharDocumentUploaded??false)?
                                  Icon(Icons.check_circle, color: AppColors.greenShade,):
                                  Icon(Icons.add, color: AppColors.primaryColor,),
                                  SizedBox(width: 10,),
                                  CustomText("Upload Aadhaar Card",
                                    color:
                                    (details.aadharDocumentUploaded??false)?
                                    AppColors.greenShade:AppColors.primaryColor,

                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,)
                                ],
                              ),
                            ),
                            SizedBox(height: 16,),
                            InkWell(
                              onTap: (){
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.panCard,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.pan,
                                      uploadSectionLabel: AppStrings.uploadPan,
                                      backImage: false,
                                      textFieldLabel: AppStrings.panNumber,
                                      textFieldHint: 'E.g. ABCDE1234F',
                                      textFieldValidation:
                                      ValidationMethod.validatePAN,
                                      maxLength: 10,
                                      keyboardType: TextInputType.text,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                              child: Row(
                                children: [
                                  (details.panDocumentUploaded??false)?
                                  Icon(Icons.check_circle, color: AppColors.greenShade,):
                                  Icon(Icons.add, color: AppColors.primaryColor,),
                                  SizedBox(width: 10,),
                                  CustomText("Upload Pan Card",
                                    color:       (details.panDocumentUploaded??false)?
                                    AppColors.greenShade:AppColors.primaryColor,

                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,)
                                ],
                              ),
                            ),
                            SizedBox(height: 16,),
                            // Row(
                            //   children: [
                            //     (details.addressProofDocumentUploaded??false)?
                            //     Icon(Icons.check_circle, color: AppColors.greenShade,):
                            //     Icon(Icons.add, color: AppColors.primaryColor,),
                            //     SizedBox(width: 10,),
                            //     CustomText("Upload Address Proof",
                            //       color: (details.addressProofDocumentUploaded??false)?
                            //       AppColors.greenShade:AppColors.primaryColor,
                            //       fontSize: 16,
                            //       fontWeight: FontWeight.w600,)
                            //   ],
                            // ),
                            // SizedBox(height: 16,),
                            InkWell(
                              onTap: (){
                                Get.toNamed(
                                    RouteHelper.getAddBankAccountScreenRoute());
                              },
                              child: Row(
                                children: [
                                  (details.bankDetailsDocumentUploaded??false)?
                                  Icon(Icons.check_circle, color: AppColors.greenShade,):
                                  Icon(Icons.add, color: AppColors.primaryColor,),
                                  SizedBox(width: 10,),
                                  CustomText("Upload Bank Details",
                                    color: (details.bankDetailsDocumentUploaded??false)?
                                    AppColors.greenShade:AppColors.primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,)
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    SizedBox(height: 10,),
                    GenerateReferralCodeCard(
                      isEditable: details.isReferralCodeSaved??false,
                      referralCode: '${referralCode()}',),
                    SizedBox(height: 10,),

                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.white
                      ),
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 6,
                          ),
                          Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  CustomText("Balance", fontSize: 16,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  SizedBox(
                                    height: 16,
                                  ),
                                  CustomText("₹ 10,000", fontSize: 20,
                                    color: AppColors.secondaryTextColor,

                                    fontWeight: FontWeight.w800,)
                                ],
                              ),
                              SizedBox(
                                width: 46,
                              ),
                              Container(
                                height: 70,
                                width: 1,
                                color: AppColors.whiteE5,
                              ),
                              SizedBox(
                                width: 46,
                              ),
                              Column(
                                children: [
                                  CustomText("Balance", fontSize: 16,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  SizedBox(
                                    height: 16,
                                  ),
                                  CustomText("₹ 10,000", fontSize: 20,
                                    color: AppColors.secondaryTextColor,

                                    fontWeight: FontWeight.w800,)
                                ],
                              ),
                            ],
                          ),


                        ],
                      ),
                    ),


                    // _referralSummaryCard(),
                    // SizedBox(height: SizeConfig.size20),
                    // CustomText(
                    //   AppStrings.referredPersons,
                    //   fontSize: 16,
                    //   fontWeight: FontWeight.w600,
                    // ),
                    // SizedBox(height: SizeConfig.size12),
                    // Center(
                    //   child: CustomText("No Referral Record Found"),
                    // )
                  ],
                ),
              ),


            ],
          ),
        );
      }),
    );
  }


  Widget _referredUserCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, size: 28),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "User Name",
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  "Referred on 12 Nov 2025",
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ],
            ),
          ),
          CustomText(
            "+10 pts",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          )
        ],
      ),
    );
  }
}

class GenerateReferralCodeCard extends StatelessWidget {
  const GenerateReferralCodeCard(
      {super.key, required this.referralCode, this.isEditable});

  final String referralCode;
  final bool? isEditable;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => ReferralController());
    final  referralFormKey = GlobalKey<FormState>();
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.white
      ),
      padding: EdgeInsets.all(14),
      child: Form(
        key: referralFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LocalAssets(imagePath: AppIconAssets.multiPersonsIcon,
                  imgColor: AppColors.secondaryTextColor,),
                SizedBox(width: 6,),
                CustomText("Generate Your Referral Code", fontSize: 16,
                  color: AppColors.secondaryTextColor,
                )
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Obx(() {
              return CommonTextField(
                fontSize: 14,
                readOnly: !controller.makeReferralEditable.value,
                textEditController: controller.mainReferralCode,
                focusNode: controller.referralFocusNode,
                isValidate: false,
                hintText: "Enter Your Referral Code",
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Referral code cannot be empty";
                  }
                  if (value.trim().length < 6) {
                    return "Referral code must be 6 characters";
                  }
                  if (value.trim().length > 6) {
                    return "Referral code must be 6 characters";
                  }
                  return null;
                },
                sIcon: (isEditable == false) ?
                IconButton(onPressed: () {
                  controller.makeReferralEditable.value = true;
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (controller.makeReferralEditable.value) {
                      controller.referralFocusNode.requestFocus();
                    }
                  });
                }, icon:
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: LocalAssets(imagePath: AppIconAssets.editIcon,
                    imgColor: AppColors.secondaryTextColor,),
                )
                ) :
                IconButton(onPressed: () {
                  Clipboard.setData(ClipboardData(text:  controller.mainReferralCode.text));
                  commonSnackBar(message: "Referral copied to clipboard");
                }, icon:
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      // slightly smaller than outer
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor.withOpacity(0.06),
                          AppColors.primaryColor.withOpacity(0.02),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: Row(
                          children: [
                            Icon(Icons.copy, color: AppColors.primaryColor,),
                            SizedBox(width: 6,),
                            CustomText("Copy",
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,)
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                )

                ,
              );
            }),

            SizedBox(height: 10,),
            if(isEditable == false)
              Row(mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(() {
                    return CustomBtn(
                        width: 100,
                        height: 40,
                        radius: 14,
                        isLoading: controller.updateNewCodeLoading.value,
                        isValidate: true,
                        onTap: () async {
                          if(referralFormKey.currentState!.validate()){
                            await controller.saveNewReferralCodeApi();
                          }
                        },
                        title: "Submit");
                  })
                ],
              )

          ],
        ),
      ),
    );
  }
}
