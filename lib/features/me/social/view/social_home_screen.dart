import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/social/controller/social_home_controller.dart';
import 'package:BlueEra/features/me/social/model/social_profile_res_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialHomeScreen extends StatefulWidget {
  SocialHomeScreen({super.key});

  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> {
  final ctrl = Get.put(SocialHomeController());

  final personalCreateProfileController =
      getOrPut(() => PersonalCreateProfileController());

  final viewProfileController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  @override
  void initState() {
    // TODO: implement initState
    ctrl.fetchProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.profile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = ctrl.profile.value?.data;
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size8),
          child: Column(
            children: [
              _buildHeaderSection(context),
              _identityCard(data?.identity),
              _activitiesCard(data?.activities ?? []),
              _missionVisionCard(data?.missionVision),
              _activitiesCard(data?.activities ?? []),
              _eventsCard(data?.events ?? []),
              _achievementsCard(data?.achievements ?? []),
              _socialActivitiesCard(data?.socialActivities ?? []),
              // 5. Contact Section
              _buildContactCard(data),

              CommonCardWidget(
                padding: 0,
                child: BusinessLocationWidget(
                    locationText: "",
                    latitude: double.parse(
                        data?.contact?.location?.coordinates?[0].toString() ??
                            "0.0"),
                    longitude: double.parse(
                        data?.contact?.location?.coordinates?[1].toString() ??
                            "0.0"),
                    businessName: "",
                    padding: 0,
                    isTitleShow: true),
              ),

              SizedBox(height: kBottomNavigationBarHeight + 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContactCard(SocialProfileData? profile) {
    return CommonCardWidget(
      padding: 5,
      // cardMargin: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 6),
            child: const CustomText("Contact Us", fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                    viewProfileController
                        .personalProfileDetails.value.user?.name,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),

                const SizedBox(height: 5),

                // Contact List
                _contactItem(AppIconAssets.website_click,
                    profile?.contact?.websiteUrl ?? "", Colors.blue),
                _contactItem(
                    AppIconAssets.principal, "Reception", Colors.grey[700]!),
                _contactItem(AppIconAssets.email, profile?.contact?.email ?? "",
                    AppColors.secondaryTextColor),
                _contactItem(
                    AppIconAssets.phone_outline,
                    profile?.contact?.phoneNo ?? "",
                    AppColors.secondaryTextColor),
                _contactItem(AppIconAssets.location_new,
                    profile?.contact?.location?.name ?? "", Colors.grey[700]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(label, fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    String _capitalizeFirstLetter(String text) {
      if (text.isEmpty) return '';
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
      ),
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A1A1A), Color(0xFF2B2B2B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Obx(() {
                        final banner = personalCreateProfileController
                                .coverImagePath?.value ??
                            '';
                        return banner.isNotEmpty
                            ? Image.network(banner, fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: personalCreateProfileController
                                        .imagePath?.value ??
                                    '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: SizeConfig.size32,
                                  height: SizeConfig.size32,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    size: SizeConfig.size32 / 2),
                              );
                      }),
                    ),
                  ),

                  // Profile Image
                  Positioned(
                    left: 20,
                    top: 90,
                    child: Obx(() {
                      return CommonProfileImage(
                        imagePath:
                            personalCreateProfileController.imagePath?.value ??
                                "",
                        onImageUpdate: (image) async {
                          personalCreateProfileController.imagePath?.value =
                              image;
                          dynamic dataImage =
                              await multiPartImage(imagePath: image);
                          var reqProfile = {ApiKeys.profile_image: dataImage};
                          await personalCreateProfileController
                              .updateUserProfileDetails(
                                  params: reqProfile, isFromProfileOnly: true);
                        },
                        dialogTitle: AppStrings.uploadProfilePicture,
                        //radius: 36,
                        showProfileBorder: true,
                      );
                    }),
                  ),

                  Positioned(
                      right: 10,
                      top: 8,
                      child: InkWell(
                          onTap: () async {
                            final String? newPath =
                                await SelectProfilePictureDialog.showLogoDialog(
                                    context, AppStrings.editCoverPicture,
                                    cropAspectRatio:
                                        CropAspectRatio(width: 3, height: 1)
                                    // cropAspectRatio: CropAspectRatio(width: 16, height: 9)
                                    );

                            if (newPath == null || newPath.isEmpty) {
                              return;
                            }

                            dynamic dataImage =
                                await multiPartImage(imagePath: newPath);
                            var reqProfile = {ApiKeys.coverpicture: dataImage};
                            await personalCreateProfileController
                                .updateUserProfileDetails(
                                    params: reqProfile,
                                    isFromProfileOnly: true);
                          },
                          child: CircleAvatar(
                            backgroundColor:
                                AppColors.black.withValues(alpha: 0.3),
                            child: LocalAssets(
                                imagePath: 'assets/images/image.png'),
                          )))
                ],
              ),
            ),

            // const SizedBox(height: 48),

            // === Name + Role ===
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomText(
                    _capitalizeFirstLetter(
                      viewProfileController
                              .personalProfileDetails.value.user?.name ??
                          '',
                    ),
                    fontSize: SizeConfig.size24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  // const SizedBox(height: 8),
                 /* Row(
                    children: [
                      (viewProfileController
                                  .personalProfileDetails.value.user?.name ==
                              '')
                          ? SizedBox()
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: BoxBorder.all(
                                    color: AppColors.secondaryTextColor,
                                  )),
                              child: CustomText(
                                viewProfileController.personalProfileDetails
                                        .value.user?.username ??
                                    '',
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                      const SizedBox(
                        width: 6,
                      ),
                      if (viewProfileController.personalProfileDetails.value
                              .user?.profession?.isNotEmpty ??
                          false)
                        InkWell(
                          onTap: () {
                            // _showCategoryBottomSheet();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: BoxBorder.all(
                                  color: AppColors.secondaryTextColor,
                                )),
                            child: Row(
                              children: [
                                CustomText(
                                  viewProfileController.personalProfileDetails
                                          .value.user?.designation ??
                                      '',
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                ),
                                SizedBox(width: SizeConfig.size10),
                                LocalAssets(
                                  imagePath: AppIconAssets.editIcon,
                                  height: SizeConfig.size12,
                                  width: SizeConfig.size12,
                                  imgColor: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        )
                    ],
                  ),*/
                ],
              ),
            ),
            // === Bio Section ===
            viewProfileController
                        .personalProfileDetails.value.user?.bio?.isNotEmpty ??
                    false
                ? Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                    child: ExpandableText(
                      text: viewProfileController
                              .personalProfileDetails.value.user?.bio ??
                          "",
                      trimLines: 3,
                      style: TextStyle(
                        color: AppColors.mainTextColor,
                        fontSize: 14,
                        wordSpacing: 0.4,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w400,
                        height:
                            1.5, // 👈 increases vertical gap between lines (default is ~1.0)
                      ),
                      expandMode: ExpandMode.dialog,
                      dialogTitle: AppStrings.bio,
                    ),
                  )
                : SizedBox(),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _identityCard(identity) {
    return CommonCardWidget(
      child: SizedBox(
        width: Get.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText("Short Bio", fontWeight: FontWeight.w600),
            SizedBox(height: SizeConfig.size10),
            CustomText(identity?.bio ?? "-"),
            SizedBox(height: SizeConfig.size10),
            CustomText("Journey", fontWeight: FontWeight.w600),
            SizedBox(height: SizeConfig.size8),
            CustomText(identity?.journey ?? "-",
                color: AppColors.black28, fontSize: SizeConfig.small),
            SizedBox(height: SizeConfig.size10),
            CustomText("Family Background", fontWeight: FontWeight.w600),
            SizedBox(height: SizeConfig.size8),
            CustomText(identity?.familyBackground ?? "-",
                color: AppColors.black28, fontSize: SizeConfig.small),
          ],
        ),
      ),
    );
  }

  Widget _missionVisionCard(mv) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText("Mission & Vision", fontWeight: FontWeight.w600),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          if (mv?.mediaUrl != null && (mv?.mediaUrl as String).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(SizeConfig.size8),
              child: Image.network(
                mv?.mediaUrl ?? "",
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          SizedBox(height: SizeConfig.size10),
          CustomText(mv?.description ?? "-"),
        ],
      ),
    );
  }

  Widget _activitiesCard(List activities) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText("Activities", fontWeight: FontWeight.w600),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          _responsiveGrid(
            itemCount: activities.length,
            builder: (context, index) {
              final a = activities[index];
              return _mediaTile(
                  a?.title ?? "-",
                  (a?.mediaUrls ?? []).isNotEmpty
                      ? a?.mediaUrls?.first ?? ""
                      : "",
                  a?.description ?? "");
            },
          ),
        ],
      ),
    );
  }

  Widget _eventsCard(List events) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText("Events", fontWeight: FontWeight.w600),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size6),
            itemBuilder: (context, index) {
              final e = events[index];
              return _eventTile(
                e?.title ?? "-",
                e?.venue?.name ?? e?.venue?.location?.name ?? "-",
                e?.timing?.from ?? "",
                e?.timing?.to ?? "",
                e?.eventType ?? "",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _achievementsCard(List achievements) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText("Achievements", fontWeight: FontWeight.w600),
          SizedBox(height: SizeConfig.size10),
          _responsiveGrid(
            itemCount: achievements.length,
            builder: (context, index) {
              final c = achievements[index];
              return _mediaTile(
                  c?.title ?? "-", c?.fileUrl ?? "", c?.description ?? "");
            },
          ),
        ],
      ),
    );
  }

  Widget _socialActivitiesCard(List socialActivities) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText("Social Activities", fontWeight: FontWeight.w600),
          SizedBox(height: SizeConfig.size10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: socialActivities.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size6),
            itemBuilder: (context, index) {
              final s = socialActivities[index];
              return _socialActivityTile(
                s?.title ?? "-",
                s?.description ?? "",
                s?.location?.name ?? "-",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _responsiveGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) builder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width > 1000) {
          crossAxisCount = 3;
        } else if (width > 600) {
          crossAxisCount = 2;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: SizeConfig.size8,
            crossAxisSpacing: SizeConfig.size8,
            childAspectRatio: 3 / 2,
          ),
          itemBuilder: builder,
        );
      },
    );
  }

  Widget _mediaTile(String title, String url, String description) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(SizeConfig.size8),
                topRight: Radius.circular(SizeConfig.size8),
              ),
              child: url.isNotEmpty
                  ? Image.network(url,
                      width: double.infinity, fit: BoxFit.cover)
                  : Container(color: AppColors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(title, fontWeight: FontWeight.w600),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.black28,
                  fontSize: SizeConfig.small,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _eventTile(
      String title, String location, String from, String to, String type) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(title, fontWeight: FontWeight.w600),
          SizedBox(height: SizeConfig.size6),
          CustomText(location, color: AppColors.black28),
          SizedBox(height: SizeConfig.size6),
          CustomText("$from - $to • $type",
              color: AppColors.black28, fontSize: SizeConfig.small),
        ],
      ),
    );
  }

  Widget _socialActivityTile(
      String title, String description, String location) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(title, fontWeight: FontWeight.w600),
          SizedBox(height: SizeConfig.size6),
          CustomText(description, color: AppColors.black28),
          SizedBox(height: SizeConfig.size6),
          CustomText(location,
              color: AppColors.black28, fontSize: SizeConfig.small),
        ],
      ),
    );
  }
}