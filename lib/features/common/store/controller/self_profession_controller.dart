import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:get/get.dart';

enum CategoryFilter {
  nearest('Nearest'),
  experienced('Experienced'),
  priceLowToHigh('Price (Low-High)');

  final String label;

  const CategoryFilter(this.label);
}


class SelfProfessionController extends GetxController{
  Rx<IndividualProfileCategory> selectedSelfProfessionData =  IndividualProfileCategory(
    name: AppStrings.electrician,
    slugId: ELECTRICIAN,
    icon: AppIconAssets.electricianIcon,
  ).obs;
  RxInt selectedTabIndex = 0.obs;
  final List<CategoryFilter> filters = CategoryFilter.values;
  Rx<CategoryFilter> selectedFilter = CategoryFilter.nearest.obs;

}