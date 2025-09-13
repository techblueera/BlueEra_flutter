import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/response/get_countRating_response_modal.dart';
import 'package:BlueEra/core/api/model/user_profile_res.dart';
import 'package:BlueEra/core/api/model/user_testimonial_model.dart';
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
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/view/widget/over_view_widget.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart'
    hide User;
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_media_carosal_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_poll_options_widget.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/common/reelsModule/font_style.dart';
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
import 'package:BlueEra/features/personal/personal_profile/view/widget/testimonial_listing_widget.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/channel_profile_header.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/horizontal_tab_selector.dart';

class PersonalChatProfile extends StatefulWidget {
  final String userId;
  final String channelId;
  final String? contactNumber;
  final bool isTestimonialRating;
  PersonalChatProfile(
      {super.key,
      required this.userId,
      this.contactNumber,
      this.channelId='',
      this.isTestimonialRating = false});

  @override
  State<PersonalChatProfile> createState() => _PersonalChatProfileState();
}

class _PersonalChatProfileState extends State<PersonalChatProfile> {
  final viewProfileController = Get.put(ViewPersonalDetailsController());
  final personalCreateProfileController =
      Get.put(PersonalCreateProfileController());
  final VideoController videosController =
      Get.put<VideoController>(VideoController());
  VideoType videoType = VideoType.latest;

  final ShortsController shortsController =
      Get.put<ShortsController>(ShortsController());

