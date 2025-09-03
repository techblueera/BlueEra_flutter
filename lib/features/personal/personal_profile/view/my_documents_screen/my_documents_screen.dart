import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents_screen/add_document_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'my_documents_controller.dart';

class MyDocumentsScreen extends StatelessWidget {
  const MyDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyDocumentsController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: 'My Documents',
        isLeading: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(controller),
            SizedBox(height: SizeConfig.size20),

            // Documents List
            Expanded(
              child: Obx(() => _buildDocumentsList(controller)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(MyDocumentsController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          'All Documents',
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Get.to(() => AddDocumentScreen());
            Get.toNamed(RouteHelper.getaddDocumentScreenRoute());
          },
          icon: Icon(
            Icons.add,
            color: Colors.white,
            size: 18,
          ),
          label: CustomText(
            'Add Document',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList(MyDocumentsController controller) {
    if (controller.documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              'No documents found',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              'Add your first document',
              fontSize: SizeConfig.small,
              color: Colors.grey[500],
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.documents.length,
      separatorBuilder: (context, index) => SizedBox(height: SizeConfig.size12),
      itemBuilder: (context, index) {
        final document = controller.documents[index];
        return _buildDocumentCard(document, controller);
      },
    );
  }

  Widget _buildDocumentCard(
      Document document, MyDocumentsController controller) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Document Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.description_outlined,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: SizeConfig.size16),

          // Document Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  document.name,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  document.size,
                  fontSize: SizeConfig.small,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size12),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete Button
              GestureDetector(
                onTap: () => controller.deleteDocument(document),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size8),

              // Edit Button
              GestureDetector(
                onTap: () => controller.editDocument(document),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryColor),
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
