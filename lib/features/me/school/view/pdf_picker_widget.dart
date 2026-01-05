import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/pdf_picker_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SinglePdfPreviewWidget extends StatelessWidget {
  final controller = Get.put(PdfPickerController());

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
                    "Select PDF",
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
                  "File: ${controller.selectedFile.value!.path.split('/').last}",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: controller.removeFile,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const CustomText("Remove", color: Colors.red),
              )
            ],
          ),
        ],
      );
    });
  }
}
// import 'package:BlueEra/features/me/school/controller/pdf_picker_controller.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class PdfPickerWidget extends StatelessWidget {
//   PdfPickerWidget({super.key});
//
//   // Inject the controller
//   final controller = Get.put(PdfPickerController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       return Column(
//         children: [
//           GestureDetector(
//             onTap: controller.isPicking.value ? null : controller.pickPdfFile,
//             child: Container(
//               height: 150,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.blueAccent, width: 2),
//                 borderRadius: BorderRadius.circular(12),
//                 color: Colors.blue.withOpacity(0.05),
//               ),
//               child: controller.isPicking.value
//                   ? const Center(child: CircularProgressIndicator())
//                   : Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
//                   const SizedBox(height: 10),
//                   CustomText(
//                     controller.selectedFile.value == null
//                         ? "Tap to Upload PDF"
//                         : "PDF Selected ✅",
//                   fontWeight: FontWeight.bold
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (controller.selectedFile.value != null) ...[
//             const SizedBox(height: 10),
//             ListTile(
//               leading: const Icon(Icons.file_present),
//               title: CustomText(controller.selectedFile.value!.path.split('/').last),
//               trailing: IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red),
//                 onPressed: controller.clearFile,
//               ),
//             ),
//           ],
//         ],
//       );
//     });
//   }
// }
