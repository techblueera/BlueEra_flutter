import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/health_care_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/me/medical/view/pharmacy_stores_screen.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthServiceCardWidget extends StatelessWidget {
  const HealthServiceCardWidget({super.key});

  /// Pharmacy has its own flow (sub-category tabs → pharmacy cards → cart), so
  /// it opens [PharmacyStoresScreen] rather than the healthcare listing — whose
  /// `rightContent()` has no PHARMACY branch and would show "Coming soon".
  /// Every other category routes into the listing as before.
  void _open(OnboardingCategoryModel categoryItem) {
    if (categoryItem.slugId == PHARMACY) {
      Get.to(() => const PharmacyStoresScreen());
      return;
    }
    Get.to(() => HealthCareListingScreen(
          selectedProfessionConsultantData: categoryItem,
        ));
  }

  @override
  Widget build(BuildContext context) {
    // No "View All": the grid is 5 columns wide and [healthCareList] is short
    // enough to show every category at once, so the link would promise more
    // than exists.
    return DiscoverGridSection(
      title: AppStrings.healthcareServices.tr,
      items: healthCareList,
      getName: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      onItemTap: (item) => _open(item),
    );
  }
}
