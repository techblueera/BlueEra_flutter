import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/journey_status_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/typedef_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/applied_job_controller.dart';
import 'package:BlueEra/features/journey/repo/travel_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_settings_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_button_with_icon.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:BlueEra/widgets/user_profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/shared_preference_utils.dart';
import '../features/business/visiting_card/view/business_own_profile_screen.dart';
import '../features/chat/view/contacts/view/be_available_contacts_list.dart';
import '../features/common/home/widgets/drawer.dart';
import '../features/me/medical/view/widget/add_product_common_dialog.dart';
import '../features/me/politician/widget/add_politician_activity_event.dart';
import '../features/me/politician/widget/add_social_activity.dart';

class CommonBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonBackAppBar(
      {super.key,
      this.title,
      this.isLeading = true,
      this.isFilter = false,
      this.isShowMoreInfoIcon = false,
      this.isNotification = false,
      this.bellIconNotEmpty = false,
      this.onNotificationTap,
      this.onBackTap,
      this.appBarColor,
      this.isTextButton = false,
      this.isShadowShow = true,
      this.actionText,
      this.actionTextColor,
      this.isShareButton,
      this.isLogout,
      this.isDownloadButton,
      this.isChangeToEditMode = false,
      this.isQrCodeButton,
      this.onQrCodeTap,
      this.onShareTap,
      this.isLocation,
      this.isMore,
      this.isSearch,
      this.controller,
      this.onSearchTap,
      this.onClearCallback,
      this.searchHintText,
      this.onLocationTap,
      this.onMoreTap,
      this.isTrimmedButton,
      this.onTrimmedTap,
      this.isSaveButton,
      this.onSavedTap,
      this.iClearButton,
      this.onClearNotificationsTap,
      this.isSettingButton,
      this.isAddPlace,
      this.onAddPlaceTap,
      this.isEndJourney,
      this.onEndJourneyTap,
      this.titleColor,
      this.isCancelButton,
      this.onCancelTap,
      this.isJobPopUpMenuButton,
      this.isProfile,
      this.isResumeCardButton,
      this.isReloadContactButton,
      this.onRefreshContact,
      this.onProfileTap,
      this.isPDFExport,
      this.isDrawerMenu = false,
      this.onPDFExportTap,
      this.jobID,
      this.jobStatus,
      this.showRightTextButton = false,
      this.rightTextButtonText,
      this.rightTextButtonColor,
      this.onRightTextButtonTap,
      this.isShowCursor,
      this.currentCity,
      this.isGuestLogout,
      this.transactionFilterSelectedValue,
      this.buildCustomActionWidget,
      // this.isAddProduct = false,
      // this.isAddProductCategory = false,
      this.bottomWidget,
      this.showTransactionFilter=false,
      this.isGoLiveWidget,
      this.isShowAcceptOrRejectBtn,
      this.isFollowRefreshWidget,
      this.isCreateSocialWidget,
      this.isFollowRefresh = false,
      this.isGoLive = false,
      this.isInventoryPopUpMenu = false,
      this.isStoreProfile,
      this.isCurrentAddress,
      this.onTabAcceptBtn,
      this.transactionFilterOnTap,
      this.orderAcceptText,
      this.backArrowColor,
      this.orderAcceptBgColor,
      this.orderAcceptBorderColor,
      this.orderAcceptTextColor,
      this.isRejectButton,
      this.rejectButton,
      this.isAddProductButton,
      this.isCreateButton,
      this.isCreateEventBtn,
      this.showElevation,
      this.categoryId,
      this.isCustomTitleWidget,
        this.isForwardUi});

  // final AppBar? appBar;
  final String? title;
  final String? actionText;
  final bool? isLeading;
  final bool? isFilter;
  final bool? isNotification;
  final bool bellIconNotEmpty;
  final OnTab? onNotificationTap;
  final bool? isTextButton;
  final bool? isShadowShow;
  final bool? isChangeToEditMode;
  final bool? isShowMoreInfoIcon;
  final bool? isShowAcceptOrRejectBtn;
  final VoidCallback? onTabAcceptBtn;
  final String? orderAcceptText;
  final Color? orderAcceptBgColor;
  final Color? orderAcceptBorderColor;
  final Color? orderAcceptTextColor;
  final bool? isDownloadButton;
  final bool? isLogout;
  final bool? isGuestLogout;
  final bool? isShareButton;
  final bool? isQrCodeButton;
  final bool? isMore;
  final bool? isLocation;
  final bool? isSearch;
  final bool? isShowCursor;
  final TextEditingController? controller;
  final OnTab? onSearchTap;
  final OnTab? onClearCallback;
  final String? searchHintText;
  final OnTab? onBackTap;
  final OnTab? onShareTap;
  final OnTab? onMoreTap;
  final OnTab? onLocationTap;
  final OnTab? onQrCodeTap;
  final Color? appBarColor;
  final Color? actionTextColor;
  final Color? backArrowColor;
  final bool? isTrimmedButton;
  final OnTab? onTrimmedTap;
  final bool? isSaveButton;
  final OnTab? onSavedTap;
  final bool? iClearButton;
  final OnTab? onClearNotificationsTap;
  final bool? isSettingButton;
  final bool? isAddPlace;
  final bool? isDrawerMenu;
  final bool? isEndJourney;
  final OnTab? onEndJourneyTap;
  final OnTab? onAddPlaceTap;
  final Color? titleColor;
  final bool? isCancelButton;
  final OnTab? onCancelTap;
  final bool? isJobPopUpMenuButton;
  final bool? isProfile;
  final bool? isResumeCardButton;
  final bool? isReloadContactButton;
  final Function? onRefreshContact;
  final OnTab? onProfileTap;
  final bool? isPDFExport;
  final String? jobID;
  final String? jobStatus;
  final OnTab? onPDFExportTap;
  final bool? showRightTextButton;
  final String? rightTextButtonText;
  final Color? rightTextButtonColor;
  final OnTab? onRightTextButtonTap;
  final String? currentCity;
  final Widget Function()? buildCustomActionWidget;

  // final bool isAddProduct;
  // final bool isAddProductCategory;
  final PreferredSizeWidget? bottomWidget;
  final bool? isFollowRefresh;
  final bool? isGoLive;
  final Widget Function()? isFollowRefreshWidget;
  final Widget Function()? isCreateSocialWidget;
  final Widget Function()? isGoLiveWidget;
  final bool? isInventoryPopUpMenu;
  final bool? isStoreProfile;
  final bool? isCurrentAddress;
  final bool? isRejectButton;
  final Widget Function()? rejectButton;
  final String? categoryId;
  final bool? isAddProductButton;
  final bool? isCreateButton;
  final bool? isCreateEventBtn;
  final double? showElevation;
  final Widget Function()? isCustomTitleWidget;
  final bool? showTransactionFilter;
  final String? transactionFilterSelectedValue;
  final Function(String? value)? transactionFilterOnTap;
  final bool? isForwardUi;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: showElevation ?? 4,
      shadowColor: (isShadowShow == true) ? Colors.black26 : null,
      surfaceTintColor: AppColors.white,
      backgroundColor: appBarColor ?? Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      centerTitle: (isLeading ?? false) ? true : false,
      title: Padding(
        padding: EdgeInsets.only(
            // left: SizeConfig.paddingL,
            right: SizeConfig.paddingXSL,
            // top: SizeConfig.paddingXSL,
            bottom: SizeConfig.paddingXSL),
        child: Obx(() {
          bool isSearchOn = Get.find<AuthController>().isSearchOpen.value;
          return Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLeading ?? false)
                IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onBackTap ??
                        () async {
                          Navigator.of(context).pop();
                        },
                    icon: LocalAssets(
                      imagePath: AppIconAssets.back_arrow,
                      height: SizeConfig.paddingL,
                      width: SizeConfig.paddingL,
                      imgColor: backArrowColor ?? Colors.black,
                    )),

              // if (isLeading ?? false) SizedBox(width: SizeConfig.paddingXSL),
              if (isDrawerMenu ?? false)
                Padding(
                  padding: const EdgeInsets.only(left: 15.0, top: 10),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                          barrierDismissible: true,
                          barrierColor: Colors.black.withOpacity(0.3),
                          context: context,
                          builder: (BuildContext context) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: Get.width * 0.85, // 👈 40% of screen
                                height: double.infinity,
                                child: Drawer(
                                  child: ProfileMenuDrawer(),
                                ),
                              ),
                            );
                          });
                    },
                    child: LocalAssets(
                      imagePath: AppIconAssets.drawer_more,
                    ),
                  ),
                ),

              if (isProfile ?? false) CommonProfileAvatar(),

              if (isStoreProfile ?? false)
                Builder(
                  builder: (BuildContext context) {
                    return InkWell(
                      onTap: () {
                        if (isGuestUser()) {
                          createProfileScreen();
                        } else if (isIndividualUser()) {
                          Get.to(() => PersonalProfileSetupNewScreen());
                        } else if (isBusinessUser()) {
                          navigatePushTo(context, BusinessOwnProfileScreen());
                        }
                      },
                      child: Padding(
                          padding: EdgeInsets.only(left: SizeConfig.size15),
                          child: CachedAvatarWidget(
                              imageUrl: userProfileGlobal,
                              size: SizeConfig.size30,
                              borderRadius: SizeConfig.size15,
                              showProfileOnFullScreen: false)),
                    );
                  },
                ),

              if (title?.isNotEmpty ?? false)
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: SizeConfig.paddingXSL,
                      bottom: SizeConfig.paddingXSL,
                      left: (isLeading == true) ? 0 : SizeConfig.size20,
                    ),
                    child: CustomText(
                      title ?? "",
                      fontSize: SizeConfig.large,
                      color: titleColor ?? AppColors.black,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              if (isSearch == true &&
                  Get.find<AuthController>().isSearchOpen.value == false)
                Spacer(),
              if (isSearch ?? false)
                if (controller == null)
                  SizedBox()
                else
                  (Get.find<AuthController>().isSearchOpen.value)
                      ? Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: (isLeading ?? false)
                                    ? 0.0
                                    : SizeConfig.size15,
                                top: 10),
                            child: CommonSearchBar(
                                controller: controller!,
                                isShowCursor: isShowCursor,
                                onSearchTap: onSearchTap ?? () {},
                                onClearCallback: onClearCallback,
                                hintText: searchHintText),
                          ),
                        )
                      : SizedBox(),

              if (isSearch == true && isSearchOn == false)
                InkWell(
                    onTap: () {
                      Get.find<AuthController>().isSearchOpen.value =
                          !Get.find<AuthController>().isSearchOpen.value;
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: LocalAssets(
                        imagePath: AppIconAssets.search,
                        height: 28,
                        width: 28,
                      ),
                    )),
              if (isSearch == true && isSearchOn)
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 12),
                  child: InkWell(
                      onTap: () {
                        Get.find<AuthController>().isSearchOpen.value =
                            !Get.find<AuthController>().isSearchOpen.value;
                      },
                      child: Icon(
                        Icons.search_off,
                        size: 25,
                      )),
                ),
              if (isGoLive ?? false)
                Builder(
                  builder: (context) => Row(
                    children: [
                      isGoLiveWidget!(),
                    ],
                  ),
                ),

              if (isLocation ?? false)
                Builder(
                  builder: (context) => Container(
                    height: SizeConfig.size45,
                    width: SizeConfig.size45,
                    margin: EdgeInsets.only(left: SizeConfig.size5),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, RouteHelper.getCustomizeMapScreenRoute());
                      },
                      icon: LocalAssets(imagePath: AppIconAssets.earth),
                    ),
                  ),
                ),

              if (isNotification == true &&
                  Get.find<AuthController>().isSearchOpen.value == false)
                Builder(builder: (context) {
                  return Padding(
                    padding: EdgeInsets.only(left: SizeConfig.size15, top: 10),
                    child: InkWell(
                        onTap: () => onNotificationTap?.call(),
                        child: LocalAssets(
                            imagePath: AppIconAssets.notificationOutlineIcon)),
                  );
                }),

              if (iClearButton ?? false)
                Builder(
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(left: SizeConfig.size10),
                    child: IconButton(
                      onPressed: onClearNotificationsTap ?? () {},
                      icon: CustomText(
                        AppStrings.clear,
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),

              if (isSettingButton ?? false)
                Builder(
                  builder: (context) => Container(
                    margin: EdgeInsets.only(left: SizeConfig.size10),
                    height: SizeConfig.size30,
                    width: SizeConfig.size30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      icon: LocalAssets(
                        imagePath: AppIconAssets.settingIcon,
                        imgColor: AppColors.black,
                      ),
                    ),
                  ),
                ),

              if (isMore ?? false)
                PopupMenuButton<PostCreationMenu>(
                  padding: EdgeInsets.zero,
                  offset: const Offset(-6, 36),
                  color: AppColors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onSelected: (value) async {
                    if (isGuestUser()) {
                      createProfileScreen();
                    } else if (/*value == PostCreationMenu.videos ||
                      value == PostCreationMenu.photos ||*/
                        value == PostCreationMenu.message ||
                            value == PostCreationMenu.poll) {
                      postVia(context, value);
                    } else if (value == PostCreationMenu.jobPost) {
                      Get.toNamed(RouteHelper.getCreateJobPostScreenRoute(),
                          arguments: {
                            'isEditMode': false,
                            'jobId': '',
                            'createJobVia': 'business',
                          });
                    }
                  },
                  icon: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: LocalAssets(
                      imagePath: AppIconAssets.addOutlinedIcon,
                      imgColor: AppColors.primaryColor,
                    ),
                  ),
                  itemBuilder: (context) => popupMenuItems(),
                ),

              if (isResumeCardButton ?? false)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  offset: const Offset(-6, 36),
                  color: AppColors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onSelected: (value) {},
                  icon: LocalAssets(imagePath: AppIconAssets.resumeCardIcon),
                  itemBuilder: (context) => popupMenuResumeCardItems(),
                ),

              if (isGuestLogout ?? false)
                Builder(
                  builder: (context) => Container(
                    height: SizeConfig.size30,
                    width: SizeConfig.size30,
                    margin: EdgeInsets.only(right: SizeConfig.size20),
                    child: IconButton(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size5),
                      onPressed: () async {
                        await showCommonDialog(
                            context: context,
                            text: AppStrings.logoutConfirmationMessage,
                            confirmCallback: () async {
                              await SharedPreferenceUtils.clearPreference();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  RouteHelper.getMobileNumberLoginRoute(),
                                  (Route<dynamic> route) => false);
                            },
                            cancelCallback: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            confirmText: AppStrings.yes,
                            cancelText: AppStrings.no);
                      },
                      icon: LocalAssets(
                        imagePath: AppIconAssets.logout_new,
                        // height: SizeConfig.size15,
                        // width: SizeConfig.size15,
                      ),
                    ),
                  ),
                ),

              if (isInventoryPopUpMenu ?? false)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  offset: const Offset(-6, 36),
                  color: AppColors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  icon: Icon(Icons.more_vert),
                  itemBuilder: (context) => inventoryPopupMenuItems(),
                ),

              if (isCustomTitleWidget != null)
                Builder(
                  builder: (context) => isCustomTitleWidget!(),
                ),
            ],
          );
        }),
      ),
      actions: [
        if (buildCustomActionWidget != null)
          Builder(
            builder: (context) => buildCustomActionWidget!(),
          ),
        if(showTransactionFilter??false)
          PopupMenuButton<int>(
              offset: const Offset(-6, 36),
              color: AppColors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onSelected: (value) {},
              icon:LocalAssets(imagePath: AppIconAssets.filterIcon,height: 24,width: 24,),
              itemBuilder: (context) =>
              [
                PopupMenuItem(
                    value: 2,
                    child: ExpansionTile(
                      expandedAlignment: Alignment.centerLeft,
                      childrenPadding: EdgeInsets.zero,
                      expandedCrossAxisAlignment:
                      CrossAxisAlignment.start,
                      title: CustomText(
                        "Type",
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.medium15,
                      ),
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () =>transactionFilterOnTap?.call("CREDIT"),

                              child: CustomText(
                                "Credit",
                                textAlign: TextAlign.left,
                                color: transactionFilterSelectedValue ==
                                    "CREDIT"
                                    ? AppColors.green39
                                    : AppColors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                            transactionFilterSelectedValue == "CREDIT"
                                ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0),
                              child: InkWell(
                                onTap: () =>transactionFilterOnTap?.call(null),

                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                ),
                              ),
                            )
                                : SizedBox()
                          ],
                        ),
                        Divider(),
                        Row(
                          children: [
                            InkWell(
                              onTap: () =>transactionFilterOnTap?.call("DEBIT"),

                              child: CustomText(
                                "Debit",
                                textAlign: TextAlign.left,
                                color:
                                transactionFilterSelectedValue == "DEBIT"
                                    ? AppColors.green39
                                    : AppColors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                            transactionFilterSelectedValue == "DEBIT"
                                ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0),
                              child: InkWell(
                                onTap: () =>transactionFilterOnTap?.call(null),

                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                ),
                              ),
                            )
                                : SizedBox()
                          ],
                        ),
                        Divider(),
                      ],
                    )),
                PopupMenuItem(
                    value: 1,
                    child: ExpansionTile(
                      expandedAlignment: Alignment.centerLeft,
                      childrenPadding: EdgeInsets.zero,
                      expandedCrossAxisAlignment:
                      CrossAxisAlignment.start,
                      title: CustomText(
                        "Status",
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.medium15,
                      ),
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () =>transactionFilterOnTap?.call("SUCCESSFUL"),
                              child: CustomText(
                                "Successful",
                                textAlign: TextAlign.left,
                                color: transactionFilterSelectedValue ==
                                    "SUCCESSFUL"
                                    ? AppColors.green39
                                    : AppColors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                            transactionFilterSelectedValue == "SUCCESSFUL"
                                ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0),
                              child: InkWell(
                                onTap: () =>transactionFilterOnTap?.call(null),

                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                ),
                              ),
                            )
                                : SizedBox()
                          ],
                        ),
                        Divider(),
                        Row(
                          children: [
                            InkWell(
                              onTap: () =>transactionFilterOnTap?.call("FAILED"),

                              child: CustomText(
                                "Failed",
                                textAlign: TextAlign.left,
                                color: transactionFilterSelectedValue ==
                                    "FAILED"
                                    ? AppColors.green39
                                    : AppColors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                            transactionFilterSelectedValue == "FAILED"
                                ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0),
                              child: InkWell(
                                onTap: () =>transactionFilterOnTap?.call(null),

                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                ),
                              ),
                            )
                                : SizedBox()
                          ],
                        ),
                        Divider(),
                        Row(
                          children: [
                            InkWell(
                              onTap: () =>transactionFilterOnTap?.call("PENDING"),

                              child: CustomText(
                                "Pending",
                                color: transactionFilterSelectedValue ==
                                    "PENDING"
                                    ? AppColors.green39
                                    : AppColors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                            transactionFilterSelectedValue == "PENDING"
                                ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0),
                              child: InkWell(
                                onTap: () =>transactionFilterOnTap?.call(null),

                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                ),
                              ),
                            )
                                : SizedBox()
                          ],
                        ),
                        Divider(),
                      ],
                    )),



              ]),
        if (actionText?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(right: 25),
            child: CustomText(actionText),
          ),
        if (isRejectButton ?? false)
          Builder(
            builder: (context) => rejectButton!(),
          ),
        if (isFollowRefresh ?? false)
          Builder(
            builder: (context) => isFollowRefreshWidget!(),
          ),
        if (isCreateSocialWidget != null)
          Builder(
            builder: (context) => isCreateSocialWidget!(),
          ),
        if (isLogout ?? false)
          Builder(
            builder: (context) => Container(
              height: SizeConfig.size30,
              width: SizeConfig.size30,
              margin: EdgeInsets.only(right: SizeConfig.size20),
              child: IconButton(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size5),
                onPressed: () async {
                  Get.to(() => ProfileSettingsNewScreen());
                },
                icon: LocalAssets(
                  imagePath: AppIconAssets.more_setting,
                  imgColor: AppColors.black,
                ),
              ),
            ),
          ),
        if (isShareButton ?? false)
          Builder(
            builder: (context) => Container(
              height: SizeConfig.size30,
              width: SizeConfig.size30,
              margin: EdgeInsets.only(right: SizeConfig.size20),
              child: IconButton(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size5),
                onPressed: onShareTap ?? () {},
                icon: LocalAssets(
                  imagePath: AppIconAssets.share,
                  height: SizeConfig.size15,
                  width: SizeConfig.size15,
                ),
              ),
            ),
          ),
        if (isTrimmedButton ?? false)
          Builder(
            builder: (context) => Container(
              height: SizeConfig.size30,
              width: SizeConfig.size30,
              margin: EdgeInsets.only(right: SizeConfig.size20),
              child: IconButton(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size5),
                onPressed: onTrimmedTap ?? () {},
                icon: LocalAssets(
                  imagePath: AppIconAssets.trimmedIcon,
                  height: SizeConfig.size30,
                  width: SizeConfig.size30,
                  imgColor: AppColors.black,
                ),
              ),
            ),
          ),
        if (isSaveButton ?? false)
          Builder(
            builder: (context) => Padding(
              padding: EdgeInsets.only(right: SizeConfig.size20),
              child: CustomBtn(
                width: SizeConfig.size90,
                height: SizeConfig.size30,
                onTap: onSavedTap ?? () {},
                title: AppStrings.save,
                isValidate: true,
              ),
            ),
          ),
        if (isCancelButton ?? false)
          Builder(
            builder: (context) => InkWell(
              onTap: onCancelTap ?? () {},
              child: Padding(
                padding: EdgeInsets.only(right: SizeConfig.size10),
                child: CustomText(
                  AppStrings.cancel,
                  fontSize: SizeConfig.medium,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        if (isAddPlace ?? false)
          Builder(
            builder: (context) => Padding(
              padding: EdgeInsets.only(right: SizeConfig.size20),
              child: commonButtonWithIcon(
                  height: SizeConfig.size30,
                  width: SizeConfig.size110,
                  onTap: onAddPlaceTap ?? () {},
                  title: "Add Place",
                  icon: AppIconAssets.add,
                  borderColor: AppColors.primaryColor,
                  textColor: AppColors.primaryColor,
                  iconColor: AppColors.primaryColor,
                  isPrefix: true),
            ),
          ),
        if (isEndJourney ?? false)
          Builder(
            builder: (context) => Padding(
              padding: EdgeInsets.only(right: SizeConfig.size20),
              child: PositiveCustomBtn(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  width: SizeConfig.screenWidth / 3,
                  onTap: onEndJourneyTap ?? () {},
                  title: "End journey"),
            ),
          ),
        if (isReloadContactButton ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: InkWell(
              onTap: () {
                onRefreshContact!();
              },
              child: Center(
                child: Icon(
                  Icons.refresh,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        if (isPDFExport ?? false)
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (value) async {
              String? selectedExt;
              if (value == AppConstants.exportPDF) {
                selectedExt = "pdf";
              }
              if (value == AppConstants.exportExcel) {
                selectedExt = "xlsx";
              }
              await Get.find<AppliedJobController>().downloadCandidateList(
                  jobID: jobID, fileExtensions: selectedExt, status: jobStatus);
            },
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AppConstants.exportPDF,
                child: CustomText(
                  AppStrings.excelPdf,
                ),
              ),
              PopupMenuItem(
                value: AppConstants.exportExcel,
                child: CustomText(
                  AppStrings.exportExcel,
                ),
              ),
            ],
            child: Padding(
              padding: EdgeInsets.only(right: SizeConfig.size20),
              child: Row(
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.upload_share,
                    imgColor: AppColors.primaryColor,
                  ),
                  SizedBox(
                    width: SizeConfig.size10,
                  ),
                  CustomText(
                    AppStrings.export,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  )
                ],
              ),
            ),
          ),
        if (showRightTextButton ?? false)
          Padding(
            padding: EdgeInsets.only(right: SizeConfig.size20),
            child: TextButton(
              onPressed: onRightTextButtonTap ?? () {},
              child: CustomText(
                rightTextButtonText ?? '',

                  color: rightTextButtonColor ?? AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.medium,

              ),
            ),
          ),
        if (isCurrentAddress ?? false)
          Builder(
            builder: (context) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: SizeConfig.size15),
                child: Row(children: [
                  LocalAssets(
                    imagePath: AppIconAssets.currentLocationIcon,
                    height: SizeConfig.size24,
                    width: SizeConfig.size24,
                  ),
                  SizedBox(width: SizeConfig.size10),
                  CustomText(
                    [
                      LocationService.userCurrentAddress.value.city,
                      LocationService.userCurrentAddress.value.state,
                    ].where((e) => e.isNotEmpty).join(', '),
                    fontSize: SizeConfig.large,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            ),
          ),
        if (isShowMoreInfoIcon ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: SvgPicture.asset(
              AppIconAssets.chat_info_pop,
              height: 24,
              width: 24,
            ),
          ),
        if (isShowAcceptOrRejectBtn ?? false)
          InkWell(
            onTap: onTabAcceptBtn,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size14,
                vertical: SizeConfig.size6,
              ),
              decoration: BoxDecoration(
                color: orderAcceptBgColor,
                border: Border.all(color: orderAcceptBorderColor!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    orderAcceptText,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: orderAcceptTextColor,
                  ),
                ],
              ),
            ),
          ),
        if (isAddProductButton ?? false)
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: CustomBtn(
              width: 80,
              isValidate: true,
              onTap: () {
                AddProductCommonDialog.showAddProduct(
                  context: context,
                  categoryId: categoryId ?? "",
                );
              },
              title: "Add Product",
            ),
          ),
        if (isCreateButton ?? false)
          InkWell(
            onTap: () {
              Get.to(() => SocialActivityForm());
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: CustomText(
                "Create New",
                color: AppColors.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (isCreateEventBtn ?? false)
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => const AddPoliticianActivityEvent(),
              );
            },
            child: Container(
              width: 94,
              height: 34,
              // padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryColor)),
              child: Center(
                child: CustomText(
                  "Create Event",
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        if(isForwardUi??false)
          Row(
            children: [
              Icon(Icons.person_add_alt, color: Colors.black),
              SizedBox(width: 16),
              InkWell(
                  onTap: (){
                    Get.to(()=>BeAvailableContactsList(isFromForwardMessage: true,));
                  },
                  child: Icon(Icons.search, color: Colors.black)),
              SizedBox(width: 12),
            ],
          ),


      ],
      bottom: bottomWidget,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  ///GET CHANNEL DETAILS...

  ///GET CHANNEL DETAILS...
  Future<JourneyStatusModel?> getJourneyDetails() async {
    try {
      ResponseModel response = await TravelRepo().journeyStatusPost();

      if (response.statusCode == 200) {
        JourneyStatusModel journeyStatusModel =
            JourneyStatusModel.fromJson(response.response?.data);
        return journeyStatusModel;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
