import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/model/referral_get_bdm_details_model.dart';
import 'package:BlueEra/features/common/referral/view/bdm_document_verified_page.dart';
import 'package:BlueEra/features/common/referral/view/bdm_id_card_page.dart';
import 'package:BlueEra/features/common/referral/view/join_as_bdm_screen.dart';
import 'package:BlueEra/features/common/referral/widgets/generate_referral_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/view/add_document_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/cancel_cheque_document_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_divider.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import '../../../../widgets/custom_text_cm.dart';
import '../../../business/auth/controller/view_business_details_controller.dart';
import '../../../personal/auth/controller/view_personal_details_controller.dart';
import '../../../personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import '../../../personal/personal_profile/view/my_documents/widget/generic_document_widget.dart';
import '../controller/referral_controller.dart';


class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final controller = getOrPut(() => ReferralController());
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final viewBusinessProfileController = getOrPut(() =>
      ViewBusinessDetailsController(), permanent: true);
  final myDocumentsController = getOrPut(() => MyDocumentsController());

  String referralCode() {
    if (accountTypeGlobal != "BUSINESS") {
      return viewProfileController
          .personalProfileDetails.value.user?.referral_code ?? '';
    } else {
      return
        viewBusinessProfileController.businessProfileDetails.value?.data
            ?.referral_code ?? "";
    }
  }

  @override
  void initState() {
    super.initState();
    controller.referralSuggestionsApi();
    loadDetails();
  }

  void loadDetails() async {
    // controller.mainReferralCode.text = referralCode();
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
        if(controller.referralBdmDetailsResponse.value.status == Status.INITIAL){
          return Center(
              child: CircularProgressIndicator()
          );
        }

        ReferralGetBdmDetailsModel details = controller.referralBdmDetails.value;
        String status = details.status ?? 'NOT_STARTED';
        print('bdm status -- $status');

        if(status == 'COMPLETED')
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size15,
                  SizeConfig.paddingXSL,
                  SizeConfig.size15,
                  0,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Get.to(() => const BdmIdCardPage()),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size12,
                      vertical: SizeConfig.size10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            color: AppColors.primaryColor),
                        SizedBox(width: SizeConfig.size8),
                        Expanded(
                          child: CustomText(
                            "View My BlueEra ID Card",
                            fontSize: SizeConfig.medium,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: AppColors.primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: BdmDocumentVerifiedPage()),
            ],
          );
        else
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomFormCard(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  children: [
                    HorizontalVideoPlayer(),

                    SizedBox(height: SizeConfig.paddingXSL),

                    // Step one for adding personal details
                    (status == 'NOT_STARTED')
                     ? Align(
                      alignment: Alignment.centerRight,
                       child: InkWell(
                          onTap: () {
                            Get.to(()=> JoinAsBDMScreen());
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.primaryColor
                                )
                            ),
                            padding: EdgeInsets.all(10,),
                            child: CustomText(
                              "Join As Business Development Manager (BDM)",
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,),
                          ),
                        ),
                     )
                     : SizedBox()
                  ],
                ),
              ),

              // Step two once personal details fill
              if(status == 'PENDING')
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      SizedBox(height: SizeConfig.paddingXSL),
                      CustomFormCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  left: SizeConfig.size10,
                                  right: SizeConfig.size10,
                                  top: SizeConfig.size15,
                                  bottom: SizeConfig.size8,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  LocalAssets(
                                    imagePath: AppIconAssets.green_tick_icon,
                                    height: 20,
                                    width: 20,
                                  ),
                                  SizedBox(width: SizeConfig.size8),
                                  CustomText(
                                    "Personal Details",
                                    fontWeight: FontWeight.w400,
                                    fontSize: SizeConfig.large,
                                    color: AppColors.secondaryTextColor,
                                  )
                                ],
                              ),
                            ),

                            // Aadhaar
                            _buildDocumentButton(
                              title: AppStrings.uploadAadhar,
                              document: DocumentKeys.aadhar,
                              status: myDocumentsController.getStatus(DocumentKeys.aadhar),
                              onTap: () {

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
                                        cropAspectRatio: const CropAspectRatio(width: 4, height: 3)
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),

                            // Pan
                            _buildDocumentButton(
                              title: AppStrings.uploadPan,
                              document: DocumentKeys.pan,
                              status: myDocumentsController.getStatus(DocumentKeys.pan),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.panCard,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.pan,
                                      uploadSectionLabel: AppStrings.uploadPan,
                                      isCapitalize: true,
                                      backImage: false,
                                      textFieldLabel: AppStrings.panNumber,
                                      textFieldHint: 'E.g. ABCDE1234F',
                                      textFieldValidation:
                                      ValidationMethod.validatePAN,
                                      maxLength: 10,
                                      keyboardType: TextInputType.text,
                                        cropAspectRatio: const CropAspectRatio(width: 4, height: 3)
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,

                                );
                              },
                            ),

                            // Address Proof
                            // _buildDocumentButton(
                            //   title: AppStrings.uploadAddressProof,
                            //   document: DocumentKeys.addressProof,
                            //   status: myDocumentsController.getStatus(DocumentKeys.addressProof),
                            //   onTap: () {
                            //     Get.bottomSheet(
                            //       CommonDocumentBottomSheet(
                            //         title: AppStrings.addressProof,
                            //         child: GenericDocumentWidget(
                            //           documentType: DocumentKeys.addressProof,
                            //           uploadSectionLabel:
                            //           'Upload Front and Back Images',
                            //           backImage: true,
                            //           textFieldLabel: 'Name of ID',
                            //           textFieldHint:
                            //           'E.g. Voter ID, Gas Bill...',
                            //           textFieldValidation:
                            //           ValidationMethod.validateName,
                            //           maxLength: 24,
                            //           keyboardType: TextInputType.text,
                            //         ),
                            //       ),
                            //       isScrollControlled: true,
                            //       backgroundColor: Colors.transparent,
                            //     );
                            //   },
                            // ),

                            // Bank Cancel Cheque

                            // _buildDocumentButton(
                            //   title: AppStrings.uploadBankerCancelCheck,
                            //   document: DocumentKeys.bankersCancelledCheque,
                            //   status: myDocumentsController.getStatus(
                            //       DocumentKeys.bankersCancelledCheque),
                            //   onTap: () {
                            //     Get.bottomSheet(
                            //       CommonDocumentBottomSheet(
                            //         title: "Cancelled Cheque",
                            //         child: CancelChequeDocumentWidget(
                            //             documentType: DocumentKeys
                            //                 .bankersCancelledCheque),
                            //       ),
                            //       isScrollControlled: true,
                            //       backgroundColor: Colors.transparent,
                            //     );
                            //   },
                            // ),

                            SizedBox(height: SizeConfig.size8),

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
                    SizedBox(height: SizeConfig.paddingXSL),

                    // While the user hasn't started the BDM application,
                    // any tap on the referral section should funnel them
                    // back to the JoinAsBDM screen — IgnorePointer disables
                    // the inner controls and the outer GestureDetector
                    // catches the tap as a single CTA.
                    if (status == 'NOT_STARTED')
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Get.to(() => JoinAsBDMScreen()),
                        child: IgnorePointer(
                          child: GenerateReferralSection(
                            controller: controller,
                            isEligible: false,
                            initialText: '* * * * * *',
                          ),
                        ),
                      )
                    else
                      GenerateReferralSection(
                        controller: controller,
                        isEligible:
                            (status == 'PENDING') && areRequiredDocumentsProvided,
                        initialText:
                            ((status == 'PENDING') && areRequiredDocumentsProvided)
                                ? ''
                                : '* * * * * *',
                      ),


                    //   GenerateReferralCodeCard(
                    //   isEditable: details.isReferralCodeSaved ?? false,
                    //   referralCode: '${referralCode()}'
                    // ),

                    SizedBox(height: SizeConfig.paddingXSL),

                    CustomFormCard(
                      padding: EdgeInsets.all(SizeConfig.size10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 6,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CustomText(
                                    "Balance",
                                    fontSize: SizeConfig.large,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  SizedBox(
                                    height: SizeConfig.paddingM,
                                  ),
                                  CustomText(
                                    "₹ 00",
                                    fontSize: SizeConfig.extraLarge,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w600)
                                ],
                              ),
                              SizedBox(
                                width: SizeConfig.size50,
                              ),
                              CommonVerticalDivider(
                                  height: SizeConfig.size60,
                                  width: 1,
                                  color: AppColors.whiteE5,
                              ),
                              SizedBox(
                                width: SizeConfig.size50,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CustomText(
                                    "Total Earn",
                                    fontSize: SizeConfig.large,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  SizedBox(
                                    height: SizeConfig.paddingM,
                                  ),
                                  CustomText(
                                      "₹ 00",
                                    fontSize: SizeConfig.extraLarge,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w600)
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

  Widget _buildDocumentButton({
    required String title,
    required String document,
    required VoidCallback onTap,
    required DocStatus status,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton(
            onPressed: (status == DocStatus.verified || status == DocStatus.pending)
                ? null
                : onTap,
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (status == DocStatus.verified || status == DocStatus.pending)
                    ? LocalAssets(
                  imagePath: AppIconAssets.green_tick_icon,
                  height: 20,
                  width: 20,
                )
                : Icon(
                  CupertinoIcons.add,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: CustomText(
                    title,
                    color: status == DocStatus.notUploaded
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                ),
                  if (status == DocStatus.verified || status == DocStatus.pending)
                    InkWell(
                      onTap: () {
                        AddDocumentScreen.showDocumentProofDialog(context, document);
                      },
                      child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.primaryColor
                              )

                          ),
                          child: Row(
                            children: [
                              Icon(Icons.remove_red_eye,color: AppColors.primaryColor,size: 16,),
                              SizedBox(width: 6,),
                              CustomText("View", color: AppColors.primaryColor)
                            ],
                          )),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool get areRequiredDocumentsProvided {
    // Define the keys that are mandatory
    final requiredKeys = [
      DocumentKeys.aadhar,
      DocumentKeys.pan,
      // DocumentKeys.addressProof
    ];

    // If even one is 'notUploaded', it returns false.
    return requiredKeys.every((key) => myDocumentsController.getStatus(key) != DocStatus.notUploaded);
  }

}

