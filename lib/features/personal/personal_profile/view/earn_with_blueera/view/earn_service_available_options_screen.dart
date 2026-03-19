import 'dart:developer';
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
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/rider_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../../../common/cab_and_transport_partner/view/cab_and_transport_partner.dart';


class EarnServiceAvailableOptionsScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  const EarnServiceAvailableOptionsScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<EarnServiceAvailableOptionsScreen> createState() => _EarnServiceAvailableOptionsScreenState();
}

class _EarnServiceAvailableOptionsScreenState extends State<EarnServiceAvailableOptionsScreen>
    with SingleTickerProviderStateMixin, RouteAware {

  final controller = getOrPut(() => EarnServiceController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());

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
    return Obx(() {
      if(userProfessionGlobal == DELIVERY_RIDER ||
         userProfessionGlobal == GOODS_TAXI ||
         userProfessionGlobal == AUTO_TAXI
      ){
        return RiderServiceScreen(
            fromBottomNavBar: widget.fromBottomNavBar
        );
     }  else if(userProfileTypeGlobal == GIG_WORKER && userProfessionGlobal==CAR_TAXI){
        return CabAndTransportPartner(
            fromBottomNavBar: widget.fromBottomNavBar
        );
      }

      return _buildEarnDisabledScaffold(context);
    });
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: !widget.fromBottomNavBar,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEarnDisabledScaffold(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: !widget.fromBottomNavBar,
       // title: userProfessionGlobal,
        //isProfile: true
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size15,
            horizontal: SizeConfig.size8,
          ),
          child: CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEarnHeader(),
                SizedBox(height: SizeConfig.size10),
                const HorizontalVideoPlayer(),
                SizedBox(height: SizeConfig.size20),
                _buildServiceGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarnHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(SizeConfig.size6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.primaryColor, width: 0.5),
          ),
          child: LocalAssets(
            width: SizeConfig.size22,
            height: SizeConfig.size22,
            imagePath: AppIconAssets.earnWithBlueEra,
            imgColor: AppColors.primaryColor,
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            AppStrings.earnWithBlueEra,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: earnWithBlueEraServiceList.length,
      itemBuilder: (_, i) => CommonServiceCard(
        service: earnWithBlueEraServiceList[i],
        getName: (item) => item.name,
        getIcon: (item) => item.icon??'',
        spacing: 8.0,
        onTap: (item) => controller.handleServiceTap(
          context,
          item,
        ),
      ),
    );
  }

}