  final youtubeController = TextEditingController();
  List<String> postTab = [];
  int selectedIndex = 0;
  late VisitProfileController controller;
  final GlobalKey _cardKey = GlobalKey();
  double _cardHeight = 0;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VisitProfileController());
    log('author id-- ${widget.userId}');
    // controller.fetchUserById(userId: "689deb7aac8beb10537e3107");
    controller.fetchUserById(userId: widget.userId);
    controller.getCountRatingByUser(userId: widget.userId);
    controller.getRatingSummary(userId: widget.userId);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await viewProfileController
        .viewPersonalProfiles(widget.contactNumber ?? "");
    await viewProfileController.UserFollowersAndPostsCount(widget.userId);
    await controller.getTestimonialController(userID: widget.userId);
    await viewProfileController.getAllPostApi(widget.userId);
    shortsController.getShortsByType(
      Shorts.latest,
      widget.channelId,
      widget.userId
    );

    videosController.getVideosByType(videoType, '', widget.userId);

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
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size4, vertical: SizeConfig.size10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Obx(
                () => widget_profileHeader(controller.userData.value?.user),
              ),
              SizedBox(
                height: SizeConfig.size12,
              ),
              buildCustomTabRow(
                selectedIndex: selectedIndex,
                onTabSelected: (p0) {
                  setState(() {
                    selectedIndex = p0;
                  });
                },
              ),
              SizedBox(
                height: SizeConfig.size8,
              ),
              _buildTabWidget(selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabWidget(int index) {
    switch (index) {
      case 0:
        return overViewTabWidget();
      case 1:
        return testimonialsTab();
      case 2:
        return buildPostCard(
            posts: viewProfileController.postRes.value?.data ?? []);
      case 3:
        return ShortsChannelSection(
          isOwnShorts: true,
          channelId: '',
          authorId: widget.userId,
          showShortsInGrid: true,
          postVia: PostVia.profile,
        );
      case 4:
        return VideoChannelSection(
          isOwnVideos: true,
          channelId: '',
          authorId: widget.userId,
          postVia: PostVia.profile,
          boxShadow: [
              BoxShadow(
                  color: Color(0xFA999999),
                  offset: Offset(0, 0.65),
                  blurRadius: 1.3
              )
            ]
        );
      default:
        return Text("Not implemented");
    }
  }

  Widget overViewTabWidget() {
    return Column(
      children: [
        Obx(
          () => buildRatingSummary(
            rating: double.parse(
                (controller.getRattingSummaryResponse.value?.data?.avgRating ??
                        0)
                    .toString()),
            totalReviews: "5,455",
            reviewData: controller.getCountRattingResponse.value?.data ?? [],
            totalRating: controller.getCountRattingResponse.value?.data
                    ?.map(
                      (e) => e.count!,
                    )
                    .reduce(
                      (value, element) => value + element,
                    ) ??
                1,
          ),
        ),
        SizedBox(
          height: controller.testimonialsList?.value.isEmpty ?? true ? 0 : 12,
        ),
        Obx(
          () {
            return controller.testimonialsList?.value.isEmpty ?? true
                ? SizedBox()
                : buildTestimonialsCard(
                    controller.testimonialsList?.value ?? []);
          },
        ),
        SizedBox(
          height: 12,
        ),
        Obx(
          () => buildPostCard(
              posts: viewProfileController.postRes.value?.data ?? []),
        ),

        // SizedBox(
        //   height: 20,
        // ),
        Obx(()=> buildHorizontalSortsList()),

        // SizedBox(
        //   height: 20,
        // ),

        Obx(()=> customVideoCard()),

        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  widget_profileHeader(User? user) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 10.0,
                          left: 10.0,
                          right: 10.0,
                          bottom: 10.0,
                      ),
                      child: InkWell(
                        onTap: (){
                          navigatePushTo(
                            context,
                            ImageViewScreen(
                              appBarTitle: AppLocalizations.of(context)!.imageViewer,
                              imageUrls: [user?.profileImage ?? ""],
                              initialIndex: 0,
                            ),
                          );
                        },
                        child: CachedAvatarWidget(
                            imageUrl: user?.profileImage ?? "",
                            size: SizeConfig.size60,
                            borderRadius: SizeConfig.size30)
                        ,
                      ),
                    ),
                    CustomBtn(
                      onTap: () {
                        controller.isFollow.value
                            ? controller
                                .unFollowUserController(
                                    candidateResumeId: user?.id)
                                .then((value) => controller.fetchUserById(
                                      userId: widget.userId,
                                    ))
                            : controller
                                .followUserController(
                                    candidateResumeId: user?.id)
                                .then((value) => controller.fetchUserById(
                                      userId: widget.userId,
                                    ));
                      },
                      title: controller.isFollow.value ? "UnFollow" : "Follow",
                      fontWeight: FontWeight.bold,
                      height: SizeConfig.size24,
                      bgColor: AppColors.skyBlueDF,
                      width: SizeConfig.size60,
                      radius: SizeConfig.size8,
                    ),

                    // InkWell(
                    //   onTap: () {
                    //     showDialog(
                    //       context: context,
                    //       builder: (context) {
                    //         return buildProfilePopup(
                    //             contact: user?.contactNo ?? "",
                    //             dob:
                    //                 "${user?.dateOfBirth?.month ?? ""},${user?.dateOfBirth?.date ?? ""}",
                    //             email: user?.email ?? "",
                    //             location:
                    //                 "${user?.userLocation?.lat ?? ""},${user?.userLocation?.lon ?? ""}",
                    //             channel: user?.accountType ?? "",
                    //             designation: user?.designation ?? "",
                    //             name: user?.name ?? "");
                    //       },
                    //     );
                    //   },
                    //   child: CustomText(
                    //     "View Channel",
                    //     color: AppColors.skyBlueDF,
                    //     fontWeight: FontWeight.w600,
                    //     fontSize: 10,
                    //     decoration: TextDecoration.underline,
                    //     decorationColor: AppColors.skyBlueDF,
                    //   ),
                    // ),
                  ],
                ),
                SizedBox(
                  width: SizeConfig.size8,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    child: CustomText(
                                      (user?.name ?? "").capitalizeFirst,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: SizeConfig.size18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(
                                    width: SizeConfig.size2,
                                  ),
                                  user?.emailVerified ?? false
                                      ? Icon(
                                          Icons.verified,
                                          color: AppColors.skyBlueDF,
                                          size: 16,
                                        )
                                      : SizedBox(),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.size10,
                            ),
                            PopupMenuButton(
                                onSelected: (value) async {
                                  if (value == 1) {
                                    if (_isSharing) return;

                                    try {
                                      _isSharing = true; // Set flag to prevent multiple calls

                                      final link = profileDeepLink(userId: widget.userId);
                                      final message = "See my profile on BlueEra:\n$link\n";

                                      await SharePlus.instance.share(ShareParams(
                                        text: message,
                                        subject: user?.name,
                                      ));

                                    } catch (e) {
                                      print("Profile share failed: $e");
                                    } finally {
                                      _isSharing = false; // Reset flag
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                      PopupMenuItem(
                                          value: 1,
                                          child: Row(
                                            children: [
                                              Icon(Icons.share),
                                              CustomText("Share"),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 2, child: CustomText("Mute")),
                                      PopupMenuItem(
                                          value: 3, child: CustomText("Block"))
                                    ])
                          ],
                        ),
                      ),

                      // ""
                      // CustomText(
                      //   "+91 2343543545",
                      //   color: AppColors.blackD9,
                      //   fontWeight: FontWeight.w600,
                      //   fontSize: 15,
                      // ),
                      SizedBox(
                        height: SizeConfig.size5,
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return buildProfilePopup(
                                  contact: user?.contactNo ?? "",
                                  dob:
                                      "${user?.dateOfBirth?.month ?? ""},${user?.dateOfBirth?.date ?? ""}",
                                  email: user?.email ?? "",
                                  location:
                                      "${user?.userLocation?.lat ?? ""},${user?.userLocation?.lon ?? ""}",
                                  channel: user?.accountType ?? "",
                                  designation: user?.designation ?? "",
                                  name: user?.name ?? "");
                            },
                          );
                        },
                        child: CustomText(
                          "Personal Details",
                          color: AppColors.skyBlueDF,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.skyBlueDF,
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size5,
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: SizeConfig.size16, color: AppColors.black),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(
                            "Join US:  ",
                            fontWeight: FontWeight.w600,
                          ),
                          Expanded(
                            child: CustomText(
                              "${getMonthName(user?.dateOfBirth?.month ?? 0)}, ${user?.dateOfBirth?.year ?? ""}",
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.black,
                            ),
                          )
                        ],
                      ),

                      SizedBox(height: SizeConfig.size10),
                      // Row(
                      //   children: [
                      //     _buildTag(user?.username ?? ""),
                      //     SizedBox(width: SizeConfig.size6),
                      //     _buildTag(user?.designation ?? ""),
                      //   ],
                      // ),
                      // SizedBox(
                      //   height: SizeConfig.size8,
                      // ),

                      // SizedBox(
                      //   height: SizeConfig.size8,
                      // ),
                      Row(
                        children: [
                          // RichText(
                          //     maxLines: 1,
                          //     overflow: TextOverflow.ellipsis,
                          //     text: TextSpan(
                          //         text:
                          //             "${viewProfileController.postsCount.value} ",
                          //         style: TextStyle(
                          //           color: AppColors.black,
                          //           fontSize: 16,
                          //         ),
                          //         children: [
                          //           TextSpan(
                          //               text: "Posts",
                          //               style: TextStyle(
                          //                   color: AppColors.coloGreyText))
                          //         ])),
                          // SizedBox(
                          //   height: SizeConfig.size20,
                          //   child: VerticalDivider(
                          //     width: SizeConfig.size14,
                          //     color: AppColors.borderGray,
                          //     thickness: 1,
                          //   ),
                          // ),
                          Flexible(
                            child: InkWell(
                              onTap: (){
                                Get.to(()=> FollowersFollowingPage(
                                  tabIndex: 0,
                                  userID: controller.userData.value?.user?.id ?? "",
                                ));
                              },
                              child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                      text:
                                          "${(controller.userData.value?.followingCount ?? "").toString()} ",
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontSize: 16,
                                      ),
                                      children: [
                                        TextSpan(
                                            text: "Following",
                                            style: TextStyle(
                                                color: AppColors.coloGreyText))
                                      ])),
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.size20,
                            child: VerticalDivider(
                              width: SizeConfig.size14,
                              color: AppColors.borderGray,
                              thickness: 1,
                            ),
                          ),
                          Flexible(
                            child: InkWell(
                              onTap: (){
                                Get.to(()=> FollowersFollowingPage(
                                  tabIndex: 1,
                                  userID: controller.userData.value?.user?.id ?? "",
                                ));
                              },
                              child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                      text:
                                          "${(controller.userData.value?.followersCount ?? "").toString()} ",
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontSize: 16,
                                      ),
                                      children: [
                                        TextSpan(
                                            text: "Followers",
                                            style: TextStyle(
                                              color: AppColors.coloGreyText,
                                            ))
                                      ])),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: SizeConfig.size12,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            ReadMoreText(
              viewProfileController.overView.value,
              trimMode: TrimMode.Line,
              trimLines: 2,
              colorClickableText: AppColors.primaryColor,
              trimCollapsedText: ' Show more',
              trimExpandedText: ' Show less',
              moreStyle: AppFontStyle.styleW500(
                  AppColors.primaryColor, SizeConfig.size14),
            ),
          ],
        ),
      ),
    );
  }

  _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget buildProfilePopup(
      {required String contact,
      required String email,
      required String dob,
      required String location,
      required String channel,
      required String name,
      required String designation}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            Center(
              child: Card(
                elevation: 10,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          InkWell(
                              onTap: () => Get.back(),
                              child: Icon(Icons.close)),
                        ],
                      ),
                      Text(
                        designation,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Divider(thickness: 2, height: 30, color: Colors.grey),
                      buildInfoRow(
                        Icons.phone,
                        'Contact',
                        contact,
                        "tel:$contact",
                      ),
                      const SizedBox(height: 20), // Spacer
                      buildInfoRow(
                        Icons.email_outlined,
                        'Email',
                        email,
                        Uri(
                          scheme: 'mailto',
                          path: 'smith@example.com',
                          queryParameters: {
                            'subject': 'Example Subject & Symbols are allowed!',
                          },
                        ).toString(),
                      ),
                      const SizedBox(height: 20), // Spacer
                      buildInfoRow(
                          Icons.calendar_month_outlined, 'Birth Day', dob, ""),
                      const SizedBox(height: 20), // Spacer
                      buildInfoRow(
                        Icons.location_on_outlined,
                        'Location',
                        'Lucknow, Utter Pradesh',
                        "https://www.google.com/maps/search/?api=1&query=${location}'",
                      ),
                      const SizedBox(height: 20), // Spacer
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.video_call_outlined),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "View Channel",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                channel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value, String url) {
    return InkWell(
      onTap: () {
        _launchUrl(url);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    String text, {
    Color borderColor = AppColors.greyA5,
    Color textColor = AppColors.black,
  }) {
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size20),
          border: Border.all(color: borderColor),
        ),
        child: CustomText(
          text,
          fontSize: SizeConfig.size12,
          overflow: TextOverflow.ellipsis,
          color: textColor,
        ));
  }

  Widget buildCustomTabRow({
    required int selectedIndex,
    required Function(int) onTabSelected,
  }) {
    final tabs = [
      "Overview",
      "Testimonial" "Reviews",
      "Post",
      "short",
      "Video"
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size6, vertical: SizeConfig.size8),
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.skyBlueDF : AppColors.white,
                borderRadius: BorderRadius.circular(SizeConfig.size12),
                border: Border.all(
                  color: isSelected ? AppColors.skyBlueDF : AppColors.black,
                  width: 1,
                ),
              ),
              child: CustomText(
                tabs[index],
                color: isSelected ? AppColors.white : AppColors.coloGreyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isExpanded = false;

  Widget buildRatingSummary({
    required double rating,
    required String totalReviews,
    required List<GetCountRattingResponseDatum> reviewData,
    required int totalRating,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CustomText(
                "Rating Summary",
                fontSize: SizeConfig.size20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              SizedBox(height: SizeConfig.size12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomText(
                          rating.toStringAsFixed(1),
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.size35,
                          color: AppColors.black,
                        ),
                        SizedBox(width: SizeConfig.size12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AbsorbPointer(
                              absorbing: true,
                              child: RatingBar.builder(
                                initialRating: rating,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemSize: 36,
                                unratedColor: Colors.grey.shade400,
                                itemBuilder: (context, _) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                onRatingUpdate: (rate) {},
                              ),
                            ),
                            SizedBox(height: SizeConfig.size4),
                            CustomText(
                              "${(totalReviews ?? "").toString()} Reviews",
                              fontSize: SizeConfig.size14,
                              color: AppColors.coloGreyText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Icon(
                      !_isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      size: SizeConfig.size32,
                    ),
                  ),
                ],
              ),

              if (_isExpanded) const SizedBox(height: 16),

              /// Expanded → Show detailed breakdown + Rate & Review UI
              if (_isExpanded) ...[
                /// Rating distribution bars
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: reviewData
                            .where(
                              (element) => element.count != 0,
                            )
                            .toList()
                            .map(
                              (e) => _buildRatingRow(e.rating!,
                                  (e.count! / (totalRating ?? 0)) * 100),
                            )
                            .toList() ??
                        []),
              ],
              widget.isTestimonialRating == true
                  ? SizedBox(height: SizeConfig.size20)
                  : SizedBox(),
              widget.isTestimonialRating == true
                  ? Center(
                      child: InkWell(
                        onTap: () => showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) => buildRatingReviewWidget(
                            context,
                            (rating, review) async {
                              if (rating == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a rating'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              final ViewBusinessDetailsController
                                  _ratingController =
                                  ViewBusinessDetailsController();
                              final success = await _ratingController
                                  .submitBusinessRating(
                                businessId: widget.userId,
                                rating: rating,
                                comment: review,
                              )
                                  .then((value) {
                                if (mounted) {
                                  Get.back();
                                }
                              });
                            },
                          ),
                        ),
                        child: AbsorbPointer(
                          absorbing: true,
                          child: RatingBar.builder(
                            initialRating: 0,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: 36,
                            unratedColor: Colors.grey.shade400,
                            itemBuilder: (context, _) => const Icon(
                              Icons.star_border,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (rate) {
                              setState(() {
                                rating = rate;
                              });
                            },
                          ),
                        ),
                      ),
                    )
                  : SizedBox(),
            ]),
      ),
    );
  }

  Widget _buildRatingRow(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$stars ★", style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage.toDouble(),
              backgroundColor: Colors.grey.shade300,
              color: Colors.blue,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRatingReviewWidget(
    BuildContext context,
    void Function(int rating, String comments) onSubmit,
  ) {
    int rating = 0;
    final TextEditingController reviewController = TextEditingController();

    return Center(
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Card(
                elevation: 0,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Rate And Review",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          RatingBar.builder(
                            initialRating: rating.toDouble(),
                            minRating: 0,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: 36,
                            unratedColor: Colors.grey.shade400,
                            itemBuilder: (context, index) => Icon(
                              rating >= index ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (rate) {
                              setState(() {
                                rating = rate.toInt();
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // ✍ Review Box
                          Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                "Write Your Review (Optional)",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 8),
                          TextField(
                            controller: reviewController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'E.g. "Great service, quick response, highly recommended!"',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 📸 Upload
                          Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                "Share Image or Video (Optional)",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ) /*const Text(
                              "",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),*/
                              ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text("Upload Image or Video"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: CustomBtn(
                                  onTap: () => Get.back(),
                                  title: "Cancel",
                                  radius: 12,
                                  borderColor: AppColors.skyBlueDF,
                                  bgColor: AppColors.white,
                                  textColor: AppColors.skyBlueDF,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomBtn(
                                  onTap: () =>
                                      onSubmit(rating, reviewController.text),
                                  title: "Submit",
                                  bgColor: AppColors.skyBlueDF,
                                  textColor: AppColors.white,
                                  radius: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTestimonialsCard(List<Testimonials> list) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              "Testimonials",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: list.length ?? 0,
                itemBuilder: (context, index) {
                  Testimonials data = list[index] ?? Testimonials();
                  return Container(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    margin: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(SizeConfig.size12),
                        border: Border.all(color: AppColors.whiteDB, width: 2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            if (data.fromUser?.id == userId) {
                              return;
                            }
                            // if (data.fromUser?.accountType?.toUpperCase() ==
                            //     AppConstants.individual) {
                            //
                            //     Get.to(() => VisitProfileScreen1(authorId: data.fromUser?.id??""));
                            // }
                            // if (data.fromUser?.accountType?.toUpperCase() ==
                            //     AppConstants.business) {
                            //
                            //     Get.to(() => VisitBusinessProfile(businessId: data.fromUser?.id??""));
                            // }
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                  data.fromUser?.profileImage ?? "",
                                ),
                              ),
                              SizedBox(width: SizeConfig.size10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    '@${data.fromUser?.name ?? ""}',
                                    fontSize: SizeConfig.size16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (index) => Icon(Icons.star,
                                            color: AppColors.yellow,
                                            size: SizeConfig.size16),
                                      ),
                                      SizedBox(width: SizeConfig.size6),
                                      CustomText(
                                        getTimeAgo(data.updatedAt.toString()),
                                        color: AppColors.coloGreyText,
                                        fontSize: SizeConfig.size12,
                                      )
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: SizeConfig.size10),
                        CustomText(
                          data.description,
                          textAlign: TextAlign.start,
                          fontSize: SizeConfig.size14,
                          color: AppColors.grayText,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        Divider(
                          height: 8,
                          color: AppColors.greyA5,
                          thickness: 1,
                        ),
                        SizedBox(
                          height: SizeConfig.size16,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: AppColors.borderGray, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                height: 50.0,
                                child: Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.black,
                                      child: Icon(
                                        Icons.thumb_up_alt_outlined,
                                        color: AppColors.white,
                                        size: 16,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontSize: 11.0),
                                        decoration: InputDecoration(
                                            disabledBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            suffixIcon:
                                                Icon(Icons.edit_outlined),
                                            suffixIconConstraints:
                                                BoxConstraints(),
                                            contentPadding:
                                                new EdgeInsets.symmetric(
                                                    vertical: 0.0),
                                            border: InputBorder.none,
                                            hintText: 'Enter comment',
                                            hintStyle:
                                                TextStyle(fontSize: 11.0)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.small,
                            ),
                            InkWell(
                              onTap: () {},
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.borderGray,
                                          width: 2)),
                                  height: 50,
                                  width: 50,
                                  child:
                                      Image.asset("assets/images/share.png")),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                })
          ],
        ),
      ),
    );
  }

  Widget buildPostCard({required List<Post> posts}) {
    /*return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      color: AppColors.white,
      child: Padding(
          padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CustomText(
              "Posts",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            SizedBox(
              height: SizeConfig.size6,
              width: Get.width,
            ),
            FeedScreen(
                key: ValueKey('feedScreen_user_posts_${widget.userId}'),
                postFilterType: PostType.otherPosts,
                isInParentScroll: true,
                id: widget.userId),
          ],
        ),
      ),
    );*/

    // ? List.from(controller.postsResponse.value.data.data.data[0])
    // : [];

    if (posts.isEmpty) return SizedBox();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cardKey.currentContext != null) {
        final box = _cardKey.currentContext!.findRenderObject() as RenderBox;
        final newHeight = box.size.height;

        if (_cardHeight != newHeight) {
          setState(() {
            _cardHeight = newHeight;
          });
        }
      }
    });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          // height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Posts",
                fontSize: SizeConfig.size20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              SizedBox(
                height: SizeConfig.size6,
                width: Get.width,
              ),
              posts.isEmpty
                  ? Center(
                      child: CustomText(
                      "No Post found !!",
                      textAlign: TextAlign.center,
                    ))
                  : SizedBox(
                height: _cardHeight > 0 ? _cardHeight : 400,
                width: Get.width,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    var data = posts[index];
                    FeedType? feedType =
                    FeedType.fromValue(data.type?.toUpperCase());

                    return Container(
                      key: index == 0 ? _cardKey : null,
                      width: Get.width * 0.9,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.whiteDB, width: 2),
                        borderRadius: BorderRadius.circular(SizeConfig.size12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(SizeConfig.size12),
                              topRight: Radius.circular(SizeConfig.size12),
                            ),
                            child: SizedBox(
                              width: Get.width * 0.9,
                              child: feedType == FeedType.qaPost
                                  ? FeedPollOptionsWidget(
                                question: data.poll?.question ?? "",
                                postId: data.id,
                                poll: data.poll,
                                postFilteredType: PostType.latest,
                                postedAgo: timeAgo(
                                  data.createdAt ?? DateTime.now(),
                                ),
                                message: data.message,
                              )
                                  : FeedMediaCarouselWidget(
                                subTitle: data.subTitle ?? "",
                                taggedUser: data.taggedUsers ?? [],
                                mediaUrls: data.media ?? [],
                                postedAgo: timeAgo(
                                  data.createdAt ?? DateTime.now(),
                                ),
                                totalViews: (data.viewsCount ?? 0).toString(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(SizeConfig.size10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (data.title?.isNotEmpty ?? false) ...[
                                  CustomText(
                                    data.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: SizeConfig.size14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(height: SizeConfig.size4),
                                ],
                                CustomText(
                                  data.subTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: SizeConfig.size12,
                                  color: AppColors.coloGreyText,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.borderGray, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: NetworkImage(
                                            data.user?.profileImage ?? "",
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: RichText(
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            text: const TextSpan(
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: "Sathi: ",
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold),
                                                ),
                                                TextSpan(
                                                    text:
                                                    "Bharat Mata Ki Jai...❤️🙏 Lorem ipsum"),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.edit,
                                            size: 18, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.borderGray, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: PopupMenuButton(
                                    onSelected: (value) {
                                      if (value == 2) {
                                        onShareButtonPressed(data);
                                      } else if (value == 3) {
                                        Get.find<FeedController>().savePostToLocalDB(
                                          postId: data.id ?? '0',
                                          type: PostType.latest,
                                          sortBy: SortBy.Latest,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 1, child: Text("Re-post")),
                                      PopupMenuItem(value: 2, child: Text("Share")),
                                      PopupMenuItem(value: 3, child: Text("Save")),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHorizontalSortsList() {
    if (shortsController.isInitialLoading(Shorts.latest).isFalse) {
          if (shortsController.shortsResponse.value.status == Status.COMPLETE) {
            final channelShorts =
                shortsController.getListByType(shorts: Shorts.latest);
            if (channelShorts.isEmpty) {
              return SizedBox();
            }
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeConfig.size16),
              ),
              elevation: SizeConfig.size4,
              color: AppColors.white,
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "Shorts",
                      fontSize: SizeConfig.size20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    SizedBox(
                      height: SizeConfig.size8,
                    ),
                    SizedBox(
                      height: SizeConfig.size240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: channelShorts.length,
                        itemBuilder: (context, index) {
                          ShortFeedItem data = channelShorts[index];
                          return InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RouteHelper.getShortsPlayerScreenRoute(),
                                arguments: {
                                  ApiKeys.shorts: Shorts.latest,
                                  ApiKeys.videoItem: channelShorts,
                                  ApiKeys.initialIndex: 0,
                                },
                              );
                            },
                            child: Container(
                              width: SizeConfig.size160,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius:
                                    BorderRadius.circular(SizeConfig.size12),
                                image: DecorationImage(
                                    image: NetworkImage(data.video?.coverUrl ??
                                            "" // "assets/images/camera_stand.png",
                                        ),
                                    fit: BoxFit.cover),
                                border: Border.all(
                                    color: AppColors.whiteDB, width: 2),
                              ),
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: EdgeInsets.all(SizeConfig.size12),
                                padding: EdgeInsets.symmetric(
                                    vertical: SizeConfig.size2,
                                    horizontal: SizeConfig.size8),
                                decoration: BoxDecoration(
                                    color: AppColors.black30,
                                    borderRadius: BorderRadius.circular(
                                        SizeConfig.size12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      color: AppColors.white,
                                    ),
                                    SizedBox(
                                      width: SizeConfig.size4,
                                    ),
                                    CustomText(
                                      (data.video?.stats?.views ?? "")
                                          .toString(),
                                      color: AppColors.white,
                                      fontSize: SizeConfig.size16,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => SizedBox(
                          width: SizeConfig.size12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
    return SizedBox();
  }

  Widget customVideoCard() {
    if (videosController.isInitialLoading(videoType).isFalse) {
          if (videosController.channelVideosResponse.value.status ==
              Status.COMPLETE) {
            final channelVideos = videosController.getListByType(videoType: videoType);
            if (channelVideos.isNotEmpty) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Videos",
                        fontSize: SizeConfig.size20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                      SizedBox(
                        height: SizeConfig.size8,
                      ),
                      SizedBox(
                        height: 310,
                        child: VideoChannelSection(
                          isOwnVideos: true,
                          channelId: '',
                          isParentScroll: false,
                          authorId: widget.userId,
                          postVia: PostVia.profile,
                          padding: 4.0,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFA999999),
                              offset: Offset(0, 0.65),
                              blurRadius: 1.3
                            )
                          ]
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        }
    return SizedBox();

  }

  Widget oldBuild(BuildContext context) {
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
                                  backgroundImage: user?.profileImage != null
                                      ? NetworkImage(user!.profileImage!)
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
                                            user!.name ?? '',
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
                                    if (user.email != null)
                                      Container(
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border:
                                                Border.all(color: Colors.grey)),
                                        child: CustomText("${user.email}"),
                                      ),
                                    //     if(user.designation!=null)
                                    //      Container(
                                    //   padding: EdgeInsets.all(5),
                                    //   decoration: BoxDecoration(
                                    //     borderRadius: BorderRadius.circular(10),
                                    //     border: Border.all(color: Colors.grey)
                                    //   ),
                                    //   child:
                                    //    CustomText("${user.designation}"),
                                    // ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size5),
                                Obx(() {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 38.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: StatBlock(
                                              count: controller
                                                  .userData.value!.totalPosts
                                                  .toString(),
                                              label: "Posts",
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: SizeConfig.size3),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.center,
                                            child: StatBlock(
                                              count: controller.userData.value!
                                                  .followersCount
                                                  .toString(),
                                              label: "Followers",
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: SizeConfig.size5),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: StatBlock(
                                              count: controller.userData.value!
                                                  .followingCount
                                                  .toString(),
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
            id: widget.userId
        );
      // case 'Achievements':
      // return AchievementsWidget();
      case 'Testimonials':
        return testimonialsTab();
      case 'Shorts':
        return ShortsChannelSection(
          isOwnShorts: false,
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

  Widget_alterRow(
      {IconData? icon, required String? title, required String? subtitle}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
        ),
        SizedBox(
          width: 4,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              title,
              fontSize: SizeConfig.size1,
              fontWeight: FontWeight.bold,
            ),
            CustomText(
              subtitle,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ],
        )
      ],
    );
  }

  Widget testimonialsTab() {
    return Column(
      children: [
        buildRatingSummary(
          rating: double.parse(
              (controller.getRattingSummaryResponse.value?.data?.avgRating ?? 0)
                  .toString()),
          totalReviews: "5,455",
          reviewData: controller.getCountRattingResponse.value?.data ?? [],
          totalRating: controller.getCountRattingResponse.value?.data
                  ?.map(
                    (e) => e.count!,
                  )
                  .reduce(
                    (value, element) => value + element,
                  ) ??
              1,
        ),
        SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              CustomText(
                "Most Relevant",
                decoration: TextDecoration.underline,
                decorationColor: AppColors.skyBlueDF,
                color: AppColors.skyBlueDF,
              ),
              SizedBox(
                width: 12,
              ),
              CustomText(
                "Newest",
                decoration: TextDecoration.underline,
                decorationColor: AppColors.black,
                color: AppColors.black,
              ),
              SizedBox(
                width: 12,
              ),
              CustomText(
                "Oldest",
                decoration: TextDecoration.underline,
                decorationColor: AppColors.black,
                color: AppColors.black,
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        TestimonialsScreen(
          userName: controller.userData.value?.user?.name ?? 'N/A',
          visitUserID: widget.userId,
          isSelfTestimonial: false,
        )
      ],
    );
  }

  Widget videoTab() {
    return VideoChannelSection(
      isOwnVideos: false,
      channelId: '',
      authorId: widget.userId,
      sortBy: SortBy.Popular,
      postVia: PostVia.profile,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              CustomText(
                "Most Relevant",
                decoration: TextDecoration.underline,
                decorationColor: AppColors.skyBlueDF,
                color: AppColors.skyBlueDF,
              ),
              SizedBox(
                width: 12,
              ),
              CustomText(
                "Newest",
                decoration: TextDecoration.underline,
                decorationColor: AppColors.black,
                color: AppColors.black,
              ),
              SizedBox(
                width: 12,
              ),
              CustomText(
                "Oldest",
                decoration: TextDecoration.underline,
                decorationColor: AppColors.black,
                color: AppColors.black,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 8,
        ),
        customVideoCard(),
      ],
    );
  }
}
