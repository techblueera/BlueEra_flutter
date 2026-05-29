import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/add_document_button.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/generic_document_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleDocumentsScreen extends StatelessWidget {
  final MyDocumentsController controller;
  final bool? showViewDocProof;
  const VehicleDocumentsScreen({super.key, required this.controller,this.showViewDocProof});

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
                AppStrings.vehicleDocument.tr,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.large,
              ),
            ),
            SizedBox(height: SizeConfig.size8),
            BuildAddDocumentButton(
              showViewDocProof:showViewDocProof ,
              document: DocumentKeys.vehicleRC ,
              title: AppStrings.uploadVehicleRC.tr,
              documentKey: DocumentKeys.vehicleRC,
              status:
              controller.getStatus(DocumentKeys.vehicleRC),
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title: AppStrings.rc.tr,
                    child: GenericDocumentWidget(
                      documentType: DocumentKeys.vehicleRC,
                      uploadSectionLabel:
                      AppStrings.uploadRcBothSide.tr,
                      backImage: true,
                      textFieldLabel: AppStrings.rcNumber.tr,
                      textFieldHint: AppStrings.egUP32AB12.tr,
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
            BuildAddDocumentButton(
              showViewDocProof:showViewDocProof ,
              document: DocumentKeys.insuranceDocument ,
              title: AppStrings.insuranceDocumentUpload.tr,
              documentKey: DocumentKeys.insuranceDocument,
              status: controller.getStatus(
                  DocumentKeys.insuranceDocument),
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                      title: AppStrings.insuranceDocumentUpload.tr,
                      child: GenericDocumentWidget(
                          documentType: DocumentKeys
                              .insuranceDocument,
                          uploadSectionLabel: AppStrings.insuranceDocumentUpload.tr,
                          backImage: false)
                  ),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            BuildAddDocumentButton(
              showViewDocProof: showViewDocProof ,
              document: DocumentKeys.puc ,
              title:  AppStrings.pollutionCertificateUpload.tr,
              documentKey: DocumentKeys.puc,
              status: controller.getStatus(
                  DocumentKeys.puc),
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title:  AppStrings.pollutionCertificateUpload.tr,
                    child: GenericDocumentWidget(
                      documentType: DocumentKeys.puc,
                      uploadSectionLabel: AppStrings.pollutionCertificateUpload.tr,
                      backImage: false,
                      textFieldLabel: AppStrings.pollutionCertificateNumber.tr,
                      textFieldHint: AppStrings.egRJ0123.tr,
                      textFieldValidation: ValidationMethod.validatePUCNumber,
                      isCapitalize: true,
                      maxLength: 20,
                    ),
                  ),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            BuildAddDocumentButton(
              showViewDocProof:showViewDocProof ,
              document: DocumentKeys.vehicleFitnessCertificate ,
              title: AppStrings.fitnessCertificateCommercial.tr,
              documentKey: DocumentKeys.vehicleFitnessCertificate,
              status: controller.getStatus(
                  DocumentKeys.vehicleFitnessCertificate),
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title: AppStrings.fitnessCertificateCommercial.tr,
                    child: GenericDocumentWidget(
                        documentType: DocumentKeys
                            .vehicleFitnessCertificate,
                        uploadSectionLabel: AppStrings.fitnessCertificateCommercial.tr,
                        backImage: false),
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
