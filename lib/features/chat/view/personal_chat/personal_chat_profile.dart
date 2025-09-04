import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/view/widget/over_view_widget.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/testimonials_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/count_clock_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/info_card_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/introduction_video_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/link_tile_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/portfolio_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_bio_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
// import '../../auth/controller/view_personal_details_controller.dart';

class PersonalChatProfile extends StatefulWidget {
  final String userId ;
  const PersonalChatProfile({super.key, required this.userId});

  @override
  State<PersonalChatProfile> createState() =>
      _PersonalChatProfileState();
}

class _PersonalChatProfileState
    extends State<PersonalChatProfile> {
  final viewProfileController = Get.put(ViewPersonalDetailsController());
  final personalCreateProfileController =
      Get.put(PersonalCreateProfileController());
  final introVideoController = Get.put(IntroductionVideoController());
  final youtubeController = TextEditingController();
  List<String> postTab = [];
  int selectedIndex = 0;
  late VisitProfileController controller;
  @override
  void initState() {
    super.initState();
      controller = Get.put(VisitProfileController());

    // controller.fetchUserById(userId: "6891a80e721656f3ca842eba");
   controller.fetchUserById(userId: widget.userId);
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadInitialData() async {
    await viewProfileController.viewPersonalProfile();
    await viewProfileController.UserFollowersAndPostsCount();

    _updateTextControllers();
  }

  void _updateTextControllers() {
    if (selectedInputFieldsPersonalProfile.isNotEmpty &&
        selectedInputFieldsPersonalProfile.length >= 5) {
      selectedInputFieldsPersonalProfile[0].linkController.text =
          viewProfileController.youtube.value;
      selectedInputFieldsPersonalProfile[1].linkController.text =
          viewProfileController.twitter.value;
      selectedInputFieldsPersonalProfile[2].linkController.text =
          viewProfileController.linkedin.value;
      selectedInputFieldsPersonalProfile[3].linkController.text =
          viewProfileController.instagram.value;
      selectedInputFieldsPersonalProfile[4].linkController.text =
          viewProfileController.website.value;
    }
  }

  bool _shouldShowBioSection() {
    final bio = viewProfileController.personalProfileDetails.value.user?.bio;
    return bio != null && bio.trim().isNotEmpty;
  }

  bool _hasAnyLinks() {
    // Check if any social link is not null and not empty
    return (viewProfileController.instagram.value.isNotEmpty) ||
        (viewProfileController.website.value.isNotEmpty) ||
        (viewProfileController.linkedin.value.isNotEmpty) ||
        (viewProfileController.twitter.value.isNotEmpty) ||
        (viewProfileController.youtube.value.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: '',
        
        onShareTap: () {},
        onQrCodeTap: () {},
        onBackTap: () async {
          await Get.delete<IntroductionVideoController>();
          await Get.delete<ViewPersonalDetailsController>();
          Get.back();
        },
      ),
      // floatingActionButton: FloatingActionButton(onPressed: (){
      //   Get.to(()=>AddAccountScreen());
      //
      // }),
      body: Obx(() {
        final user = controller.userData.value?.user;
        logs(
            "viewProfileController.viewPersonalResponse.value.status  ${viewProfileController.viewPersonalResponse.value.status}");
        if (viewProfileController.viewPersonalResponse.value.status ==
            Status.COMPLETE) {
          // Unused currently; keep in case of future logic
          // final profession = viewProfileController
          //         .personalProfileDetails.value.user?.profession ??
          //     "OTHERS";
          postTab = [
            // if (viewProfileController
            //         .personalProfileDetails.value.user?.profession ==
            //     ProfessionType.SELF_EMPLOYED.name)
              'Overview',
              'Testimonials',
            'Shorts',
            'Posts',
            'Videos'
            
          ];
          return SafeArea(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size8, horizontal: SizeConfig.size20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: SizeConfig.size8),
                  Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              right: SizeConfig.size18, top: SizeConfig.size4),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: EdgeInsets.all(SizeConfig.size3),
                                // border thickness
                                
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey,
                                  backgroundImage: 
                                  user
                                              ?.profileImage !=
                                          null
                                      ? 
                                      NetworkImage(
                                          user!
                                          .profileImage!)
                                      : null,
                                  // child: viewProfileController
                                  //             .personalProfileDetails
                                  //             .value
                                  //             .user
                                  //             ?.profileImage ==
                                  //         null
                                  //     ? CustomText(
                                  //         (viewProfileController
                                  //                     .personalProfileDetails
                                  //                     .value
                                  //                     .user
                                  //                     ?.name ??
                                  //                 '')
                                  //             .trim()
                                  //             .split(' ')
                                  //             .map((e) =>
                                  //                 e.isNotEmpty ? e[0] : '')
                                  //             .take(2)
                                  //             .join()
                                  //             .toUpperCase(),
                                  //       )
                                  //     : null,
                                ),
                              ),
                            
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: SizeConfig.size10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth:
                                                  SizeConfig.screenWidth / 3),
                                          child: CustomText(
                                           user!.name??
                                                '',
                                            fontSize: SizeConfig.large,
                                            fontWeight: FontWeight.bold,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: SizeConfig.size2,
                                        ),
                                        // SvgPicture.asset(
                                        //     AppIconAssets.verify_v_profile),
                                      ],
                                    ),
                                    // Row(
                                    //   mainAxisAlignment: MainAxisAlignment.end,
                                    //   children: [
                                    //     InkWell(
                                    //         onTap: () {
                                    //           Navigator.push(
                                    //               context,
                                    //               MaterialPageRoute(
                                    //                   builder: (context) =>
                                    //                       ProfileSettingsScreen()));
                                    //         },
                                    //         child: SvgPicture.asset(
                                    //             AppIconAssets
                                    //                 .profile_v_settings)),
                                    //     SizedBox(
                                    //       width: SizeConfig.size16,
                                    //     ),
                                    //     InkWell(
                                    //         onTap: () {
                                    //         //   Navigator.push(
                                    //         //       context,
                                    //         //       MaterialPageRoute(
                                    //         //           builder: (context) =>
                                    //         //               VisitPersonalProfile()));
                                    //         },
                                    //         child: SvgPicture.asset(
                                    //             AppIconAssets.upload_share)),
                                    //   ],
                                    // ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                CustomText(user.contactNo,
                                    color: Color.fromRGBO(107, 124, 147, 1)),
                                SizedBox(height: SizeConfig.size5),

                                Row(
                                  children: [
                                    if(user.email!=null)
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey)
                                      ),
                                      child: 
                                       CustomText("${user.email}"),
                                    ),
                                    if(user.designation!=null)
                                     Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey)
                                  ),
                                  child: 
                                   CustomText("${user.designation}"),
                                ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size5),
                                Obx(() {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 38.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: StatBlock(
                                              count:controller.userData.value!.totalPosts.toString(),
                                              label: "Posts",
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: SizeConfig.size3),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.center,
                                            child: StatBlock(
                                              count: controller.userData.value!.followersCount.toString(),
                                              label: "Followers",
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: SizeConfig.size5),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: StatBlock(
                                              count:  controller.userData.value!.followingCount.toString(),
                                              label: "Following",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size16),


                

                  HorizontalTabSelector(
                    horizontalMargin: 0,
                    tabs: postTab,
                    selectedIndex: selectedIndex,
                    onTabSelected: (index, value) {
                      setState(() => selectedIndex = index);
                    },
                    labelBuilder: (label) => label,
                  ),
                  SizedBox(height: SizeConfig.size16),
                  _buildTabContent(selectedIndex)
                ],
              ),
            ),
          );
        } else {
          return SizedBox();
        }
      }),
    );
  }

  Widget _buildTabContent(int index) {
    switch (postTab[index]) {
      case 'Overview':
        return ChatProfileOverview(
     userId: widget.userId,
        );
    
      case 'Posts':
        return FeedScreen(
            key: ValueKey('feedScreen_user_posts_${widget.userId}'),
            postFilterType: PostType.otherPosts,
            isInParentScroll: true,
          
            id: widget.userId);
      // case 'Achievements':
      // return AchievementsWidget();
      case 'Testimonials':
        return TestimonialsScreen(
          userName: "",
          visitUserID: userId,
          isSelfTestimonial: true,
        );
     case 'Shorts':
     return   ShortsChannelSection(
            isOwnChannel: false,
            channelId: '',
            authorId: widget.userId,
            showShortsInGrid: false,
          );
      default:
        return const Center(child: Text('Unknown Tab'));
    }
  }

  Widget AboutMeWidget() {
    return Column(
      children: [
        SizedBox(height: SizeConfig.size18),

        // Add the IntroductionVideoWidget here
        IntroductionVideoWidget(),
        SizedBox(height: SizeConfig.size18),

        // Links Section - Show add links form or link preview card based on data
        Obx(() {
          final hasAnyLinks = _hasAnyLinks();

          // If all social links are null or empty, or in edit mode, show the form
          if (!hasAnyLinks || viewProfileController.isSocialEdit.value) {
            return Container(
              padding: EdgeInsets.only(
                top: SizeConfig.size15,
                left: SizeConfig.size15,
                right: SizeConfig.size15,
                bottom: SizeConfig.size5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText("Add Links"),
                  SizedBox(height: SizeConfig.size16),
                  Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.size14),
                    child: HttpsTextField(
                      controller: youtubeController,
                      isYoutubeValidation: true,
                      pIcon: Container(
                        width: 40,
                        child: Center(
                          child: SvgPicture.asset(
                            "assets/svg/youtube_grey.svg",
                            height: SizeConfig.size24,
                            width: SizeConfig.size24,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                      // hintText: "Your your URL here",
                      hintText: "Your Youtube URL here",

                      onChange: (value) {
                        viewProfileController.isYoutubeEdit.value = value;
                      },
                    ),
                  ),
                  /*   Column(
                    children: List.generate(
                      selectedInputFieldsPersonalProfile.length,
                      (linkIndex) {
                        final field =
                            selectedInputFieldsPersonalProfile[linkIndex];
                        return Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size14),
                          child: HttpsTextField(
                            controller: field.linkController,
                            pIcon: Container(
                              width: 40,
                              child: Center(
                                child: SvgPicture.asset(
                                  field.icon,
                                  height: SizeConfig.size24,
                                  width: SizeConfig.size24,
                                  fit: BoxFit.fitHeight,
                                ),
                              ),
                            ),
                           // hintText: "Your your URL here",
                             hintText: "Your ${field.name} URL here",
                            onChange: (value) {},
                          ),
                        );
                      },
                    ),
                  ),*/
                  SizedBox(height: SizeConfig.size10),
                  CustomBtn(
                    isValidate:
                        viewProfileController.isYoutubeEdit.value.isNotEmpty,
                    onTap: viewProfileController.isYoutubeEdit.value.isNotEmpty
                        ? () async {
                            if (youtubeController.text.isEmpty) {
                              commonSnackBar(
                                  message: "Enter youtube link here...");
                              return;
                            }
/*
                      for (var field in selectedInputFieldsPersonalProfile) {
                        String name = field.name.toLowerCase();
                        String url = field.linkController.text.trim();

                        switch (name) {
                          case 'youtube':
                            viewProfileController.youtube.value = url;
                            break;
                          case 'twitter':
                            viewProfileController.twitter.value = url;
                            break;
                          case 'linkedin':
                            viewProfileController.linkedin.value = url;
                            break;
                          case 'instagram':
                            viewProfileController.instagram.value = url;
                            break;
                          case 'website':
                            viewProfileController.website.value = url;
                            break;
                        }
                      }*/
                            await personalCreateProfileController
                                .updateUserProfileDetails(
                              params: {
                                ApiKeys.id: userId,
                                ApiKeys.youtube: youtubeController.text,
                                // ApiKeys.twitter: viewProfileController.twitter.value,
                                // ApiKeys.linkedin:
                                //     viewProfileController.linkedin.value,
                                // ApiKeys.instagram:
                                //     viewProfileController.instagram.value,
                                // ApiKeys.website: viewProfileController.website.value,
                              },
                            );
                            viewProfileController.isSocialEdit.value = false;
                            // await viewProfileController.viewPersonalProfile();
                          }
                        : null,
                    title: "Save",
                  ),
                  SizedBox(height: SizeConfig.size16),
                ],
              ),
            );
          }

          // If any social link exists and not in edit mode, show link preview card with edit icon
          if (hasAnyLinks && !viewProfileController.isSocialEdit.value) {
            return InfoCard(
              icon: AppIconAssets.links_profile_header_icon,
              title: "Links",
              onTap: () {
                viewProfileController.isSocialEdit.value = true;
                _updateTextControllers(); // Update text controllers with current values
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: SizeConfig.size12),
                  if (viewProfileController.instagram.value.isNotEmpty)
                    LinkTile(
                      label: "Instagram",
                      url: viewProfileController.instagram.value,
                    ),
                  if (viewProfileController.website.value.isNotEmpty)
                    LinkTile(
                      label: "Website",
                      url: viewProfileController.website.value,
                    ),
                  if (viewProfileController.linkedin.value.isNotEmpty)
                    LinkTile(
                      label: "LinkedIn",
                      url: viewProfileController.linkedin.value,
                    ),
                  if (viewProfileController.twitter.value.isNotEmpty)
                    LinkTile(
                      label: "Twitter",
                      url: viewProfileController.twitter.value,
                    ),
                  if (viewProfileController.youtube.value.isNotEmpty)
                    LinkTile(
                      label: "YouTube",
                      url: viewProfileController.youtube.value,
                    ),
                ],
              ),
            );
          }

          return SizedBox();
        }),
      ],
    );
  }

  bool isValidYouTubeUrl(String url) {
    final RegExp youTubeRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[\w\-]{11}(&\S*)?$',
      caseSensitive: false,
    );
    return youTubeRegex.hasMatch(url.trim());
  }
}
