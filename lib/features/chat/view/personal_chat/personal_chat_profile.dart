import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/user_profile_res.dart';
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
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
// import '../../auth/controller/view_personal_details_controller.dart';

class PersonalChatProfile extends StatefulWidget {
  final String userId;
  final String? contactNumber;
  const PersonalChatProfile(
      {super.key, required this.userId, this.contactNumber});

  @override
  State<PersonalChatProfile> createState() => _PersonalChatProfileState();
}

class _PersonalChatProfileState extends State<PersonalChatProfile> {
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

    // controller.fetchUserById(userId: "689deb7aac8beb10537e3107");
    controller.fetchUserById(userId: widget.userId);
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadInitialData() async {
    await viewProfileController
        .viewPersonalProfiles(widget.contactNumber ?? "");
    await viewProfileController.UserFollowersAndPostsCount(widget.userId);

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
            horizontal: SizeConfig.size10, vertical: SizeConfig.size10),
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
      default:
        return Text("Not implemented");
    }
  }

  Widget overViewTabWidget() {
    return Column(
      children: [
        buildRatingSummary(
          rating: 3,
          totalReviews: "5,455",
        ),
        SizedBox(
          height: 20,
        ),
        buildTestimonialsCard(),
        SizedBox(
          height: 20,
        ),
        buildPostCard(),
        SizedBox(
          height: 20,
        ),
        buildHorizontalSortsList(),
        SizedBox(
          height: 20,
        ),
        customVideoCard(),
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
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Container(
                      height: SizeConfig.size60,
                      width: SizeConfig.size60,
                      margin: EdgeInsets.all(SizeConfig.size10),
                      padding: EdgeInsets.all(SizeConfig.size3),
                      decoration: BoxDecoration(
                          color: AppColors.skyBlueDF,
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(user?.profileImage ?? ""),
                          )),
                    ),
                    CustomBtn(
                      onTap: () {},
                      title: "Follow",
                      fontWeight: FontWeight.bold,
                      height: SizeConfig.size24,
                      bgColor: AppColors.skyBlueDF,
                      width: SizeConfig.size60,
                      radius: SizeConfig.size5,
                    ),
                  ],
                ),
                SizedBox(
                  width: SizeConfig.size8,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  child: CustomText(
                                    user?.name ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: SizeConfig.size18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  width: SizeConfig.size2,
                                ),
                                Icon(
                                  Icons.verified,
                                  color: AppColors.skyBlueDF,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: SizeConfig.size10,
                          ),

                          // CustomBtn(
                          //   onTap: () {},
                          //   title: "Follow",
                          //   fontWeight: FontWeight.bold,
                          //   height: SizeConfig.size24,
                          //   bgColor: AppColors.skyBlueDF,
                          //   width: SizeConfig.size60,
                          //   radius: SizeConfig.size12,
                          // ),
                          // SizedBox(
                          //   width: SizeConfig.size4,
                          // ),
                          // Icon(Icons.more_vert),

                          PopupMenuButton(
                              onSelected: (value) {},
                              itemBuilder: (context) => [
                                    PopupMenuItem(
                                        value: 1, child: CustomText("Share")),
                                    PopupMenuItem(
                                        value: 2, child: CustomText("Mute")),
                                    PopupMenuItem(
                                        value: 3, child: CustomText("Block"))
                                  ])
                        ],
                      ),

                      // SizedBox(height: SizeConfig.),
                      // CustomText(
                      //   user?.contactNo ?? '',
                      //   fontWeight: FontWeight.bold,
                      //   fontSize: 14,
                      // ),
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
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.skyBlueDF,
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.small,
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: SizeConfig.size16, color: AppColors.black),
                          SizedBox(width: SizeConfig.size1),
                          CustomText(
                            "Join US: ",
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          Expanded(
                            child: CustomText(
                              "${user?.dateOfBirth?.date ?? ""} ${getMonthNameFromMonth(user?.dateOfBirth?.month ?? 0)},${user?.dateOfBirth?.year ?? ""}",
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.black,
                            ),
                          )
                        ],
                      ),

                      SizedBox(height: SizeConfig.size10),
                      Row(
                        children: [
                          _buildTag(user?.username ?? ""),
                          SizedBox(width: SizeConfig.size6),
                          _buildTag(user?.designation ?? ""),
                        ],
                      ),
                      SizedBox(
                        height: SizeConfig.size8,
                      ),

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
                          Expanded(
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
                                          text: "Following",
                                          style: TextStyle(
                                              color: AppColors.coloGreyText))
                                    ])),
                          ),
                          SizedBox(
                            height: SizeConfig.size20,
                            child: VerticalDivider(
                              width: SizeConfig.size14,
                              color: AppColors.borderGray,
                              thickness: 1,
                            ),
                          ),
                          Expanded(
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
                        Icons.email,
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
                      buildInfoRow(Icons.cake, 'Birth Day', dob, ""),
                      const SizedBox(height: 20), // Spacer
                      buildInfoRow(
                        Icons.location_on,
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
          color: textColor,
        ));
  }

  Widget buildCustomTabRow({
    required int selectedIndex,
    required Function(int) onTabSelected,
  }) {
    final tabs = ["Overview", "Reviews", "Post", "Jobs"];

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
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
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
                "Testimonial Summary",
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
                    onTap: () => setState(() {
                      _isExpanded = !_isExpanded;
                    }),
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
                  children: [
                    _buildRatingRow(5, 0.9),
                    _buildRatingRow(4, 0.7),
                    _buildRatingRow(3, 0.5),
                    _buildRatingRow(2, 0.3),
                    _buildRatingRow(1, 0.1),
                  ],
                ),
              ],
              SizedBox(height: SizeConfig.size20),
              RatingBar.builder(
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
                onRatingUpdate: (rate) {
                  setState(() {
                    rating = rate;
                  });
                },
              ),
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
              value: percentage,
              backgroundColor: Colors.grey.shade300,
              color: Colors.blue,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTestimonialsCard() {
    return TestimonialListingWidget(userId: userId);
    // return Text("userId: userId");
  }

  Widget buildPostCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
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
            ),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.whiteDB, width: 2),
                  borderRadius: BorderRadius.circular(SizeConfig.size12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(SizeConfig.size12),
                        topRight: Radius.circular(SizeConfig.size12)),
                    child: Image.asset(
                      "assets/images/burger.png",
                      height: SizeConfig.size200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "Top 10 AI Tools You Should Know in 2025",
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          "Stay Ahead with These Game-Changing AI Tools",
                          fontSize: SizeConfig.size12,
                          color: AppColors.coloGreyText,
                        ),
                        // SizedBox(height: SizeConfig.size10),
                      ],
                    ),
                  ),
                  // SizedBox(height: SizeConfig.size12),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.borderGray, width: 2),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              const CircleAvatar(
                                radius: 16,
                                backgroundImage: AssetImage(
                                    "assets/images/profile_logo.png"),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  text: const TextSpan(
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 13),
                                    children: [
                                      TextSpan(
                                          text: "Sathi : ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      TextSpan(
                                          text:
                                              "Bharat Mata Ki Jai...❤️🙏 Lorem ipsum Dolor Amet"),
                                    ],
                                  ),
                                ),
                              ),
                              Icon(Icons.edit,
                                  size: 18, color: Colors.grey[600]),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.borderGray, width: 2),
                              borderRadius: BorderRadius.circular(12)),
                          child: PopupMenuButton(
                              onSelected: (value) {},
                              itemBuilder: (context) => [
                                    PopupMenuItem(
                                        value: 1, child: CustomText("Re-post")),
                                    PopupMenuItem(
                                        value: 2, child: CustomText("Share")),
                                    PopupMenuItem(
                                        value: 3, child: CustomText("Save"))
                                  ]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.size16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHorizontalSortsList() {
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
              "Sorts",
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
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Container(
                    width: SizeConfig.size160,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(SizeConfig.size12),
                      image: DecorationImage(
                          image: AssetImage(
                            "assets/images/camera_stand.png",
                          ),
                          fit: BoxFit.cover),
                      border: Border.all(color: AppColors.whiteDB, width: 2),
                    ),
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: EdgeInsets.all(SizeConfig.size12),
                      padding: EdgeInsets.symmetric(
                          vertical: SizeConfig.size6,
                          horizontal: SizeConfig.size12),
                      decoration: BoxDecoration(
                          color: AppColors.black1A,
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12)),
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
                            "25K",
                            color: AppColors.white,
                            fontSize: SizeConfig.size16,
                          )
                        ],
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

  Widget customVideoCard() {
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
              height: SizeConfig.size2,
            ),
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/video_preview.png',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.volume_off,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "02:53",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black,
                          child: Icon(Icons.play_arrow, color: Colors.white),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Trying MC’s Burger for the first time!!! "
                                "Trying MC’s Burger for the...",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "TechSavvy   3.5 lakhs views   12 days ago",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// Menu button
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getMonthNameFromMonth(int mon) {
    switch (mon) {
      case 1:
        return "Jan";
      case 2:
        return "Feb";
      case 3:
        return "Mar";
      case 4:
        return "Apr";
      case 5:
        return "May";
      case 6:
        return "Jun";
      case 7:
        return "Jul";
      case 8:
        return "Aug";
      case 9:
        return "Sep";
      case 10:
        return "Oct";
      case 11:
        return "Nov";
      case 12:
        return "Dec";
      default:
        return "";
    }
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
                                        Expanded(
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
                                        Expanded(
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
}
