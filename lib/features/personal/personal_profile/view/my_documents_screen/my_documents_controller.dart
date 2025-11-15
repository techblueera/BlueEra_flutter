import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Document {
  final String id;
  final String name;
  final String size;
  final String filePath;

  Document({
    required this.id,
    required this.name,
    required this.size,
    required this.filePath,
  });
}

class MyDocumentsController extends GetxController {
  RxList<Document> documents = <Document>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDummyData();
  }

  void loadDummyData() {
    documents.value = [
      Document(
        id: '1',
        name: 'GST',
        size: '481 KB',
        filePath: '/documents/gst.pdf',
      ),
      Document(
        id: '2',
        name: 'Aadhaar Card Both Side',
        size: '481 KB',
        filePath: '/documents/aadhaar.pdf',
      ),
      Document(
        id: '3',
        name: 'Pan Card',
        size: '481 KB',
        filePath: '/documents/pan.pdf',
      ),
    ];
  }


  void editDocument(Document document) {
    // TODO: Implement edit functionality
    commonSnackBar(message: '${AppStrings.editFunctionalityMessage.tr} ${document.name} ' );

  }

  void deleteDocument(Document document) {
    Get.dialog(
      AlertDialog(
        title: CustomText(AppStrings.deleteDocument),
        content: CustomText('${AppStrings.deleteConfirmation} "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomText(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              documents.removeWhere((doc) => doc.id == document.id);
              Get.back();
              commonSnackBar(message: AppStrings.documentDeletedSuccessfully);

            },
            child: CustomText(
                AppStrings.delete,
             color: Colors.red),
            ),
        ],
      ),
    );
  }
} 