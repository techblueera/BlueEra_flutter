import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/getAllProductDetailsModel.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/business_profile_header.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
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
import 'package:share_plus/share_plus.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../personal/personal_profile/view/visit_personal_profile/visit_personal_profile.dart';
import '../../auth/controller/view_business_details_controller.dart';
import '../../auth/model/visitBusinessDetailedRatingModel.dart';
import '../../widgets/live_photos_of_business_widget.dart';


class VisitBusinessProfileNew extends StatefulWidget {
  final String businessId;

  const VisitBusinessProfileNew({super.key, required this.businessId});

  @override
  State<VisitBusinessProfileNew> createState() => VisitBusinessProfileNewState();
}

class VisitBusinessProfileNewState extends State<VisitBusinessProfileNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(ViewBusinessDetailsController());
  final controllerVisit = Get.put(VisitProfileController());
  final chatViewController = Get.find<ChatViewController>();

  late VisitProfileController visitProfileController;
  final List<String> tabs = [
    'Overview',
    // 'Products',
    // 'Reviews',
    'Posts',
    'Shorts',
    'Video',
    // 'Jobs',
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
    visitProfileController = Get.put(VisitProfileController());
    controller.viewBusinessProfileById(widget.businessId);
    controller.getBusinessRatingsSummary(widget.businessId);
    // controller.getBusinessDetailedRatings(widget.businessId);
    // controller.getAllProductsApi({ApiKeys.limit: 0});
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
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: GetBuilder<ViewBusinessDetailsController>(
        init: controller,
        builder: (controller) {
          logs("controller.viewBusinessResponse.status==== ${controller.viewBusinessResponseNew.status}");
          if ((controller.viewBusinessResponseNew.status == Status.COMPLETE)) {
            final businessData = controller.visitedBusinessProfileDetails?.data;
            final ratingData = controller.visitBusinessRatingSumModel.value.data;
            final ratingDetailedCount = controller.visitBusinessDetailedRatingModel.value.data;
            return DefaultTabController(
              length: tabs.length,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: BusinessProfileHeader(businessProfileDetails: businessData??BusinessProfileDetails(),),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CustomTabBarDelegate(
                      VisitPersonalProfileTabs(
                        onTab: (index) {
                          if (index == 2) {
                            Map<String, dynamic> data = {
                              ApiKeys.businessId: widget.businessId
                            };
                            // controller.getParticularRatingApi(data);
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
                              ratingsList:ratingDetailedCount,
                              allowRate: false,
                              rating:
                              double.parse("${ratingData?.avgRating ?? 0}"),
                              totalReviews: "${ratingData?.totalRatings??0}"),
                          SizedBox(height:SizeConfig.size4),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(SizeConfig.size16),
                            ),

                            elevation: 0,
                            color: AppColors.white,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
                              child: BusinessLivePhotos(
                                livePhotos: businessData?.livePhotos ?? [],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          BusinessLocationWidget(
                            latitude: businessData?.businessLocation?.lat
                                ?.toDouble() ??
                                0.0,
                            longitude: businessData?.businessLocation?.lon
                                ?.toDouble() ??
                                0.0,
                            businessName: businessData?.businessName ?? "N/A",
                            isTitleShow: true,
                            locationText: businessData?.address ?? "",
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          buildHorizontalProductList(
                              products: controller.getAllProductDetails?.value),
                          const SizedBox(height: 12),
                          // buildReviewCard(),
                          // const SizedBox(height: 12),
                          // buildJobCard(),
                          // const SizedBox(height: 12),
                          // buildPostCard(controller: controller),
                          // const SizedBox(height: 12),
                          // buildHorizontalSortsList(),
                          // const SizedBox(height: 12),
                          // customVideoCard(),
                          //
                          // const SizedBox(height: 30),
                          //
                          // const SizedBox(height: 24),
                          // */ /*   ProductServicesWidget(),
                          // const SizedBox(height: 20),
                          // SimilarStoreWidget(),
                          // const SizedBox(height: 30),*/
                        ],
                      ),
                    ),

                    // productTab(
                    //     products: controller.getAllProductDetails?.value),
                    //
                    // reviewTab(ratingDetailedCount,ratingData?.avgRating??0,"${ratingData?.totalRatings}"),

                    postsTab(data: businessData),
                    // jobsTab(),

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
                        // isScroll: false,
                        sortBy: selectedFilter,
                        postVia: PostVia.profile,
                      ),
                    ],
                  ),

                  //   FeedScreen(
                  //   key: const ValueKey('feedScreen_others_posts'),
                  //   postFilterType: PostType.otherPosts,
                  //   id: businessData?.userId,
                  // ),

                    // Reviews tab
                    // const Center(child: Text("No reviews yet")),
                    //
                    // // Our Branches tab
                    // const Center(child: Text("No branches yet")),
                  ],
                ),
              ),
            );
          } else if (controller.viewBusinessResponse.status == Status.LOADING) {
            return const Center(child: CircularProgressIndicator());
          } else if (controller.viewBusinessResponse.status == Status.ERROR) {
            return Center(child: CustomText("No business found"));
          } else {
            return Center(
              child: SizedBox(
                  height: 24, width: 24, child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }



  Widget _buildInfo(String title, String value) {
    return Row(
      children: [
        CustomText(
          title + ":",
          fontSize: SizeConfig.size12,
          color: AppColors.grayText,
          fontWeight: FontWeight.w400,
        ),
        SizedBox(width: SizeConfig.size6),
        CustomText(
          value,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor,
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
            horizontal: SizeConfig.size8, vertical: SizeConfig.size2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          border: Border.all(color: borderColor),
        ),
        child: CustomText(
          text,
          fontSize: SizeConfig.size10,
          fontWeight: FontWeight.w400,
          color: textColor,
        ));
  }

  bool _isExpanded = false;

  Widget buildRatingSummary({
    required double rating,
List<RatingCountsListModel>? ratingsList,
    required String totalReviews,
    bool? allowRate,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: 0,
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
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.size18,
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
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: SizeConfig.size50,
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
                                itemSize: 16,
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
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.w600,
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
              if (_isExpanded&&ratingsList!=null) ...[
                /// Rating distribution bars
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...ratingsList.map((rating) =>
                        _buildRatingRow(
                          rating.rating??0,
                          rating.count ?? 0,
                        ),
                    ).toList(),
                  ],
                ),
              ],
              (allowRate ?? true)
                  ? SizedBox(height: SizeConfig.size20)
                  : SizedBox(),
              (allowRate ?? true)
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
                          businessId: widget.businessId,
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
                      itemSize: 56,
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

  Widget buildHorizontalProductList(
      {required GetAllProductDetailsModel? products}) {
    return products == null || (products.data?.isEmpty ?? true)
        ? SizedBox()
        : Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: 0,
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
      elevation: 0,
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
            reviewContainer(),
          ],
        ),
      ),
    );
  }

  Widget reviewContainer() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          border: Border.all(color: AppColors.whiteDB, width: 2)),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  "https://randomuser.me/api/portraits/women/44.jpg",
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Courtney Henry",
                    fontSize: SizeConfig.size16,
                    fontWeight: FontWeight.w600,
                  ),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                            (index) => Icon(Icons.star,
                            color: AppColors.yellow, size: SizeConfig.size16),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        "2 mins ago",
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
            "Yorem ipsum dolor sit amet, consectetur adipiscing elit. "
                "Nunc vulputate libero et velit interdum, ac aliquet odio mattis. "
                "Class aptent taciti sociosqu ad litora torquent.",
            fontSize: SizeConfig.size14,
            color: AppColors.grayText,
          ),
          SizedBox(height: SizeConfig.size10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size12),
                    child: ColoredBox(
                      color: AppColors.red,
                      child: Image.asset(
                        "assets/images/brand_logo.png",
                        height: SizeConfig.size120,
                        // fit: BoxFit.cover,
                      ),
                    )),
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size12),
                    child: ColoredBox(
                      color: AppColors.red,
                      child: Image.asset(
                        "assets/images/brand_logo.png",
                        height: SizeConfig.size120,
                        // fit: BoxFit.cover,
                      ),
                    )),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                        border:
                        Border.all(color: AppColors.borderGray, width: 2),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 16,
                        // backgroundImage:
                        // AssetImage(
                        //     "assets/images/profile_logo.png"),
                        child: Image.network(
                            "https://randomuser.me/api/portraits/women/44.jpg"),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          text: TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 13),
                            children: [
                              TextSpan(
                                  text: "Sathi: ",
                                  style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                  "Bharat Mata Ki Jai...❤️🙏 Lorem ipsum Dolor Amet"),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderGray, width: 2),
                      borderRadius: BorderRadius.circular(12)),
                  child: PopupMenuButton(
                      onSelected: (value) {},
                      itemBuilder: (context) => [
                        PopupMenuItem(
                            value: 1, child: CustomText("Re-post")),
                        PopupMenuItem(value: 2, child: CustomText("Share")),
                        PopupMenuItem(value: 3, child: CustomText("Save"))
                      ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildJobCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: 0,
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
    List<Post> posts = controller.postsResponse.value.data != null
        ? List.from(controller.postsResponse.value.data.data)
        : [];
    if (posts.isEmpty) return SizedBox();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: 0,
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
            controller.postsResponse.value.data != null
                ? SizedBox(
              height: 200,
              child: ListView.builder(
                  itemCount: posts.length,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    var data = posts[index];
                    return FeedCard(
                      post: data,
                      index: index,
                      postFilteredType: PostType.latest,
                    );
                    return Container(
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.whiteDB, width: 2),
                          borderRadius:
                          BorderRadius.circular(SizeConfig.size12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.only(
                                  topLeft:
                                  Radius.circular(SizeConfig.size12),
                                  topRight:
                                  Radius.circular(SizeConfig.size12)),
                              child:
                              Image.network(data.media?.first ?? "")
                            // Image.asset(
                            //   "assets/images/burger.png",
                            //   height: SizeConfig.size200,
                            //   width: double.infinity,
                            //   fit: BoxFit.cover,
                            // ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(SizeConfig.size10),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.size12),
                                      borderSide: BorderSide(
                                          color: AppColors.coloGreyText),
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
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  CustomText(
                                      (data.likesCount ?? "").toString()),
                                  SizedBox(width: 6),
                                  Icon(Icons.thumb_up_alt,
                                      color: AppColors.skyBlueDF),
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
                                  CustomText((data.commentsCount ?? "")
                                      .toString()),
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
                                  Icon(Icons.ios_share,
                                      color: AppColors.coloGreyText),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: SizeConfig.size16,
                          ),
                        ],
                      ),
                    );
                  }),
            )
                : SizedBox(
              width: Get.width,
              child: Center(child: CustomText("No Post found")),
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
      elevation: 0,
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
                ClipRRect(
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

  Widget reviewTab(List<RatingCountsListModel>? ratingDetailedCount,double ratingCount,String totalReview) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: buildRatingSummary(
                  ratingsList:ratingDetailedCount,
                  allowRate: false,rating: ratingCount, totalReviews: "${totalReview}"),
            ),
            SizedBox(
              height: 12,
            ),
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
              height: 12,
            ),
            ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: 4,
                separatorBuilder: (context, index) => SizedBox(
                  height: 20,
                ),
                itemBuilder: (context, index) => Card(
                  color: AppColors.white,
                  elevation: 10,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                "https://randomuser.me/api/portraits/women/44.jpg",
                              ),
                            ),
                            SizedBox(width: SizeConfig.size10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  "Courtney Henry",
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
                                      "2 mins ago",
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
                          "Yorem ipsum dolor sit amet, consectetur adipiscing elit. "
                              "Nunc vulputate libero et velit interdum, ac aliquet odio mattis. "
                              "Class aptent taciti sociosqu ad litora torquent.",
                          fontSize: SizeConfig.size14,
                          color: AppColors.grayText,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      SizeConfig.size12),
                                  child: ColoredBox(
                                    color: AppColors.red,
                                    child: Image.asset(
                                      "assets/images/brand_logo.png",
                                      height: SizeConfig.size120,
                                      // fit: BoxFit.cover,
                                    ),
                                  )),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      SizeConfig.size12),
                                  child: ColoredBox(
                                    color: AppColors.red,
                                    child: Image.asset(
                                      "assets/images/brand_logo.png",
                                      height: SizeConfig.size120,
                                      // fit: BoxFit.cover,
                                    ),
                                  )),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.borderGray,
                                          width: 2),
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                  child: Row(children: [
                                    CircleAvatar(
                                        backgroundColor: AppColors.black,
                                        radius: 16,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.black,
                                          ),
                                          child: Icon(
                                            Icons.thumb_up_alt_outlined,
                                            color: AppColors.white,
                                            size: 16,
                                          ),
                                        )),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                            border: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                            InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            disabledBorder:
                                            InputBorder.none,
                                            hintText: "Write your comment.",
                                            hintStyle: TextStyle(
                                              fontSize: 12,
                                            )),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.borderGray,
                                          width: 2),
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                  child: Image.asset(
                                    "assets/images/share.png",
                                    color: AppColors.black,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
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
    return Text("WIP");
  }

  Widget jobsTab() {
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) => Card(
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
              child: Image.asset(
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
