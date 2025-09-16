import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/journey_status_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/typedef_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/applied_job_controller.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/journey/repo/travel_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_settings_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_button_with_icon.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/shared_preference_utils.dart';
import '../features/business/visiting_card/view/business_own_profile_screen.dart';

class CommonBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonBackAppBar({
    super.key,
    this.title,
    this.isLeading = true,
    this.isFilter = false,
    this.isNotification = false,
    this.bellIconNotEmpty = false,
    this.onNotificationTap,
    this.onBackTap,
    this.appBarColor,
    this.isTextButton = false,
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
    this.buildCardCategory
  });

  // final AppBar? appBar;
  final String? title;
  final String? actionText;
  final bool? isLeading;
  final bool? isFilter;
  final bool? isNotification;
  final bool bellIconNotEmpty;
  final OnTab? onNotificationTap;
  final bool? isTextButton;
  final bool? isChangeToEditMode;
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
  final OnTab? onBackTap;
  final OnTab? onShareTap;
  final OnTab? onMoreTap;
  final OnTab? onLocationTap;
  final OnTab? onQrCodeTap;
  final Color? appBarColor;
  final Color? actionTextColor;
  final bool? isTrimmedButton;
  final OnTab? onTrimmedTap;
  final bool? isSaveButton;
  final OnTab? onSavedTap;
  final bool? iClearButton;
  final OnTab? onClearNotificationsTap;
  final bool? isSettingButton;
  final bool? isAddPlace;
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
  final Widget Function()? buildCardCategory;

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context);
    return AppBar(
      elevation: 4,
      shadowColor: Colors.black26,
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
        child: Row(
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
                    imgColor: Colors.black,
                  )),
            // if (isLeading ?? false) SizedBox(width: SizeConfig.paddingXSL),
            if (isProfile ?? false)
              Builder(
                builder: (context) {
                  return InkWell(onTap: () {
                    print("Profile Tapped");
                    if (onProfileTap != null) {
                      onProfileTap!();
                    } else {
                      logs("ACCOUNT TYPE === ${accountTypeGlobal}");
                      if (isGuestUser()) {
                        createProfileScreen();
                      } else if (isIndividualUser()) {
                        navigatePushTo(context, PersonalProfileSetupScreen());
                      } else if (isBusinessUser()) {
                        navigatePushTo(context, BusinessOwnProfileScreen());
                      }
                    }
                  }, child: Obx(() {
                    return Padding(
                      padding: EdgeInsets.only(left: SizeConfig.size15),
                      child: CachedAvatarWidget(
                          imageUrl: Get.find<AuthController>().imgPath.value,
                          size: SizeConfig.size30,
                          borderRadius: 5.0,
                          showProfileOnFullScreen: false),
                    );
                  }));
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
            if (isSearch ?? false)
              (controller == null)
                  ? SizedBox()
                  : Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left:
                                (isLeading ?? false) ? 0.0 : SizeConfig.size15),
                        child: CommonSearchBar(
                          controller: controller!,
                          isShowCursor: isShowCursor,
                          onSearchTap: onSearchTap ?? () {},
                          onClearCallback: () {
                            controller?.clear();
                          },
                        ),
                      ),
                    ),
            if (currentCity != null)
              Builder(
                builder: (context) => Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    LocalAssets(
                        imagePath: AppIconAssets.currentLocationIcon,
                        imgColor: AppColors.black30),
                    SizedBox(width: SizeConfig.size5),
                    CustomText(
                      currentCity,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w400,
                      fontSize: SizeConfig.medium,
                    ),
                    SizedBox(width: SizeConfig.size5),
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
            if (isNotification ?? false)

              Builder(builder: (context) {
                return Padding(
                  padding: EdgeInsets.only(left: SizeConfig.size15),
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
                      AppLocalizations.of(context)!.clear,
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
                  logs("accountTypeGlobal=== ${accountTypeGlobal}");
                  if (isGuestUser()) {
                    createProfileScreen();
                  } else if (value == PostCreationMenu.videos ||
                      value == PostCreationMenu.photos ||
                      value == PostCreationMenu.message ||
                      value == PostCreationMenu.poll) {
                    postVia(context, value);
                  } else if (value == PostCreationMenu.place) {
                    Navigator.pushNamed(
                      context,
                      RouteHelper.getAddPlaceStepOneScreenRoute(),
                      // arguments: {
                      //   ApiKeys.onPlaceSelected: (double? lat, double? lng, String? address) {
                      //     // handle the callback
                      //   },
                      //   ApiKeys.isFromAddPlace: true
                      // },
                    );
                  } else if (value == PostCreationMenu.jobPost) {
                    Get.toNamed(RouteHelper.getCreateJobPostScreenRoute(),
                        arguments: {
                          'isEditMode': false,
                          'jobId': '',
                        });
                  }
                  // else if (value == PostCreationMenu.message) {
                  //   Get.toNamed(RouteHelper.getCreateMessagePostScreenRoute(),
                  //       arguments: {ApiKeys.post: null, ApiKeys.isEdit: false});
                  // } else if (value == PostCreationMenu.poll) {
                  //   Get.toNamed(RouteHelper.getPollInputScreenRoute());
                  // } else if (value == PostCreationMenu.photos) {
                  //   Get.toNamed(RouteHelper.getPhotoPostScreenRoute());
                  // }
                  // else if (value == PostCreationMenu.travel) {
                  //   JourneyStatusModel? journeyDetails =
                  //       await getJourneyDetails();
                  //   if (journeyDetails?.success ?? false) {
                  //     if (journeyDetails?.isEnded ?? false) {
                  //       Get.toNamed(
                  //           RouteHelper.getJourneyPlanningScreenRoute());
                  //     } else {
                  //       if (journeyDetails?.journeyId != null)
                  //         Get.toNamed(RouteHelper.getUpdateJourneyScreenRoute(),
                  //             arguments: {
                  //               ApiKeys.journey_id: journeyDetails?.journeyId
                  //             });
                  //     }
                  //   } else {
                  //     Get.toNamed(RouteHelper.getJourneyPlanningScreenRoute());
                  //   }
                  // }
                },
                icon: LocalAssets(imagePath: AppIconAssets.addOutlinedIcon),
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
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size5),
                    onPressed:  () async {
                      await showCommonDialog(
                          context: context,
                          text:
                          AppLocalizations.of(context)!.areYouSureYouWantToLogout,
                          confirmCallback: () async {
                            await SharedPreferenceUtils.clearPreference();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                RouteHelper.getMobileNumberLoginRoute(),
                                    (Route<dynamic> route) => false);
                          },
                          cancelCallback: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          confirmText: AppLocalizations.of(context)!.yes,
                          cancelText: AppLocalizations.of(context)!.no);
                    },
                    icon: LocalAssets(
                      imagePath: AppIconAssets.logout_new,
                      // height: SizeConfig.size15,
                      // width: SizeConfig.size15,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (isLogout ?? false)
          Builder(
            builder: (context) => Container(
              height: SizeConfig.size30,
              width: SizeConfig.size30,
              margin: EdgeInsets.only(right: SizeConfig.size20),
              child: IconButton(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size5),
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileSettingsScreen()));

                  /* await showCommonDialog(
                          context: context,
                          text: AppLocalizations.of(context)!
                              .areYouSureYouWantToLogout,
                          confirmCallback: () async {
                            await SharedPreferenceUtils.clearPreference();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                RouteHelper.getMobileNumberLoginRoute(),
                                    (Route<dynamic> route) => false);
                          },
                          cancelCallback: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          confirmText: AppLocalizations.of(context)!.yes,
                          cancelText: AppLocalizations.of(context)!.no);*/
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
                title: 'Save',
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
                  AppLocalizations.of(context)!.cancel,
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
              print('Selected: $value');
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
                  'Excel PDF',
                ),
              ),
              PopupMenuItem(
                value: AppConstants.exportExcel,
                child: CustomText(
                  'Export Excel',
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
                    "Export",
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
              child: Text(
                rightTextButtonText ?? '',
                style: TextStyle(
                  color: rightTextButtonColor ?? AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.medium,
                ),
              ),
            ),
          ),

        if (buildCardCategory!=null)
          Builder(
            builder: (context) => Container(
              constraints: BoxConstraints(
                  minHeight: SizeConfig.size30, // Use minHeight instead of fixed height
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.primaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              margin: EdgeInsets.only(right: SizeConfig.size20),
              child: buildCardCategory!()
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  ///GET CHANNEL DETAILS...
  Future<String?> getChannelDetails() async {
    try {
      ResponseModel response =
          await ChannelRepo().getChannelDetails(channelOrUserId: userId);

      if (response.statusCode == 200) {
        ChannelModel channelModel =
            ChannelModel.fromJson(response.response?.data);
        String channelId = channelModel.data.id;
        SharedPreferenceUtils.setSecureValue(channelId, channelId);
        return channelId;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

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
