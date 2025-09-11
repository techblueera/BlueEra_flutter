import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/model/getAllProductDetailsModel.dart';
import 'package:BlueEra/features/business/auth/model/getCountOfRatingModel.dart';
import 'package:BlueEra/features/business/auth/model/rating_feedback_model.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/auth/model/get_all_jobs_model.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/feed_shimmer_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/common/reelsModule/font_style.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:geolocator/geolocator.dart';
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
import 'package:BlueEra/features/common/jobs/controller/job_screen_controller.dart';

class VisitBusinessProfile extends StatefulWidget {
  final String businessId;

  const VisitBusinessProfile({super.key, required this.businessId});

  @override
  State<VisitBusinessProfile> createState() => VisitBusinessProfileState();
}

class VisitBusinessProfileState extends State<VisitBusinessProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  final controller = Get.put(ViewBusinessDetailsController());
  late VisitProfileController visitProfileController;
  final ScrollController _scrollController = ScrollController();
  final JobScreenController jobScreenController =
      Get.put(JobScreenController());
  double? _distanceInKm;
  final List<String> tabs = [
    'Overview',
    // 'Products',
    'Reviews',
    'Posts',
    'Jobs',
  ];
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;
  RxList<Jobs> jobsList = <Jobs>[].obs;
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  // @override
  // void initState() {
  //   super.initState();
  //   setFilters();
  //   _tabController = TabController(length: tabs.length, vsync: this);
  //   _tabController.addListener(() {
  //     setState(() {}); // Ensure your VisitPersonalProfileTabs updates
  //   });
  //   visitProfileController = Get.put(VisitProfileController());
  //   controller.viewBusinessProfileById(widget.businessId);
  //   controller.getAllProductsApi({ApiKeys.limit: 0});
  //   controller.getBusinessStats(widget.businessId);

  // }

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    setFilters();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      }); // Ensure your VisitPersonalProfileTabs updates
    });

    visitProfileController = Get.put(VisitProfileController());

    _initializeData().then((_) {
      _getCurrentLocation();
      setState(() => _isLoading = false);
    });
  }

  // Future<void> _initializeData() async {
  //   try{
  //     await Future.wait([
  //     controller.viewBusinessProfileById(widget.businessId),
  //     controller.getAllProductsApi({ApiKeys.limit: 0}),
  //     controller.getBusinessStats(widget.businessId),
  //   ]);
  //   final userId = controller.visitedBusinessProfileDetails?.data?.userId ?? "";
  //   // Now we can safely access the business details
  //   await jobScreenController.getVisitedBusineesAllJobsRepo(userId);
  //   controller.getAllPostApi(userId);
  //   jobsList.value = jobScreenController.jobsData ?? [];
  //   controller.businessRatingsSummary(widget.businessId);
  //   controller.getCountOfRatingApiRepo(widget.businessId);
  //   }catch(e){
  //     logs("_initializeData error $e");
  //   }
  // }

  Future<void> _initializeData() async {
    try {
      logs("_initializeData started...");

      // Wrap each with timeout so you can detect hangs
      await controller
          .viewBusinessProfileById(widget.businessId)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("viewBusinessProfileById timed out");
      });
      logs("✅ viewBusinessProfileById finished");

      await controller.getAllProductsApi({ApiKeys.limit: 0}).timeout(
          const Duration(seconds: 15), onTimeout: () {
        throw Exception("getAllProductsApi timed out");
      });
      logs("✅ getAllProductsApi finished");

      await controller
          .getBusinessStats(widget.businessId)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("getBusinessStats timed out");
      });
      logs("✅ getBusinessStats finished");

      final userId =
          controller.visitedBusinessProfileDetails?.data?.userId ?? "";
      logs("userId resolved: $userId");

      if (userId.isNotEmpty) {
        await jobScreenController
            .getVisitedBusineesAllJobsRepo(userId)
            .timeout(const Duration(seconds: 15), onTimeout: () {
          throw Exception("getVisitedBusineesAllJobsRepo timed out");
        });
        logs("✅ getVisitedBusineesAllJobsRepo finished");

        // If these return Futures, await them
        await controller.getAllPostApi(userId);
        logs("✅ getAllPostApi finished");
      } else {
        logs("⚠️ userId is empty, skipping job/post APIs");
      }

      jobsList.value = jobScreenController.jobsData ?? [];

      await controller
          .businessRatingsSummary(widget.businessId)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("businessRatingsSummary timed out");
      });
      logs("✅ businessRatingsSummary finished");

      await controller
          .getCountOfRatingApiRepo(widget.businessId)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("getCountOfRatingApiRepo timed out");
      
      });
      logs("✅ getCountOfRatingApiRepo finished");
      await  controller.getAllBusinessRatingsApi(widget.businessId)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("getAllBusinessRatingsApi timed out");
      
      });
      logs("✅ getAllBusinessRatingsApi finished");
      
      

      logs("_initializeData completed ✅");
    } catch (e, s) {
      logs("_initializeData error $e\n$s");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }
