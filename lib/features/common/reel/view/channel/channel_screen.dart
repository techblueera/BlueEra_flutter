import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/controller/channel_controller.dart';
import 'package:BlueEra/features/common/reel/controller/manage_channel_controller.dart';
import 'package:BlueEra/features/common/reel/view/sections/common_draft_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/common/store/channel_product_screen/channel_product_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/channel_setting_screen/channel_setting_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_button_with_icon.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dioObj;

import '../../../../business/visit_business_profile/view/visit_business_profile_new.dart';

enum ChannelTab {
  shorts,
  videos,
  posts,
  drafts,
  saved,
  statistics,
  product;

  /// Human-readable title (capitalised)
  String get title => name[0].toUpperCase() + name.substring(1);
}

enum visitingChannelEnum { shorts, videos, posts, product }

class ChannelScreen extends StatefulWidget {
  final String accountType;
  final String channelId;
  final String authorId;

  const ChannelScreen(
      {super.key,
        required this.accountType,
        required this.channelId,
        required this.authorId});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  ChannelController channelController = Get.put(ChannelController());
  late ChannelTab _selectedTab;
  late List<ChannelTab> _tabsList = ChannelTab.values;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contentKey = GlobalKey();
  double? _calculatedHeight;
  final GlobalKey _tabButtonsKey = GlobalKey();
  double? _tabButtonsHeight;
  bool isMeasured = false;
  bool isOwnChannel = false;
  List<SortBy>? filters;

  @override
  void initState() {
    super.initState();
    isOwnChannel = widget.channelId == channelId;
    _selectedTab = ChannelTab.shorts;
    if (!isOwnChannel) {
      _tabsList = [
        ChannelTab.shorts,
        ChannelTab.videos,
        ChannelTab.posts,
        ChannelTab.product,
      ];
    }

    // Reset scroll state when screen is initialized
    channelController.isCollapsed.value = false;
    _calculatedHeight = null;
    _tabButtonsHeight = null;
    isMeasured = false;

    updateFilters();
    _fetchInitialChannelData();
  }

  void updateFilters() {
    if (_selectedTab == ChannelTab.posts) {
      filters = SortBy.values.where((e) => e != SortBy.UnderProgress).toList();
    } else if (_selectedTab == ChannelTab.videos ||
        _selectedTab == ChannelTab.shorts) {
      if (isOwnChannel) {
        filters = SortBy.values.toList();
      } else {
        filters =
            SortBy.values.where((e) => e != SortBy.UnderProgress).toList();
      }
    } else {
      filters = null;
    }
  }

