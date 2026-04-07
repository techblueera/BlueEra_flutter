import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_list_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FinanceListingScreen extends StatefulWidget {
  final OnboardingCategoryModel? selectedCategory;

  const FinanceListingScreen({super.key, this.selectedCategory});

  @override
  State<FinanceListingScreen> createState() => _FinanceListingScreenState();
}

class _FinanceListingScreenState extends State<FinanceListingScreen> {
  final Rx<OnboardingCategoryModel?> _selectedCategory =
      Rx<OnboardingCategoryModel?>(null);

  @override
  void initState() {
    super.initState();
    _selectedCategory.value =
        widget.selectedCategory ?? financeCategories.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: 'Financial Sectors',
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: SizeConfig.paddingXSL),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _leftCategoryList(),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(child: Obx(() => _rightContent())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftCategoryList() {
    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: financeCategories,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) =>
          _selectedCategory.value?.slugId == item.slugId,
      onTap: (item, index) {
        _selectedCategory.value = item;
      },
    );
  }

  Widget _rightContent() {
    final selected = _selectedCategory.value;
    if (selected == null) {
      return const SizedBox.shrink();
    }
    return FinanceListScreen(
      categorySlugId: selected.slugId,
      key: Key(selected.slugId),
    );
  }
}
