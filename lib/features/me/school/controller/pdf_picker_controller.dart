import 'dart:io';
import 'package:BlueEra/features/me/school/controller/academic_calender_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfPickerController extends GetxController {
  // Observables
  var selectedFile = Rxn<File>();
  var isPicking = false.obs;
  final academicCalenderController = Get.find<AcademicCalenderController>();

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
