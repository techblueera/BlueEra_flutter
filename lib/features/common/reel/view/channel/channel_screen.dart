import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_joined_user_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/controller/channel_controller.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/view/channel/channel_products_listing.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/common/service/view/business_service_list.dart';
import 'package:BlueEra/features/personal/personal_profile/view/personal_profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/widget/new_profile_header_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/highlight_text_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../business/visit_business_profile/view/visit_business_profile_new.dart';

class ChannelScreen extends StatefulWidget {
  final String accountType;
  final String channelId;
  final String authorId;

  const ChannelScreen({
    super.key,
    required this.accountType,
    required this.channelId,
    required this.authorId,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen>
    with SingleTickerProviderStateMixin {
  ChannelController channelController = Get.put(ChannelController());
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  late List<ChannelTab> _tabsList;

  bool isOwnChannel = false;
  List<SortBy>? filters;
  final controller = Get.put(VisitProfileController());

  @override
  void initState() {
    super.initState();
    isOwnChannel = widget.channelId == channelId;

    // Set tabs based on channel ownership
    if (!isOwnChannel) {
      _tabsList = [
        ChannelTab.posts,
        ChannelTab.product,
      ];
    } else {
      _tabsList = ChannelTab.values;
    }

    _tabController = TabController(length: _tabsList.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    updateFilters();
    _fetchInitialChannelData();
    _setupScrollListener();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      updateFilters();
    });
  }

  void updateFilters() {
    final currentTab = _tabsList[_tabController.index];

    if (currentTab == ChannelTab.posts) {
      filters = SortBy.values.where((e) => e != SortBy.UnderProgress).toList();
    } else {
      filters = null;
    }
  }

  void _fetchInitialChannelData() async {
    try {
      channelController.isInitialLoading.value = true;

      await Future.wait([
        channelController.getChannelDetails(
            channelOrUserId: isOwnChannel ? widget.authorId : widget.channelId),
        channelController.getChannelStats(channelId: widget.channelId),
      ]);
    } catch (e) {
      debugPrint('Error loading channel data: $e');
    } finally {
      channelController.isInitialLoading.value = false;
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

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
      // Trigger pagination based on current tab
      switch (_tabController.index) {
        case 0:
        // Trigger pagination for FeedScreen
          final feedController = Get.find<FeedController>();
          final postType = _getPostType();
          if (feedController.isTargetHasMoreData.isTrue &&
              feedController.isLoading.isFalse) {
            feedController.getPostsByType(
              postType,
              isInitialLoad: false,
              id: widget.authorId,
              screenName: '',
            );
          }
          break;
        default:
          break;
      }
    }
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
    _tabController.dispose();
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
      body: Obx(() {
        if (channelController.isInitialLoading.isTrue) {
          return Center(child: CircularProgressIndicator());
        }

        return DefaultTabController(
          length: _tabsList.length,
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) =>
            [
              SliverToBoxAdapter(
                child: Obx(() {
                  return _buildHeaderSection();
                }),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CustomTabBarDelegate(
                  _buildTabButtons(),
                  hasFilters: filters != null,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: _tabsList.map((tab) => _buildTabContent(tab)).toList(),
            ),
          ),
        );
      }),
    );
  }

  void _showFullTextDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (_) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery
                    .of(context)
                    .size
                    .height * 0.7,
                maxWidth: MediaQuery
                    .of(context)
                    .size
                    .width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: HighlightText(
                          text: text,
                          style: TextStyle(
                            color: AppColors.mainTextColor,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppConstants.OpenSans,
                          )),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: Navigator
                          .of(context)
                          .pop,
                      child: const CustomText(AppStrings.close,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeaderSection() {
    ChannelData? channelData = channelController.channelData.value;
    String channelLogo = channelData?.logoUrl ?? "";
    controller.isFollow.value = channelData?.isFollowing ?? false;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            /// ==== Banner ====
            Container(
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8DD0F7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      image: ((channelLogo.isNotEmpty))
                          ? DecorationImage(
                        image: NetworkImage(channelLogo),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                  ),

                  /// ==== Profile Image ====
                  Positioned(
                    left: 20,
                    top: 90,
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.white,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: (channelLogo.isNotEmpty)
                            ? NetworkImage(channelLogo)
                            : null,
                        backgroundColor: AppColors.primaryColor,
                        child: (channelLogo.isEmpty)
                            ? CustomText(
                          getInitials(channelData?.name),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.size20,
                        )
                            : null,
                      ),
                    ),
                  ),

                  /// ==== Follow Button + Menu ====
                  Positioned(
                    right: 14,
                    top: 140,
                    child: Row(
                      children: [
                        if (!isOwnChannel)
                          Obx(() {
                            return GestureDetector(
                              onTap: () async {
                                if (isGuestUser()) {
                                  createProfileScreen();
                                } else {
                                  if (controller.isFollow.value) {
                                    await controller
                                        .unChannelFollowUserController(
                                        candidateResumeId: channelData?.id);
                                  } else {
                                    await controller
                                        .followChannelUserController(
                                        candidateResumeId: channelData?.id);
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 4),
                                decoration: BoxDecoration(
                                  color: controller.isFollow.value
                                      ? AppColors.colorTextDarkGrey
                                      : AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    CustomText(
                                      controller.isFollow.value
                                          ? AppStrings.unjoin
                                          : AppStrings.join,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: SizeConfig.size10,
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.person_add_alt,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  ],
                                ),
                              ),
                            );
                          }),
                        (!isOwnChannel)
                            ? _buildVisitingChannelPopUpMenu(onReport: () {
                          showReportDialog(
                              context: context,
                              onConfirm: (value) {
                                channelController.reportChannel(
                                    channelId: channelId, reason: value);
                              });
                        }, onMute: () {
                          showMuteUnMuteDialog();
                        }, onOwnership: () {
                          navigateToProfileSection();
                        })
                            : _buildOwnChannelPopUpMenu(
                          onChannelEdit: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              RouteHelper.getManageChannelScreenRoute(),
                              arguments: {
                                ApiKeys.channelData:
                                channelController.channelData.value,
                              },
                            );
                            if (result == true) {
                              channelController.getChannelDetails(
                                  channelOrUserId: isOwnChannel
                                      ? widget.authorId
                                      : widget.channelId);
                            }
                          },
                          // onchannelSetting: () {
                          //   Get.to(() => ChannelSettingScreen());
                          // },
                          onAddVideo: () {
                            showVideosPickerDialog(context,
                                type: PostVia.channel);
                          },
                          onAddProduct: () {
                            Get.toNamed(
                                RouteHelper
                                    .getAddUpdateProductScreenRoute(),
                                arguments: {
                                  ApiKeys.channelId: widget.channelId,
                                });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // const SizedBox(height: 45),

            /// ==== Name + Username ====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    channelData?.name ?? '',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (channelData?.username != null &&
                          (channelData?.username.isNotEmpty ?? false))
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size10,
                              vertical: SizeConfig.size4),
                          decoration: BoxDecoration(
                            border:
                            Border.all(color: AppColors.secondaryTextColor),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: CustomText(
                            "@${channelData?.username}",
                            fontSize: SizeConfig.extraSmall,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// ==== Stats Row ====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  statBlock(
                      AppStrings.post,
                      channelController.channelStats.value?.posts.toString() ??
                          "0"),
                  const SizedBox(width: 20),

                  //  _divider(),
                  InkWell(
                    onTap: () {
                      Get.to(() =>
                          ChannelJoinedUserScreen(
                              userID: channelData?.id ?? ""));
                    },
                    child: statBlock(
                        AppStrings.members,
                        channelController.channelStats.value?.followers
                            .toString() ??
                            "0"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /// ==== Bio ====
            if ((channelData?.bio ?? '')
                .trim()
                .isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: channelData?.bio != null &&
                          (channelData?.bio.isNotEmpty ?? false)
                          ? (channelData?.bio ?? "")
                          : AppStrings.noBioAvailable.tr,
                      style: TextStyle(
                        fontSize: SizeConfig.size14,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    TextSpan(
                      text: '   ${AppStrings.read_more.tr}',
                      style: TextStyle(
                        fontSize: SizeConfig.size12,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _showFullTextDialog(context, channelData?.bio ?? '');
                        },
                    ),
                  ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 10),
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
          height: SizeConfig.size34,
          child: ListView.builder(
            itemCount: _tabsList.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final isSelected = _tabController.index == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(index);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    foregroundColor: isSelected ? Colors.white : Colors.black54,
                    backgroundColor:
                    isSelected ? AppColors.primaryColor : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.size10),
                      side: BorderSide(
                          color:
                          isSelected ? Colors.blue.shade100 : Colors.grey),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size2),
                    minimumSize: Size(SizeConfig.size80, SizeConfig.size34),
                    maximumSize: Size(SizeConfig.size90, SizeConfig.size34),
                  ),
                  child: Text('${_tabsList[index]
                      .getTitle(context)
                      .tr}'),
                ),
              );
            },
          ),
        ),
        if (filters != null) ...[
          SizedBox(height: SizeConfig.size20),
          _filterButtons(),
        ]
      ],
    );
  }

  Widget _filterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
          SizedBox(width: SizeConfig.size10),
          ...filters!.map((filter) {
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
                  filter.label.tr,
                  decoration: TextDecoration.underline,
                  color: isSelected ? AppColors.primaryColor : Colors.black54,
                  decorationColor:
                  isSelected ? AppColors.primaryColor : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          SizedBox(width: SizeConfig.size20),
        ],
      ),
    );
  }

  Widget _buildTabContent(ChannelTab tab) {
    switch (tab) {
      case ChannelTab.posts:
        return FeedScreen(
          key: ValueKey(
              isOwnChannel ? 'own_channel_posts' : 'visiting_channel_posts'),
          id: widget.authorId,
          horizontalPaddingChannel: 20,
          postFilterType: PostType.latest,
          // postFilterType: _getPostType(),
          channelName: channelController.channelData.value?.name,
          isInParentScroll: true,
        );
      case ChannelTab.saved:
        return Center(child: CustomText('coming soon..'));
      case ChannelTab.statistics:
        return Center(child: CustomText('coming soon..'));
      case ChannelTab.product:
        return ChannelProductListing(
          channelController: channelController,
        );
      case ChannelTab.Service:
        return BusinessServiceList(
          channelId: channelId,
          providerType: ProviderType.channel,
        );
    // return ProductScreen();
    }
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

  Widget _buildVisitingChannelPopUpMenu({VoidCallback? onReport,
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
          case VisitingChannelMenuAction.muteAccount:
            if (onMute != null) onMute();
            break;
          case VisitingChannelMenuAction.ownership:
            if (onOwnership != null) onOwnership();
            break;
        }
      },
      itemBuilder: (context) =>
      [
        PopupMenuItem(
          value: VisitingChannelMenuAction.reportChannel,
          child:
          CustomText(AppStrings.reportChannel, fontWeight: FontWeight.w600),
        ),
        PopupMenuItem(
          value: VisitingChannelMenuAction.muteAccount,
          child:
          CustomText(AppStrings.muteAccount, fontWeight: FontWeight.w600),
        ),
        PopupMenuItem(
          value: VisitingChannelMenuAction.ownership,
          child: CustomText(AppStrings.ownership, fontWeight: FontWeight.w600),
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
    VoidCallback? onChannelSetting,
    VoidCallback? onAddVideo,
    VoidCallback? onAddProduct,
    VoidCallback? onAddService,
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
          case OwnChannelMenuAction.channelSetting:
            if (onChannelSetting != null) onChannelSetting();
            break;
          case OwnChannelMenuAction.addProduct:
            if (onAddProduct != null) onAddProduct();
            break;
          case OwnChannelMenuAction.addService:
            if (onAddService != null) onAddService();
            break;
        }
      },
      itemBuilder: (context) =>
      [
        PopupMenuItem(
          value: OwnChannelMenuAction.channelEdit,
          child: CustomText(AppStrings.channelEdit),
        ),
        PopupMenuItem(
          value: OwnChannelMenuAction.channelSetting,
          child: CustomText(AppStrings.channelSettings),
        ),
        PopupMenuItem(
          value: OwnChannelMenuAction.addProduct,
          child: CustomText(AppStrings.addProduct),
        ),
        PopupMenuItem(
          value: OwnChannelMenuAction.addService,
          child: CustomText(AppStrings.addService),
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
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding:
                        EdgeInsets.symmetric(vertical: SizeConfig.size10),
                        child: CustomText(
                          AppStrings.reportChannel,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: SizeConfig.size20),
                      CommonTextField(
                        textEditController: reasonController,
                        maxLine: 4,
                        hintText: AppStrings.writeYourReason,
                        maxLength: 150,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.reasonRequired.tr;
                          } else if (value.length < 10) {
                            return AppStrings.reasonTooShort.tr;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),
                      SizedBox(
                        width: double.infinity,
                        child: CustomBtn(
                          title: AppStrings.confirm,
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

  Future<void> showMuteUnMuteDialog() async {
    await showCommonDialog(
        context: context,
        text: channelController.isMuteChannel
            ? AppStrings.confirmMuteChannel
            : AppStrings.confirmUnmuteChannel,
        confirmCallback: () {
          channelController.muteUnMuteChannel(channelId: channelId);
        },
        cancelCallback: () {
          Navigator.of(context).pop();
        },
        confirmText: AppStrings.confirm,
        cancelText: AppStrings.cancel);
  }

  void navigateToProfileSection() {
    String accountType = widget.accountType;
    String authorId = widget.authorId;
    if (accountType.toUpperCase() == AppConstants.individual.toUpperCase()) {
      if (authorId == userId) {
        Get.to(() => PersonalProfileSetupNewScreen());
      } else {
        Get.to(() =>
            NewVisitProfileScreen(
              authorId: authorId,
              screenFromName: AppConstants.feedScreen,
            ));
      }
    } else {
      if (authorId == userId) {
        Get.to(() => BusinessOwnProfileScreen());
      } else {
        Get.to(() =>
            VisitBusinessProfileNew(
              businessId: authorId,
              screenName: AppConstants.feedScreen,
            ));
      }
    }
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
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) {
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
