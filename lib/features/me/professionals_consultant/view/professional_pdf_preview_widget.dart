import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_certificates_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ProfessionalPdfPreviewWidget extends StatelessWidget {
  final controller = Get.put(ProfessionalPdfPickerController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 1. If no file is selected, show the "Upload" UI
      if (controller.selectedFile.value == null) {
        return InkWell(
          onTap: controller.pickSinglePdf,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: AppColors.greyE5),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(imagePath: AppIconAssets.documentUploadIcon),
                  SizedBox(width: SizeConfig.size8),
                  CustomText(
                    AppStrings.proConsultSelectPdf.tr,
                    fontSize: SizeConfig.medium,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 2. If file is selected, show the Preview + Remove button
      return Column(
        children: [
          IgnorePointer(ignoring: true,
            child: Container(
              height: 150, // Preview Height
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: SfPdfViewer.file(
                controller.selectedFile.value!,
                canShowPaginationDialog: false, // Clean preview look
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText(
                  "${AppStrings.proConsultFileLabel.tr} ${controller.selectedFile.value!.path.split('/').last}",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: controller.removeFile,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: CustomText(AppStrings.remove.tr, color: Colors.red),
              )
            ],
          ),
        ],
      );
    });
  }
}

class ProfessionalPdfPickerController extends GetxController {
  // Observables
  var selectedFile = Rxn<File>();
  var isPicking = false.obs;
  final academicCalenderController = Get.find<ProfessionalsCertificatesController>();

  Future<void> pickSinglePdf() async {
    try {
      isPicking.value = true;

      // Request permissions
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false, // Strictly single file
      );

      if (result != null && result.files.single.path != null) {
        selectedFile.value = File(result.files.single.path!);
        academicCalenderController.noticeImageFile.value =
            File(selectedFile.value?.path ?? "");
        academicCalenderController.initialNoticeImageUrl =
            selectedFile.value?.path ?? "";
        academicCalenderController.docUploadName.value = "pdf";
      }
    } finally {
      isPicking.value = false;
    }
  }

  void removeFile() {
    selectedFile.value = null;
    academicCalenderController.noticeImageFile.value = null;
    academicCalenderController.initialNoticeImageUrl = "";
    academicCalenderController.docUploadName.value = "";
  }
}
