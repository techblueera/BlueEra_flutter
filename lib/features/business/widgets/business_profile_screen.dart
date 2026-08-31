import 'package:BlueEra/core/api/model/tab_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/widgets/business_profile_widget.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/apiService/api_response.dart';
import '../../../core/controller/location_controller.dart';
import '../../../widgets/custom_btn.dart';
import '../../../widgets/horizontal_tab_selector.dart';
import '../auth/controller/view_business_details_controller.dart';
import '../auth/model/viewBusinessProfileModel.dart';
import 'business_profile_header.dart';

class BusinessProfileScreen extends StatefulWidget {
  final int? selectedIndex;
  final SortBy? sortBy;

  BusinessProfileScreen({super.key, this.selectedIndex, this.sortBy});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final locationController = Get.find<LocationController>();

  List<TabItem> postTabs = [];
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;

  Future<void> noLocationPermissionDialogBox() async {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
          title: CustomText(
            AppStrings.currentLocationUnavailable,
            fontSize: 16,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w600,
          ),
          content: SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  AppStrings.locationPermissionMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                PositiveCustomBtn(
                  onTap: () async {
                    await openAppSettings();
                    Get.back();

                    // ✅ After returning, re-check permission
                    Future.delayed(const Duration(seconds: 1), () async {
                      await _handleLocationFlow();
                    });
                  },
                  title: AppStrings.changeLocationSettings,
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _handleLocationFlow() async {
    final locationData = await locationController.checkPermissionAndSetData();

    if (locationData != null) {
      // ✅ Permission granted and location fetched
      await updateAddressFromLocation();
    } else {
      // ❌ Permission denied — show dialog
      noLocationPermissionDialogBox();
    }
  }

  @override
  void initState() {
    selectedFilter = widget.sortBy ?? SortBy.Latest;
    viewBusinessDetailsController.selectedIndex.value =
        widget.selectedIndex ?? 0;
    setFilters();
    super.initState();
  }

  Future<void> updateAddressFromLocation() async {
    final locationData = await locationController.checkPermissionAndSetData();
    if (locationData != null) {
      locationData.fullAddress;
      locationData.city;
      locationData.pinCode;
      viewBusinessDetailsController.addressLat?.value =
          double.parse(locationData.lat);
      viewBusinessDetailsController.addressLong?.value =
          double.parse(locationData.long);
    }
  }

  void setFilters() {
    filters = SortBy.values.toList();
  }

  final controllerInventory = Get.put(InventoryController());
  bool isDialogShown = false;

  @override
  Widget build(BuildContext context) {
    postTabs = [
      TabItem(id: 'Profile', title: AppStrings.profile.tr),
      // TabItem(id: 'My Products', title: AppStrings.myProducts.tr),
      TabItem(id: 'My Posts', title: AppStrings.myPosts.tr),
    ];
    return GetBuilder<ViewBusinessDetailsController>(builder: (controller) {
      if (controller.viewBusinessResponse.status == Status.COMPLETE) {
        BusinessProfileDetails? details =
            viewBusinessDetailsController.businessProfileDetails.value?.data;
        if ((!isDialogShown &&
            (details?.businessLocation == null ||
                details?.businessLocation?.lat == null ||
                details?.businessLocation?.lon == null ||
                details?.businessLocation?.lat == 0.0 ||
                details?.businessLocation?.lon == 0.0))) {
          isDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            updateLocationDialog(context, details, true);
          });
        }
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8, vertical: SizeConfig.size8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 12,
              ),
              HorizontalTabSelector(
                horizontalMargin: 2,
                tabs: postTabs,
                selectedIndex:
                    viewBusinessDetailsController.selectedIndex.value,
                onTabSelected: (index, value) {
                  setState(() => viewBusinessDetailsController
                      .selectedIndex.value = index);
                  if (index == 1) {
                    final inventoryController = Get.put(InventoryController());
                    inventoryController.fetchBusinessProducts();
                  }
                },
                labelBuilder: (label) => label.title.tr,
              ),
              SizedBox(
                height: 14,
              ),
              _buildTabContent(controller,
                  viewBusinessDetailsController.selectedIndex.value, details)
            ],
          ),
        );
      } else {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(left: 40, top: 20),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
    });
  }

  Widget _buildTabContent(ViewBusinessDetailsController controller, int index,
      BusinessProfileDetails? details) {
    switch (postTabs[index].id) {
      case 'Profile':
        return Column(
          children: [
            _ProfileSetupBanner(details: details),
            BusinessProfileHeader(
              details: details,
              controller: viewBusinessDetailsController,
            ),
            BusinessProfileWidget(),
          ],
        );
      case 'My Posts':
        return FeedScreen(
            key: ValueKey('feedScreen_my_posts'),
            postFilterType: PostType.myPosts,
            id: businessId,
            isInParentScroll: true);
      // case "My Products":
      //   return MyProductCardDetails();
      default:
        return const Center(child: CustomText('Coming soon'));
    }
  }
}

class _ProfileSetupBanner extends StatelessWidget {
  final BusinessProfileDetails? details;

  const _ProfileSetupBanner({required this.details});

  bool get _isIncomplete {
    final d = details;
    if (d == null) return false;
    final missingDesc = (d.businessDescription ?? '').trim().isEmpty;
    final missingSchedule = (d.availability?.schedule ?? const []).isEmpty;
    final missingLogo = (d.logo ?? '').isEmpty;
    final missingCategory = (d.categoryDetails?.name ?? '').isEmpty;
    return missingDesc || missingSchedule || missingLogo || missingCategory;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isIncomplete) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(SizeConfig.size10),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Complete your business profile',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  'Add categories, hours, photo, address & description',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          InkWell(
            borderRadius: BorderRadius.circular(SizeConfig.size20),
            onTap: () => Get.toNamed(
              RouteHelper.getBusinessOnboardingCategoryScreenRoute(),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(SizeConfig.size20),
              ),
              child: CustomText(
                'Setup',
                fontSize: SizeConfig.small,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
