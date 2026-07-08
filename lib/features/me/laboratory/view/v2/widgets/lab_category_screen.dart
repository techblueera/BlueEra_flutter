import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/facility_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/health_camp_detail_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_contact_us_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/upload_lab_service_photos_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/create_your_own_packages_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../widgets/common_back_app_bar.dart';
import '../../../../../../widgets/local_assets.dart';

/// Tests ("Create") tab — linear-list redesign matching assets/img.png.
///
/// Each row is a slim white card (icon + label); tapping opens the section
/// the label names. A blue-outlined "Create Your Own Packages"
/// CTA sits
/// under the list. Replaces the previous mixed layout (Popular services
/// carousel + Blood test empty state + 3-column category grid +
/// health-camp hero) so the tab reads as one uniform navigation surface.
class LabCategoryScreen extends StatelessWidget {
  // ignore: unused_element
  final LabFullDetailsController controller;

  const LabCategoryScreen({super.key, required this.controller});

  /// Rows in top-to-bottom order — matches the reference image exactly.
  /// `collection` is threaded through to [LabTestListScreen] where it
  /// filters `PathologyTest.groupCategory` on the backend; for the seven
  /// test rows it names the category, for the "Others" row it lets the
  /// owner park custom tests under a free-text category.
  static final List<_MenuEntry> _entries = [
    const _MenuEntry(
      label: 'Blood & Routine Tests',
      icon: AppIconAssets.routineTestIcon,
      collection: 'Blood & Routine Tests',
    ),
    const _MenuEntry(
      label: 'Preventive & Wellness Check-ups',
      icon: AppIconAssets.wellnessTestIcon,
      collection: 'Preventive & Wellness Checkups',
    ),
    const _MenuEntry(
      label: 'Women, Pregnancy & Child Health',
      icon: AppIconAssets.womenTestIcon,
      collection: 'Women, Pregnancy & Child Health',
    ),
    const _MenuEntry(
      label: 'Diagnostics & Imaging',
      icon: AppIconAssets.imagingTestIcon,
      collection: 'Diagnostics & Imaging',
    ),
    const _MenuEntry(
      label: 'Organ & System Health',
      icon: AppIconAssets.organTestIcon,
      collection: 'Organ & System Health',
    ),
    const _MenuEntry(
      label: 'Infection, Cancer & Immunity',
      icon: AppIconAssets.infectionTestIcon,
      collection: 'Infection, Cancer & Immunity',
    ),
    const _MenuEntry(
      label: 'Others (Add Manually)',
      icon: AppIconAssets.othersTestIcon,
      collection: 'Others',
    ),
    _MenuEntry(label: 'Facility', icon: AppIconAssets.fecilityIcon),
    // _MenuEntry(label: 'Gallery', icon: Icons.photo_library_outlined),
    _MenuEntry(label: 'Create Health Camp', icon: AppIconAssets.healthcampIcon),
    // _MenuEntry(label: 'Contact Us', icon: Icons.mail_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Add Test',
        showRightTextButton: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeConfig.size12),
            for (final entry in _entries) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                child: _MenuRow(
                  label: entry.label,
                  icon: entry.icon,
                  onTap: () => _onTap(entry),
                ),
              ),
              SizedBox(height: SizeConfig.size10),
            ],
            SizedBox(height: SizeConfig.size8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              child: const _CreateYourOwnPackagesCta(),
            ),
            SizedBox(height: kBottomNavigationBarHeight + 20),
          ],
        ),
      ),
    );
  }

  void _onTap(_MenuEntry entry) {
    // Category rows share the same destination — a test list scoped to
    // the row's `collection` — which mirrors the legacy CategorySelector.
    if (entry.collection != null) {
      Get.to(() => LabTestListScreen(
            collection: entry.collection!,
            title: entry.label,
          ));
      return;
    }
    switch (entry.label) {
      case 'Facility':
        Get.to(() => FacilityScreen());
        return;
      case 'Gallery':
        Get.to(() => const UploadLabServicePhotosScreen());
        return;
      case 'Create Health Camp':
        Get.to(() => const HealthCampDetailScreen(isOwnProfile: true));
        return;
      case 'Contact Us':
        Get.to(() => LabContactUsScreen());
        return;
    }
  }
}

/// One row on the Create tab.
class _MenuEntry {
  final String label;
  final String icon;

  /// Non-null for the seven test-category rows; picked up by
  /// [LabTestsTabV2._onTap] to route into [LabTestListScreen].
  final String? collection;

  const _MenuEntry({
    required this.label,
    required this.icon,
    this.collection,
  });
}

/// Slim white row card — icon badge on the left, label to its right.
/// Matches the tile style in assets/img.png (no trailing chevron).
class _MenuRow extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _MenuRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14, vertical: SizeConfig.size14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LocalAssets(
                  imagePath: icon,
                  width: 20,
                  height: 20,
                  imgColor: AppColors.secondaryTextColor,
                ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: CustomText(
                  label,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blue-outlined pill CTA at the bottom of the tab — matches the
/// "Create Your Own Packages" button visible at the bottom of img.png.
class _CreateYourOwnPackagesCta extends StatelessWidget {
  const _CreateYourOwnPackagesCta();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => const CreateYourOwnPackagesScreen()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        child: CustomText(
          'Create Your Own Packages',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
