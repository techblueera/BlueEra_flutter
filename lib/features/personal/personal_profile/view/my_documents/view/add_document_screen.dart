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
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key, this.documentVia});

  final String? documentVia;

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
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
          title: "Add Documents",
          isLeading: true,
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8, vertical: SizeConfig.size15),
          child: Obx(() => Column(
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
                                AppStrings.personalDocument,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.large,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size8),
                            _buildAddButton(
                              title: AppStrings.uploadAadhar,
                              document: DocumentKeys.aadhar,
                              status: controller.getStatus(DocumentKeys.aadhar),
                              onTap: () {
                                // Get.bottomSheet(
                                //   CommonDocumentBottomSheet(
                                //     title: AppStrings.aadharCard,
                                //     child: AadharDocumentWidget(),
                                //   ),
                                //   isScrollControlled: true,
                                //   backgroundColor: Colors.transparent,
                                // );
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.aadharCard,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.aadhar,
                                      uploadSectionLabel:
                                          AppStrings.uploadAadharBothSide,
                                      backImage: true,
                                      textFieldLabel:
                                          'Hotel Trade License Number',
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
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadPan,
                              document: DocumentKeys.pan,
                              status: controller.getStatus(DocumentKeys.pan),
                              onTap: () {
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
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadDrivingLicense,
                              document: DocumentKeys.drivingLicense,
                              status: controller
                                  .getStatus(DocumentKeys.drivingLicense),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.drivingLicence,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.drivingLicense,
                                      uploadSectionLabel: AppStrings
                                          .uploadDrivingLicenceBothSide,
                                      backImage: true,
                                      textFieldLabel:
                                          AppStrings.drivingLicenceNumber,
                                      textFieldHint: 'E.g. DL0120110012345',
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
                              title: AppStrings.uploadVehicleRC,
                              document: DocumentKeys.vehicleRC,
                              status:
                                  controller.getStatus(DocumentKeys.vehicleRC),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.rc,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.vehicleRC,
                                      uploadSectionLabel:
                                          AppStrings.uploadRcBothSide,
                                      backImage: true,
                                      textFieldLabel: AppStrings.rcNumber,
                                      textFieldHint: AppStrings.egUP32AB12,
                                      textFieldValidation:
                                          ValidationMethod.validateRC,
                                      maxLength: 10,
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
                              title: AppStrings.uploadAddressProof,
                              document: DocumentKeys.addressProof,
                              status: controller
                                  .getStatus(DocumentKeys.addressProof),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: AppStrings.addressProof,
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.addressProof,
                                      uploadSectionLabel:
                                          'Upload Front and Back Images',
                                      backImage: true,
                                      textFieldLabel: 'Name of ID',
                                      textFieldHint:
                                          'E.g. Voter ID, Gas Bill...',
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
                              title: AppStrings.uploadNOC,
                              document: DocumentKeys.noc,
                              status: controller.getStatus(DocumentKeys.noc),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Police Verification / NOC",
                                    child: GenericDocumentWidget(
                                        documentType: DocumentKeys.noc,
                                        uploadSectionLabel:
                                            "Upload Police Verification / NOC",
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadBankerCancelCheck,
                              document: DocumentKeys.bankersCancelledCheque,
                              status: controller.getStatus(
                                  DocumentKeys.bankersCancelledCheque),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Cancelled Cheque",
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
                                AppStrings.businessDocument,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.large,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size8),
                            _buildAddButton(
                              title: AppStrings.uploadGSTCertificate,
                              document: DocumentKeys.gstCertificate,
                              status: controller
                                  .getStatus(DocumentKeys.gstCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "GST Registration Certificate",
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.gstCertificate,
                                      textFieldLabel: "GSTIN Number",
                                      textFieldHint: "E.g. 23333....",
                                      uploadSectionLabel:
                                          "Upload GST Certificate",
                                      backImage: true,
                                      textFieldValidation:
                                          ValidationMethod.validateGSTIN,
                                      maxLength: 15,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.fssaiLicense,
                              document: DocumentKeys.fssaiLicense,
                              status: controller
                                  .getStatus(DocumentKeys.fssaiLicense),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "FSSAI License",
                                    child: GenericDocumentWidget(
                                      documentType: DocumentKeys.fssaiLicense,
                                      textFieldLabel: "FSSAI License Number",
                                      textFieldHint: "E.g. 12345678901234",
                                      uploadSectionLabel:
                                          "Upload FSSAI Certificate",
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
                              title: AppStrings.uploadMedicalLicense,
                              document: DocumentKeys.medicalLicense,
                              status: controller
                                  .getStatus(DocumentKeys.medicalLicense),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Medical License",
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.medicalLicense,
                                        uploadSectionLabel:
                                            AppStrings.uploadMedicalLicense,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadFireSafetyCertificate,
                              document: DocumentKeys.fireSafetyCertificate,
                              status: controller.getStatus(
                                  DocumentKeys.fireSafetyCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Fire/Safety Certificate",
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.fireSafetyCertificate,
                                        uploadSectionLabel: AppStrings
                                            .uploadFireSafetyCertificate,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadMunicipalCorpCertificate,
                              document: DocumentKeys.municipalCorpCertificate,
                              status: controller.getStatus(
                                  DocumentKeys.municipalCorpCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Municipal Corp. Certificate",
                                    child: GenericDocumentWidget(
                                        documentType: DocumentKeys
                                            .municipalCorpCertificate,
                                        uploadSectionLabel: AppStrings
                                            .uploadMunicipalCorpCertificate,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadMSMECertificate,
                              document: DocumentKeys.msmeCertificate,
                              status: controller
                                  .getStatus(DocumentKeys.msmeCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: 'MSME Certificate',
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.msmeCertificate,
                                        uploadSectionLabel:
                                            AppStrings.uploadMSMECertificate,
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadShopActCertificate,
                              document: DocumentKeys.shopActCertificate,
                              status: controller
                                  .getStatus(DocumentKeys.shopActCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: 'Shop Act Certificate',
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.shopActCertificate,
                                        uploadSectionLabel:
                                            AppStrings.uploadShopActCertificate,
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

                  SizedBox(height: SizeConfig.paddingXSL),
                  if (widget.documentVia == AppConstants.hotelServiceScreen)
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
                                AppStrings.hotelNdHomeStayDocument,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.large,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size8),
                            _buildAddButton(
                              title: AppStrings.hotelTradeLicense,
                              document: DocumentKeys.hotelTradeLicense,
                              status: controller
                                  .getStatus(DocumentKeys.hotelTradeLicense),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Hotel Trade License",
                                    child: GenericDocumentWidget(
                                      documentType:
                                          DocumentKeys.hotelTradeLicense,
                                      uploadSectionLabel:
                                          "Upload Photo (Both Side)",
                                      backImage: true,
                                      textFieldLabel:
                                          "Hotel Trade License Number",
                                      textFieldHint: "E.g. 23333....",
                                      textFieldValidation:
                                          ValidationMethod.validateTradeLicense,
                                      maxLength: 30,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.panCardHotelOrOwner,
                              document: DocumentKeys.hotelPanCard,
                              status: controller
                                  .getStatus(DocumentKeys.hotelPanCard),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                      title: AppStrings.panCard,
                                      child: GenericDocumentWidget(
                                        documentType: DocumentKeys.hotelPanCard,
                                        textFieldLabel: AppStrings.panNumber,
                                        textFieldHint: 'E.g. ABCDE1234F',
                                        uploadSectionLabel:
                                            AppStrings.uploadPan,
                                        backImage: true,
                                        textFieldValidation:
                                            ValidationMethod.validatePAN,
                                        maxLength: 10,
                                      )),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.gstRegistrationCertificate,
                              document: DocumentKeys.hotelGstCertificate,
                              status: controller
                                  .getStatus(DocumentKeys.hotelGstCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "GST Registration Certificate",
                                    child: GenericDocumentWidget(
                                      documentType:
                                          DocumentKeys.hotelGstCertificate,
                                      textFieldLabel: "GSTIN Number",
                                      textFieldHint: "E.g. 23333....",
                                      uploadSectionLabel:
                                          "Upload GST Certificate",
                                      backImage: true,
                                      textFieldValidation:
                                          ValidationMethod.validateGSTIN,
                                      maxLength: 15,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.cancelledCheque,
                              document: DocumentKeys.hotelCancelledCheque,
                              status: controller
                                  .getStatus(DocumentKeys.hotelCancelledCheque),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Cancelled Cheque",
                                    child: CancelChequeDocumentWidget(
                                        documentType:
                                            DocumentKeys.hotelCancelledCheque),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.policeVerificationOrNOC,
                              document: DocumentKeys.hotelPoliceVerification,
                              status: controller.getStatus(
                                  DocumentKeys.hotelPoliceVerification),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Police Verification / NOC",
                                    child: GenericDocumentWidget(
                                        documentType: DocumentKeys
                                            .hotelPoliceVerification,
                                        uploadSectionLabel:
                                            "Upload Police Verification / NOC",
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.fireSafetyCertificate,
                              document: DocumentKeys.hotelFireSafetyCertificate,
                              status: controller.getStatus(
                                  DocumentKeys.hotelFireSafetyCertificate),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "Fire Safety Certificate",
                                    child: GenericDocumentWidget(
                                        documentType: DocumentKeys
                                            .hotelFireSafetyCertificate,
                                        uploadSectionLabel:
                                            "Upload Fire Safety Certificate",
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.fssaiLicense,
                              document: DocumentKeys.hotelFssaiLicense,
                              status: controller
                                  .getStatus(DocumentKeys.hotelFssaiLicense),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title: "FSSAI License",
                                    child: GenericDocumentWidget(
                                      documentType:
                                          DocumentKeys.hotelFssaiLicense,
                                      textFieldLabel: "FSSAI License Number",
                                      textFieldHint: "E.g. 12345678901234",
                                      uploadSectionLabel:
                                          "Upload FSSAI Certificate",
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
                              title:
                                  AppStrings.ownerOrAuthorizedSignatoryIDProof,
                              document: DocumentKeys.hotelOwnerIdProof,
                              status: controller
                                  .getStatus(DocumentKeys.hotelOwnerIdProof),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title:
                                        "Owner / Authorized Signatory ID Proof",
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.hotelOwnerIdProof,
                                        uploadSectionLabel:
                                            "Upload Aadhar Card (Both Side)",
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.hotelOnboardingAgreementSigned,
                              document: DocumentKeys.hotelOnboardingAgreement,
                              status: controller.getStatus(
                                  DocumentKeys.hotelOnboardingAgreement),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title:
                                        "Hotel Onboarding Agreement (Signed)",
                                    child: GenericDocumentWidget(
                                        documentType: DocumentKeys
                                            .hotelOnboardingAgreement,
                                        uploadSectionLabel:
                                            "Upload Signed Agreement",
                                        backImage: true),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                            _buildAddButton(
                              title:
                                  AppStrings.propertyOwnershipOrLeaseAgreement,
                              document: DocumentKeys.hotelPropertyAgreement,
                              status: controller.getStatus(
                                  DocumentKeys.hotelPropertyAgreement),
                              onTap: () {
                                Get.bottomSheet(
                                  CommonDocumentBottomSheet(
                                    title:
                                        "Property Ownership / Lease Agreement",
                                    child: GenericDocumentWidget(
                                        documentType:
                                            DocumentKeys.hotelPropertyAgreement,
                                        uploadSectionLabel:
                                            "Upload Ownership Deed / Lease Agreement",
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
              )),
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
                Flexible(
                  child: CustomText(
                    title,
                    color: isUploadable
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
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
