import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/testimonials_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/circular_progress_painter.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/count_clock_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/info_card_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/introduction_video_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/link_tile_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/portfolio_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_bio_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/update_profile_view.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../auth/controller/view_personal_details_controller.dart';

class PersonalProfileSetupNewScreen extends StatefulWidget {
  final int? selectedIndex;
  final SortBy? sortBy;

  const PersonalProfileSetupNewScreen({
    super.key,
    this.selectedIndex,
    this.sortBy
  });

  @override
  State<PersonalProfileSetupNewScreen> createState() =>
      _PersonalProfileSetupNewScreenState();
}

class _PersonalProfileSetupNewScreenState
    extends State<PersonalProfileSetupNewScreen> with TickerProviderStateMixin {
  final viewProfileController = Get.put(ViewPersonalDetailsController());

  final personalCreateProfileController =
  Get.isRegistered<PersonalCreateProfileController>()
      ? Get.find<PersonalCreateProfileController>()
      : Get.put(PersonalCreateProfileController());

  final introVideoController = Get.put(IntroductionVideoController());
  final youtubeController = TextEditingController();
  List<String> postTab = [];
  int selectedIndex = 0;
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;

  TabController? _tabController;

  @override
  void initState() {
    selectedFilter = widget.sortBy ?? SortBy.Latest;
    selectedIndex = widget.selectedIndex ?? 0;
    _tabController = TabController(length: 0, vsync: this);
    _loadInitialData();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _onTabChanged() {
    if (_tabController?.indexIsChanging??false) return;
    setState(() {
      selectedIndex = _tabController!.index;
      updateFilters(selectedIndex);
    });
  }

  void updateFilters(int index) {
    final currentTab = postTab[index];
    if (currentTab == 'Shorts' || currentTab == 'Videos') {
      filters = SortBy.values.toList();
    } else {
      filters = null;
    }
  }

  Future<void> _loadInitialData() async {
    await viewProfileController.viewPersonalProfile();
    await viewProfileController.UserFollowersAndPostsCount(userId);

    _updateTextControllers();
  }

  void _initializeTabController() {
    final user = viewProfileController.personalProfileDetails.value.user;
    postTab = [
      if (user?.profession == SELF_EMPLOYED) 'My Portfolio',
      'About Me',
      'Posts',
      'Shorts',
      'Videos',
      'Testimonials'
    ];

    if (_tabController == null || _tabController!.length != postTab.length) {
      // Dispose old controller if exists
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();

      // Create new controller
      final initialIndex = selectedIndex.clamp(0, postTab.length - 1);
      _tabController = TabController(
        length: postTab.length,
        vsync: this,
        initialIndex: initialIndex,
      );
      _tabController!.addListener(_onTabChanged);

      // Update filters for the initial tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          updateFilters(_tabController!.index);
        }
      });
    }
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
    return bio != null && bio
        .trim()
        .isNotEmpty;
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
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        isLeading: true,
        title: '',
        isLogout: true,
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
      body: isGuestUser()
          ? PositiveCustomBtn(onTap: () {}, title: "Logout")
          : Obx(() {
        if (viewProfileController.viewPersonalResponse.value.status ==
            Status.COMPLETE) {
          // Initialize TabController after data is loaded
          _initializeTabController();

          // If TabController is still null, show loading
          if (_tabController == null) {
            return Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size8
              ),
              child: DefaultTabController(
                length: postTab.length,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: _buildHeaderSection(),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CustomTabBarDelegate(
                        _buildTabButtons(),
                        hasFilters: filters != null
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: postTab.map((tab) {
                      final index = postTab.indexOf(tab);
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size10
                        ),
                        child: _buildTabContent(index),
                      );
                    }).toList(),

                  ),

                ),
              ),  // child: Column(
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
      case 'My Portfolio':
        return PortfolioWidget(
          isSelfPortfolio: true,
        );
      case 'About Me':
        return AboutMeWidget();
      case 'Posts':
        return FeedScreen(
          key: ValueKey('feedScreen_my_posts'),
          postFilterType: PostType.myPosts,
          id: userId,
          isInParentScroll: true,
        );
      case 'Shorts':
        return ShortsChannelSection(
          isOwnShorts: true,
          channelId: '',
          authorId: userId,
          showShortsInGrid: true,
          sortBy: selectedFilter,
          postVia: PostVia.profile,
        );
      case 'Videos':
        return VideoChannelSection(
          isOwnVideos: true,
          sortBy: selectedFilter,
          channelId: '',
          authorId: userId,
          padding: 0.0,
          postVia: PostVia.profile,
        );
      case 'Testimonials':
        return TestimonialsScreen(
          userName: "",
          visitUserID: userId,
          isSelfTestimonial: true,
        );
    // case 'Channels':
    // return ChannelsWidget();
      default:
        return const Center(child: Text('Unknown Tab'));
    }
  }

  Widget AboutMeWidget() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: SizeConfig.size10),
      
          _buildChannelWidget(),
      
          SizedBox(height: SizeConfig.size10),
      
          _buildEarnWithBlueEraWidget(),
      
          SizedBox(height: SizeConfig.size10),
      
          _buildPaymentAccountWidget(),
      
          SizedBox(height: SizeConfig.size10),
      
          _buildMyDocumentWidget(),
      
          SizedBox(height: SizeConfig.size10),
      
          _buildBookingAndaAvailabilityWidget(),
      
          // Add the IntroductionVideoWidget here
          // IntroductionVideoWidget(),
          // SizedBox(height: SizeConfig.size18),
      
          SizedBox(height: SizeConfig.size10),
      
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
      ),
    );
  }

  bool isValidYouTubeUrl(String url) {
    final RegExp youTubeRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[\w\-]{11}(&\S*)?$',
      caseSensitive: false,
    );
    return youTubeRegex.hasMatch(url.trim());
  }

  Widget _filterButtons() {
    return SingleChildScrollView(
        padding:
        EdgeInsets.only(top: SizeConfig.size20, bottom: SizeConfig.size10),
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Row(
                children: filters!.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size14),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      child: CustomText(
                        (filter == SortBy.Latest) ? 'Published' : filter.label,
                        // use .label for display text
                        decoration: TextDecoration.underline,
                        color: isSelected ? Colors.blue : Colors.black54,
                        decorationColor:
                        isSelected ? Colors.blue : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ));
  }

  Widget _buildMyProfileWidget() {
    final List<_ProfileFieldStatus> fields = [
      _ProfileFieldStatus('Profile video', false),
      _ProfileFieldStatus('Bio', true),
      _ProfileFieldStatus('Designation', true),
      _ProfileFieldStatus('Phone number', true),
      _ProfileFieldStatus('Set availability', false),
      _ProfileFieldStatus('Organization', true),
      _ProfileFieldStatus('Email (Unverified)', false),
    ];

    return CustomFormCard(
      margin: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size12),
      borderRadius: BorderRadius.circular(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final double rightSectionWidth = totalWidth * 0.7;
          final double itemWidth = (rightSectionWidth / 2) - SizeConfig.size8;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left section - text + circle
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Your profile completion score',
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(
                      height: SizeConfig.size8,
                    ),
                    SizedBox(
                      width: SizeConfig.size60,
                      height: SizeConfig.size60,
                      child: CustomPaint(
                        painter: CircleProgressPainter(0.85),
                        child: Center(
                          child: CustomText(
                            "${(0.85 * 100).toInt()}%",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.small,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                child: Container(
                  width: 1,
                  height: SizeConfig.size120, // ensure visible height
                  color: AppColors.whiteE5,
                ),
              ),

              // Right section - 2-column checklist
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: SizeConfig.size12,
                      runSpacing: SizeConfig.size8,
                      children: fields.map((item) {
                        return SizedBox(
                          width: itemWidth,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.isCompleted ? Icons.check_circle : Icons.error,
                                color: item.isCompleted ? Colors.blue : Colors.red,
                                size: 16,
                              ),
                              SizedBox(width: 2),
                              Expanded(
                                child: CustomText(
                                  item.title,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(
                      height: SizeConfig.size12
                    ),

                    CustomText(
                      "2 actions pending",
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.small,
                      color: AppColors.yellow00,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size15
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        return CommonProfileImage(
                            imagePath: personalCreateProfileController
                                .imagePath?.value ??
                                "",
                            onImageUpdate: (image) async {
                              personalCreateProfileController
                                  .imagePath?.value = image;

                              dynamic dataImage = await multiPartImage(
                                imagePath: image,
                              );
                              var reqProfile = {
                                ApiKeys.profile_image: dataImage
                              };
                              await personalCreateProfileController
                                  .updateUserProfileDetails(
                                  params: reqProfile,
                                  isFromProfileOnly: true);
                              setState(() {

                              });
                            },
                            dialogTitle: 'Upload Profile Picture',
                            showProfileBorder: false
                        );
                      }),
                      SizedBox(width: SizeConfig.size16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                                          SizeConfig.screenWidth /
                                              2.5),
                                      child: CustomText(
                                        viewProfileController
                                            .personalProfileDetails
                                            .value
                                            .user
                                            ?.name ??
                                            '',
                                        fontSize: SizeConfig.large18,
                                        fontWeight: FontWeight.bold,
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        color: AppColors.mainTextColor,
                                      ),
                                    ),
                                    SizedBox(
                                      width: SizeConfig.size8,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (viewProfileController
                                            .personalProfileDetails
                                            .value
                                            .isProfileCreated ==
                                            false) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      CreateProfileScreen()));
                                        } else {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      UpdateProfileScreen()));
                                        }
                                      },
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                        AppColors.primaryColor,
                                        child: Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
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
                            SizedBox(height: SizeConfig.size5),
                            CustomText(
                              viewProfileController.personalProfileDetails.value.user?.profession ?? "OTHERS",
                              color: AppColors.secondaryTextColor,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                            ),
                            SizedBox(height: SizeConfig.size12),
                            Obx(() {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    StatBlock(
                                      count: viewProfileController
                                          .postsCount.value
                                          .toString(),
                                      label: "Posts",
                                    ),
                                    SizedBox(width: 4),
                                    StatBlock(
                                      count: viewProfileController
                                          .followersCount.value
                                          .toString(),
                                      label: "Followers",
                                      callback: (){
                                        Get.to(()=> FollowersFollowingPage(
                                          tabIndex: 1,
                                          userID: userId,
                                        ));
                                      },
                                    ),
                                    SizedBox(width: 4),
                                    StatBlock(
                                      count: viewProfileController
                                          .followingCount.value
                                          .toString(),
                                      label: "Following",
                                      callback: (){
                                        Get.to(()=> FollowersFollowingPage(
                                          tabIndex: 0,
                                          userID: userId,
                                        ));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      LocalAssets(
                          imagePath: AppIconAssets.upload_share,
                          imgColor: AppColors.secondaryTextColor
                      )
                    ],
                  ),

                  // Conditional Bio Section
                  if (_shouldShowBioSection())
                    Padding(
                      padding: EdgeInsets.only(top: SizeConfig.size15),
                      child: ExpandableText(
                        text: viewProfileController
                            .personalProfileDetails.value.user?.bio ?? '',
                        trimLines: 4,
                        style: TextStyle(
                          color: AppColors.mainTextColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                        ),
                        expandMode: ExpandMode.dialog,
                        dialogTitle: 'Bio',
                      ),
                    ),

                  SizedBox(height: SizeConfig.size12),

                  Row(
                    children: [
                      if ((viewProfileController.personalProfileDetails.value
                          .isProfileCreated ??
                          false) &&
                          isResumeShow(
                              designation: viewProfileController
                                  .personalProfileDetails
                                  .value
                                  .user
                                  ?.profession)) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: (){
                              Get.toNamed(
                                  RouteHelper.getCreateResumeScreenRoute());
                            },
                            child: Container(
                              padding: EdgeInsets.all(SizeConfig.size6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.primaryColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    "My Resume",
                                    color: AppColors.primaryColor,
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: SizeConfig.size25,
                                    height: SizeConfig.size25,
                                    child: CustomPaint(
                                      painter: CircleProgressPainter(0.85),
                                      child: Center(
                                        child: CustomText(
                                          "${(0.85 * 100).toInt()}%",
                                          fontWeight: FontWeight.w600,
                                          fontSize: SizeConfig.extraSmall,
                                          color: AppColors.mainTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                      ],
                      Obx(()=> Expanded(
                        child: GestureDetector(
                          onTap: (){
                            viewProfileController.isMyProfileShow.value = !viewProfileController.isMyProfileShow.value;
                          },
                          child: Container(
                            padding: EdgeInsets.all(SizeConfig.size8),
                            decoration: BoxDecoration(
                              color: viewProfileController.isMyProfileShow.isTrue ? AppColors.primaryColor : AppColors.white,
                              border: Border.all(color: AppColors.primaryColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomText(
                                  "My Profile",
                                  color: viewProfileController.isMyProfileShow.isTrue ? AppColors.white : AppColors.primaryColor,
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w600,
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: SizeConfig.size25,
                                  height: SizeConfig.size25,
                                  child: CustomPaint(
                                    painter: CircleProgressPainter(
                                        0.42,
                                        isMyProfile: viewProfileController.isMyProfileShow.value
                                    ),
                                    child: Center(
                                      child: CustomText(
                                        "${(0.42 * 100).toInt()}%",
                                        fontWeight: FontWeight.w600,
                                        fontSize: SizeConfig.extraSmall,
                                        color: viewProfileController.isMyProfileShow.isTrue ? AppColors.white : AppColors.mainTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                  )

                ],
              )
          ),


          Obx(()=> (viewProfileController.isMyProfileShow.isTrue)
              ?  _buildMyProfileWidget() : SizedBox())
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SizeConfig.size34,
          child: ListView.builder(
            itemCount: postTab.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final isSelected = _tabController?.index == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    _tabController?.animateTo(index);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    foregroundColor: isSelected ? Colors.black87 : Colors.black54,
                    backgroundColor: isSelected ? Colors.blue.shade100 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.size10),
                      side: BorderSide(
                          color: isSelected ? Colors.blue.shade100 : Colors.grey
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size2),
                    minimumSize: Size(SizeConfig.size80, SizeConfig.size34),
                    maximumSize: Size(SizeConfig.size90, SizeConfig.size34),
                  ),
                  child: Text('${postTab[index]}'),
                ),
              );
            },
          ),
        ),
        if (filters != null) ...[
          _filterButtons(),
        ]
      ],
    );
  }

  Widget _buildChannelWidget(){
    return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: channelId.isNotEmpty
            ? Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildCircleIcon(AppIconAssets.channelNew),
                    SizedBox(width: SizeConfig.size6),
                    _buildTitleWidget('My Channel'),
                  ],
                ),
                SizedBox(width: SizeConfig.size6),

                InkWell(
                  onTap: (){
                    Get.toNamed(
                      RouteHelper.getChannelScreenRoute(),
                      arguments: {
                        ApiKeys.argAccountType: accountTypeGlobal,
                        ApiKeys.channelId: channelId,
                        ApiKeys.authorId:
                        (accountTypeGlobal == AppConstants.individual)
                            ? userId
                            : businessId
                      },
                    );
                  },
                  child: CustomText(
                    'View',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                )
              ],
            ),

            SizedBox(
              height: SizeConfig.size16,
            ),

            _buildContainerOverlay(
              child: Row(
                children: [
                  CustomText(
                    channelName,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    '@$channelOwner',
                    fontSize: SizeConfig.extraSmall,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            )

          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildCircleIcon(AppIconAssets.channelNew),
                SizedBox(width: SizeConfig.size6),
                _buildTitleWidget('My Channel'),
              ],
            ),
            SizedBox(width: SizeConfig.size6),

            InkWell(
              onTap: (){
                Navigator.pushNamed(
                  context,
                  RouteHelper.getManageChannelScreenRoute(),
                );
              },
              child: CustomText(
                'Create',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            )
          ],
        ),
    );
  }

  Widget _buildEarnWithBlueEraWidget(){
    return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: SizedBox()
    );
  }

  Widget _buildPaymentAccountWidget(){
    return CustomFormCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildCircleIcon(AppIconAssets.payment),
                    SizedBox(width: SizeConfig.size6),
                    _buildTitleWidget('Payment Account'),
                  ],
                ),
                SizedBox(width: SizeConfig.size6),

                InkWell(
                  onTap: (){
                    // Get.toNamed(
                    //   RouteHelper.getChannelScreenRoute(),
                    //   arguments: {
                    //     ApiKeys.argAccountType: accountTypeGlobal,
                    //     ApiKeys.channelId: channelId,
                    //     ApiKeys.authorId:
                    //     (accountTypeGlobal == AppConstants.individual)
                    //         ? userId
                    //         : businessId
                    //   },
                    // );
                  },
                  child: LocalAssets(
                    height: 18,
                    imagePath: AppIconAssets.pen_line,
                  ),
                )
              ],
            ),

            SizedBox(height: SizeConfig.size16),
            Row(
              children: [
                Expanded(
                  child: _buildContainerOverlay(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomText(
                              'My Wallet:',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
                          CustomText(
                              ' ₹ 522',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    )
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: _buildContainerOverlay(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomText(
                              'Total Earning:',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextColor,
                            ),
                            CustomText(
                              ' ₹ 522',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      )
                  ),
                )
              ],
            ),

            SizedBox(height: SizeConfig.size10),
            _buildContainerOverlay(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CustomText(
                      'Bank Account: ',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    CustomText(
                      ' Ramesh Kumar State bank Of India',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                )
            ),

            SizedBox(height: SizeConfig.size10),
            _buildContainerOverlay(
                child: Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.mailIcon,
                    ),
                    SizedBox(
                        width: SizeConfig.size10
                    ),
                    CustomText(
                      'Manage Subscription',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    Spacer(),
                    CustomText(
                      'Free Plan',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ],
                )
            )

          ]
        )
    );
  }

  Widget _buildMyDocumentWidget(){
    return CustomFormCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildCircleIcon(AppIconAssets.myDocuments),
                    SizedBox(width: SizeConfig.size6),
                    _buildTitleWidget('My Documents'),
                  ],
                ),
                SizedBox(width: SizeConfig.size6),

                InkWell(
                  onTap: (){
                    // Get.toNamed(
                    //   RouteHelper.getChannelScreenRoute(),
                    //   arguments: {
                    //     ApiKeys.argAccountType: accountTypeGlobal,
                    //     ApiKeys.channelId: channelId,
                    //     ApiKeys.authorId:
                    //     (accountTypeGlobal == AppConstants.individual)
                    //         ? userId
                    //         : businessId
                    //   },
                    // );
                  },
                  child: PositiveCustomBtn(
                    onTap: ()  {

                    },
                    title: 'Add Document',
                    textColor: AppColors.primaryColor,
                    iconPath: AppIconAssets.add,
                    iconColor: AppColors.primaryColor,
                    width: SizeConfig.size120,
                    height: SizeConfig.size30,
                    bgColor: Colors.transparent,
                    borderColor: AppColors.primaryColor,
                    radius: 6.0,
                  ),
                ),
              ],
            ),

            SizedBox(height: SizeConfig.size16),
          ],
        )
    );
  }

  Widget _buildBookingAndaAvailabilityWidget(){
    return CustomFormCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildCircleIcon(AppIconAssets.bookingEnquiries),
                SizedBox(width: SizeConfig.size6),
                _buildTitleWidget('Booking & Enquiries'),
              ],
            ),

            SizedBox(height: SizeConfig.size16),

            _buildContainerOverlay(
                child: Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.mailIcon,
                    ),
                    SizedBox(
                        width: SizeConfig.size10
                    ),
                    CustomText(
                      'Bookings',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right)
                  ],
                )
            )
          ],
        )
    );
  }

  Widget _buildCircleIcon(String iconImage){
    return Container(
      padding: EdgeInsets.all(SizeConfig.size6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        border: Border.all(
          color: AppColors.primaryColor,
          width: 0.5
        ),
      ),
      child: LocalAssets(
          width: SizeConfig.size22,
          height: SizeConfig.size22,
          imagePath: iconImage,
          imgColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildTitleWidget(String text){
    return CustomText(
        text,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
    );
  }

  Widget _buildContainerOverlay({required Widget child}){
    return Container(
      width: SizeConfig.screenWidth,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyE5, width: 1),
          boxShadow: [AppShadows.textFieldShadow]
      ),
      child: child,
    );
  }



}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  final bool hasFilters;

  _CustomTabBarDelegate(this.tabBar, {this.hasFilters = false});

  @override
  double get minExtent => hasFilters ? 90.0 : 50.0;

  @override
  double get maxExtent => hasFilters ? 90.0 : 50.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.only(top: 8),
      color: AppColors.appBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_CustomTabBarDelegate oldDelegate) => true;
}

class _ProfileFieldStatus {
  final String title;
  final bool isCompleted;
  _ProfileFieldStatus(this.title, this.isCompleted);
}