// calculating distance from the visited business profile
      Position position = await Geolocator.getCurrentPosition();
      final businessProfile = controller.businessProfileDetails;
      if (businessProfile?.data?.businessLocation != null) {
        final businessLocation = businessProfile!.data!.businessLocation!;
        double distanceInMeters = await Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          businessLocation.lat!.toDouble(),
          businessLocation.lon!.toDouble(),
        );
        setState(() {
          _distanceInKm =
              double.parse((distanceInMeters / 1000).toStringAsFixed(1));
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
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

    if (_isLoading) {
      return const Scaffold(
        body: FeedShimmerCard(),
      );
    }
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: GetBuilder<ViewBusinessDetailsController>(
        init: controller,
        builder: (controller) {
          if (controller.viewBusinessResponse.status == Status.LOADING) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.viewBusinessResponse.status == Status.ERROR) {
            return Center(child: CustomText("No business found"));
          }
          final businessData = controller.visitedBusinessProfileDetails?.data;
          return DefaultTabController(
            length: tabs.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 18.0, left: 12, right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget_profileHeader(businessData),
                        // HeaderWidget(
                        //   businessId: widget.businessId,
                        //   userId: businessData?.userId ?? "",
                        //   businessName:
                        //       businessData?.businessName ?? "Business Name",
                        //   logoUrl: businessData?.logo ?? "",
                        //   // businessType: businessData?.typeOfBusiness ?? "Business",
                        //   businessType: (businessData?.subCategoryDetails !=
                        //               null &&
                        //           businessData?.subCategoryDetails?.name !=
                        //               null)
                        //       ? businessData?.subCategoryDetails?.name ?? ''
                        //       : (businessData?.categoryDetails != null &&
                        //               businessData?.categoryDetails?.name !=
                        //                   null)
                        //           ? businessData?.categoryDetails?.name ?? ''
                        //           : (businessData?.natureOfBusiness ??
                        //               'OTHERS'),
                        //   location: "${businessData?.address ?? ''}",
                        // ),
                        // const SizedBox(height: 30),
                        // ProfileInfoWidget(),
                        // const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CustomTabBarDelegate(
                    VisitPersonalProfileTabs(
                      onTab: (index) async {
                        // Let the tab change happen first
                        _tabController.animateTo(index);

                        // Then make the API call if needed
                        if (index == 1) {
                          // Wrap in Future.microtask to let the UI update first
                          Future.microtask(() {
                            // controller
                            //     .getAllBusinessRatingsApi(widget.businessId);
                          });
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
                  // overview tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildRatingSummary(
                            rating: controller
                                .ratingSummaryResponse.value.data.avgRating,
                            totalReviews: controller
                                .ratingSummaryResponse.value.data.totalRatings
                                .toString()),
                        // RatingReviewCard(
                        //   businessId: widget.businessId,
                        //   businessProfile: businessData,
                        // ),
                        const SizedBox(height: 12),
                        BusinessLocationWidget(
                          latitude:
                              businessData?.businessLocation?.lat?.toDouble() ??
                                  0.0,
                          longitude:
                              businessData?.businessLocation?.lon?.toDouble() ??
                                  0.0,
                          businessName: businessData?.businessName ?? "N/A",
                          isTitleShow: true,
                          locationText: businessData?.address ?? "",
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        buildHorizontalProductList(
                            products: controller.getAllProductDetails?.value),
                        const SizedBox(height: 12),
                        buildReviewCard(),
                        const SizedBox(height: 12),
                        Obx(() {
                          return jobsList.isNotEmpty
                              ? JobTabCard(job: jobsList.first)
                              : const SizedBox();
                        }),
                        const SizedBox(height: 12),
                        buildPostCard(controller: controller),
                        const SizedBox(height: 12),
                        buildHorizontalSortsList(), const SizedBox(height: 12),
                        customVideoCard(),

                        /* const SizedBox(height: 30),
                       AboutBusinessWidget(
                          businessDescription:
                              businessData?.businessDescription ??
                                  "No description available",
                          livePhotos: businessData?.livePhotos ?? [],
                        ),
                        const SizedBox(height: 30),

                        const SizedBox(height: 24),
                        */ /*   ProductServicesWidget(),
                        const SizedBox(height: 20),
                        SimilarStoreWidget(),
                        const SizedBox(height: 30),*/
                      ],
                    ),
                  ),

                  // productTab(products: controller.getAllProductDetails?.value),

                  reviewTab(),

                  postsTab(data: businessData),
                  jobsTab(),

                  /*// Shorts tab
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
                  ),*/

                  /*FeedScreen(
                    key: const ValueKey('feedScreen_others_posts'),
                    postFilterType: PostType.otherPosts,
                    id: businessData?.userId,
                  ),*/

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

  widget_profileHeader(BusinessProfileDetails? businessData) {
    final businessStatsData = controller.businessStatsData;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        // margin: EdgeInsets.all(SizeConfig.size10),
                        padding: EdgeInsets.all(SizeConfig.size3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              image: NetworkImage(businessData?.logo ?? "")),
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size8,
                      ),
                      CustomBtn(
                        onTap: () {
                          if (!(businessData?.is_following ?? false)) {
                            visitProfileController
                                .followUserController(
                                    candidateResumeId: businessData?.userId)
                                .then(
                                  (value) => controller.viewBusinessProfileById(
                                      businessData?.id ?? ""),
                                );
                          } else {
                            visitProfileController
                                .unFollowUserController(
                                    candidateResumeId: businessData?.userId)
                                .then(
                                  (value) => controller.viewBusinessProfileById(
                                      businessData?.id ?? ""),
                                );
                          }
                        },
                        title: businessData?.is_following == true
                            ? "Unfollow"
                            : "Follow",
                        fontWeight: FontWeight.bold,
                        height: SizeConfig.size30,
                        bgColor: AppColors.skyBlueDF,
                        width: SizeConfig.size60,
                        radius: SizeConfig.size12,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: SizeConfig.size16,
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              businessData?.businessName ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: SizeConfig.size18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            width: SizeConfig.size16,
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size6),
                      Row(
                        children: [
                          _buildTag((businessData?.subCategoryDetails != null &&
                                  businessData?.subCategoryDetails?.name !=
                                      null)
                              ? businessData?.subCategoryDetails?.name ?? ''
                              : (businessData?.categoryDetails != null &&
                                      businessData?.categoryDetails?.name !=
                                          null)
                                  ? businessData?.categoryDetails?.name ?? ''
                                  : (businessData?.natureOfBusiness ??
                                      'OTHERS')),
                          SizedBox(width: SizeConfig.size6),
                          // _buildTag("Closed",
                          //     borderColor: AppColors.red,
                          //     textColor: AppColors.red),
                          // SizedBox(width: SizeConfig.size6),
                          // _buildTag("14.2 KM Far"),
                        ],
                      ),
                      SizedBox(
                        height: SizeConfig.size16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: SizeConfig.size24,
                                    color: AppColors.black),
                                SizedBox(width: SizeConfig.size6),
                                CustomText(
                                  _distanceInKm != null
                                      ? "${_distanceInKm} KM Far"
                                      : "14.2KM Far",
                                  maxLines: 2,
                                  color: AppColors.skyBlueDF,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.skyBlueDF,
                                ),
                                // SizedBox(width: SizeConfig.size1),
                                // Expanded(
                                //   child: CustomText(
                                //     businessData?.address ?? "",
                                //     maxLines: 2,
                                //     overflow: TextOverflow.ellipsis,
                                //     color: AppColors.black,
                                //   ),
                                // )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: businessData?.isActive ?? false
                                    ? AppColors.green39
                                    : AppColors.red)),
                        child: CustomText(
                          fontSize: 14,
                          businessData?.isActive ?? false ? "Open" : "Closed",
                          color: businessData?.isActive ?? false
                              ? AppColors.green39
                              : AppColors.red,
                        ),
                      ),
                      // SizedBox(
                      //   width: SizeConfig.size4,
                      // ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        offset: const Offset(-6, 36),
                        color: AppColors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        onSelected: (value) =>
                            controller.handleWidgetProfileHeaderOption(value,
                                controller.visitedBusinessProfileDetails?.data),
                        onCanceled: () {
                          // WidgetsBinding.instance.addPostFrameCallback((_) {
                          //   _searchFocusNode.unfocus();
                          // });
                        },
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.grey9B,
                          size: 20,
                        ),
                        itemBuilder: (context) =>
                            popupvisitBusinessProfileMenuItems(), // still reused
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            ReadMoreText(
              businessData?.businessDescription ?? "",
              trimMode: TrimMode.Line,
              trimLines: 2,
              colorClickableText: AppColors.primaryColor,
              trimCollapsedText: ' Show more',
              trimExpandedText: ' Show less',
              moreStyle: AppFontStyle.styleW500(
                  AppColors.primaryColor, SizeConfig.size14),
            ),
            SizedBox(height: SizeConfig.size12),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size12, horizontal: SizeConfig.size12),
              decoration: BoxDecoration(
                // color: AppColors.lightBlue,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(SizeConfig.size12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfo("Rating",
                          "★ ${double.parse(businessStatsData?.avgRating ?? '0').floor().toString()}"),
                      SizedBox(
                        height: SizeConfig.size6,
                      ),
                      _buildInfo("Views",
                          "${businessStatsData?.totalUniqueViews ?? 0}"),
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size40,
                    child: VerticalDivider(
                      color: AppColors.coloGreyText,
                      width: 12,
                      thickness: 1.2,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfo(
                          "Inquiries", "${businessStatsData?.inquiries ?? 0}"),
                      SizedBox(
                        height: SizeConfig.size6,
                      ),
                      _buildInfo(
                          "Followers", "${businessStatsData?.count ?? 0}"),
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size40,
                    child: VerticalDivider(
                      color: AppColors.coloGreyText,
                      width: 12,
                      thickness: 1.2,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomText(
                        "Joined :",
                        fontSize: SizeConfig.size14,
                        color: AppColors.grayText,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: SizeConfig.size6),
                      CustomText(
                        businessData?.dateOfIncorporation == null
                            ? ""
                            : "${businessData?.dateOfIncorporation?.date ?? ""}/${(businessData?.dateOfIncorporation?.month ?? 1)}/${businessData?.dateOfIncorporation?.year ?? ""}",
                        fontSize: SizeConfig.size14,
                        maxLines: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String title, String value) {
    return Row(
      children: [
        CustomText(
          title + ":",
          fontSize: SizeConfig.size14,
          color: AppColors.grayText,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(width: SizeConfig.size6),
        CustomText(
          value,
          fontSize: SizeConfig.size14,
          fontWeight: FontWeight.w900,
        ),
      ],
    );
  }

  Widget _buildTag(
    String text, {
    Color borderColor = AppColors.greyA5,
    Color textColor = AppColors.black,
  }) {
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size4, vertical: SizeConfig.size4),
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

  bool _isExpanded = false;

  Widget buildRatingSummary({
    required String rating,
    required String totalReviews,
  }) {
    List<RatingDistribution> sortedList =
        List.from(controller.ratingDistributionList);
    sortedList.sort((a, b) => b.rating.compareTo(a.rating));
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
                          double.parse(rating).floor().toString() + ".0",
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.size60,
                          color: AppColors.black,
                        ),
                        SizedBox(width: SizeConfig.size12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AbsorbPointer(
                              absorbing: true,
                              child: RatingBar.builder(
                                initialRating: double.parse(rating),
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemSize: 23,
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
                              "${(totalReviews ?? "").toString()} Review",
                              fontSize: SizeConfig.size18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey4C,
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
                  children: sortedList
                      .map((item) =>
                          _buildRatingRow(item.rating, item.count.toDouble()))
                      .toList(),
                ),
              ],
              SizedBox(height: SizeConfig.size20),
              Center(
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => Dialog(
                      insetPadding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40), // ← ADD THIS
                      child: SingleChildScrollView(
                        // ← ADD THIS
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: buildRatingReviewWidget(
                          context,
                          _rating, // ← PASS the stored rating
                          _reviewController, // ← PASS the controller
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

                            try {
                              final success = await _ratingController
                                  .submitBusinessRating(
                                businessId: widget.businessId,
                                rating: rating,
                                comment: review,
                              )
                                  .then((value) {
                                // Update the _rating variable to reflect the submitted rating
                                setState(() {
                                  _rating = rating;
                                });
                                Get.back();
                              });
                            } catch (e) {
                              if (mounted) {
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   SnackBar(
                                //     content: Text('Failed to submit review: ${e.toString()}'),
                                //     backgroundColor: Colors.red,
                                //   ),
                                // );
                                commonSnackBar(
                                    message: "Failed to submit review",
                                    snackBackgroundColor: AppColors.red);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  child: AbsorbPointer(
                    absorbing: true,
                    child: RatingBar.builder(
                      initialRating: _rating == 0 ? 0 : _rating.toDouble(),
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 60,
                      unratedColor: Colors.grey.shade400,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star_border,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rate) {
                        setState(() {
                          _rating = rate.toInt();
                        });
                      },
                    ),
                  ),
                ),
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
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 14, color: Colors.black), // Default text color
              children: [
                TextSpan(text: stars.toString()),
                const TextSpan(
                  text: " ★",
                  style:
                      TextStyle(color: Colors.amber), // Golden color for star
                ),
              ],
            ),
          ),
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

  Widget buildRatingReviewWidget(
    BuildContext context,
    int currentRating,
    TextEditingController reviewController,
    Function(int, String) onSubmit,
  ) {
    int rating = 0;

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
                                _rating = rate.toInt();
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

  Widget buildHorizontalProductList(
      {required GetAllProductDetailsModel? products}) {
    return products == null || (products.data?.isEmpty ?? true)
        ? SizedBox()
        : Card(
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
                    "Products",
                    fontSize: SizeConfig.size20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                  SizedBox(
                    height: SizeConfig.size8,
                  ),
                  SizedBox(
                    height: 270,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.data?.length ?? 0,
                      itemBuilder: (context, index) {
                        var data = products.data![index];
                        return Container(
                          width: SizeConfig.size200,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius:
                                BorderRadius.circular(SizeConfig.size12),
                            border:
                                Border.all(color: AppColors.whiteDB, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(SizeConfig.size8),
                                  topRight: Radius.circular(SizeConfig.size8),
                                ),
                                child: Image.network(
                                  data.media?.isNotEmpty ?? false
                                      ? data.media!.first.url ?? ""
                                      : "",
                                  height: SizeConfig.size150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    "assets/images/camera_stand.png",
                                    height: SizeConfig.size150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(SizeConfig.size8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      (data.name ?? "").capitalizeFirst,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: SizeConfig.size16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    SizedBox(height: SizeConfig.size2),
                                    CustomText(
                                      "₹${data.ourPrice}",
                                      fontSize: SizeConfig.size15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    SizedBox(height: SizeConfig.size2),
                                    CustomText(
                                      "50% Off ₹${data.ourPrice}",
                                      fontSize: SizeConfig.size14,
                                      color: AppColors.coloGreyText,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    SizedBox(height: SizeConfig.size2),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: AppColors.yellow,
                                            size: SizeConfig.size18),
                                        SizedBox(width: SizeConfig.size4),
                                        CustomText(
                                          (data.avgRating ?? "").toString(),
                                          fontSize: SizeConfig.size14,
                                          color: AppColors.coloGreyText,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        SizedBox(width: SizeConfig.size4),
                                        CustomText(
                                          "(${data.feedbackCount ?? "0"} reviews)",
                                          fontSize: SizeConfig.size13,
                                          color: AppColors.coloGreyText,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(
                        width: SizeConfig.size20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget buildReviewCard() {
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
              "Reviews & Ratings",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            reviewContainerdynamic(),
          ],
        ),
      ),
    );
  }

  reviewContainerdynamic() {
    FeedbackData feedBackData = controller.feedBackdataList.first;
    return Card(
      color: AppColors.white,
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // const CircleAvatar(
                //   radius: 20,
                //   backgroundImage: NetworkImage(
                //     "https://randomuser.me/api/portraits/women/44.jpg",
                //   ),
                // ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors
                      .primaryColor, // Add your preferred background color
                  child: Text(
                    feedBackData.user.username.isNotEmpty
                        ? feedBackData.user.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: SizeConfig.size16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "${feedBackData.user.username}",
                      fontSize: SizeConfig.size16,
                      fontWeight: FontWeight.w600,
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          feedBackData.rating,
                          (index) => Icon(Icons.star,
                              color: AppColors.yellow, size: SizeConfig.size16),
                        ),
                        SizedBox(width: SizeConfig.size6),
                        CustomText(
                          "${feedBackData.formattedCreatedAt}",
                          color: AppColors.coloGreyText,
                          fontSize: SizeConfig.size12,
                        )
                      ],
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              "${feedBackData.comment}",
              fontSize: SizeConfig.size14,
              color: AppColors.grayText,
            ),
            SizedBox(height: SizeConfig.size10),
            // Row(
            //   children: [
            //     Expanded(
            //       child: ClipRRect(
            //           borderRadius: BorderRadius.circular(SizeConfig.size12),
            //           child: ColoredBox(
            //             color: AppColors.red,
            //             child: Image.asset(
            //               "assets/images/brand_logo.png",
            //               height: SizeConfig.size120,
            //               // fit: BoxFit.cover,
            //             ),
            //           )),
            //     ),
            //     SizedBox(width: SizeConfig.size8),
            //     Expanded(
            //       child: ClipRRect(
            //           borderRadius: BorderRadius.circular(SizeConfig.size12),
            //           child: ColoredBox(
            //             color: AppColors.red,
            //             child: Image.asset(
            //               "assets/images/brand_logo.png",
            //               height: SizeConfig.size120,
            //               // fit: BoxFit.cover,
            //             ),
            //           )),
            //     ),
            //   ],
            // ),
            // SizedBox(height: SizeConfig.size12),
            // Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 0),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: Container(
            //           height: 50,
            //           padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            //           decoration: BoxDecoration(
            //               border:
            //                   Border.all(color: AppColors.borderGray, width: 2),
            //               borderRadius: BorderRadius.circular(12)),
            //           child: Row(children: [
            //             CircleAvatar(
            //                 backgroundColor: AppColors.black,
            //                 radius: 16,
            //                 child: Container(
            //                   decoration: BoxDecoration(
            //                     shape: BoxShape.circle,
            //                     color: AppColors.black,
            //                   ),
            //                   child: Icon(
            //                     Icons.thumb_up_alt_outlined,
            //                     color: AppColors.white,
            //                     size: 16,
            //                   ),
            //                 )),
            //             const SizedBox(width: 8),
            //             Expanded(
            //               child: TextField(
            //                 decoration: InputDecoration(
            //                     border: InputBorder.none,
            //                     errorBorder: InputBorder.none,
            //                     focusedErrorBorder: InputBorder.none,
            //                     focusedBorder: InputBorder.none,
            //                     enabledBorder: InputBorder.none,
            //                     disabledBorder: InputBorder.none,
            //                     hintText: "Write your comment.",
            //                     hintStyle: TextStyle(
            //                       fontSize: 12,
            //                     )),
            //               ),
            //             ),
            //           ]),
            //         ),
            //       ),
            //       const SizedBox(width: 8),
            //       Container(
            //           height: 50,
            //           width: 50,
            //           decoration: BoxDecoration(
            //               border:
            //                   Border.all(color: AppColors.borderGray, width: 2),
            //               borderRadius: BorderRadius.circular(12)),
            //           child: Image.asset(
            //             "assets/images/share.png",
            //             color: AppColors.black,
            //           )),
            //     ],
            //   ),
            // ),
          
          ],
        ),
      ),
    );
  }

  // Widget reviewContainer() {
  //   return Container(
  //     padding: EdgeInsets.all(SizeConfig.size12),
  //     decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(SizeConfig.size12),
  //         border: Border.all(color: AppColors.whiteDB, width: 2)),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: [
  //             const CircleAvatar(
  //               radius: 20,
  //               backgroundImage: NetworkImage(
  //                 "https://randomuser.me/api/portraits/women/44.jpg",
  //               ),
  //             ),
  //             SizedBox(width: SizeConfig.size10),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 CustomText(
  //                   "Courtney Henry",
  //                   fontSize: SizeConfig.size16,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //                 Row(
  //                   children: [
  //                     ...List.generate(
  //                       5,
  //                       (index) => Icon(Icons.star,
  //                           color: AppColors.yellow, size: SizeConfig.size16),
  //                     ),
  //                     SizedBox(width: SizeConfig.size6),
  //                     CustomText(
  //                       "2 mins ago",
  //                       color: AppColors.coloGreyText,
  //                       fontSize: SizeConfig.size12,
  //                     )
  //                   ],
  //                 ),
  //               ],
  //             )
  //           ],
  //         ),
  //         SizedBox(height: SizeConfig.size10),
  //         CustomText(
  //           "Yorem ipsum dolor sit amet, consectetur adipiscing elit. "
  //           "Nunc vulputate libero et velit interdum, ac aliquet odio mattis. "
  //           "Class aptent taciti sociosqu ad litora torquent.",
  //           fontSize: SizeConfig.size14,
  //           color: AppColors.grayText,
  //         ),
  //         SizedBox(height: SizeConfig.size10),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(SizeConfig.size12),
  //                   child: ColoredBox(
  //                     color: AppColors.red,
  //                     child: Image.asset(
  //                       "assets/images/brand_logo.png",
  //                       height: SizeConfig.size120,
  //                       // fit: BoxFit.cover,
  //                     ),
  //                   )),
  //             ),
  //             SizedBox(width: SizeConfig.size8),
  //             Expanded(
  //               child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(SizeConfig.size12),
  //                   child: ColoredBox(
  //                     color: AppColors.red,
  //                     child: Image.asset(
  //                       "assets/images/brand_logo.png",
  //                       height: SizeConfig.size120,
  //                       // fit: BoxFit.cover,
  //                     ),
  //                   )),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: SizeConfig.size12),
  //         Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 0),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: Container(
  //                   height: 50,
  //                   padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
  //                   decoration: BoxDecoration(
  //                       border:
  //                           Border.all(color: AppColors.borderGray, width: 2),
  //                       borderRadius: BorderRadius.circular(12)),
  //                   child: Row(children: [
  //                     CircleAvatar(
  //                       radius: 16,
  //                       // backgroundImage:
  //                       // AssetImage(
  //                       //     "assets/images/profile_logo.png"),
  //                       child: Image.network(
  //                           "https://randomuser.me/api/portraits/women/44.jpg"),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: RichText(
  //                         overflow: TextOverflow.ellipsis,
  //                         maxLines: 2,
  //                         text: TextSpan(
  //                           style: TextStyle(color: Colors.black, fontSize: 13),
  //                           children: [
  //                             TextSpan(
  //                                 text: "Sathi: ",
  //                                 style:
  //                                     TextStyle(fontWeight: FontWeight.bold)),
  //                             TextSpan(
  //                                 text:
  //                                     "Bharat Mata Ki Jai...❤️🙏 Lorem ipsum Dolor Amet"),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                     Icon(Icons.edit, size: 18, color: Colors.grey[600]),
  //                   ]),
  //                 ),
  //               ),
  //               const SizedBox(width: 8),
  //               Container(
  //                 height: 50,
  //                 width: 50,
  //                 decoration: BoxDecoration(
  //                     border: Border.all(color: AppColors.borderGray, width: 2),
  //                     borderRadius: BorderRadius.circular(12)),
  //                 child: PopupMenuButton(
  //                     onSelected: (value) {},
  //                     itemBuilder: (context) => [
  //                           PopupMenuItem(
  //                               value: 1, child: CustomText("Re-post")),
  //                           PopupMenuItem(value: 2, child: CustomText("Share")),
  //                           PopupMenuItem(value: 3, child: CustomText("Save"))
  //                         ]),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget buildJobCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              "Jobs",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            SizedBox(
              height: 6,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SizeConfig.size12),
                  border: Border.all(color: AppColors.whiteDB, width: 2)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(SizeConfig.size12),
                        bottomLeft: Radius.circular(SizeConfig.size12)),
                    child: Image.asset(
                      "assets/images/hiring_image.jpg",
                      height: 250,
                      width: 120,
                      fit: BoxFit.fill,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: SizeConfig.size8,
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.skyBlueDF,
                              child: Center(
                                child: CustomText(
                                  "B",
                                  color: AppColors.white,
                                  fontSize: SizeConfig.size20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.size8,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  "BlueCS Limited",
                                  fontWeight: FontWeight.bold,
                                  fontSize: SizeConfig.size12,
                                ),
                                CustomText(
                                  "Posted On: 07-Feb-2025",
                                  fontSize: SizeConfig.size10,
                                  color: AppColors.coloGreyText,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Divider(
                          color: AppColors.borderGray,
                          thickness: 1,
                        ),
                        SizedBox(height: SizeConfig.size6),
                        RichText(
                            text: TextSpan(
                                text: "Job title: ",
                                style: TextStyle(
                                    color: AppColors.coloGreyText,
                                    fontSize: SizeConfig.size14),
                                children: [
                              TextSpan(
                                  text: "UI / UX Designer",
                                  style: TextStyle(color: AppColors.black))
                            ])),
                        RichText(
                            text: TextSpan(
                                text: "Job type: ",
                                style: TextStyle(
                                    color: AppColors.coloGreyText,
                                    fontSize: SizeConfig.size14),
                                children: [
                              TextSpan(
                                  text: "Full Time - On Site",
                                  style: TextStyle(color: AppColors.black))
                            ])),
                        RichText(
                            text: TextSpan(
                                text: "Min Experience: ",
                                style: TextStyle(
                                    color: AppColors.coloGreyText,
                                    fontSize: SizeConfig.size14),
                                children: [
                              TextSpan(
                                  text: "5 yrs",
                                  style: TextStyle(color: AppColors.black))
                            ])),
                        RichText(
                            text: TextSpan(
                                text: "Monthly Pay: ",
                                style: TextStyle(
                                    color: AppColors.coloGreyText,
                                    fontSize: SizeConfig.size14),
                                children: [
                              TextSpan(
                                  text: "15,000 to 20,000",
                                  style: TextStyle(color: AppColors.black))
                            ])),
                        RichText(
                            text: TextSpan(
                                text: "Job Location: ",
                                style: TextStyle(
                                    color: AppColors.coloGreyText,
                                    fontSize: SizeConfig.size14),
                                children: [
                              TextSpan(
                                  text: "Gomti Nagar, Lucknow",
                                  style: TextStyle(color: AppColors.black))
                            ])),
                        SizedBox(height: SizeConfig.size12),
                        Row(
                          children: [
                            Expanded(
                                child: CustomBtn(
                              radius: SizeConfig.size10,
                              onTap: () {},
                              title: "Directions",
                              height: SizeConfig.size30,
                              fontWeight: FontWeight.bold,
                              bgColor: AppColors.white,
                              textColor: AppColors.skyBlueDF,
                              borderColor: AppColors.skyBlueDF,
                            )),
                            SizedBox(
                              width: SizeConfig.size12,
                            ),
                            Expanded(
                                child: CustomBtn(
                              radius: SizeConfig.size10,
                              onTap: () {},
                              title: "Apply Now",
                              height: SizeConfig.size30,
                              fontWeight: FontWeight.bold,
                              bgColor: AppColors.skyBlueDF,
                            )),
                            SizedBox(
                              width: SizeConfig.size12,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size12),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPostCard({required ViewBusinessDetailsController controller}) {
    final data = controller.post.value;

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
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(SizeConfig.size12)),
                    child: Image.network(
                      data.media?.first ?? "",
                      height: SizeConfig.size200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Placeholder(fallbackHeight: SizeConfig.size200),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          data.message ?? "",
                          fontSize: SizeConfig.size16,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          data.subTitle,
                          fontSize: SizeConfig.size14,
                          color: AppColors.coloGreyText,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Your Comment.....",
                            fillColor: AppColors.whiteF3,
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size12,
                                vertical: SizeConfig.size10),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.size12),
                              borderSide:
                                  BorderSide(color: AppColors.coloGreyText),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  Divider(
                    endIndent: SizeConfig.size16,
                    indent: SizeConfig.size16,
                    height: 8,
                    color: AppColors.greyA5,
                    thickness: 1,
                  ),
                  SizedBox(
                    height: SizeConfig.size16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          CustomText((data.likesCount ?? "").toString()),
                          SizedBox(width: 6),
                          Icon(Icons.thumb_up_alt, color: AppColors.skyBlueDF),
                        ],
                      ),
                      SizedBox(
                          height: SizeConfig.size24,
                          child: VerticalDivider(
                            color: AppColors.coloGreyText,
                            width: 2,
                            thickness: 1,
                          )),
                      Row(
                        children: [
                          CustomText((data.commentsCount ?? "").toString()),
                          SizedBox(width: 6),
                          Icon(Icons.comment_outlined,
                              color: AppColors.coloGreyText),
                        ],
                      ),
                      SizedBox(
                          height: SizeConfig.size24,
                          child: VerticalDivider(
                            color: AppColors.coloGreyText,
                            width: 2,
                            thickness: 1,
                          )),
                      Row(
                        children: const [
                          Text("50"),
                          SizedBox(width: 6),
                          Icon(Icons.ios_share, color: AppColors.coloGreyText),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size16,
                  ),
                ],
              ),
            )

            // posts.isNotEmpty
            // ? SizedBox(
            //     height: SizeConfig.size230,
            //     child: ListView.builder(
            //         itemCount: posts.length,
            //         scrollDirection: Axis.horizontal,
            //         shrinkWrap: true,
            //         itemBuilder: (context, index) {
            //           var data = posts[index];
            //           // return FeedCard(
            //           //   post: data,
            //           //   index: index,
            //           //   postFilteredType: PostType.latest,
            //           // );
            //           return Container(
            //             height: SizeConfig.size230,
            //             width: double.infinity,
            //             decoration: BoxDecoration(
            //                 border: Border.all(
            //                     color: AppColors.whiteDB, width: 2),
            //                 borderRadius:
            //                     BorderRadius.circular(SizeConfig.size12)),
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 ClipRRect(
            //                     borderRadius: BorderRadius.only(
            //                         topLeft:
            //                             Radius.circular(SizeConfig.size12),
            //                         topRight:
            //                             Radius.circular(SizeConfig.size12)),
            //                     child:
            //                         Image.network(data.media?.first ?? "")
            //                     // Image.asset(
            //                     //   "assets/images/burger.png",
            //                     //   height: SizeConfig.size200,
            //                     //   width: double.infinity,
            //                     //   fit: BoxFit.cover,
            //                     // ),
            //                     ),
            //                 Padding(
            //                   padding: EdgeInsets.all(SizeConfig.size10),
            //                   child: Column(
            //                     crossAxisAlignment:
            //                         CrossAxisAlignment.start,
            //                     children: [
            //                       CustomText(
            //                         data.message ?? "",
            //                         fontSize: SizeConfig.size16,
            //                         fontWeight: FontWeight.bold,
            //                       ),
            //                       SizedBox(height: SizeConfig.size4),
            //                       CustomText(
            //                         data.subTitle,
            //                         fontSize: SizeConfig.size14,
            //                         color: AppColors.coloGreyText,
            //                       ),
            //                       SizedBox(height: SizeConfig.size10),
            //                       TextField(
            //                         decoration: InputDecoration(
            //                           hintText: "Your Comment.....",
            //                           fillColor: AppColors.whiteF3,
            //                           filled: true,
            //                           contentPadding: EdgeInsets.symmetric(
            //                               horizontal: SizeConfig.size12,
            //                               vertical: SizeConfig.size10),
            //                           border: OutlineInputBorder(
            //                             borderRadius: BorderRadius.circular(
            //                                 SizeConfig.size12),
            //                             borderSide: BorderSide(
            //                                 color: AppColors.coloGreyText),
            //                           ),
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //                 SizedBox(height: SizeConfig.size12),
            //                 Divider(
            //                   endIndent: SizeConfig.size16,
            //                   indent: SizeConfig.size16,
            //                   height: 8,
            //                   color: AppColors.greyA5,
            //                   thickness: 1,
            //                 ),
            //                 SizedBox(
            //                   height: SizeConfig.size16,
            //                 ),
            //                 Row(
            //                   mainAxisAlignment:
            //                       MainAxisAlignment.spaceAround,
            //                   children: [
            //                     Row(
            //                       children: [
            //                         CustomText(
            //                             (data.likesCount ?? "").toString()),
            //                         SizedBox(width: 6),
            //                         Icon(Icons.thumb_up_alt,
            //                             color: AppColors.skyBlueDF),
            //                       ],
            //                     ),
            //                     SizedBox(
            //                         height: SizeConfig.size24,
            //                         child: VerticalDivider(
            //                           color: AppColors.coloGreyText,
            //                           width: 2,
            //                           thickness: 1,
            //                         )),
            //                     Row(
            //                       children: [
            //                         CustomText((data.commentsCount ?? "")
            //                             .toString()),
            //                         SizedBox(width: 6),
            //                         Icon(Icons.comment_outlined,
            //                             color: AppColors.coloGreyText),
            //                       ],
            //                     ),
            //                     SizedBox(
            //                         height: SizeConfig.size24,
            //                         child: VerticalDivider(
            //                           color: AppColors.coloGreyText,
            //                           width: 2,
            //                           thickness: 1,
            //                         )),
            //                     Row(
            //                       children: const [
            //                         Text("50"),
            //                         SizedBox(width: 6),
            //                         Icon(Icons.ios_share,
            //                             color: AppColors.coloGreyText),
            //                       ],
            //                     ),
            //                   ],
            //                 ),
            //                 SizedBox(
            //                   height: SizeConfig.size16,
            //                 ),
            //               ],
            //             ),
            //           );

            //         }),
            //   )

            // : SizedBox(
            //     width: Get.width,
            //     child: Center(child: CustomText("No Post found")),
            //   ),
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
      child: Container(
        width: Get.width,
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
            ShortsChannelSection(
              isOwnShorts: true,
              channelId: '',
              authorId:
                  controller.visitedBusinessProfileDetails?.data?.userId ?? "",
              showShortsInGrid: false,
              sortBy: selectedFilter,
              postVia: PostVia.profile,
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
            VideoChannelSection(
              isOwnVideos: true,
              channelId: '',
              authorId:
                  controller.visitedBusinessProfileDetails?.data?.userId ?? "",
              isScroll: false,
              postVia: PostVia.profile,
              sortBy: selectedFilter,
              showOnlyOne: true,
            )

            // Card(
            //   elevation: 10,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   color: AppColors.white,
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Stack(
            //         children: [
            //           ClipRRect(
            //             borderRadius: const BorderRadius.only(
            //               topLeft: Radius.circular(12),
            //               topRight: Radius.circular(12),
            //             ),
            //             child: Image.asset(
            //               'assets/images/video_preview.png',
            //               height: 200,
            //               width: double.infinity,
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //           Positioned(
            //             top: 8,
            //             right: 8,
            //             child: Container(
            //               decoration: BoxDecoration(
            //                 color: Colors.black.withOpacity(0.6),
            //                 shape: BoxShape.circle,
            //               ),
            //               padding: const EdgeInsets.all(6),
            //               child: const Icon(
            //                 Icons.volume_off,
            //                 size: 16,
            //                 color: Colors.white,
            //               ),
            //             ),
            //           ),
            //           Positioned(
            //             bottom: 8,
            //             right: 8,
            //             child: Container(
            //               padding: const EdgeInsets.symmetric(
            //                   horizontal: 6, vertical: 2),
            //               decoration: BoxDecoration(
            //                 color: Colors.black.withOpacity(0.8),
            //                 borderRadius: BorderRadius.circular(4),
            //               ),
            //               child: const Text(
            //                 "02:53",
            //                 style: TextStyle(color: Colors.white, fontSize: 12),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.all(8.0),
            //         child: Row(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             const CircleAvatar(
            //               radius: 18,
            //               backgroundColor: Colors.black,
            //               child: Icon(Icons.play_arrow, color: Colors.white),
            //             ),
            //             const SizedBox(width: 8),

            //             Expanded(
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: const [
            //                   Text(
            //                     "Trying MC’s Burger for the first time!!! "
            //                     "Trying MC’s Burger for the...",
            //                     maxLines: 2,
            //                     overflow: TextOverflow.ellipsis,
            //                     style: TextStyle(
            //                       fontWeight: FontWeight.w500,
            //                       fontSize: 14,
            //                     ),
            //                   ),
            //                   SizedBox(height: 4),
            //                   Text(
            //                     "TechSavvy   3.5 lakhs views   12 days ago",
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Colors.grey,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),

            //             /// Menu button
            //             IconButton(
            //               onPressed: () {},
            //               icon: const Icon(Icons.more_vert, size: 18),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
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
                    }).toList() ??
                    [],
              ),
            )
          ],
        ));
  }

  Widget productTab({GetAllProductDetailsModel? products}) {
    return products == null
        ? SizedBox(
            width: Get.width,
            child: Center(
              child: CustomText("No product found"),
            ),
          )
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 0.65,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12),
              itemCount: products.data?.length ?? 0,
              itemBuilder: (context, index) {
                var data = products.data![index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(SizeConfig.size12),
                    border: Border.all(color: AppColors.whiteDB, width: 2),
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
                          child: Image.network(
                            data.media?.isNotEmpty ?? false
                                ? data.media!.first.url ?? ""
                                : "",
                            height: SizeConfig.size100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              "assets/images/camera_stand.png",
                              height: SizeConfig.size100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(SizeConfig.size8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              (data.name ?? "").capitalizeFirst,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: SizeConfig.size16,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: SizeConfig.size2),
                            CustomText(
                              "₹${data.ourPrice}",
                              fontSize: SizeConfig.size15,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: SizeConfig.size2),
                            CustomText(
                              "50% Off ₹${data.ourPrice}",
                              fontSize: SizeConfig.size14,
                              color: AppColors.coloGreyText,
                              decoration: TextDecoration.lineThrough,
                            ),
                            SizedBox(height: SizeConfig.size2),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.network(
                                    "https://randomuser.me/api/portraits/women/44.jpg",
                                    height: 28,
                                  ),
                                ),
                                SizedBox(
                                  width: SizeConfig.size8,
                                ),
                                Expanded(
                                    child: CustomText(
                                  "Pervez Mobile Shop",
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ))
                              ],
                            ),
                            SizedBox(height: SizeConfig.size2),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    color: AppColors.yellow,
                                    size: SizeConfig.size18),
                                SizedBox(width: SizeConfig.size4),
                                CustomText(
                                  (data.avgRating ?? "").toString(),
                                  fontSize: SizeConfig.size14,
                                  color: AppColors.coloGreyText,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(width: SizeConfig.size4),
                                CustomText(
                                  "(${data.feedbackCount ?? "0"} reviews)",
                                  fontSize: SizeConfig.size13,
                                  color: AppColors.coloGreyText,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }

  Widget reviewTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: buildRatingSummary(
                  rating: controller.ratingSummaryResponse.value.data.avgRating,
                  totalReviews: controller
                      .ratingSummaryResponse.value.data.totalRatings
                      .toString()),
            ),
            SizedBox(
              height: 12,
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 12),
            //   child: Row(
            //     children: [
            //       CustomText(
            //         "Most Relevant",
            //         decoration: TextDecoration.underline,
            //         decorationColor: AppColors.skyBlueDF,
            //         color: AppColors.skyBlueDF,
            //       ),
            //       SizedBox(
            //         width: 12,
            //       ),
            //       CustomText(
            //         "Newest",
            //         decoration: TextDecoration.underline,
            //         decorationColor: AppColors.black,
            //         color: AppColors.black,
            //       ),
            //       SizedBox(
            //         width: 12,
            //       ),
            //       CustomText(
            //         "Oldest",
            //         decoration: TextDecoration.underline,
            //         decorationColor: AppColors.black,
            //         color: AppColors.black,
            //       ),
            //     ],
            //   ),
            // ),
            SizedBox(
              height: 12,
            ),
            ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: controller.feedBackdataList.length,
                separatorBuilder: (context, index) => SizedBox(
                      height: 20,
                    ),
                itemBuilder: (context, index) {
                  FeedbackData feedBackData =
                      controller.feedBackdataList[index];
                  return Card(
                    color: AppColors.white,
                    elevation: 10,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // const CircleAvatar(
                              //   radius: 20,
                              //   backgroundImage: NetworkImage(
                              //     "https://randomuser.me/api/portraits/women/44.jpg",
                              //   ),
                              // ),
                              
                              
                              CircleAvatar(
  radius: 20,
  backgroundColor: AppColors.primaryColor, // Add your preferred background color
  child: Text(
    feedBackData.user.username.isNotEmpty 
      ? feedBackData.user.username[0].toUpperCase() 
      : '?',
    style: TextStyle(
      fontSize: SizeConfig.size16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),
                              SizedBox(width: SizeConfig.size10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "${feedBackData.user.username}",
                                    fontSize: SizeConfig.size16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        feedBackData.rating,
                                        (index) => Icon(Icons.star,
                                            color: AppColors.yellow,
                                            size: SizeConfig.size16),
                                      ),
                                      SizedBox(width: SizeConfig.size6),
                                      CustomText(
                                        "${feedBackData.formattedCreatedAt}",
                                        color: AppColors.coloGreyText,
                                        fontSize: SizeConfig.size12,
                                      )
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                          SizedBox(height: SizeConfig.size10),
                          CustomText(
                            "${feedBackData.comment}",
                            fontSize: SizeConfig.size14,
                            color: AppColors.grayText,
                          ),
                          SizedBox(height: SizeConfig.size10),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: ClipRRect(
                          //           borderRadius: BorderRadius.circular(
                          //               SizeConfig.size12),
                          //           child: ColoredBox(
                          //             color: AppColors.red,
                          //             child: Image.asset(
                          //               "assets/images/brand_logo.png",
                          //               height: SizeConfig.size120,
                          //               // fit: BoxFit.cover,
                          //             ),
                          //           )),
                          //     ),
                          //     SizedBox(width: SizeConfig.size8),
                          //     Expanded(
                          //       child: ClipRRect(
                          //           borderRadius: BorderRadius.circular(
                          //               SizeConfig.size12),
                          //           child: ColoredBox(
                          //             color: AppColors.red,
                          //             child: Image.asset(
                          //               "assets/images/brand_logo.png",
                          //               height: SizeConfig.size120,
                          //               // fit: BoxFit.cover,
                          //             ),
                          //           )),
                          //     ),
                          //   ],
                          // ),
                          // SizedBox(height: SizeConfig.size12),
                          // Padding(
                          //   padding: EdgeInsets.symmetric(horizontal: 0),
                          //   child: Row(
                          //     children: [
                          //       Expanded(
                          //         child: Container(
                          //           height: 50,
                          //           padding: EdgeInsets.symmetric(
                          //               vertical: 4, horizontal: 8),
                          //           decoration: BoxDecoration(
                          //               border: Border.all(
                          //                   color: AppColors.borderGray,
                          //                   width: 2),
                          //               borderRadius:
                          //                   BorderRadius.circular(12)),
                          //           child: Row(children: [
                          //             CircleAvatar(
                          //                 backgroundColor: AppColors.black,
                          //                 radius: 16,
                          //                 child: Container(
                          //                   decoration: BoxDecoration(
                          //                     shape: BoxShape.circle,
                          //                     color: AppColors.black,
                          //                   ),
                          //                   child: Icon(
                          //                     Icons.thumb_up_alt_outlined,
                          //                     color: AppColors.white,
                          //                     size: 16,
                          //                   ),
                          //                 )),
                          //             const SizedBox(width: 8),
                          //             Expanded(
                          //               child: TextField(
                          //                 decoration: InputDecoration(
                          //                     border: InputBorder.none,
                          //                     errorBorder: InputBorder.none,
                          //                     focusedErrorBorder:
                          //                         InputBorder.none,
                          //                     focusedBorder: InputBorder.none,
                          //                     enabledBorder: InputBorder.none,
                          //                     disabledBorder: InputBorder.none,
                          //                     hintText: "Write your comment.",
                          //                     hintStyle: TextStyle(
                          //                       fontSize: 12,
                          //                     )),
                          //               ),
                          //             ),
                          //           ]),
                          //         ),
                          //       ),
                          //       const SizedBox(width: 8),
                          //       Container(
                          //           height: 50,
                          //           width: 50,
                          //           decoration: BoxDecoration(
                          //               border: Border.all(
                          //                   color: AppColors.borderGray,
                          //                   width: 2),
                          //               borderRadius:
                          //                   BorderRadius.circular(12)),
                          //           child: Image.asset(
                          //             "assets/images/share.png",
                          //             color: AppColors.black,
                          //           )),
                          //     ],
                          //   ),
                          // ),
                        
                        ],
                      ),
                    ),
                  );
                })
          ],
        ),
      ),
    );
  }

  Widget postsTab({BusinessProfileDetails? data}) {
    return FeedScreen(
      key: const ValueKey('feedScreen_others_posts'),
      postFilterType: PostType.otherPosts,
      id: data?.userId,
    );
  }

  Widget jobsTab() {
    return jobScreenController.jobsData == null ||
            jobScreenController.jobsData!.isEmpty
        ? Center(
            child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CustomText('No Jobs Available'),
          )) /*ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [

                  ],
                )*/
        : ListView.separated(
            itemCount: jobScreenController.jobsData!.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              Jobs job = jobScreenController.jobsData![index];
              return JobTabCard(job: job);
            },
          );
  }
}

