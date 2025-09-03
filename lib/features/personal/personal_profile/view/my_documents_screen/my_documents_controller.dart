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
    Get.snackbar(
      'Edit Document',
      'Edit functionality for ${document.name} will be implemented here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void deleteDocument(Document document) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              documents.removeWhere((doc) => doc.id == document.id);
              Get.back();
              Get.snackbar(
                'Success',
                'Document deleted successfully',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 