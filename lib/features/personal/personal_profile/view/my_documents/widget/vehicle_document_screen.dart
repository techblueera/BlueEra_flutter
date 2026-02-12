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

  const VehicleDocumentsScreen({super.key, required this.controller});

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
                'Vehicle Document',
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.large,
              ),
            ),
            SizedBox(height: SizeConfig.size8),
            BuildAddDocumentButton(
              title: AppStrings.uploadVehicleRC,
              documentKey: DocumentKeys.vehicleRC,
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
            BuildAddDocumentButton(
              title: AppStrings.insuranceDocumentUpload,
              documentKey: DocumentKeys.insuranceDocument,
              status: controller.getStatus(
                  DocumentKeys.insuranceDocument),
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                      title: AppStrings.insuranceDocumentUpload,
                      child: GenericDocumentWidget(
                          documentType: DocumentKeys
                              .insuranceDocument,
                          uploadSectionLabel: AppStrings.insuranceDocumentUpload,
                          backImage: false)
                  ),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
            ),
            BuildAddDocumentButton(
              title:  AppStrings.pollutionCertificateUpload,
              documentKey: DocumentKeys.puc,
              status: controller.getStatus(
                  DocumentKeys.puc),
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title:  AppStrings.pollutionCertificateUpload,
                    child: GenericDocumentWidget(
                      documentType: DocumentKeys.puc,
                      uploadSectionLabel: AppStrings.pollutionCertificateUpload,
                      backImage: false,
                      textFieldLabel: "Pollution Certificate Number",
                      textFieldHint: "E.g. RJ0123...",
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
              title: AppStrings.fitnessCertificateCommercial,
              documentKey: DocumentKeys.vehicleFitnessCertificate,
              status: controller.getStatus(
                  DocumentKeys.vehicleFitnessCertificate),
              onTap: () {
                Get.bottomSheet(
                  CommonDocumentBottomSheet(
                    title: AppStrings.fitnessCertificateCommercial,
                    child: GenericDocumentWidget(
                        documentType: DocumentKeys
                            .vehicleFitnessCertificate,
                        uploadSectionLabel: AppStrings.fitnessCertificateCommercial,
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
