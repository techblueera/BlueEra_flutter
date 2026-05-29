import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/cancel_cheque_document_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/doc_verification_pending_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/generic_document_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/hotel_all_documents.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/vehicle_document_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({
    super.key,
    this.documentVia,
    this.showViewDocProof = true});

  final String? documentVia;
  final bool showViewDocProof;

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();

  static void showDocumentProofDialog(BuildContext context, String docKey) {
    final meta = Get.find<MyDocumentsController>().documentStatuses[docKey];

    if (meta == null ||
        (meta.frontUrl == null && meta.backUrl == null)) {
      Get.snackbar(AppStrings.info.tr, AppStrings.noDocumentUploaded.tr);
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                  AppStrings.documentProof.tr,
                  fontSize: 18, fontWeight: FontWeight.bold
              ),
              const SizedBox(height: 16),

              if (meta.frontUrl != null)
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(AppStrings.frontSide.tr,fontSize: 14,fontWeight: FontWeight.w600,),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: (){
                        Get.to(
                              () => ImageViewScreen(
                            appBarTitle: AppStrings.frontSide.tr,
                            imageUrls: [meta.frontUrl!],
                            initialIndex: 0,
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.greyE5),
                            boxShadow: [AppShadows.textFieldShadow],
                          ),
                          child: CachedNetworkImage(
                            imageUrl: meta.frontUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __ )=> Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___)=>  LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              height: 150,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              if (meta.backUrl != null) ...[
                const SizedBox(height: 16),
                CustomText(AppStrings.backSide.tr,fontSize: 14,fontWeight: FontWeight.w600,),
                const SizedBox(height: 8),
                InkWell(
                  onTap: (){
                    Get.to(
                          () => ImageViewScreen(
                        appBarTitle: AppStrings.backSide.tr,
                        imageUrls: [meta.backUrl!],
                        initialIndex: 0,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE5),
                        boxShadow: [AppShadows.textFieldShadow]
                      ),
                      child: CachedNetworkImage(
                        imageUrl: meta.backUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __ )=> Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (_, __, ___)=>  LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            height: 150,
                            width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              CustomBtn(onTap: (){
                Get.back();
              }, title: AppStrings.close.tr,
                isValidate: true)
            ],
          ),
        ),
      ),
    );
  }


}

class _AddDocumentScreenState extends State<AddDocumentScreen>  {
  final controller = getOrPut(() => MyDocumentsController());