  void _fetchInitialChannelData() async {
    try {
      channelController.isInitialLoading.value = true;

      final channelData = Future.wait([
        channelController.getChannelDetails(
            channelOrUserId: isOwnChannel ? widget.authorId : widget.channelId),
        channelController.getChannelStats(channelId: widget.channelId),
      ]);

      // Wait for the other two if not done yet
      await channelData;
    } catch (e) {
      debugPrint('Error loading feeds: $e');
    } finally {
      debugPrint('Error loading feeds:');
      channelController.isInitialLoading.value = false;

      await Future.delayed(Duration(milliseconds: 100));

      /// if any api fail we also need to set this to see channel video, shorts and other content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadChannelContent();
      });
    }
  }

  void loadChannelContent() {
    _calculateContentHeight();
    _getTabButtonsHeight();
    _setupScrollListener();

    // Reset scroll position to top when content is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _calculateContentHeight() {
    final context = _contentKey.currentContext;
    log("context--> $context");
    if (context == null || !mounted) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      setState(() {
        _calculatedHeight = box.size.height;
        log("height--> $_calculatedHeight");
        isMeasured = true;
      });
    }
  }

  void _getTabButtonsHeight() {
    final context = _tabButtonsKey.currentContext;
    if (context != null) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      setState(() {
        _tabButtonsHeight = box.size.height;
        print("📏 TabButtons Height: $_tabButtonsHeight");
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients || _calculatedHeight == null) return;

      final shouldCollapse =
          _scrollController.offset > (_calculatedHeight! - SizeConfig.size15);

      if (channelController.isCollapsed != shouldCollapse) {
        setState(() {
          channelController.isCollapsed.value = shouldCollapse;
          log("isCollapsed--> ${channelController.isCollapsed.value}");
        });
      }

      // Handle pagination for child sections
      _handleChildSectionPagination();
    });
  }

  void _handleChildSectionPagination() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom =
        position.pixels >= position.maxScrollExtent - 100; // 100px threshold

    if (isAtBottom) {
      print('is At Bottom');
      // Trigger pagination based on current tab
      switch (_selectedTab) {
        case ChannelTab.shorts:
        // Trigger pagination for ShortsChannelSection
          final shortsController = Get.find<ShortsController>();
          final shorts = _getShortsType();
          if (shortsController.isHasMoreData(shorts) &&
              shortsController.isMoreDataLoading(shorts).isFalse) {
            shortsController.isMoreDataLoading(shorts).value = true;
            shortsController.getShortsByType(
                shorts, widget.channelId,
                widget.authorId,
                postVia: PostVia.channel
            );
          }
          break;
        case ChannelTab.videos:
        // Trigger pagination for VideoChannelSection
          final videosController = Get.find<VideoController>();
          final videos = _getVideosType();
          if (videosController.isMoreDataAvailable &&
              videosController.isLoading.isFalse) {
            videosController.getVideosByType(
              videos,
              widget.channelId,
              widget.authorId,
            );
          }
          break;
        case ChannelTab.posts:
        // Trigger pagination for FeedScreen
          final feedController = Get.find<FeedController>();
          final postType = _getPostType();
          log('Posts pagination check - hasMoreData: ${feedController.isTargetHasMoreData.value}, isLoading: ${feedController.isLoading.value}');
          if (feedController.isTargetHasMoreData.isTrue &&
              feedController.isLoading.isFalse) {
            feedController.getPostsByType(
              postType,
              isInitialLoad: false, // This is pagination, not initial load
              id: widget.authorId,
            );
          }
          break;
        default:
          break;
      }
    }
  }

  Shorts _getShortsType() {
    return switch (channelController.selectedFilter) {
      SortBy.Latest => Shorts.latest,
      SortBy.Popular => Shorts.popular,
      SortBy.Oldest => Shorts.oldest,
      SortBy.UnderProgress => Shorts.underProgress,
    };
  }

  VideoType _getVideosType() {
    return switch (channelController.selectedFilter) {
      SortBy.Latest => VideoType.latest,
      SortBy.Popular => VideoType.popular,
      SortBy.Oldest => VideoType.oldest,
      SortBy.UnderProgress => VideoType.underProgress,
    };
  }

  PostType _getPostType() {
    return switch (channelController.selectedFilter) {
      SortBy.Latest => PostType.latest,
      SortBy.Popular => PostType.popular,
      SortBy.Oldest => PostType.oldest,
      SortBy.UnderProgress => PostType.latest,
    };
  }

  @override
  void dispose() {
    // Reset the collapsed state when disposing
    channelController.isCollapsed.value = false;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset scroll state when dependencies change (e.g., when returning to screen)
    if (mounted && _scrollController.hasClients) {
      channelController.isCollapsed.value = false;
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          isLeading: true,
        ),
        body: Obx(() => channelController.isInitialLoading.isTrue
            ? Center(child: CircularProgressIndicator())
            : (!isMeasured)
            ? Container(
          key: _contentKey,
          width: MediaQuery.of(context).size.width,
          child: _buildHeaderSection(),
        )
            : CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: _calculatedHeight,
              backgroundColor: channelController.isCollapsed.isTrue
                  ? AppColors.white
                  : Colors.transparent,
              elevation: 0,
              titleSpacing: 0,
              title: channelController.isCollapsed.isTrue
                  ? _buildTabButtons()
                  : null,
              toolbarHeight: channelController.isCollapsed.isTrue
                  ? _tabButtonsHeight ?? SizeConfig.size100
                  : kToolbarHeight,
              flexibleSpace: channelController.isCollapsed.isTrue
                  ? null
                  : FlexibleSpaceBar(
                background: _buildHeaderSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (channelController.isCollapsed.isFalse) ...[
                    SizedBox(height: SizeConfig.size5),
                    _buildTabButtons(),
                  ],
                  Padding(
                    padding: EdgeInsets.only(
                        left: SizeConfig.size15,
                        right: SizeConfig.size15
                    ),
                    child: _buildTabView(),
                  ),
                ],
              ),
            ),
          ],
        )));
  }

  Widget _buildHeaderSection() {
    return Obx(() => Padding(
      padding: EdgeInsets.only(
          left: SizeConfig.size15,
          right: SizeConfig.size15,
          top: SizeConfig.size12,
          bottom: SizeConfig.size6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: EdgeInsets.only(
                    right: SizeConfig.size18, top: SizeConfig.size4),
                child: CommonProfileImage(
                    imagePath: channelController.channelLogo.value,
                    onImageUpdate: (image) async {
                      final manageChannelController =
                      Get.put(ManageChannelController());

                      channelController.channelLogo.value = image;

                      dioObj.MultipartFile? imageByPart;

                      String fileName = image.split('/').last;
                      imageByPart = await dioObj.MultipartFile.fromFile(
                          image,
                          filename: fileName);

                      Map<String, dynamic> requestData = {
                        ApiKeys.name:
                        channelController.channelData.value?.name,
                      };
                      requestData[ApiKeys.logo] = imageByPart;
                      await manageChannelController.updateChannel(
                        reqData: requestData,
                      );

                      // print("Update Params: $reqProfile");
                    },
                    dialogTitle: 'Upload Channel Logo',
                    isOwnProfile: isOwnChannel
                ),
              ),
              /*      Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CachedAvatarWidget(
                            imageUrl:
                                channelController.channelData.value?.logoUrl ??
                                    "",
                            size: SizeConfig.size100,
                            borderRadius: SizeConfig.size100 / 2,
                            borderColor: AppColors.primaryColor),
                        if (isOwnChannel)
                          Positioned(
                            right: -(SizeConfig.size1),
                            bottom: -(SizeConfig.size1),
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  RouteHelper.getManageChannelScreenRoute(),
                                  arguments: {
                                    ApiKeys.channelData: channelController.channelData.value,
                                  },
                                );
                                if (result == true) {
                                  channelController.getChannelDetails(
                                      channelOrUserId: isOwnChannel
                                          ? widget.authorId
                                          : widget.channelId);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryColor),
                                child: Icon(Icons.edit_outlined,
                                    color: AppColors.white,
                                    size: SizeConfig.size20),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),*/
              // SizedBox(width: SizeConfig.size20),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomText(
                            channelController.channelData.value?.name ?? "",
                            fontSize: SizeConfig.extraLarge,
                            fontWeight: FontWeight.w700,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: SizeConfig.size5),
                          (channelController.channelData.value?.verification
                              .isVerified ??
                              false)
                              ? Padding(
                            padding: EdgeInsets.only(
                                top: SizeConfig.size4),
                            child: LocalAssets(
                                imagePath:
                                AppIconAssets.verifiedIcon),
                          )
                              : SizedBox(),
                          Spacer(),
                          (!isOwnChannel)
                              ? _buildVisitingChannelPopUpMenu(
                              onReport: () {
                                showReportDialog(
                                    context: context,
                                    onConfirm: (value) {
                                      channelController.reportChannel(
                                          channelId: channelId,
                                          reason: value);
                                    });
                              },
                              // onBlock: (){
                              //   showBlockUnBlockDialog();
                              // },
                              onMute: () {
                                showMuteUnMuteDialog();
                              }, onOwnership: () {
                            navigateToProfileSection();
                          })
                              : _buildOwnChannelPopUpMenu(
                            onChannelEdit: () async {
                              final result =
                              await Navigator.pushNamed(
                                context,
                                RouteHelper
                                    .getManageChannelScreenRoute(),
                                arguments: {
                                  ApiKeys.channelData: channelController
                                      .channelData.value,
                                },
                              );
                              if (result == true) {
                                channelController.getChannelDetails(
                                    channelOrUserId: isOwnChannel
                                        ? widget.authorId
                                        : widget.channelId);
                              }
                            },
                            onchannelSetting: () {
                              Get.to(() => ChannelSettingScreen());
                            },
                            onAddVideo: () {
                              showVideosPickerDialog(context,
                                  type: PostVia.channel);
                            },
                            onAddProduct: () {
                              Get.toNamed(
                                  RouteHelper
                                      .getAddUpdateProductScreenRoute(),
                                  arguments: {
                                    ApiKeys.channelId:
                                    widget.channelId,
                                  });
                            },
                          ),
                        ],
                      ),
                      SizedBox(width: SizeConfig.size2),
                      CustomText(
                        channelController.channelData.value?.username ?? "",
                        color: AppColors.grey4C,
                        fontSize: SizeConfig.small,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          buildStatBlock(
                              channelController.channelStats.value?.posts
                                  .toString() ??
                                  "0",
                              "Posts"),
                          GestureDetector(
                              onTap: () {
                                // Navigator.pushNamed(
                                //     context,
                                //     RouteHelper
                                //         .getFollowerFollowingScreenRoute());
                              },
                              child: buildStatBlock(
                                  channelController
                                      .channelStats.value?.followers
                                      .toString() ??
                                      "0",
                                  "Followers")),
                          GestureDetector(
                            onTap: () {
                              // Navigator.pushNamed(
                              //     context,
                              //     RouteHelper
                              //         .getFollowerFollowingScreenRoute());
                            },
                            child: buildStatBlock(
                                channelController
                                    .channelStats.value?.following
                                    .toString() ??
                                    "0",
                                "Following"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            channelController.channelData.value?.bio ?? "",
            fontSize: SizeConfig.small,
          ),
          SizedBox(height: SizeConfig.size8),
          Wrap(
            spacing: 12,
            children: channelController.channelData.value?.socialLinks
                .map((link) {
              final platform = link.platform.toLowerCase();
              final url = link.url;

              if (url.isEmpty) return const SizedBox();

              return InkWell(
                onTap: () {
                  channelController.launchSmartUrl(url);
                },
                child: LocalAssets(
                  imagePath: _getIconForPlatform(platform),
                  height: SizeConfig.size22,
                ),
              );
            }).toList() ??
                [],
          ),
          SizedBox(height: SizeConfig.size8),
          if (!isOwnChannel) ...[
            SizedBox(height: SizeConfig.size8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => Expanded(
                  child: commonButtonWithIcon(
                    height: SizeConfig.size36,
                    onTap: () {
                      if (isGuestUser()) {
                        createProfileScreen();
                        return;
                      }
                      channelController.followUnfollowChannel(
                          channelId: widget.channelId,
                          isFollowing:
                          channelController.isChannelFollow.value);
                    },
                    title: channelController.isChannelFollow.isTrue
                        ? "Following"
                        : "Follow",
                    icon: AppIconAssets.personFollowIcon,
                    iconColor: AppColors.white,
                    bgColor: AppColors.primaryColor,
                    isPrefix: false,
                    radius: SizeConfig.size8,
                  ),
                )),
                /* SizedBox(width: SizeConfig.size8),
                    Expanded(
                      child: commonButtonWithIcon(
                        height: SizeConfig.size36,
                        onTap: () {},
                        title: "Connect",
                        textColor: AppColors.primaryColor,
                        icon: AppIconAssets.connectIcon,
                        iconColor: AppColors.primaryColor,
                        borderColor: AppColors.primaryColor,
                        isPrefix: false,
                        radius: SizeConfig.size8,
                      ),
                    )*/
              ],
            ),
          ],
        ],
      ),
    ));
  }

  Widget _buildTabButtons() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: _tabButtonsKey,
        child: Column(
          children: [
            SizedBox(
              height: 34,
              child: ListView.builder(
                padding: EdgeInsets.only(left: SizeConfig.size8),
                itemCount: _tabsList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final isSelected = _selectedTab == _tabsList[index];
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTab = _tabsList[index];
                          updateFilters();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        foregroundColor:
                        isSelected ? Colors.black87 : Colors.black54,
                        backgroundColor:
                        isSelected ? Colors.blue.shade100 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(SizeConfig.size10),
                          side: BorderSide(
                              color: isSelected
                                  ? Colors.blue.shade100
                                  : Colors.grey),
                        ),
                        padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size2),
                        minimumSize: Size(SizeConfig.size80, SizeConfig.size34),
                        maximumSize: Size(SizeConfig.size90, SizeConfig.size34),
                      ),
                      child: Text('${_tabsList[index].title}'),
                    ),
                  );
                },
              ),
            ),
            if (filters != null) ...[
              SizedBox(height: SizeConfig.size20),
              _filterButtons(),
              SizedBox(height: SizeConfig.size10),
            ]
          ],
        ),
      ),
    );
  }

  Widget _filterButtons() {
    return SingleChildScrollView(
        child: Row(
          children: [
            SizedBox(width: SizeConfig.size20),
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Row(
                children: filters!.map((filter) {
                  final isSelected = channelController.selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size14),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          channelController.selectedFilter = filter;
                        });
                      },
                      child: CustomText(
                        filter.label, // use .label for display text
                        decoration: TextDecoration.underline,
                        color: isSelected ? Colors.blue : Colors.black54,
                        decorationColor: isSelected ? Colors.blue : Colors.black54,
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

  Widget buildStatBlock(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          value,
          fontSize: SizeConfig.medium,
        ),
        SizedBox(height: SizeConfig.size5),
        CustomText(
          label,
          fontSize: SizeConfig.medium,
          color: AppColors.greyA5,
        ),
      ],
    );
  }

  Widget _buildTabView() {
    switch (_selectedTab) {
      case ChannelTab.shorts:
        return isOwnChannel
            ? ShortsChannelSection(
          isOwnShorts: isOwnChannel,
          sortBy: channelController.selectedFilter,
          showShortsInGrid: true,
          channelId: '',
          authorId: widget.authorId,
          postVia: PostVia.channel,
        ) : ShortsChannelSection(
          isOwnShorts: isOwnChannel,
          sortBy: channelController.selectedFilter,
          showShortsInGrid: true,
          channelId: widget.channelId,
          authorId: widget.authorId,
          postVia: PostVia.channel,
        );
      case ChannelTab.videos:
        return isOwnChannel
            ?
         VideoChannelSection(
          isOwnVideos: isOwnChannel,
          sortBy: channelController.selectedFilter,
          channelId: '',
          authorId: widget.authorId,
          postVia: PostVia.channel,
        ) : VideoChannelSection(
          isOwnVideos: isOwnChannel,
          sortBy: channelController.selectedFilter,
          channelId: widget.channelId,
          authorId: widget.authorId,
          postVia: PostVia.channel,
        );

      case ChannelTab.posts:
        if (isOwnChannel)
          return FeedScreen(
            key: ValueKey('own_channel_posts'),
            id: widget.authorId,
            postFilterType: _getPostType(),
            isInParentScroll: true, // Indicate this is used in parent scroll
          );
        else
          return FeedScreen(
            key: ValueKey('visiting_channel_posts'),
            id: widget.authorId,
            postFilterType: _getPostType(),
            isInParentScroll: true, // Indicate this is used in parent scroll
          );
      case ChannelTab.product:
        return ChannelProductScreen(
          isOwnChannel: isOwnChannel,
          channelId: widget.channelId,
        );

    // Own channel only
      case ChannelTab.drafts:
        return CommonDraftSection(
            isOwnProfile: isOwnChannel,
            channelId: widget.channelId,
            authorId: widget.authorId);
      case ChannelTab.saved:
        return SizedBox();
      case ChannelTab.statistics:
        return SizedBox();
    }
  }

  Widget _buildVisitingChannelPopUpMenu(
      {VoidCallback? onReport,
        // VoidCallback? onBlock,
        VoidCallback? onMute,
        VoidCallback? onOwnership}) {
    return PopupMenuButton<VisitingChannelMenuAction>(
      padding: EdgeInsets.zero,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: BoxConstraints(),
      onSelected: (VisitingChannelMenuAction value) {
        if (isGuestUser()) {
          createProfileScreen();
          return;
        }
        switch (value) {
          case VisitingChannelMenuAction.reportChannel:
            if (onReport != null) onReport();
            break;
        // case VisitingChannelMenuAction.blockUser:
        //   if (onBlock != null) onBlock();
        //   break;
          case VisitingChannelMenuAction.muteAccount:
            if (onMute != null) onMute();
            break;
          case VisitingChannelMenuAction.ownership:
            if (onOwnership != null) onOwnership();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: VisitingChannelMenuAction.reportChannel,
          child: Text("Report Channel",
              style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ),
        // PopupMenuItem(
        //   value: VisitingChannelMenuAction.blockUser,
        //   child: Text("Block User",
        //       style:
        //           TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        // ),
        PopupMenuItem(
          value: VisitingChannelMenuAction.muteAccount,
          child: Text("Mute Account",
              style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ),
        PopupMenuItem(
          value: VisitingChannelMenuAction.ownership,
          child: Text("Ownership",
              style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.more_vert,
          color: Colors.black,
          size: SizeConfig.size20,
        ),
      ),
    );
  }

  Widget _buildOwnChannelPopUpMenu({
    VoidCallback? onChannelEdit,
    VoidCallback? onchannelSetting,
    VoidCallback? onAddVideo,
    VoidCallback? onAddProduct,
  }) {
    return PopupMenuButton<OwnChannelMenuAction>(
      padding: EdgeInsets.zero,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: BoxConstraints(),
      onSelected: (OwnChannelMenuAction value) {
        switch (value) {
          case OwnChannelMenuAction.channelEdit:
            if (onChannelEdit != null) onChannelEdit();
            break;
          case OwnChannelMenuAction.chennelSetting:
            if (onchannelSetting != null) onchannelSetting();
            break;
          case OwnChannelMenuAction.addVideo:
            if (onAddVideo != null) onAddVideo();
            break;
          case OwnChannelMenuAction.addProduct:
            if (onAddProduct != null) onAddProduct();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: OwnChannelMenuAction.channelEdit,
          child: CustomText(
            "Channel Edit",
          ),
        ),
        PopupMenuItem(
          value: OwnChannelMenuAction.chennelSetting,
          child: CustomText(
            "Channel Settings",
          ),
        ),
        // PopupMenuItem(
        //   value: OwnChannelMenuAction.addShort,
        //   child: Text("Add Shorts",
        //       style:
        //       TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        // ),
        PopupMenuItem(
          value: OwnChannelMenuAction.addVideo,
          child: CustomText(
            "Add Video",
          ),
        ),
        PopupMenuItem(
          value: OwnChannelMenuAction.addProduct,
          child: CustomText(
            "Add Product",
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.more_vert,
          color: Colors.black,
          size: SizeConfig.size20,
        ),
      ),
    );
  }

  String _getIconForPlatform(String platform) {
    switch (platform) {
      case 'youtube':
        return AppImageAssets.ytIcon;
      case 'x':
      case 'twitter':
        return AppImageAssets.xIcon;
      case 'linkedin':
        return AppImageAssets.linkedInIcon;
      case 'instagram':
        return AppImageAssets.instagramIcon;
      case 'web':
      case 'website':
      default:
        return AppImageAssets.webIcon;
    }
  }

  void showReportDialog({
    required BuildContext context,
    required Function(String reason) onConfirm,
  }) {
    final TextEditingController reasonController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Title
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding:
                        EdgeInsets.symmetric(vertical: SizeConfig.size10),
                        child: CustomText(
                          "Report Content",
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: SizeConfig.size20),

                      /// Input Field
                      CommonTextField(
                        textEditController: reasonController,
                        maxLine: 4,
                        hintText: "Write your reason...",
                        maxLength: 150,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Reason is required';
                          } else if (value.length < 10) {
                            return 'length must be at least 10 characters long';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),

                      /// Confirm Button
                      SizedBox(
                        width: double.infinity,
                        child: CustomBtn(
                          title: "Confirm",
                          isValidate: true,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              final reason = reasonController.text.trim();
                              Navigator.pop(context);
                              onConfirm(reason);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Future<void> showBlockUnBlockDialog() async {
  //   await showCommonDialog(
  //   context: context,
  //   text: channelController.isBlockChannel ? "Are you sure want to block this channel?" : "Are you sure want to unblock this channel?",
  //   confirmCallback: () {
  //    channelController.blockUnblockChannel(channelId: channelId);
  //   },
  //   cancelCallback: () {
  //     Navigator.of(context).pop(); // Close the dialog
  //   },
  //   confirmText: 'Confirm',
  //   cancelText: 'Cancel'
  //   );
  // }

  Future<void> showMuteUnMuteDialog() async {
    await showCommonDialog(
        context: context,
        text: channelController.isMuteChannel
            ? "Are you sure want to mute this channel?"
            : "Are you sure want to unmute this channel?",
        confirmCallback: () {
          channelController.muteUnMuteChannel(channelId: channelId);
        },
        cancelCallback: () {
          Navigator.of(context).pop(); // Close the dialog
        },
        confirmText: 'Confirm',
        cancelText: 'Cancel');
  }

  void navigateToProfileSection() {
    String accountType = widget.accountType;
    String authorId = widget.authorId;
    if (accountType.toUpperCase() == AppConstants.individual.toUpperCase()) {
      if (authorId == userId) {
        Get.to(() => PersonalProfileSetupScreen());
      } else {
        Get.to(() => VisitProfileScreen(authorId: authorId));
      }
    } else {
      if (authorId == userId) {
        Get.to(() => BusinessOwnProfileScreen());
      } else {
        Get.to(() => VisitBusinessProfileNew(businessId: authorId));
      }
    }
  }
}
