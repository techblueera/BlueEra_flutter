import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_catalog_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/category_selector_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/empty_blood_test_add_widget.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/empty_health_camp_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tests tab — surfaces popular services, blood-test add CTA, the
/// category selector and the health-camp section. Reuses the existing
/// lab widgets so all action paths (add test, browse catalog, etc.)
/// remain identical to the legacy `LabFullDetailsScreen`.
class LabTestsTabV2 extends StatelessWidget {
  final LabFullDetailsController controller;

  const LabTestsTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tests = controller.details.value?.tests ?? <Tests>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),

          // ── Popular services ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: tests.isEmpty
                  ? EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_gallery.png',
                      ctaLabel: AppStrings.labAddTestsToShowcase.tr,
                      ctaIcon: Icons.medical_services_outlined,
                      onTap: () => Get.to(
                        () => const LabTestCatalogScreen(collection: ''),
                      )?.then((_) => controller.fetchFullDetails()),
                    )
                  : _PopularServices(tests: tests),
            ),
          ),

          SizedBox(height: SizeConfig.size12),
          BloodTestEmptyState(),

          SizedBox(height: SizeConfig.size12),
          CategorySelector(),

          SizedBox(height: SizeConfig.size12),
          EmptyHealthCampWidget(),

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}

class _PopularServices extends StatelessWidget {
  final List<Tests> tests;
  const _PopularServices({required this.tests});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(AppStrings.ourPopularServices.tr,
            fontWeight: FontWeight.w700),
        SizedBox(height: SizeConfig.size8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tests.length.clamp(0, 10),
            separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
            itemBuilder: (_, i) {
              final t = tests[i];
              return Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      t.testName ?? '',
                      fontSize: SizeConfig.small,
                      maxLines: 2,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
