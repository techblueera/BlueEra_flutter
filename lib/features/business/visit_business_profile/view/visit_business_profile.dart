import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../common/reel/view/sections/shorts_channel_section.dart';
import '../../../personal/personal_profile/view/visit_personal_profile/visit_personal_profile.dart';
import '../../auth/controller/view_business_details_controller.dart';
import '../../widgets/abourt_business_widget.dart';
import '../../widgets/header_widget.dart';
import '../../widgets/profile_info_widget.dart';
import '../../widgets/rating_widget.dart';

class VisitBusinessProfile extends StatefulWidget {
  final String businessId;
  const VisitBusinessProfile({super.key,required this.businessId});


  @override
  State<VisitBusinessProfile> createState() => VisitBusinessProfileState();
}

class VisitBusinessProfileState extends State<VisitBusinessProfile> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(ViewBusinessDetailsController());
  // final ScrollController _scrollController = ScrollController();
  final List<String> tabs = [
    'Profile',
    'Shorts',
    'Videos'
    'Posts',
    // 'Reviews',
    // 'Our Branches'
  ];
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;

  @override
  void initState() {
    super.initState();
    setFilters();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Ensure your VisitPersonalProfileTabs updates
    });

    controller.viewBusinessProfileById(widget.businessId);
    controller.getAllProductsApi({ApiKeys.limit: 0});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  setFilters() {
    SortBy.values.where((e) => e != SortBy.UnderProgress).toList();
  }

  @override
  Widget build(BuildContext context) {
    //   if(isOwnChannel){
    //         response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
    //       }else {
    //         response = await ChannelRepo().getAllChannelVideos(channelOrUserId: channelOrUserId, queryParams: params);
    //       }
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: GetBuilder<ViewBusinessDetailsController>(
        builder: (controller) {
          if (controller.viewBusinessResponse.status == Status.LOADING) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.viewBusinessResponse.status == Status.ERROR) {
            return  Center(child: CustomText("No business found"));
          }
          final businessData = controller.visitedBusinessProfileDetails?.data;
          return DefaultTabController(
            length: tabs.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18.0,left: 18,right: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeaderWidget(
                          businessId: widget.businessId,
                          userId: businessData?.userId??"",
                          businessName: businessData?.businessName ?? "Business Name",
                          logoUrl: businessData?.logo ?? "",
                          businessType: businessData?.typeOfBusiness ?? "Business",
                          location: "${businessData?.address ?? ''}",
                        ),
                        const SizedBox(height: 30),
                        ProfileInfoWidget(),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CustomTabBarDelegate(
                    VisitPersonalProfileTabs(onTab: (index){
                      if(index==3){
                        Map<String,dynamic> data={
                          ApiKeys.businessId : widget.businessId
                        };
                        controller.getParticularRatingApi(data);
                      }
                    },
                      tabs: tabs,
                      tabController: _tabController,
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Profile tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingReviewCard(
                          businessId: widget.businessId,
                          businessProfile: businessData,
                        ),
                        const SizedBox(height: 30),
                        AboutBusinessWidget(
                          businessDescription: businessData?.businessDescription ?? "No description available",
                          livePhotos: businessData?.livePhotos ?? [],
                        ),
                        const SizedBox(height: 30),
                        BusinessLocationWidget(
                          latitude: businessData?.businessLocation?.lat?.toDouble() ?? 0.0,
                          longitude: businessData?.businessLocation?.lon?.toDouble() ?? 0.0,
                          businessName: businessData?.businessName ?? "N/A",
                          isTitleShow: true,
                        ),
                        const SizedBox(height: 24),
                     /*   ProductServicesWidget(),
                        const SizedBox(height: 20),
                        SimilarStoreWidget(),
                        const SizedBox(height: 30),*/
                      ],
                    ),
                  ),

                  // Shorts tab
                  Column(
                    children: [
                      _filterButtons(),

                      SizedBox(height: SizeConfig.size8),

                      ShortsChannelSection(
                        // scrollController: _scrollController,
                        isOwnShorts: false,
                        showShortsInGrid: true,
                        channelId: '',
                        sortBy: selectedFilter,
                        authorId: widget.businessId,
                        postVia: PostVia.profile,
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      _filterButtons(),

                      SizedBox(height: SizeConfig.size8),

                      VideoChannelSection(
                        isOwnVideos: false,
                        channelId: '',
                        authorId: widget.businessId,
                        isScroll: false,
                        sortBy: selectedFilter,
                        postVia: PostVia.profile,
                      ),
                    ],
                  ),

                  FeedScreen(
                    key: const ValueKey('feedScreen_others_posts'),
                    postFilterType: PostType.otherPosts,
                    id: businessData?.userId,
                  ),

                  // Reviews tab
                  // const Center(child: Text("No reviews yet")),
                  //
                  // // Our Branches tab
                  // const Center(child: Text("No branches yet")),
                ],
              ),
            ),
          );
        },
      ),
    );
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
                children: filters?.map((filter) {
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
                        filter.label,
                        decoration: TextDecoration.underline,
                        color: isSelected ? Colors.blue : Colors.black54,
                        decorationColor:
                        isSelected ? Colors.blue : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList()??[],
              ),
            )
          ],
        ));
  }

}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final VisitPersonalProfileTabs tabBar;

  _CustomTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 50;

  @override
  double get maxExtent => 50;

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
