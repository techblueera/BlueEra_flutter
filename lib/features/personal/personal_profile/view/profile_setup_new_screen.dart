import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/controller/booking_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/availability_schedule_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/model/upload_document_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/doc_verification_pending_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/view_document_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/testimonials_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/circular_progress_painter.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/count_clock_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/introduction_video_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/update_profile_view.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../auth/controller/view_personal_details_controller.dart';

class PostTabModel {
  final String id; // For internal logic
  final String nameKey; // For localization lookup

  const PostTabModel({required this.id, required this.nameKey});
}

class PostTabs {
  static const aboutMe = PostTabModel(
    id: "aboutMe",
    nameKey: AppStrings.aboutMe,
  );

  static const posts = PostTabModel(
    id: "posts",
    nameKey: AppStrings.posts,
  );

  static const testimonials = PostTabModel(
    id: "testimonials",
    nameKey: AppStrings.testimonials,
  );

  static const myStore = PostTabModel(
    id: "myStore",
    nameKey: AppStrings.myStore,
  );

  static const List<PostTabModel> postTab = [
    aboutMe,
    posts,
    testimonials,
    myStore,
  ];
}

class PersonalProfileSetupNewScreen extends StatefulWidget {
  final int? selectedIndex;
  final SortBy? sortBy;
  final String? isScreenName;

  const PersonalProfileSetupNewScreen(
      {super.key, this.selectedIndex, this.sortBy, this.isScreenName});

  @override
  State<PersonalProfileSetupNewScreen> createState() =>
      _PersonalProfileSetupNewScreenState();
}

