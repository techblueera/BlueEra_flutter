import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/choose_earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_food_home_page.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarnServiceDashboardView extends StatefulWidget {
  final bool fromBottomNavBar;

  const EarnServiceDashboardView({
    super.key,
    this.fromBottomNavBar = false,
  });

  @override
  State<EarnServiceDashboardView> createState() =>
      _EarnServiceDashboardViewState();
}

class _EarnServiceDashboardViewState extends State<EarnServiceDashboardView> {
  final controller = getOrPut(() => EarnServiceController());
  final viewPersonalDetailsController =
      Get.find<ViewPersonalDetailsController>();

  final RxInt _tabIndex = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size15,
        horizontal: SizeConfig.size15,
      ),
      child: Row(
        children: [
          if (!widget.fromBottomNavBar)
            Padding(
              padding: EdgeInsets.only(right: SizeConfig.size10),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: LocalAssets(
                  imagePath: AppIconAssets.back_arrow,
                  height: SizeConfig.paddingL,
                  width: SizeConfig.paddingL,
                  imgColor: Colors.black,
                ),
              ),
            ),
          Obx(() {
            final earnType =
                viewPersonalDetailsController.earnProfileType.value ?? '';
            return CustomText(
              _earnProfileLabel(earnType),
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            );
          }),
          Spacer(),
          _buildGoLiveChip(),
        ],
      ),
    );
  }

  Widget _buildGoLiveChip() {
    return Container(
      height: SizeConfig.size40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(width: SizeConfig.paddingXSL),
          CustomText(
            AppStrings.goLive,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          buildToggleSwitchChip(
            value: viewPersonalDetailsController.shopStatusOpenClose,
            onChanged: viewPersonalDetailsController.toggleShopStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Obx(() => Container(
          color: AppColors.white,
          child: Row(
            children: [
              _buildTab(AppStrings.home.tr, 0),
              _buildTab(AppStrings.statistics.tr, 1),
            ],
          ),
        ));
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _tabIndex.value == index;
    return Expanded(
      child: InkWell(
        onTap: () => _tabIndex.value = index,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? AppColors.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: CustomText(
              label,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primaryColor : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (_tabIndex.value == 0) {
        final earnType =
            viewPersonalDetailsController.earnProfileType.value;
        switch (earnType) {
          case 'homeMadeFood':
            return const HomeMadeFoodHomePage();
          default:
            return Center(
              child: CustomText(
                'Coming Soon',
                fontSize: SizeConfig.large,
                color: AppColors.secondaryTextColor,
              ),
            );
        }
      }
      return const SubscriptionStatusView();
    });
  }

  String _earnProfileLabel(String type) {
    switch (type) {
      case 'homeMadeFood':
        return 'Home Made Food';
      case 'homeMadeProduct':
        return 'Home Made Product';
      case 'homeService':
        return 'Home Services';
      case 'Channel':
        return 'Channel';
      default:
        return type.isNotEmpty ? type : 'Earn Service';
    }
  }
}
