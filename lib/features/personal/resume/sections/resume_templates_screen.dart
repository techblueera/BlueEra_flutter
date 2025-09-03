import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/common_back_app_bar.dart';
import '../controller/resume_templates_controller.dart';
import '../model/resume_template_model.dart';

class ResumeTemplateScreen extends StatelessWidget {
  final controller = Get.put(ResumeTemplateController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommonBackAppBar(title: 'Resume Templates'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return GridView.builder(
          itemCount: controller.templates.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75, // Adjusted for better proportions
          ),
          itemBuilder: (_, index) {
            final ResumeTemplateModel template = controller.templates[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Template Image Container
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          template.url,
                          fit: BoxFit.contain,
                          // Changed to contain to show full image
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2196F3),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (c, e, s) => Container(
                            alignment: Alignment.center,
                            color: Colors.grey[50],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 32,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Template',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                        vertical: SizeConfig.size10),
                    child: PositiveCustomBtn(
                        onTap: () => controller.downloadTemplate(template),
                        title: "Download"),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