class _PersonalProfileSetupNewScreenState
    extends State<PersonalProfileSetupNewScreen> with TickerProviderStateMixin {
  final viewProfileController = getOrPut(() => ViewPersonalDetailsController());
  final personalCreateProfileController = getOrPut(() => PersonalCreateProfileController());
  final bookingTabController = getOrPut(() => BookingTabController());
  final myDocumentsController = getOrPut(() => MyDocumentsController());
  final introVideoController = getOrPut(() => IntroductionVideoController());

  final youtubeController = TextEditingController();

  // List<String> postTab = [];
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
    if (_tabController?.indexIsChanging ?? false) return;
    setState(() {
      selectedIndex = _tabController!.index;
      updateFilters(selectedIndex);
    });
  }

  void updateFilters(int index) {
    final currentTab = PostTabs.postTab[index].id;
    if (currentTab == 'Shorts' || currentTab == 'Videos') {
      filters = SortBy.values.toList();
    } else {
      filters = null;
    }
  }

  Future<void> _loadInitialData() async {
    await viewProfileController.viewPersonalProfile();
    if (userProfileGlobal == SELF_EMPLOYED &&
        earnServiceCreatedStatusGlobal == 'false') {
      viewProfileController.partiallyForceToCreateService();
    }
    await viewProfileController.UserFollowersAndPostsCount(userId);
    // viewProfileController.isChannelCreated.value = channelId.isNotEmpty;
    checkAndGetAvailabilityBookingData();
    getAllDocumentsData();
    _updateTextControllers();
  }

  Future<void> checkAndGetAvailabilityBookingData() async {
      await bookingTabController.checkAndGetAvailabilityBookingData(userId);
  }

  Future<void> getAllDocumentsData() async {
    myDocumentsController.fetchAllDocumentApi();
  }

  void _initializeTabController() {
    if (_tabController == null ||
        _tabController!.length != PostTabs.postTab.length) {
      // Dispose old controller if exists
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();

      // Create new controller
      final initialIndex = selectedIndex.clamp(0, PostTabs.postTab.length - 1);
      _tabController = TabController(
        length: PostTabs.postTab.length,
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

  bool _hasAnyLinks() {
    // Check if any social link is not null and not empty
    return (viewProfileController.instagram.value.isNotEmpty) ||
        (viewProfileController.website.value.isNotEmpty) ||
        (viewProfileController.linkedin.value.isNotEmpty) ||
        (viewProfileController.twitter.value.isNotEmpty) ||
        (viewProfileController.youtube.value.isNotEmpty);
  }

  backPressTrigger() async {
    if (widget.isScreenName == AppConstants.deepLinkScreen) {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        arguments: {ApiKeys.initialIndex: 0},
      );
      deleteIfRegistered<IntroductionVideoController>();
      deleteIfRegistered<ViewPersonalDetailsController>();
    } else {
      deleteIfRegistered<IntroductionVideoController>();
      deleteIfRegistered<ViewPersonalDetailsController>();
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        backPressTrigger();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteF3,
        appBar: CommonBackAppBar(
          isLeading: true,
          title: '',
          isLogout: true,
          onShareTap: () {},
          onQrCodeTap: () {},
          onBackTap: () async {
            backPressTrigger();
          },
        ),
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
                    child: Container(
                      child: DefaultTabController(
                        length: PostTabs.postTab.length,
                        child: NestedScrollView(
                          headerSliverBuilder: (context, innerBoxIsScrolled) =>
                              [
                            SliverToBoxAdapter(
                              child: _buildHeaderSection(),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _CustomTabBarDelegate(
                                  _buildTabButtons(),
                                  hasFilters: filters != null),
                            ),
                          ],
                          body: TabBarView(
                            controller: _tabController,
                            children: PostTabs.postTab.map((tab) {
                              final index = PostTabs.postTab.indexOf(tab);
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.size10,
                                    vertical: 10),
                                child: _buildTabContent(index),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              }),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (PostTabs.postTab[index].id) {
      case "myStore":
        return CustomText("Coming soon...");

      case "aboutMe":
        return AboutMeWidget();

      case "posts":
        return FeedScreen(
          key: ValueKey('feedScreen_my_posts'),
          postFilterType: PostType.myPosts,
          id: userId,
          isInParentScroll: true,
        );

      case "testimonials":
        return TestimonialsScreen(
          userName: "",
          visitUserID: userId,
          isSelfTestimonial: true,
        );

      default:
        return const Center(child: Text('Unknown Tab'));
    }

    /*  switch (postTab[index]) {
      case 'My Store':
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
      case 'Testimonials':
        return TestimonialsScreen(
          userName: "",
          visitUserID: userId,
          isSelfTestimonial: true,
        );
      default:
        return const Center(child: Text('Unknown Tab'));
    }*/
  }

  Widget AboutMeWidget() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: SizeConfig.size10),

          _buildChannelWidget(),

          SizedBox(height: SizeConfig.size10),

          _buildEarnWithBlueEraWidget(),

          if (Platform.isAndroid) ...[
            SizedBox(height: SizeConfig.size10),
            _buildPaymentAccountWidget(),
          ],

          SizedBox(height: SizeConfig.size10),
          _buildMyDocumentWidget(),

          SizedBox(height: SizeConfig.size10),
          _buildBookingAndaAvailabilityWidget(),

          // Add the IntroductionVideoWidget here

          SizedBox(height: SizeConfig.size10),
          IntroductionVideoWidget(),

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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildCircleIcon(AppIconAssets.link),
                        SizedBox(width: SizeConfig.size6),
                        _buildTitleWidget(AppStrings.links),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size16),
                    Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size14),
                      child: HttpsTextField(
                        controller: youtubeController,
                        isYoutubeValidation: true,
                        hintText: "e.g. https://addlinkhere.com",
                        onChange: (value) {
                          viewProfileController.isYoutubeEdit.value = value;
                        },
                      ),
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CustomBtn(
                      isValidate:
                          viewProfileController.isYoutubeEdit.value.isNotEmpty,
                      onTap: viewProfileController
                              .isYoutubeEdit.value.isNotEmpty
                          ? () async {
                              if (youtubeController.text.isEmpty) {
                                commonSnackBar(
                                    message: "Enter youtube link here...");
                                return;
                              }

                              await personalCreateProfileController
                                  .updateUserProfileDetails(
                                params: {
                                  ApiKeys.id: userId,
                                  ApiKeys.youtube: youtubeController.text,
                                },
                              );
                              viewProfileController.isSocialEdit.value = false;
                            }
                          : null,
                      title: AppStrings.save,
                    ),
                    SizedBox(height: SizeConfig.size16),
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
    return CustomFormCard(
      margin: EdgeInsets.only(top: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size15),
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
                      AppStrings.yourProfileCompletionScore,
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
                        painter: CircleProgressPainter(viewProfileController
                            .myProfileCompletionPercent.value),
                        child: Center(
                          child: CustomText(
                            "${(viewProfileController.myProfileCompletionPercent.value * 100).toInt()}%",
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
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: SizeConfig.size12,
                        runSpacing: SizeConfig.size8,
                        children: viewProfileController.fields.map((item) {
                          return GestureDetector(
                            onTap: () {
                              viewProfileController.onFieldTap(item);
                            },
                            child: SizedBox(
                              width: itemWidth,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.isCompleted
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: item.isCompleted
                                        ? Colors.blue
                                        : Colors.red,
                                    size: 16,
                                  ),
                                  SizedBox(width: 2),
                                  Expanded(
                                    child: CustomText(
                                      item.title,
                                      fontSize: 11,
                                      color: AppColors.mainTextColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: SizeConfig.size15),
                      Builder(
                        builder: (_) {
                          final pendingCount = viewProfileController.fields
                              .where((item) => item.isCompleted == false)
                              .length;

                          return CustomText(
                            "$pendingCount action${pendingCount != 1 ? 's' : ''} pending",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.small,
                            color: pendingCount == 0
                                ? AppColors.green7F
                                : AppColors.yellow00,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    String _capitalizeFirstLetter(String text) {
      if (text.isEmpty) return '';
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size15),
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Banner + Profile + Edit + Share ===
            Container(
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner (dark gradient or user banner)
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

                  // Edit + Share buttons
                  Positioned(
                    right: 12,
                    top: 140,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (viewProfileController.personalProfileDetails
                                    .value.isProfileCreated ==
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryColor,
                                )),
                            child: CustomText(
                              AppStrings.editProfile,
                              color: AppColors.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            try {
                              // 🧩 Generate deep link for this profile
                              final link = profileDeepLink(
                                  userId: userId,
                                  accountType: AppConstants.individual);

                              // 🧩 Message to share
                              final message =
                                  "See my profile on BlueEra:\n$link\n";

                              // 🧩 Use SharePlus to share link
                              await SharePlus.instance.share(
                                ShareParams(
                                    text: message,
                                    subject: viewProfileController
                                            .personalProfileDetails
                                            .value
                                            .user
                                            ?.name ??
                                        ""),
                              );
                            } catch (e) {
                              debugPrint("Error while sharing profile: $e");
                            }
                          },
                          child: LocalAssets(
                            imagePath: AppIconAssets.shareIcon,
                            imgColor: Colors.black,
                          ),
                        )
                      ],
                    ),
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
                            // personalCreateProfileController.imagePath?.value = image;
                            // dynamic dataImage = await multiPartImage(imagePath: image);
                            // var reqProfile = {ApiKeys.profile_image: dataImage};
                            // await personalCreateProfileController.updateUserProfileDetails(
                            //     params: reqProfile, isFromProfileOnly: true);
                          },
                          child: CircleAvatar(
                            backgroundColor: AppColors.black.withValues(alpha: 0.3),
                            child: LocalAssets(
                                imagePath: 'assets/diwali_card/image.png'),
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
                  const SizedBox(height: 8),
                  Row(
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
                      viewProfileController.personalProfileDetails.value
                          .user?.profession?.isNotEmpty??false?Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: BoxBorder.all(
                              color: AppColors.secondaryTextColor,
                            )),
                        child: CustomText(
                          viewProfileController.personalProfileDetails.value
                                  .user?.profession ??
                              '',
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                        ),
                      ):SizedBox(),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // === Stats Row ===
            Obx(() {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatBlock(
                      callback: () {
                        _tabController?.animateTo(1);
                      },
                      count: viewProfileController.postsCount.value.toString(),
                      label: AppStrings.post,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    StatBlock(
                      count:
                          viewProfileController.followingCount.value.toString(),
                      label: AppStrings.following,
                      callback: () {
                        Get.to(() => FollowersFollowingPage(
                            tabIndex: 0, userID: userId));
                      },
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    StatBlock(
                      count:
                          viewProfileController.followersCount.value.toString(),
                      label: AppStrings.followers,
                      callback: () {
                        Get.to(() => FollowersFollowingPage(
                            tabIndex: 1, userID: userId));
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),

            // === Bio Section ===
            // if (_shouldShowBioSection())
            viewProfileController
                .personalProfileDetails.value.user?.bio?.isNotEmpty??false?Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
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
            ):SizedBox(),

            //
            //
            //
            const SizedBox(height: 12),

            // === Buttons Row ===
            Padding(
              padding: EdgeInsets.only(
                  left: SizeConfig.size15,
                  right: SizeConfig.size15,
                  bottom: SizeConfig.size12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.toNamed(RouteHelper.getCreateResumeScreenRoute());
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              AppStrings.myResume,
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 25,
                              height: 25,
                              child: CustomPaint(
                                painter: CircleProgressPainter(0.85),
                                child: Center(
                                  child: CustomText(
                                    "${(0.85 * 100).toInt()}%",
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
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
                  Expanded(
                    child: Obx(() => GestureDetector(
                          onTap: () {
                            viewProfileController.isMyProfileShow.value =
                                !viewProfileController.isMyProfileShow.value;
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size10, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  viewProfileController.isMyProfileShow.isTrue
                                      ? AppColors.primaryColor
                                      : Colors.white,
                              border: Border.all(color: AppColors.primaryColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomText(
                                  AppStrings.myProfile,
                                  color: viewProfileController
                                          .isMyProfileShow.isTrue
                                      ? Colors.white
                                      : AppColors.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CustomPaint(
                                    painter: CircleProgressPainter(
                                      viewProfileController
                                          .myProfileCompletionPercent.value,
                                      isMyProfile: viewProfileController
                                          .isMyProfileShow.value,
                                    ),
                                    child: Center(
                                      child: CustomText(
                                        "${(viewProfileController.myProfileCompletionPercent.value * 100).toInt()}%",
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: viewProfileController
                                                .isMyProfileShow.isTrue
                                            ? Colors.white
                                            : AppColors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ),
                ],
              ),
            ),
            Obx(() {
              return !viewProfileController.isMyProfileShow.value
                  ? SizedBox()
                  : _buildMyProfileWidget();
            })
          ],
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SizeConfig.size40,
          child: ListView.builder(
            itemCount: PostTabs.postTab.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final isSelected = _tabController?.index == index;
              // return  InkWell(
              //   onTap: (){
              //     _tabController?.animateTo(index);
              //
              //   },
              //   child: Container(
              //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              //       margin: EdgeInsets.only(right: SizeConfig.size8),
              //       decoration: BoxDecoration(
              //          color: isSelected ? AppColors.primaryColor : Colors.white,                    borderRadius: BorderRadius.circular(10),
              //           border: Border.all(
              //             color: isSelected
              //                 ? AppColors.primaryColor
              //                 : AppColors.secondaryTextColor,)),
              //       child: CustomText(
              //         '${PostTabs.postTab[index].nameKey}',                  color: isSelected ? AppColors.white : AppColors.black,
              //         fontSize: SizeConfig.size10,
              //         fontWeight: FontWeight.w700,
              //       ),
              //     ),
              // );
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  child: ElevatedButton(
                    onPressed: () {
                      _tabController?.animateTo(index);
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: isSelected
                          ? AppColors.white
                          : AppColors.secondaryTextColor,
                      backgroundColor:
                          isSelected ? AppColors.primaryColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.secondaryTextColor,
                        ),
                      ),
                      padding: EdgeInsets.only(left: 8, right: 8),
                      // minimumSize: Size(SizeConfig.size80, SizeConfig.size34),
                      // maximumSize: Size(SizeConfig.size90, SizeConfig.size34),
                    ),
                    child: CustomText(
                      '${PostTabs.postTab[index].nameKey}',
                      color: isSelected ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIcon(String iconImage) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primaryColor, width: 0.5),
      ),
      child: LocalAssets(
        width: SizeConfig.size22,
        height: SizeConfig.size22,
        imagePath: iconImage,
        imgColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildTitleWidget(String text) {
    return CustomText(
      text,
      fontSize: SizeConfig.medium,
      fontWeight: FontWeight.w600,
      color: AppColors.secondaryTextColor,
    );
  }

  Widget _buildContainerOverlay({required Widget child}) {
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
          boxShadow: [AppShadows.textFieldShadow]),
      child: child,
    );
  }

  Widget _buildChannelWidget() {
    return CustomFormCard(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size10,
      ),
      child: channelId.isNotEmpty
          ? Column(
              children: [
                Row(
                  children: [
                    _buildCircleIcon(AppIconAssets.channelNew),
                    SizedBox(width: SizeConfig.size6),
                    Expanded(child: _buildTitleWidget(AppStrings.myChannel)),
                    SizedBox(width: SizeConfig.size6),
                    InkWell(
                      onTap: () {
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
                        AppStrings.view,
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
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        '@$channelOwner',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                )
              ],
            )
          : InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteHelper.getManageChannelScreenRoute(),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleIcon(AppIconAssets.channelNew),
                  SizedBox(width: SizeConfig.size6),
                  _buildTitleWidget(AppStrings.myChannel),
                  Spacer(),
                  CustomText(
                    AppStrings.create,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildEarnWithBlueEraWidget() {
    return CustomFormCard(
        // padding: EdgeInsets.all(SizeConfig.size16),
        child: Column(children: [
      Row(
        children: [
          _buildCircleIcon(AppIconAssets.earnWithBlueEra),
          SizedBox(width: SizeConfig.size6),
          Expanded(child: _buildTitleWidget(AppStrings.earnWithBlueEra)),
        ],
      ),
      SizedBox(height: SizeConfig.size16),
      HorizontalVideoPlayer(),
      SizedBox(height: SizeConfig.size16),
      Align(
        alignment: Alignment.bottomRight,
        child: CustomBtn(
          width: SizeConfig.size160,
          title: AppStrings.letsStartEarningNow,
          onTap: () {
            if (viewProfileController
                    .personalProfileDetails.value.isProfileCreated ==
                false) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateProfileScreen()));
            } else {
              log('user work type-- $userWorkTypeGlobal');
              if(userWorkTypeGlobal == DELIVERY_RIDER
                  // || userWorkTypeGlobal == 'Delivery Partner'
              ){
                Get.toNamed(RouteHelper
                    .getRiderServiceScreenRoute());
              }else{
                Get.toNamed(RouteHelper
                    .getEarnServiceScreenRoute());
              }
            }
          },
          bgColor: AppColors.primaryColor,
          textColor: AppColors.white,
          height: SizeConfig.size34,
          radius: 10.0,
        ),
      ),
    ]));
  }

  Widget _buildPaymentAccountWidget() {
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
              _buildTitleWidget(AppStrings.paymentAccount),
            ],
          ),
          SizedBox(width: SizeConfig.size6),
          InkWell(
            onTap: () => Get.toNamed(RouteHelper.getPaymentSettingScreenRoute()),
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
                child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomText(
                  "${AppStrings.myWallet.tr}: ",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
                CustomText(
                  '₹ 0',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ],
            )),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: _buildContainerOverlay(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomText(
                  "${AppStrings.totalEarning.tr}: ",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
                CustomText(
                  '₹ 0',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            )),
          )
        ],
      ),
      SizedBox(height: SizeConfig.size10),
      _buildContainerOverlay(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CustomText(
            '${AppStrings.bankAccount.tr}: ',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
          CustomText(
            'State payment Of India',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
        ],
      )),
      SizedBox(height: SizeConfig.size10),
      Align(
        alignment: Alignment.centerRight,
        child: CustomBtn(
            onTap: (){},
            height: SizeConfig.size30,
            width: SizeConfig.size90,
            title: AppStrings.withdraw,
            bgColor: AppColors.primaryColor,
            radius: 10.0,
        ),
      )
      // _buildContainerOverlay(
      //     child: InkWell(
      //   onTap: () => Get.to(() => SubscriptionScreen()),
      //   child: Row(
      //     children: [
      //       LocalAssets(
      //         imagePath: AppIconAssets.subscription,
      //         width: SizeConfig.size18,
      //         height: SizeConfig.size18,
      //       ),
      //       SizedBox(width: SizeConfig.size10),
      //       CustomText(
      //         AppStrings.manageSubscription,
      //         fontSize: SizeConfig.small,
      //         fontWeight: FontWeight.w700,
      //         color: AppColors.secondaryTextColor,
      //       ),
      //       Spacer(),
      //       CustomText(
      //         AppStrings.freePlan,
      //         fontSize: SizeConfig.small,
      //         fontWeight: FontWeight.w600,
      //         color: AppColors.primaryColor,
      //       ),
      //     ],
      //   ),
      // )
      // )
    ]));
  }

  Widget _buildMyDocumentWidget() {
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
                _buildTitleWidget(AppStrings.myDocuments),
              ],
            ),
            SizedBox(width: SizeConfig.size6),
            PositiveCustomBtn(
              onTap: () {
                Get.toNamed(RouteHelper.getAddDocumentScreenRoute());
              },
              title: AppStrings.addDocument,
              padding: EdgeInsets.symmetric(horizontal: 3),
              textColor: AppColors.primaryColor,
              fontSize: SizeConfig.small,
              iconPath: AppIconAssets.add,
              iconColor: AppColors.primaryColor,
              width: SizeConfig.size120,
              height: SizeConfig.size30,
              bgColor: Colors.transparent,
              borderColor: AppColors.primaryColor,
              radius: 6.0,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size16),
        Container(
          margin: EdgeInsets.symmetric(vertical: SizeConfig.size8),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.whiteE0),
              boxShadow: [AppShadows.textFieldShadow]),
          child: (myDocumentsController.documents.isEmpty)
              ? ListTile(
                  dense: true,
                  onTap: ()=> Get.toNamed(RouteHelper.getAddDocumentScreenRoute()),
                  leading: Icon(
                    Icons.folder_open,
                    color: AppColors.primaryColor,
                  ),
                  title: CustomText(
                    AppStrings.noDocumentsFound,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                  subtitle: CustomText(
                    AppStrings.addYourFirstDocument,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                )
              : ExpansionTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  title: CustomText(
                    AppStrings.myDocuments,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  childrenPadding: EdgeInsets.only(bottom: SizeConfig.size8),
                  children: [
                      for (int i = 0;
                          i < myDocumentsController.documents.length;
                          i++) ...[
                        _buildDocumentCard(
                          myDocumentsController.documents[i],
                          myDocumentsController,
                        ),
                        if (i != myDocumentsController.documents.length - 1)
                          CommonHorizontalDivider(
                            color: AppColors.greyE5, // <-- your colour
                          ),
                      ]
                    ]),
        )
      ],
    ));
  }

  Widget _buildBookingAndaAvailabilityWidget() {
    return CustomFormCard(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildCircleIcon(AppIconAssets.bookingEnquiries),
            SizedBox(width: SizeConfig.size6),
            _buildTitleWidget(AppStrings.myAvailabilityAndBookings),
            if (bookingTabController.availabilityDetails.value != null) ...[
              Spacer(),
              InkWell(
                onTap: () async {
                   await Get.toNamed(
                      RouteHelper.getAvailabilityScreenRoute(),
                      arguments: {
                        ApiKeys.argId: userId,
                      });
                },
                child: LocalAssets(
                  height: 18,
                  imagePath: AppIconAssets.pen_line,
                ),
              )
            ]
          ],
        ),
        SizedBox(height: SizeConfig.size16),
        _buildContainerOverlay(
            child: bookingTabController.availabilityDetails.value != null
                ? Obx(() {
                    AvailabilityData data = bookingTabController.availabilityDetails.value!;
                    final selectedType;
                    final bt = data.bookingType?.toLowerCase();
                    if (bt == 'online') {
                      selectedType = BookingType.online;
                    } else if (bt == 'offline') {
                      selectedType = BookingType.offline;
                    } else {
                      selectedType = BookingType.both;
                    }
                    final landMark = data.location?.landmark ?? '';
                    final location = data.location?.address ?? '';
                    final instruction = data.instructions ?? '';
                    final minFee = data.feeDetails?.minFee?.toString() ?? '';
                    final maxFee = data.feeDetails?.maxFee?.toString() ?? '';
                    final feeType = data.feeDetails?.feeType?.toString() ?? '';
                    final selectedTimeSlot;
                    if (data.durationInMinutes?.toString().isNotEmpty ??
                        false) {
                      final candidate = '${data.durationInMinutes} Min';
                      const allowed = ['15 Min', '30 Min', '60 Min'];
                      selectedTimeSlot =
                          allowed.contains(candidate) ? candidate : '30 Min';
                    } else {
                      selectedTimeSlot = '30 Min';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Booking Type
                        CustomText(
                          'Booking Type',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size12),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                            vertical: SizeConfig.size10,
                          ),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.whiteE5),
                              boxShadow: [AppShadows.textFieldShadow]),
                          child: Row(
                            children: [
                              Icon(Icons.event_available,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: SizeConfig.size8),
                              CustomText(
                                bt,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mainTextColor,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: SizeConfig.size16),

                        /// Location
                        selectedType != BookingType.online
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // landmark
                                  CustomText(
                                    'Landmark',
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),
                                  SizedBox(height: SizeConfig.size8),
                                  Container(
                                    width: SizeConfig.screenWidth,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size12,
                                      vertical: SizeConfig.size10,
                                    ),
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.whiteE0),
                                        boxShadow: [
                                          AppShadows.textFieldShadow
                                        ]),
                                    child: CustomText(
                                      landMark,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mainTextColor,
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.size16),

                                  // address
                                  CustomText(
                                    'Location',
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),
                                  SizedBox(height: SizeConfig.size8),
                                  Container(
                                    width: SizeConfig.screenWidth,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size12,
                                      vertical: SizeConfig.size10,
                                    ),
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.whiteE0),
                                        boxShadow: [
                                          AppShadows.textFieldShadow
                                        ]),
                                    child: CustomText(
                                      location,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mainTextColor,
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.size16),
                                ],
                              )
                            : const SizedBox.shrink(),

                        /// Booking Fee
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    'Min Fee',
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),
                                  SizedBox(height: SizeConfig.size8),
                                  Container(
                                    width: SizeConfig.screenWidth,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size12,
                                      vertical: SizeConfig.size10,
                                    ),
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.whiteE0),
                                        boxShadow: [AppShadows.textFieldShadow]),
                                    child: CustomText(
                                      minFee,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mainTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    'Max Fee',
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),
                                  SizedBox(height: SizeConfig.size8),
                                  Container(
                                    width: SizeConfig.screenWidth,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size12,
                                      vertical: SizeConfig.size10,
                                    ),
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.whiteE0),
                                        boxShadow: [AppShadows.textFieldShadow]),
                                    child: CustomText(
                                      maxFee,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mainTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size16),

                        /// Fee Type
                        CustomText(
                          'Fee Type',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Container(
                          width: SizeConfig.screenWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                            vertical: SizeConfig.size10,
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.whiteE0),
                              boxShadow: [AppShadows.textFieldShadow]),
                          child: CustomText(
                            feeType,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mainTextColor,
                          ),
                        ),

                        SizedBox(height: SizeConfig.size16),

                        /// Instructions
                        CustomText(
                          'Instructions',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Container(
                          width: SizeConfig.screenWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                            vertical: SizeConfig.size10,
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.whiteE0),
                              boxShadow: [AppShadows.textFieldShadow]),
                          child: CustomText(
                            instruction,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                        SizedBox(height: SizeConfig.size16),

                        /// Booking appointment duration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  'Duration per appointment',
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size12,
                                  vertical: SizeConfig.size6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CustomText(
                                selectedTimeSlot,
                                fontSize: SizeConfig.size16,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: SizeConfig.size16),

                        /// Booking days and timings
                        AvailabilityScheduleCard(data: data)
                      ],
                    );
                  })
                : InkWell(
                    onTap: () {
                      Get.toNamed(RouteHelper.getAvailabilityScreenRoute(),
                          arguments: {ApiKeys.argId: userId});
                    },
                    child: Row(
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.mailIcon,
                        ),
                        SizedBox(width: SizeConfig.size10),
                        CustomText(
                          AppStrings.bookings,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right)
                      ],
                    ),
                  ))
      ],
    ));
  }

  Widget _buildDocumentCard(
      DocumentsResponse document, MyDocumentsController controller) {

    return Container(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size12, horizontal: SizeConfig.size15),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size6),
            decoration: BoxDecoration(
                color: AppColors.whiteFE,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.greyE5,
                  width: 1,
                ),
                boxShadow: [AppShadows.textFieldShadow]),
            child: LocalAssets(
              imagePath: AppIconAssets.outlinedDocument,
              width: SizeConfig.size20,
              height: SizeConfig.size20,
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          // Document Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  controller.getDocumentName(document.documentType??''),
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  document.createdAt,
                  fontSize: SizeConfig.extraSmall,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size12),

          // Action Buttons
          GestureDetector(
            onTap: () {
              Get.bottomSheet(
                CommonDocumentBottomSheet(
                  title: controller.getDocumentName(document.documentType??''),
                  child: (document.isVerified ?? false) ? ViewDocumentWidget(
                    document: document,
                  ) : DocumentVerificationPendingWidget(
                      documentName: controller.getDocumentName(document.documentType??''),
                  ),
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            child: LocalAssets(
              imagePath: AppIconAssets.eyeIcon,
              height: 20,
              width: 20,
              imgColor: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  final bool hasFilters;

  _CustomTabBarDelegate(this.tabBar, {this.hasFilters = false});

  @override
  double get minExtent => 50;

  @override
  double get maxExtent => 50;

  // double get maxExtent => hasFilters ? 90.0 : 50.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.only(top: 0),
      color: AppColors.appBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_CustomTabBarDelegate oldDelegate) => true;
}
