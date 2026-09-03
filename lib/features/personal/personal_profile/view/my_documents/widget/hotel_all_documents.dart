import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/add_document_button.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/cancel_cheque_document_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/generic_document_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelAllDocumentsScreen extends StatelessWidget {
  final MyDocumentsController controller;

  const HotelAllDocumentsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(()=> CustomFormCard(
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
            BuildAddDocumentButton(
              title: AppStrings.hotelTradeLicense,
              documentKey: DocumentKeys.hotelTradeLicense,
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
            BuildAddDocumentButton(
              title: AppStrings.panCardHotelOrOwner,
              documentKey: DocumentKeys.hotelPanCard,
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
                        isCapitalize: true,
                        maxLength: 10,
                      )),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            BuildAddDocumentButton(
              title: AppStrings.gstRegistrationCertificate,
              documentKey: DocumentKeys.hotelGstCertificate,
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
                      isCapitalize: true,
                    ),
                  ),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            BuildAddDocumentButton(
              title: AppStrings.cancelledCheque,
              documentKey: DocumentKeys.hotelCancelledCheque,
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
            BuildAddDocumentButton(
              title: AppStrings.policeVerificationOrNOC,
              documentKey: DocumentKeys.hotelPoliceVerification,
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
            BuildAddDocumentButton(
              title: AppStrings.fireSafetyCertificate,
              documentKey: DocumentKeys.hotelFireSafetyCertificate,
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
            BuildAddDocumentButton(
              title: AppStrings.fssaiLicense,
              documentKey: DocumentKeys.hotelFssaiLicense,
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
            BuildAddDocumentButton(
              title:
              AppStrings.ownerOrAuthorizedSignatoryIDProof,
              documentKey: DocumentKeys.hotelOwnerIdProof,
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
                        "Upload Aadhaar Card (Both Sides)",
                        backImage: true),
                  ),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            BuildAddDocumentButton(
              title: AppStrings.hotelOnboardingAgreementSigned,
              documentKey: DocumentKeys.hotelOnboardingAgreement,
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
            BuildAddDocumentButton(
              title: AppStrings.propertyOwnershipOrLeaseAgreement,
              documentKey: DocumentKeys.hotelPropertyAgreement,
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
        )));
  }
}
