import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/controller/channel_controller.dart';
import 'package:BlueEra/features/common/reel/view/sections/common_draft_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/common/reelsModule/font_style.dart';
import 'package:BlueEra/features/common/store/channel_product_screen/channel_product_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
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
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';

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
    print('channel ');
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
                shorts, widget.channelId, widget.authorId, isOwnChannel,
                postVia: PostVia.channel);
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
              isOwnChannel,
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
                    Container(
                      height: SizeConfig.size60,
                      width: SizeConfig.size60,
                      margin: EdgeInsets.all(SizeConfig.size10),
                      padding: EdgeInsets.all(SizeConfig.size3),
                      decoration: BoxDecoration(
                          color: AppColors.skyBlueDF,
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(channelController.channelLogo.value),
                          )),
                    ),
                    CustomBtn(
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
                      title: channelController.isChannelFollow.isTrue ? "Follow" : "UnFollow",
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
                                      (channelController.channelData.value?.name ?? "").capitalizeFirst,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: SizeConfig.size18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(
                                    width: SizeConfig.size2,
                                  ),
                                  channelController.channelData.value?.verification.isVerified?? false
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
                                    final link =
                                    profileDeepLink(userId: widget.authorId);
                                    final message =
                                        "See my profile on BlueEra:\n$link\n";
                                    await SharePlus.instance.share(ShareParams(
                                      text: message,
                                      subject: channelController.channelData.value?.name ?? "",
                                    ));
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
                          // showDialog(
                          //   context: context,
                          //   builder: (context) {
                          //     return buildProfilePopup(
                          //         contact: channelController.channelData.value.,
                          //         dob:
                          //         "${user?.dateOfBirth?.month ?? ""},${user?.dateOfBirth?.date ?? ""}",
                          //         email: user?.email ?? "",
                          //         location:
                          //         "${user?.userLocation?.lat ?? ""},${user?.userLocation?.lon ?? ""}",
                          //         channel: user?.accountType ?? "",
                          //         designation: user?.designation ?? "",
                          //         name: user?.name ?? "");
                          //   },
                          // );
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
                              "${getMonthName(channelController.channelData.value?.createdAt.month??0)},${channelController.channelData.value?.createdAt.year}",
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
                          Expanded(
                            child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                    text:
                                    channelController.channelStats.value?.following.toString() ?? "0",
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
                                    channelController.channelStats.value?.followers.toString() ?? "0",
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
              channelController.channelData.value?.bio ?? "",
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
        return ShortsChannelSection(
          isOwnShorts: isOwnChannel,
          sortBy: channelController.selectedFilter,
          showShortsInGrid: true,
          channelId: widget.channelId,
          authorId: widget.authorId,
          postVia: PostVia.channel,
        );
      case ChannelTab.videos:
        return VideoChannelSection(
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
        Get.to(() => VisitBusinessProfile(businessId: authorId));
      }
    }
  }
}
