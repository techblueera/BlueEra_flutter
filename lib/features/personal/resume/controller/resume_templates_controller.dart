import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:get/get.dart';

import '../../../../core/constants/snackbar_helper.dart';
import '../model/resume_template_model.dart';
import '../repo/resume_repo.dart';

class ResumeTemplateController extends GetxController {
  final ResumeRepo _resumeRepo = ResumeRepo();

  RxList<ResumeTemplateModel> templates = <ResumeTemplateModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
   fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    final result = await _resumeRepo.getResumeTemplates();

    if (result.isSuccess) {
      final data = result.response?.data;
      if (data != null &&
          data['templates'] != null &&
          data['templates'] is List) {
        final List list = data['templates'];
        templates.value =
            list.map((e) => ResumeTemplateModel.fromJson(e)).toList();
      } else {
        commonSnackBar(message: "No templates found");
      }
    } else {
      commonSnackBar(message: "Failed to fetch templates");
    }
  }

  Future<void> downloadTemplate(ResumeTemplateModel template) async {
  try {
    await _resumeRepo.downloadResumeTemplate( template.name);
  } catch (e) {
    commonSnackBar(message: AppStrings.somethingWentWrong);
  }
}

}