  @override
  void initState() {
    controller.fetchAllDocumentStatusApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.addDocuments.tr,
          isLeading: true,
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8, vertical: SizeConfig.size15),
          child: Obx(() {
            // Access the observable so GetX tracks it for rebuilds
            final _ = controller.documentStatuses.length;
            return Column(
                children: [
                  if (widget.documentVia == AppConstants.personalDocumentScreen ||
                      widget.documentVia == AppConstants.businessDocumentScreen)
                    CustomFormCard(
                        padding: EdgeInsets.only(
                            top: SizeConfig.size16, bottom: SizeConfig.size8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16),
                              child: CustomText(
                                AppStrings.personalDocument.tr,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.large,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size8),
                            _buildAddButton(
                              title: AppStrings.uploadAadhar.tr,
                              document: DocumentKeys.aadhar,
                              status: controller.getStatus(DocumentKeys.aadhar),
                              onTap: () {

                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.aadharCard.tr,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.aadhar,
                                      uploadSectionLabel:
                                          AppStrings.uploadAadharBothSide.tr,
                                      backImage: true,
                                      textFieldLabel:
                                          AppStrings.hotelTradeLicenseNumber.tr,
                                      textFieldHint: AppStrings.aadharNumberHint.tr,
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
                            _buildAddButton(
                              title: AppStrings.uploadPan.tr,
                              document: DocumentKeys.pan,
                              status: controller.getStatus(DocumentKeys.pan),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.panCard.tr,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.pan,
                                      uploadSectionLabel: AppStrings.uploadPan.tr,
                                      isCapitalize: true,
                                      backImage: false,
                                      textFieldLabel: AppStrings.panNumber.tr,
                                      textFieldHint: AppStrings.egABCDE1234F.tr,
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
                            _buildAddButton(
                              title: AppStrings.uploadDrivingLicense.tr,
                              document: DocumentKeys.drivingLicense,
                              status: controller
                                  .getStatus(DocumentKeys.drivingLicense),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.drivingLicence.tr,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.drivingLicense,
                                      uploadSectionLabel: AppStrings
                                          .uploadDrivingLicenceBothSide.tr,
                                      backImage: true,
                                      textFieldLabel:
                                          AppStrings.drivingLicenceNumber.tr,
                                      textFieldHint: AppStrings.egDL0120110012345.tr,
                                      textFieldValidation: ValidationMethod
                                          .validateDrivingLicense,
                                      maxLength: 15,
                                      keyboardType: TextInputType.text,
                                      isCapitalize: true,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadAddressProof.tr,
                              document: DocumentKeys.addressProof,
                              status: controller
                                  .getStatus(DocumentKeys.addressProof),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.addressProof.tr,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.addressProof,
                                      uploadSectionLabel:
                                          AppStrings.uploadFrontAndBackImages.tr,
                                      backImage: true,
                                      textFieldLabel: AppStrings.nameOfId.tr,
                                      textFieldHint:
                                          AppStrings.nameOfIdHint.tr,
                                      textFieldValidation:
                                          ValidationMethod.validateName,
                                      maxLength: 24,
                                      keyboardType: TextInputType.text,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadNOC.tr,
                              document: DocumentKeys.noc,
                              status: controller.getStatus(DocumentKeys.noc),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.policeVerificationNoc.tr,
                                    child: GenericDocumentWidget(
                                        documentType: DocumentKeys.noc,
                                        uploadSectionLabel:
                                            AppStrings.uploadPoliceVerificationNoc.tr,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadBankDetails.tr,
                              document: DocumentKeys.bankDetails,
                              status: controller.getStatus(DocumentKeys.bankDetails),
                              onTap: () {

                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.uploadBankDetails.tr,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.bankDetails,
                                      uploadSectionLabel: AppStrings.passbookFrontPageOrBankStatement.tr,
                                      backImage: false
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadBankerCancelCheck.tr,
                              document: DocumentKeys.bankersCancelledCheque,
                              status: controller.getStatus(
                                  DocumentKeys.bankersCancelledCheque),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.cancelledCheque.tr,
                                    child: CancelChequeDocumentWidget(
                                        documentType: DocumentKeys
                                            .bankersCancelledCheque),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                          ],
                        )),

                  if (widget.documentVia ==
                      AppConstants.businessDocumentScreen) ...[
                    SizedBox(height: SizeConfig.paddingXSL),
                    CustomFormCard(
                        padding: EdgeInsets.only(
                            top: SizeConfig.size16, bottom: SizeConfig.size8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16),
                              child: CustomText(
                                AppStrings.businessDocument.tr,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.large,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size8),
                            _buildAddButton(
                              title: AppStrings.uploadGSTCertificate.tr,
                              document: DocumentKeys.gstCertificate,
                              status: controller
                                  .getStatus(DocumentKeys.gstCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.gstRegistrationCertificate.tr,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.gstCertificate,
                                      textFieldLabel: AppStrings.gstinNumber.tr,
                                      textFieldHint: AppStrings.gstinNumberHint.tr,
                                      uploadSectionLabel:
                                          AppStrings.uploadGstCertificate.tr,
                                      backImage: true,
                                      textFieldValidation:
                                          ValidationMethod.validateGSTIN,
                                      maxLength: 15,
                                      isCapitalize: true,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.fssaiLicense.tr,
                              document: DocumentKeys.fssaiLicense,
                              status: controller
                                  .getStatus(DocumentKeys.fssaiLicense),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.fssaiLicenseTitle.tr,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.fssaiLicense,
                                      textFieldLabel: AppStrings.fssaiLicenseNumber.tr,
                                      textFieldHint: AppStrings.fssaiLicenseNumberHint.tr,
                                      uploadSectionLabel:
                                          AppStrings.uploadFssaiCertificate.tr,
                                      backImage: false,
                                      textFieldValidation:
                                          ValidationMethod.validateFSSAI,
                                      maxLength: 14,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadMedicalLicense.tr,
                              document: DocumentKeys.medicalLicense,
                              status: controller
                                  .getStatus(DocumentKeys.medicalLicense),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.medicalLicenseTitle.tr,
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.medicalLicense,
                                        uploadSectionLabel:
                                            AppStrings.uploadMedicalLicense.tr,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadFireSafetyCertificate.tr,
                              document: DocumentKeys.fireSafetyCertificate,
                              status: controller.getStatus(
                                  DocumentKeys.fireSafetyCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.fireSafetyCertificateTitle.tr,
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.fireSafetyCertificate,
                                        uploadSectionLabel: AppStrings
                                            .uploadFireSafetyCertificate.tr,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadMunicipalCorpCertificate.tr,
                              document: DocumentKeys.municipalCorpCertificate,
                              status: controller.getStatus(
                                  DocumentKeys.municipalCorpCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.municipalCorpCertificateTitle.tr,
                                    child: GenericDocumentWidget(
                                        documentType: DocumentKeys
                                            .municipalCorpCertificate,
                                        uploadSectionLabel: AppStrings
                                            .uploadMunicipalCorpCertificate.tr,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadMSMECertificate.tr,
                              document: DocumentKeys.msmeCertificate,
                              status: controller
                                  .getStatus(DocumentKeys.msmeCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.msmeCertificateTitle.tr,
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.msmeCertificate,
                                        uploadSectionLabel:
                                            AppStrings.uploadMSMECertificate.tr,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadShopActCertificate.tr,
                              document: DocumentKeys.shopActCertificate,
                              status: controller
                                  .getStatus(DocumentKeys.shopActCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.shopActCertificateTitle.tr,
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.shopActCertificate,
                                        uploadSectionLabel:
                                            AppStrings.uploadShopActCertificate.tr,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                          ],
                        )),
                  ],

                  if(widget.documentVia == AppConstants.personalDocumentScreen)
                    ...[
                      SizedBox(height: SizeConfig.paddingXSL),
                      VehicleDocumentsScreen(
                        controller: controller,
                        showViewDocProof: true,
                      ),
                    ],

                  if (widget.documentVia == AppConstants.hotelServiceScreen)
                    ...[
                      SizedBox(height: SizeConfig.paddingXSL),
                      HotelAllDocumentsScreen(
                        controller: controller,
                      ),
                    ]

                ],
              );
            }),
        )));
  }

  Widget _buildAddButton({
    required String title,
    required String document,
    required VoidCallback onTap,
    required DocStatus status,
  }) {
    bool isUploadable = status == DocStatus.notUploaded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton(
            onPressed: status == DocStatus.verified
                ? null
                : () {
                    if (status == DocStatus.pending) {
                      _showPendingInstructionDialog(document);
                    } else {
                      onTap();
                    }
                  },
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (!isUploadable)
                    ? status == DocStatus.verified
                        ? LocalAssets(
                            imagePath: AppIconAssets.green_tick_icon,
                            height: 20,
                            width: 20,
                          )
                        : LocalAssets(
                            imagePath: AppIconAssets.storeWatch,
                            imgColor: AppColors.yellow,
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
                    color: isUploadable
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                ),
                if(widget.showViewDocProof)
                if(!isUploadable)
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
                          CustomText(AppStrings.view.tr, color: AppColors.primaryColor)
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


  void _showPendingInstructionDialog(String document) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: DocumentVerificationPendingWidget(
            documentName: document,
            // onOkayTap: ()=> Get.back()
          ),
        ),
      ),
    );
  }
}
