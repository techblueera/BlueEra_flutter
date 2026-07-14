import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/tab_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/model/getAllProductDetailsModel.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/business_profile_header.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/food/view/standalone_food_screen.dart';
import 'package:BlueEra/features/common/product_listing/view/standalone_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/widget/rating_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../widgets/local_assets.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../personal/personal_profile/view/visit_personal_profile/visit_personal_profile.dart';
import '../../auth/controller/view_business_details_controller.dart';
import '../../widgets/live_photos_of_business_widget.dart';
import 'package:BlueEra/features/common/product_listing/view/standalone_product_screen.dart';

class VisitBusinessProfileNew extends StatefulWidget {
  final String businessId;
  final String screenName;
  final String? isScreenFrom;
  final bool showAppBar;

  const VisitBusinessProfileNew(
      {super.key,
      required this.businessId,
      required this.screenName,
      this.isScreenFrom,
      this.showAppBar = true});

  @override
  State<VisitBusinessProfileNew> createState() =>
      VisitBusinessProfileNewState();
}

class VisitBusinessProfileNewState extends State<VisitBusinessProfileNew>
    with SingleTickerProviderStateMixin {
  // Created lazily once the business data loads, because the number of tabs
  // depends on the business type (Overview + Posts + optional
  // Products/Service/Foods). A fixed length would mismatch TabBarView's
  // children count and throw.
  TabController? _tabController;
  final controller = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  final controllerVisit = Get.put(VisitProfileController());
  final chatViewController = Get.isRegistered<ChatViewController>()
      ? Get.find<ChatViewController>()
      : Get.put(ChatViewController());

  late VisitProfileController visitProfileController;

  // List<String> tabs = [];
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;

  @override
  void initState() {
    super.initState();
    setFilters();
    visitProfileController = Get.put(VisitProfileController());
    controller.loadInitData(visitBusinessId: widget.businessId);
    // controller.getAllProductsApi({ApiKeys.limit: 0});
  }

  // Ensure the TabController exists and matches the current number of tabs.
  // Recreates it when the tab count changes so the controller's length always
  // equals the TabBarView children count.
  void _ensureTabController(int length) {
    if (_tabController != null && _tabController!.length == length) return;
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
    _tabController!.addListener(() {
      if (mounted) setState(() {}); // Ensure VisitPersonalProfileTabs updates
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  setFilters() {
    SortBy.values.where((e) => e != SortBy.UnderProgress).toList();
  }

  backPress() {
    if (widget.isScreenFrom == AppConstants.deepLinkScreen) {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        arguments: {ApiKeys.initialIndex: 1},
      );
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        backPress();
        return false;
      },
      child: Scaffold(
        // Transparent so the app-wide themed background (AppHomeBackground,
        // set via app_background_screen) shows through instead of white.
        backgroundColor: Colors.transparent,
        appBar: widget.showAppBar ? CommonBackAppBar(
          onBackTap: (){
            backPress();
          }
        ) : null,
        body: GetBuilder<ViewBusinessDetailsController>(
          init: controller,
          builder: (controller) {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if ((controller.viewBusinessResponseNew.status ==
                Status.COMPLETE)) {
              final businessData =
                  controller.visitedBusinessProfileDetails?.data;

              // final List<String> tabs = [
              //   'Overview',
              //   'Posts',
              //   if (isShowProduct
              //       .contains(businessData?.typeOfBusiness?.toLowerCase()))
              //     'Products',
              //   if (isShowService
              //       .contains(businessData?.typeOfBusiness?.toLowerCase()))
              //     'Service',
              //   if (isShowFood
              //       .contains(businessData?.typeOfBusiness?.toLowerCase()))
              //     'Foods'
              // ];
              List<TabItem> postTabs = [
                TabItem(id: 'Overview', title: AppStrings.overview.tr),
                TabItem(id: 'Posts', title: AppStrings.posts.tr),
                if (isShowProduct
                    .contains(businessData?.typeOfBusiness?.toLowerCase()))
                  TabItem(id: 'Products', title: AppStrings.tab_product.tr),
                if (isShowService
                    .contains(businessData?.typeOfBusiness?.toLowerCase()))
                  TabItem(id: 'Service', title: AppStrings.tab_service.tr),
                if (isShowFood
                    .contains(businessData?.typeOfBusiness?.toLowerCase()))
                  TabItem(id: 'Foods', title: AppStrings.food.tr),
              ];

              // Keep the controller length in sync with the tab count before
              // the TabBarView/tabs use it.
              _ensureTabController(postTabs.length);

              return DefaultTabController(
                length: postTabs.length,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      // White so the header reads as one white block down to
                      // the tab bar; the tab content below shows the app bg.
                      child: Container(
                        color: AppColors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: BusinessProfileHeader(
                            businessProfileDetails:
                                businessData ?? BusinessProfileDetails(),
                          ),
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CustomTabBarDelegate(
                        VisitPersonalProfileTabs(
                          onTab: (index) {
                            if (index == 2) {
                              // controller.getParticularRatingApi(data);
                            }
                          },
                          tabs: postTabs.map((e) => e.title).toList(),
                          tabController: _tabController!,
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController!,
                    children: [
                      // overview tab
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: SizeConfig.size10,
                            ),
                            // controller.userData.value?.user

                            RatingSummaryWidget(
                              rating:
                                  businessData?.avg_rating?.toDouble() ?? 0.0,
                              ratingPersonCount:
                                  businessData?.total_ratings?.toInt() ?? 0,
                              userId: businessData?.id ?? "",
                              screenFromName: widget.screenName,
                              ratingForAccountName: AppConstants.business,
                              businessId: businessData?.id ?? "",
                            ),

                            // buildRatingSummary(
                            //     ratingsList: ratingDetailedCount,
                            //     allowRate: false,
                            //     rating:
                            //         double.parse("${ratingData?.avgRating ?? 0}"),
                            //     totalReviews: "${ratingData?.totalRatings ?? 0}"),
                            // SizedBox(height: SizeConfig.size8),

                            Card(
                              margin: EdgeInsets.all(SizeConfig.size10),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(SizeConfig.size8),
                              ),
                              elevation: 0,
                              color: AppColors.white,
                              child: BusinessLivePhotos(
                                livePhotos: businessData?.livePhotos ?? [],
                              ),
                            ),

                            if ((businessData?.businessLocation?.lat != null &&
                                    businessData?.businessLocation?.lat != 0) &&
                                (businessData?.businessLocation?.lon != null &&
                                    businessData?.businessLocation?.lon !=
                                        0)) ...[
                              // s

                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: SizeConfig.size6,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        LocalAssets(
                                          height: 30,
                                          width: 30,
                                          imagePath: AppIconAssets
                                              .locationOutlineIconGreyIcon,
                                          boxFix: BoxFit.cover,
                                        ),
                                        SizedBox(
                                          width: SizeConfig.size4,
                                        ),
                                        Expanded(
                                          child: CustomText(
                                            businessData?.address ?? '',
                                            fontSize: SizeConfig.size14,
                                            color: AppColors.mainTextColor,
                                            fontWeight: FontWeight.w400,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Column(
                                    //   children: [
                                    //     Row(
                                    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //       children: [
                                    //         Expanded(
                                    //           child: CustomText(
                                    //             "Your business live location",
                                    //             fontSize: SizeConfig.large,
                                    //             fontWeight: FontWeight.bold,
                                    //             overflow: TextOverflow.ellipsis,
                                    //             color: AppColors.secondaryTextColor,
                                    //           ),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //     Align(
                                    //       alignment: Alignment.centerLeft,
                                    //       child: CustomText(
                                    //         businessData?.address??'',
                                    //         fontSize: SizeConfig.medium,
                                    //         color: AppColors.secondaryTextColor,
                                    //         fontWeight: FontWeight.w400,
                                    //         overflow: TextOverflow.ellipsis,
                                    //       ),
                                    //     ),
                                    //     // Align(
                                    //     //   alignment: Alignment.centerLeft,
                                    //     //   child: CustomText(
                                    //     //     "Your store’s map location",
                                    //     //     fontSize: SizeConfig.medium,
                                    //     //     color: AppColors.secondaryTextColor,
                                    //     //     fontWeight: FontWeight.w400,
                                    //     //     overflow: TextOverflow.ellipsis,
                                    //     //   ),
                                    //     // ),
                                    //   ],
                                    // ),

                                    BusinessLocationWidget(
                                        locationText: "",
                                        // locationText: businessData?.address,
                                        latitude: (businessData
                                                ?.businessLocation?.lat
                                                ?.toDouble() ??
                                            0.0),
                                        longitude: (businessData
                                                ?.businessLocation?.lon
                                                ?.toDouble() ??
                                            0.0),
                                        businessName:
                                            businessData?.businessName ?? "",
                                        padding: 0,
                                        isTitleShow: false),
                                  ],
                                ),
                              ),
                            ],
                            // SizedBox(
                            //   height: SizeConfig.size6,
                            // ),
                            StandaloneProductScreen(
                              businessId: businessData?.id ?? "",
                              isGrid: false,
                              businessData: businessData,
                            ),
                            const BusinessShareBanner(),
                          ],
                        ),
                      ),

                      postsTab(data: businessData),
                      // Container(
                      //   height: 900,
                      //   color: AppColors.red,
                      // ),
                      // jobsTab(),

                      // Shorts tab
                      // Column(
                      //   children: [
                      //     _filterButtons(),
                      //     SizedBox(height: SizeConfig.size8),
                      //     Expanded(
                      //       child: ShortsChannelSection(
                      //         // scrollController: _scrollController,
                      //         isOwnShorts: false,
                      //         showShortsInGrid: true,
                      //         channelId: '',
                      //         sortBy: selectedFilter,
                      //         authorId: widget.businessId,
                      //         postVia: PostVia.profile,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      //
                      // Column(
                      //   children: [
                      //     _filterButtons(),
                      //     SizedBox(height: SizeConfig.size8),
                      //     VideoChannelSection(
                      //       isOwnVideos: false,
                      //       channelId: '',
                      //       authorId: widget.businessId,
                      //       // isScroll: false,
                      //       sortBy: selectedFilter,
                      //       postVia: PostVia.profile,
                      //     ),
                      //   ],
                      // ),

                      if (isShowProduct.contains(
                          businessData?.typeOfBusiness?.toLowerCase()))
                        StandaloneProductScreen(
                          businessId: businessData?.id ?? "",
                          isGrid: true,
                          businessData: businessData,
                        ),

                      if (isShowService.contains(
                          businessData?.typeOfBusiness?.toLowerCase()))
                        StandaloneServiceScreen(
                          businessId: businessData?.id ?? "",
                          isGrid: true,
                          businessData: businessData,
                        ),

                      if (isShowFood.contains(
                          businessData?.typeOfBusiness?.toLowerCase()))
                        StandaloneFoodScreen(
                          businessId: businessData?.id ?? "",
                          isGrid: true,
                          businessData: businessData,
                        ),
                    ],
                  ),
                ),
              );
            } else if (controller.viewBusinessResponse.status ==
                Status.LOADING) {
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
      ),
    );
  }

  // Widget buildRatingSummary({
  //   required double rating,
  //   List<RatingCountsListModel>? ratingsList,
  //   required String totalReviews,
  //   bool? allowRate,
  // }) {
  //   return Card(
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(SizeConfig.size16),
  //     ),
  //     elevation: 0,
  //     color: AppColors.white,
  //     child: Padding(
  //       padding: EdgeInsets.symmetric(
  //           horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
  //       child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisAlignment: MainAxisAlignment.start,
  //           children: [
  //             CustomText(
  //               "Rating Summary",
  //               fontWeight: FontWeight.w600,
  //               fontSize: SizeConfig.medium15,
  //               color: AppColors.secondaryTextColor,
  //             ),
  //             SizedBox(height: SizeConfig.size12),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: Row(
  //                     crossAxisAlignment: CrossAxisAlignment.center,
  //                     children: [
  //                       CustomText(
  //                         rating.toStringAsFixed(1),
  //                         fontWeight: FontWeight.w600,
  //                         fontSize: SizeConfig.size50,
  //                         color: AppColors.black,
  //                       ),
  //                       SizedBox(width: SizeConfig.size12),
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           AbsorbPointer(
  //                             absorbing: true,
  //                             child: RatingBar.builder(
  //                               initialRating: rating,
  //                               minRating: 1,
  //                               direction: Axis.horizontal,
  //                               allowHalfRating: false,
  //                               itemCount: 5,
  //                               itemSize: 16,
  //                               unratedColor: Colors.grey.shade400,
  //                               itemBuilder: (context, _) => const Icon(
  //                                 Icons.star,
  //                                 color: Colors.amber,
  //                               ),
  //                               onRatingUpdate: (rate) {
  //
  //                               },
  //                             ),
  //                           ),
  //                           SizedBox(height: SizeConfig.size4),
  //                           CustomText(
  //                             "${(totalReviews).toString()} Reviews",
  //                             fontSize: SizeConfig.size14,
  //                             fontWeight: FontWeight.w600,
  //                             color: AppColors.coloGreyText,
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 InkWell(
  //                   onTap: () => setState(() {
  //                     _isExpanded = !_isExpanded;
  //                   }),
  //                   child: Icon(
  //                     !_isExpanded
  //                         ? Icons.keyboard_arrow_down
  //                         : Icons.keyboard_arrow_up,
  //                     size: SizeConfig.size32,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //
  //             if (_isExpanded) const SizedBox(height: 16),
  //
  //             /// Expanded → Show detailed breakdown + Rate & Review UI
  //             if (_isExpanded && ratingsList != null) ...[
  //               /// Rating distribution bars
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   ...ratingsList
  //                       .map(
  //                         (rating) => _buildRatingRow(
  //                           rating.rating ?? 0,
  //                           rating.count ?? 0,
  //                         ),
  //                       )
  //                       .toList(),
  //                 ],
  //               ),
  //             ],
  //             (allowRate ?? true)
  //                 ? SizedBox(height: SizeConfig.size20)
  //                 : SizedBox(),
  //             (allowRate ?? true)
  //                 ? Center(
  //                     child: InkWell(
  //                       onTap: () => showDialog(
  //                         context: context,
  //                         barrierDismissible: true,
  //                         builder: (context) => RatingFeedbackDialog(businessId: widget.businessId,
  //                            reviewFor: AppConstants.business,)
  //                         //     buildRatingReviewWidget(
  //                         //   context,
  //                         //   (rating, review) async {
  //                         //     if (rating == 0) {
  //                         //       commonSnackBar(
  //                         //           message: "Please select a rating");
  //                         //
  //                         //       return;
  //                         //     }
  //                         //   },
  //                         // ),
  //                       ),
  //                       child: AbsorbPointer(
  //                         absorbing: true,
  //                         child: RatingBar.builder(
  //                           initialRating: 0,
  //                           minRating: 1,
  //                           direction: Axis.horizontal,
  //                           allowHalfRating: false,
  //                           itemCount: 5,
  //                           itemSize: 56,
  //                           unratedColor: Colors.grey.shade400,
  //                           itemBuilder: (context, _) => const Icon(
  //                             Icons.star_border,
  //                             color: Colors.amber,
  //                           ),
  //                           onRatingUpdate: (rate) {
  //                             setState(() {
  //                               rating = rate;
  //                             });
  //                           },
  //                         ),
  //                       ),
  //                     ),
  //                   )
  //                 : SizedBox(),
  //           ]),
  //     ),
  //   );
  // }

  // Widget _buildRatingRow(int stars, double percentage) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 2),
  //     child: Row(
  //       children: [
  //         Text("$stars ★", style: const TextStyle(fontSize: 14)),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: LinearProgressIndicator(
  //             value: percentage,
  //             backgroundColor: Colors.grey.shade300,
  //             color: Colors.blue,
  //             minHeight: 6,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget buildRatingReviewWidget(
  //   BuildContext context,
  //   void Function(int rating, String comments) onSubmit,
  // ) {
  //   int rating = 0;
  //   final TextEditingController reviewController = TextEditingController();
  //
  //   return Center(
  //     child: Wrap(
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.all(12.0),
  //           child: Center(
  //             child: Card(
  //               elevation: 0,
  //               child: StatefulBuilder(
  //                 builder: (context, setState) {
  //                   return Container(
  //                     margin: const EdgeInsets.all(16),
  //                     padding: const EdgeInsets.all(16),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(16),
  //                     ),
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         const Text(
  //                           "Rate And Review",
  //                           style: TextStyle(
  //                               fontSize: 20, fontWeight: FontWeight.bold),
  //                         ),
  //                         const SizedBox(height: 12),
  //
  //                         RatingBar.builder(
  //                           initialRating: rating.toDouble(),
  //                           minRating: 0,
  //                           direction: Axis.horizontal,
  //                           allowHalfRating: false,
  //                           itemCount: 5,
  //                           itemSize: 36,
  //                           unratedColor: Colors.grey.shade400,
  //                           itemBuilder: (context, index) => Icon(
  //                             rating >= index ? Icons.star : Icons.star_border,
  //                             color: Colors.amber,
  //                           ),
  //                           onRatingUpdate: (rate) {
  //                             setState(() {
  //                               rating = rate.toInt();
  //                             });
  //                           },
  //                         ),
  //                         const SizedBox(height: 16),
  //
  //                         // ✍ Review Box
  //                         Align(
  //                             alignment: Alignment.centerLeft,
  //                             child: CustomText(
  //                               "Write Your Review (Optional)",
  //                               fontSize: 14,
  //                               fontWeight: FontWeight.w500,
  //                             )),
  //                         const SizedBox(height: 8),
  //                         TextField(
  //                           controller: reviewController,
  //                           maxLines: 3,
  //                           decoration: InputDecoration(
  //                             hintText:
  //                                 'E.g. "Great service, quick response, highly recommended!"',
  //                             hintStyle: TextStyle(color: Colors.grey.shade400),
  //                             border: OutlineInputBorder(
  //                               borderRadius: BorderRadius.circular(10),
  //                             ),
  //                             filled: true,
  //                             fillColor: Colors.grey.shade50,
  //                           ),
  //                         ),
  //                         const SizedBox(height: 16),
  //
  //                         // 📸 Upload
  //                         Align(
  //                             alignment: Alignment.centerLeft,
  //                             child: CustomText(
  //                               "Share Image or Video (Optional)",
  //                               fontSize: 14,
  //                               fontWeight: FontWeight.w500,
  //                             ) /*const Text(
  //                             "",
  //                             style: TextStyle(
  //                                 fontSize: 14, fontWeight: FontWeight.w500),
  //                           ),*/
  //                             ),
  //                         const SizedBox(height: 8),
  //                         OutlinedButton.icon(
  //                           onPressed: () {},
  //                           icon: const Icon(Icons.upload_file_outlined),
  //                           label: const Text("Upload Image or Video"),
  //                           style: OutlinedButton.styleFrom(
  //                             minimumSize: const Size(double.infinity, 48),
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(10),
  //                             ),
  //                           ),
  //                         ),
  //                         const SizedBox(height: 20),
  //
  //                         // Buttons
  //                         Row(
  //                           children: [
  //                             Expanded(
  //                               child: CustomBtn(
  //                                 onTap: () => Get.back(),
  //                                 title: "Cancel",
  //                                 radius: 12,
  //                                 borderColor: AppColors.skyBlueDF,
  //                                 bgColor: AppColors.white,
  //                                 textColor: AppColors.skyBlueDF,
  //                               ),
  //                             ),
  //                             const SizedBox(width: 12),
  //                             Expanded(
  //                               child: CustomBtn(
  //                                 onTap: () async {
  //                                   // final success = await reviewController
  //                                   //     .submitBusinessRatingController(
  //                                   //   businessId: widget.businessId,
  //                                   // //  rating: selectedRating,
  //                                   //  // comment: _feedbackController.text.trim(),
  //                                   // );
  //                                   //
  //                                   // if (success && mounted) {
  //                                   //   Navigator.of(context).pop(success);
  //                                   //}
  //
  //                                 },
  //
  //
  //
  //                                     //onSubmit(rating, reviewController.text),
  //                                 title: "Submit",
  //                                 bgColor: AppColors.skyBlueDF,
  //                                 textColor: AppColors.white,
  //                                 radius: 12,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
                                    AppImageAssets.receivedIcon,
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

  Widget postsTab({BusinessProfileDetails? data}) {
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size10),
      child: FeedScreen(
        key: const ValueKey('feedScreen_others_posts'),
        postFilterType: PostType.otherPosts,
        isInParentScroll: true,
        id: data?.userId,
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
      // Full-width white so the header-through-tab-bar region is one white
      // block; the tab content below shows the app background.
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: AppColors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_CustomTabBarDelegate oldDelegate) => true;
}
