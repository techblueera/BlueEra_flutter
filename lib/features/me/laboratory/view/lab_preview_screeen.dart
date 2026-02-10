import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/ai_lab_service_model_res.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabPreviewScreen extends StatelessWidget {
  final controller = Get.find<LabServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Diagnostic Laboratory Preview ",
      ),
      body: Obx(() {
        // Accessing data through the 'aiLabResModel' variable
        final na = controller.aiLabResModel?.value.data;

        if (na == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // About Section
                CustomText(na.aboutUs?.name ?? "Lab Name",
                    fontSize: 22, fontWeight: FontWeight.bold),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    CustomText(" ${na.aboutUs?.rating} (Verified)",
                        color: Colors.grey[700]),
                  ],
                ),
                const SizedBox(height: 12),
                CustomText(na.aboutUs?.description ?? "",
                    color: Colors.grey[600], fontSize: 14),

                const Divider(height: 40),

                // 2. Popular Services Horizontal List
                _buildHeading("Popular Services"),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: na.popularServices?.length ?? 0,
                    itemBuilder: (context, i) =>
                        _serviceCard(na.popularServices![i]),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Featured Tests (The "FeaturedTest" List)
                _buildHeading("Featured Tests"),
                ...na.featuredTest!
                    .map((test) => _featuredTestTile(test))
                    .toList(),

                const SizedBox(height: 24),

                // 4. Health Packages Grid
                _buildHeading("Health Packages"),
                _buildPackageGrid(na.packages ?? []),

                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        );
      }),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomText(title,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor),
    );
  }

  Widget _serviceCard(PopularServices service) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              service.image ?? "",
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                height: 80,
                width: 80,
              ),
            ),
          ),
          const SizedBox(height: 8),
          CustomText(service.title ?? "",
              fontSize: 12, textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }

  Widget _featuredTestTile(FeaturedTest test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(test.title ?? "", fontWeight: FontWeight.bold),
                CustomText(test.parameters ?? "",
                    fontSize: 11, color: Colors.grey),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(test.discountPrice ?? "",
                  color: AppColors.primaryColor, fontWeight: FontWeight.bold),
              CustomText(test.price ?? "",
                  fontSize: 10, decoration: TextDecoration.lineThrough),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPackageGrid(List<Packages> packages) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: packages.length,
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(packages[i].title ?? "",
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            const SizedBox(height: 4),
            CustomText(packages[i].price ?? "",
                color: AppColors.primaryColor, fontWeight: FontWeight.bold),
          ],
        ),
      ),
    );
  }
}
