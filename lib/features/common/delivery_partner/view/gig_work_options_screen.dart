import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/choose_earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../cab_and_transport_partner/view/cab_and_transport_partner.dart';


class GigWorkOptionsScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  const GigWorkOptionsScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<GigWorkOptionsScreen> createState() => _GigWorkOptionsScreenState();
}

class _GigWorkOptionsScreenState extends State<GigWorkOptionsScreen>
    with SingleTickerProviderStateMixin, RouteAware {

  final controller = getOrPut(() => EarnServiceController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());
  final _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  @override
  void initState() {
    log('user profession global -- $userProfessionGlobal');
    log('user designation global -- $userDesignationGlobal');
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
  }


  @override
  void dispose() {
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (userProfessionGlobal == BIKE_RIDER ||
        userProfessionGlobal == GOODS_TAXI ||
        userProfessionGlobal == AUTO_TAXI ||
        userProfessionGlobal == CAR_TAXI_DRIVER) {
      body = RiderServiceScreen(fromBottomNavBar: widget.fromBottomNavBar);
    } else {
      body = CabAndTransportPartner(fromBottomNavBar: widget.fromBottomNavBar);
    }

    return Scaffold(
      appBar: CommonBackAppBar(
        showElevation: 0,
        isDrawerMenu: true,
        isLeading: false,
        isProfile: false,
        isNotification: !isGuestUser(),
        bellIconNotEmpty: true,
        isGuestLogout: isGuestUser(),
        onNotificationTap: () {
          Navigator.pushNamed(
            context,
            RouteHelper.getNotificationScreenRoute(),
          );
        },
        buildCustomActionWidget: () => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EarnActionPill(
              onTap: () => Get.to(() => const chooseEarnServiceScreen()),
            ),
            _buildGoLiveAction(),
          ],
        ),
      ),
      // BottomNavHideOnScroll listens to scroll notifications bubbling
      // up from the inner Scaffolds (RiderServiceScreen /
      // CabAndTransportPartner) and toggles the bottom nav visibility
      // accordingly. The outer AppBar stays fixed because it lives
      // outside the inner screens' NestedScrollView headers — moving it
      // into those headers would require editing those child screens.
      body: BottomNavHideOnScroll(child: body),
    );
  }

  Widget _buildGoLiveAction() {
    if (!Platform.isAndroid) return const SizedBox.shrink();
    return Builder(builder: (_) {
      final statusData = serviceProviderStatusGlobal.toUpperCase();
      final isOpen = statusData == AppConstants.OPEN.toUpperCase();
      if (_viewCtrl.shopStatusOpenClose.value != isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _viewCtrl.shopStatusOpenClose.value = isOpen;
        });
      }
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          height: SizeConfig.size32,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: SizeConfig.size8),
              CustomText(
                AppStrings.goLive,
                fontSize: SizeConfig.small,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              Obx(() {
                if (_viewCtrl.isShopStatusUpdating.value) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size10,
                      vertical: SizeConfig.size6,
                    ),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                      ),
                    ),
                  );
                }
                return buildToggleSwitchChip(
                  value: _viewCtrl.shopStatusOpenClose,
                  onChanged: _viewCtrl.toggleShopStatus,
                );
              }),
            ],
          ),
        ),
      );
    });
  }


}

class _EarnActionPill extends StatelessWidget {
  final VoidCallback onTap;

  const _EarnActionPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.earnWithBEIcon,
                  imgColor: AppColors.primaryColor,
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Earn',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
