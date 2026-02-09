import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/address_location_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/delivery_partner_orders.dart';
import 'package:BlueEra/features/common/delivery_partner/view/personal_information_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_information_riding_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderServiceScreen extends StatefulWidget {
  final bool fromBottomNavBar;

  const RiderServiceScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<RiderServiceScreen> createState() => _RiderServiceScreenState();
}

class _RiderServiceScreenState extends State<RiderServiceScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  final controller = getOrPut(() => EarnServiceController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());
  final viewPersonalDetailsController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  bool allCompleted = false;
  bool allStepsCompleted = false;

  @override
  void initState() {
    _checkRiderStatus();
    // _checkRiderServiceStatus();
    _tabController = TabController(length: 3, vsync: this);
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
    _checkRiderStatus();
    // _checkRiderServiceStatus();
  }

  @override
  void dispose() {
    print('disposed');
    deleteIfRegistered<EarnServiceController>();
    deleteIfRegistered<DeliveryPartnerController>();
    _tabController.dispose();
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _checkRiderStatus() {
    /// check riding status
    deliveryPartnerController.ridersOnboardingStatusRepoApi();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (deliveryPartnerController
          .ridersOnboardingStatusResponse.value.status ==
          Status.COMPLETE) {
        final stepStatus = deliveryPartnerController.stepStatus;
        // Check if all completed
        allCompleted = deliveryPartnerController
            .riderOnboardingStatusData.value?.verificationStatus ==
            "approved";
        allStepsCompleted = stepStatus.values.every((status) => status == true);
        final riderOpt = deliveryPartnerController.isRiderServiceOpt.value;
        if (riderOpt.isEmpty) {
          return _buildLoading();
        }

        return _buildRiderEnabled(context);
      }
      return SizedBox.shrink();
    });
  }

  Widget _buildLoading() {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: !widget.fromBottomNavBar,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }


  Widget _buildRiderEnabled(BuildContext context) {
    final stepStatus = deliveryPartnerController.stepStatus;

    // Check if all completed
    // Find first incomplete step
    final firstIncompleteEntry = stepStatus.entries
        .where((entry) => entry.value == false)
        .cast<MapEntry<RiderProfileStep, bool>>()
        .toList()
        .firstOrNull;

    // final firstIncompleteEntry = stepStatus.entries.firstWhere(
    //       (entry) => entry.value == false,
    //   orElse: () =>  MapEntry(RiderProfileStep.none, true),
    // );

    // final firstIncompleteEntry =
    //     stepStatus.entries.firstWhere((entry) => entry.value == false);


    return Scaffold(
      // floatingActionButton: _buildFAB(),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            _buildFloatingHeader(context),
            _buildPinnedTabBar(),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              (firstIncompleteEntry?.key == RiderProfileStep.personalInfo)
                  ? PersonalInformationRidingScreen(
                      screeName: 'from_tab_view',
                    )
                  : (firstIncompleteEntry?.key == RiderProfileStep.addressInfo)
                      ? AddressLocationRidingScreen(
                          screeName: 'from_tab_view',
                        )
                      : (firstIncompleteEntry?.key == RiderProfileStep.vehicleInfo)
                          ? VehicleInformationRidingScreen(
                              screeName: 'from_tab_view',
                            )
                          : deliveryPartnerController.riderOnboardingStatusData
                                  .value?.verificationStatus == "approved"
                              ? DeliveryPartnerOrders()
                              : RiderProfileStatusScreen(
                                  screeName: 'from_tab_view',
                            ),
              const Center(child: CustomText(AppStrings.comingSoon)),
              const Center(child: CustomText(AppStrings.comingSoon)),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildFAB() {
  //   return Padding(
  //     padding: EdgeInsets.only(
  //       bottom: widget.fromBottomNavBar
  //           ? kBottomNavigationBarHeight + SizeConfig.size20
  //           : 0,
  //     ),
  //     child: FloatingActionButton(
  //       onPressed: _openEarnWithBlueEraSheet,
  //       backgroundColor: AppColors.primaryColor,
  //       foregroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //       child: Icon(Icons.add, size: SizeConfig.size36),
  //     ),
  //   );
  // }

  Widget _buildFloatingHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: false,
      expandedHeight: SizeConfig.size70,
      flexibleSpace: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
        child: _buildHeader(context),
      ),
    );
  }

  Widget _buildPinnedTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
                text: allCompleted
                    ? AppStrings.myOrder.tr
                    : AppStrings.document.tr),
            Tab(text: AppStrings.myStore.tr),
            Tab(text: AppStrings.linkedShops.tr),
          ],
        ),
      ),
    );
  }

  // Widget _buildRiderDisabled(BuildContext context) {
  //   return Scaffold(
  //     appBar: CommonBackAppBar(
  //       isLeading: !widget.fromBottomNavBar,
  //     ),
  //     body: SafeArea(
  //       child: SingleChildScrollView(
  //         padding: EdgeInsets.symmetric(
  //           vertical: SizeConfig.size15,
  //           horizontal: SizeConfig.size8,
  //         ),
  //         child: CustomFormCard(
  //           padding: EdgeInsets.all(SizeConfig.size10),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               _buildEarnHeader(),
  //               SizedBox(height: SizeConfig.size10),
  //               const HorizontalVideoPlayer(),
  //               SizedBox(height: SizeConfig.size20),
  //               _buildServiceGrid(context),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildEarnHeader() {
  //   return Row(
  //     children: [
  //       Container(
  //         padding: EdgeInsets.all(SizeConfig.size6),
  //         decoration: BoxDecoration(
  //           shape: BoxShape.circle,
  //           color: AppColors.primaryColor.withValues(alpha: 0.1),
  //           border: Border.all(color: AppColors.primaryColor, width: 0.5),
  //         ),
  //         child: LocalAssets(
  //           width: SizeConfig.size22,
  //           height: SizeConfig.size22,
  //           imagePath: AppIconAssets.earnWithBlueEra,
  //           imgColor: AppColors.primaryColor,
  //         ),
  //       ),
  //       SizedBox(width: SizeConfig.size6),
  //       Expanded(
  //         child: CustomText(
  //           AppStrings.earnWithBlueEra,
  //           fontSize: SizeConfig.medium,
  //           fontWeight: FontWeight.w600,
  //           color: AppColors.secondaryTextColor,
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildServiceGrid(BuildContext context) {
  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 4,
  //       childAspectRatio: 0.6,
  //       crossAxisSpacing: 30,
  //       mainAxisSpacing: 20,
  //     ),
  //     itemCount: earnWithBlueEraServiceList.length,
  //     itemBuilder: (_, i) => CommonServiceCard(
  //       service: earnWithBlueEraServiceList[i],
  //       onTap: () => earnWithBlueEraController.handleServiceTap(
  //         context,
  //         earnWithBlueEraServiceList[i],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. leading (back-arrow) – only if NOT from bottom-nav
        if (!widget.fromBottomNavBar)
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            icon: LocalAssets(
              imagePath: AppIconAssets.back_arrow,
              height: SizeConfig.paddingL,
              width: SizeConfig.paddingL,
              imgColor: Colors.black,
            ),
          ),

        SizedBox(width: SizeConfig.size15),

        CommonProfileAvatar(),
        SizedBox(width: SizeConfig.size15),

        // 2. trailing – Go-Live switch (always at the end)
        Builder(builder: (_) {
            final statusData = serviceProviderStatusGlobal.toUpperCase();
            viewPersonalDetailsController.shopStatusOpenClose.value =
                statusData == AppConstants.OPEN.toUpperCase();

            return Container(
              margin: EdgeInsets.only(
                  left: SizeConfig.size10, right: SizeConfig.paddingL),
              height: SizeConfig.size40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(width: SizeConfig.size10),
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
          })

      ],
    );
  }
}