class JobTabCard extends StatelessWidget {
  const JobTabCard({
    super.key,
    required this.job,
  });

  final Jobs job;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      margin: EdgeInsets.symmetric(horizontal: 12),
      // decoration: BoxDecoration(
      //     borderRadius: BorderRadius.circular(SizeConfig.size12),
      //     border: Border.all(color: AppColors.whiteDB, width: 2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(SizeConfig.size12),
                bottomLeft: Radius.circular(SizeConfig.size12)),
            child: job?.jobPostImage != null && job!.jobPostImage!.isNotEmpty
                ? Image.network(
                    job.jobPostImage!,
                    height: 230,
                    width: 120,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      "assets/images/hiring_image.jpg",
                      height: 230,
                      width: 120,
                      fit: BoxFit.fill,
                    ),
                  )
                : Image.asset(
                    "assets/images/hiring_image.jpg",
                    height: 230,
                    width: 120,
                    fit: BoxFit.fill,
                  ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: SizeConfig.size8,
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.skyBlueDF,
                      child: Center(
                        child: CustomText(
                          (job?.companyName?.isNotEmpty ?? false)
                              ? job!.companyName!.substring(0, 1).toUpperCase()
                              : "C",
                          color: AppColors.white,
                          fontSize: SizeConfig.size20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: SizeConfig.size8,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          job?.companyName ?? "Company Name",
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.size12,
                        ),
                        CustomText(
                          "Posted On: ${job?.postedOn ?? 'N/A'}",
                          fontSize: SizeConfig.size10,
                          color: AppColors.coloGreyText,
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(
                  color: AppColors.borderGray,
                  thickness: 1,
                ),
                SizedBox(height: SizeConfig.size6),
                RichText(
                    text: TextSpan(
                        text: "Job title: ",
                        style: TextStyle(
                            color: AppColors.coloGreyText,
                            fontSize: SizeConfig.size14),
                        children: [
                      TextSpan(
                          text: job?.jobTitle ?? "Job Title",
                          style: TextStyle(color: AppColors.black))
                    ])),
                RichText(
                    text: TextSpan(
                        text: "Job type: ",
                        style: TextStyle(
                            color: AppColors.coloGreyText,
                            fontSize: SizeConfig.size14),
                        children: [
                      TextSpan(
                          text:
                              "${job?.jobType ?? 'Job Type'} - ${job?.workMode ?? 'Work Mode'}",
                          style: TextStyle(color: AppColors.black))
                    ])),
                RichText(
                    text: TextSpan(
                        text: "Min Experience: ",
                        style: TextStyle(
                            color: AppColors.coloGreyText,
                            fontSize: SizeConfig.size14),
                        children: [
                      TextSpan(
                          text: "${job?.experience ?? 0} yrs",
                          style: TextStyle(color: AppColors.black))
                    ])),
                RichText(
                    text: TextSpan(
                        text: "Monthly Pay: ",
                        style: TextStyle(
                            color: AppColors.coloGreyText,
                            fontSize: SizeConfig.size14),
                        children: [
                      TextSpan(
                          text: job?.compensation != null
                              ? "${job!.compensation!.minSalary ?? 0} to ${job.compensation!.maxSalary ?? 0}"
                              : "Not specified",
                          style: TextStyle(color: AppColors.black))
                    ])),
                RichText(
                    text: TextSpan(
                        text: "Job Location: ",
                        style: TextStyle(
                            color: AppColors.coloGreyText,
                            fontSize: SizeConfig.size14),
                        children: [
                      TextSpan(
                          text: job?.location?.addressString ??
                              "Location not specified",
                          style: TextStyle(color: AppColors.black))
                    ])),
                SizedBox(height: SizeConfig.size12),
                Row(
                  children: [
                    Expanded(
                        child: CustomBtn(
                      radius: SizeConfig.size10,
                      onTap: () {},
                      title: "Directions",
                      height: SizeConfig.size30,
                      fontWeight: FontWeight.bold,
                      bgColor: AppColors.white,
                      textColor: AppColors.skyBlueDF,
                      borderColor: AppColors.skyBlueDF,
                    )),
                    SizedBox(
                      width: SizeConfig.size12,
                    ),
                    Expanded(
                        child: CustomBtn(
                      radius: SizeConfig.size10,
                      onTap: () {},
                      title: "Apply Now",
                      height: SizeConfig.size30,
                      fontWeight: FontWeight.bold,
                      bgColor: AppColors.skyBlueDF,
                    )),
                    SizedBox(
                      width: SizeConfig.size12,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size12),
              ],
            ),
          )
        ],
      ),
    );
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
