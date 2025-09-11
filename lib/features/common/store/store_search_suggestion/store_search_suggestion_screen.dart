// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/widgets/commom_textfield.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import 'store_search_suggestion_controller.dart';

// class StoreSearchSuggestionScreen extends StatelessWidget {
//   const StoreSearchSuggestionScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<StoreSearchSuggestionController>(
//       init: StoreSearchSuggestionController(),
//       builder: (controller) {
//         return
//          Scaffold(
//           // backgroundColor: AppColors.white,
//           body: SafeArea(
//             child: Column(
//               children: [
//                 // Header Section with Search Bar
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: SizeConfig.size16,
//                     vertical: SizeConfig.size12,
//                   ),
//                   child: Row(
//                     children: [
//                       // Back Button
//                       GestureDetector(
//                         onTap: () => Get.back(),
//                         child: const Icon(
//                           Icons.arrow_back_ios,
//                           color: AppColors.black,
//                           size: 20,
//                         ),
//                       ),
//                       SizedBox(width: SizeConfig.size12),
//                       Expanded(
//                         child: CommonTextField(
//                           textEditController: controller.searchController,
//                           onChange: (value) {
//                             controller.searchBusinesses(value);
//                           },
//                           hintText: 'Search businesses...',
//                           isValidate: false,

//                         ),
//                       ),
//                       // Search Bar
//                     /*  Expanded(
//                         child: Container(
//                           height: 45,
//                           padding: EdgeInsets.symmetric(
//                             horizontal: SizeConfig.size12,
//                           ),
//                           decoration: BoxDecoration(
//                             color: AppColors.fillColor,
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: AppColors.greyE5,
//                               width: 1,
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.search,
//                                 color: AppColors.grey9B,
//                                 size: 20,
//                               ),
//                               SizedBox(width: SizeConfig.size8),
//                               Expanded(
//                                 child: TextField(
//                                   controller: controller.searchController,
//                                   style: const TextStyle(
//                                     color: AppColors.black,
//                                     fontSize: 14,
//                                   ),
//                                   decoration: const InputDecoration(
//                                     hintText: 'Search businesses...',
//                                     hintStyle: TextStyle(
//                                       color: AppColors.grey9B,
//                                       fontSize: 14,
//                                     ),
//                                     border: InputBorder.none,
//                                   ),
//                                   onChanged: (value) {
//                                     controller.searchBusinesses(value);
//                                   },
//                                 ),
//                               ),
//                               if (controller.searchController.text.isNotEmpty)
//                                 GestureDetector(
//                                   onTap: () {
//                                     controller.searchController.clear();
//                                     controller.clearSearchResults();
//                                   },
//                                   child: const Icon(
//                                     Icons.close,
//                                     color: AppColors.grey9B,
//                                     size: 20,
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ),*/
//                     ],
//                   ),
//                 ),

//                 // Content Sections
//                 Expanded(
//                   child: Obx(() {
//                     if (controller.isLoading.value) {
//                       return const Center(child: CircularProgressIndicator());
//                     } else if (controller.searchResults.isEmpty && controller.searchController.text.isNotEmpty) {
//                       return Center(child: CustomText('No results found'));
//                     } else if (controller.searchResults.isEmpty) {
//                       return Center(child: CustomText('Search for businesses'));
//                     } else {
//                       return ListView.builder(
//                         itemCount: controller.searchResults.length,
//                         itemBuilder: (context, index) {
//                           final business = controller.searchResults[index];
//                           return ListTile(
//                             title: CustomText(
//                               business.businessName ?? 'Unknown Business',
//                               fontSize: SizeConfig.medium,
//                               fontWeight: FontWeight.w500,
//                             ),
//                             subtitle: business.categoryOfBusiness?.name != null
//                                 ? CustomText(
//                                     business.categoryOfBusiness!.name,
//                                     fontSize: SizeConfig.small,
//                                     color: AppColors.secondaryTextColor,
//                                   )
//                                 : null,
//                             onTap: () {
//                               controller.onBusinessSelected(business,context);
//                             },
//                           );
//                         },
//                       );
//                     }
//                   }),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }


import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';

import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reelsModule/font_style.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../personal/personal_profile/view/visit_personal_profile/visit_personal_profile.dart';

class BusinessChatProfile extends StatefulWidget {
  final String userId;
  const BusinessChatProfile({super.key, required this.userId});

  @override
  State<BusinessChatProfile> createState() => BusinessChatProfileState();
}

class BusinessChatProfileState extends State<BusinessChatProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(ViewBusinessDetailsController());
  // final ScrollController _scrollController = ScrollController();
  final List<String> tabs = [
    'Overview',
    'Product',
    'Reviews',
    'Posts',
    "Job"
    //
    // 'Our Branches'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Ensure your VisitPersonalProfileTabs updates
    });

    controller.viewBusinessProfileById(widget.userId);
    controller.getAllProductsApi({ApiKeys.limit: 0});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> products = [
    {
      "imageUrl":
          "https://slicecover.com/cdn/shop/files/14proSMCskyblue.png?v=1709805718&width=2000",
      "title": "Apple iPhone 16",
      "price": "₹61,499",
      "originalPrice": "₹98,000",
      "discount": "50% Off",
      "shop": "Pervez Mobile Shop",
      "rating": "4.8 ",
      'reviews': "48 reviews"
    },
    {
      "imageUrl":
          "https://slicecover.com/cdn/shop/files/14proSMCskyblue.png?v=1709805718&width=2000",
      "title": "Apple iPhone 16",
      "price": "₹61,499",
      "originalPrice": "₹98,000",
      "discount": "50% Off",
      "shop": "Pervez Mobile Shop",
      "rating": "4.8 (48 reviews)",
      'reviews': "48 reviews"
    },
    {
      "imageUrl":
          "https://slicecover.com/cdn/shop/files/14proSMCskyblue.png?v=1709805718&width=2000",
      "title": "Apple iPhone 16",
      "price": "₹61,499",
      "originalPrice": "₹98,000",
      "discount": "50% Off",
      "shop": "Pervez Mobile Shop",
      "rating": "4.8 ",
      'reviews': "48 reviews"
    },
  ];

  @override
  Widget build(BuildContext context) {
    print("sdns${widget.userId}");
    // if(isOwnChannel){
    //       response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
    //     }else {
    //       response = await ChannelRepo().getAllChannelVideos(channelOrUserId: channelOrUserId, queryParams: params);
    //     }
    // BussinessProfileNewscreen

    return 
    Scaffold(
      appBar: CommonBackAppBar(),
      body: GetBuilder<ViewBusinessDetailsController>(
        builder: (controller) {
          if (controller.viewBusinessResponse.status == Status.LOADING) {
            return const Center(child: CircularProgressIndicator());
          }
          // if (controller.viewBusinessResponse.status == Status.ERROR) {
          //   return  Center(child: CustomText("No business found"));
          // }
          final businessData = controller.visitedBusinessProfileDetails?.data;
          print(businessData?.userId ?? "" + "=======================");
          return DefaultTabController(
            length: tabs.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: widget_profileHeader(businessData),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CustomTabBarDelegate(
                    VisitPersonalProfileTabs(
                      onTab: (index) {
                        if (index == 3) {
                          Map<String, dynamic> data = {
                            ApiKeys.businessId: widget.userId
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
                    padding:
                        const EdgeInsets.only(left: 12, right: 12, top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildRatingSummary(
                          rating: (businessData?.rating??0).toDouble(),
                          totalReviews: 18,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        BusinessLocationWidget(
                          latitude:
                              businessData?.businessLocation?.lat?.toDouble() ??
                                  0.0,
                          longitude:
                              businessData?.businessLocation?.lon?.toDouble() ??
                                  0.0,
                          businessName: businessData?.businessName ?? "N/A",
                          isTitleShow: true,
                          locationText: businessData?.address??"",
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        buildHorizontalProductList(),
                        SizedBox(
                          height: 20,
                        ),
                        buildReviewCard(),
                        SizedBox(
                          height: 20,
                        ),
                      
                        buildPostCard(controller: controller),
                        SizedBox(
                          height: 20,
                        ),
                        buildJobCard(),
                        SizedBox(
                          height: 100,
                        ),
                      ],
                    ),
                  ),

                  // product tab
                  productTab(),
                  reviewTab(),
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

  widget_profileHeader(BusinessProfileDetails? businessData) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      child: Card(
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
                  Container(
                    margin: EdgeInsets.all(SizeConfig.size10),
                    padding: EdgeInsets.all(SizeConfig.size3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: SizeConfig.size28,
                      backgroundColor: AppColors.red,
                      child: Image.asset("assets/images/brand_logo.png"),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                businessData?.userId ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                fontSize: SizeConfig.size18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.size16,
                            ),
                            CustomBtn(
                              onTap: () {},
                              title: businessData?.is_following == true
                                  ? "Unfollow"
                                  : "Follow",
                              fontWeight: FontWeight.bold,
                              height: SizeConfig.size30,
                              bgColor: AppColors.skyBlueDF,
                              width: SizeConfig.size60,
                              radius: SizeConfig.size12,
                            ),
                            SizedBox(
                              width: SizeConfig.size4,
                            ),
                            Icon(Icons.more_vert)
                          ],
                        ),
                        SizedBox(height: SizeConfig.size6),
                        Row(
                          children: [
                            _buildTag("Restaurant"),
                            SizedBox(width: SizeConfig.size6),
                            // _buildTag("Closed",
                            //     borderColor: AppColors.red,
                            //     textColor: AppColors.red),
                            // SizedBox(width: SizeConfig.size6),
                            // _buildTag("14.2 KM Far"),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // CustomText(
                  //   "View Channel",
                  //   color: AppColors.skyBlueDF,
                  //   fontWeight: FontWeight.w600,
                  //   decoration: TextDecoration.underline,
                  //   decorationColor: AppColors.skyBlueDF,
                  // ),
                  SizedBox(
                    width: SizeConfig.size12,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: SizeConfig.size16, color: AppColors.black),
                        SizedBox(width: SizeConfig.size1),
                        CustomText(
                    "14.2KM Far-",
                    color: AppColors.skyBlueDF,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.skyBlueDF,
                  ),
                    SizedBox(width: SizeConfig.size1),
                        Expanded(
                          child: CustomText(
                            businessData?.address ?? "",
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.black,
                          ),
                        )
                      ],
                    ),
                  ),
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
                    vertical: SizeConfig.size12, horizontal: SizeConfig.size24),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(SizeConfig.size12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfo("Rating", "★ ${businessData?.rating ?? 0}"),
                        SizedBox(
                          height: SizeConfig.size6,
                        ),
                        _buildInfo("Views", "75"),
                      ],
                    ),
                    SizedBox(
                      height: SizeConfig.size40,
                      child: VerticalDivider(
                        color: AppColors.coloGreyText,
                        width: 2,
                        thickness: 1.2,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfo("Inquiries", "25"),
                        SizedBox(
                          height: SizeConfig.size6,
                        ),
                        _buildInfo("Followers", "50k"),
                      ],
                    ),
                    SizedBox(
                      height: SizeConfig.size40,
                      child: VerticalDivider(
                        color: AppColors.coloGreyText,
                        width: 2,
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
                          fontWeight: FontWeight.w500,
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                            businessData?.dateOfIncorporation==null?"": "${businessData?.dateOfIncorporation?.date??""}/${getMonthName(businessData?.dateOfIncorporation?.month ?? 1)}/${businessData?.dateOfIncorporation?.year??""}",
                          fontSize: SizeConfig.size14,
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

  Widget buildRatingSummary({
    required double rating,
    required int totalReviews,
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
                        rating.toStringAsFixed(1),
                        fontWeight: FontWeight.bold,
                        fontSize: SizeConfig.size40,
                        color: AppColors.black,
                      ),
                      SizedBox(width: SizeConfig.size12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating.floor()
                                    ? Icons.star
                                    : (index < rating
                                        ? Icons.star_half
                                        : Icons.star_border),
                                color: AppColors.yellow,
                                size: SizeConfig.size22,
                              );
                            }),
                          ),
                          SizedBox(height: SizeConfig.size4),
                          CustomText(
                            "${totalReviews.toString()} Reviews",
                            fontSize: SizeConfig.size14,
                            color: AppColors.coloGreyText,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: SizeConfig.size32,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return Icon(Icons.star_border,
                    color: AppColors.coloGreyText, size: SizeConfig.size32);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHorizontalProductList() {
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
              "Products",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            SizedBox(
              height: SizeConfig.size280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Container(
                    width: SizeConfig.size200,
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
                          child: Image.asset(
                            "assets/images/camera_stand.png",
                            height: SizeConfig.size150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(SizeConfig.size8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                "Apple iPhone 16",
                                fontSize: SizeConfig.size16,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(height: SizeConfig.size2),
                              CustomText(
                                "₹61,499",
                                fontSize: SizeConfig.size15,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(height: SizeConfig.size2),
                              CustomText(
                                "50% Off ₹98,000",
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
                                    "4.8",
                                    fontSize: SizeConfig.size14,
                                    color: AppColors.coloGreyText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(width: SizeConfig.size4),
                                  CustomText(
                                    "(48 reviews)",
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
            Container(
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
                            borderRadius:
                                BorderRadius.circular(SizeConfig.size12),
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
                            borderRadius:
                                BorderRadius.circular(SizeConfig.size12),
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
                  Divider(
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
                        children: const [
                          CustomText("5K+"),
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
                        children: const [
                          CustomText("310"),
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildPostCard({ required ViewBusinessDetailsController controller}) {
       List<Post> posts = List.from( controller.postsResponse.value.data);
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
            ListView.builder(itemCount: posts.length,
              itemBuilder: (context, index) {
              
          var data=posts[index];
            
                return Container(
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
                        child: Image.network(data.media?.first??"")
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              data.message??"",
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
                            children:   [
                              CustomText((data.likesCount??"").toString()),
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
                            children:   [
                              CustomText((data.commentsCount??"").toString()),
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
                );
              }
            ),
          ],
        ),
      ),
    );
  }

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
                              title: "Apply Now",
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

  GridView productTab() {
    return GridView.builder(
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 items per row
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65, // controls height of card
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  product["imageUrl"],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product["title"],
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      product["price"],
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black),
                    ),
                    Text(
                      "${product["discount"]} ${product["originalPrice"]}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.store, size: 14, color: Colors.black54),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product["shop"],
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 14),
                        SizedBox(width: 4),
                        Text(
                          product["rating"],
                          style: TextStyle(fontSize: 12),
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
    );
  }

  Card reviewTab() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Row
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    "https://randomuser.me/api/portraits/women/44.jpg",
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Courtney Henry",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Icon(Icons.star_half, color: Colors.amber, size: 16),
                        SizedBox(width: 6),
                        Text("2 mins ago",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Review Text
            const Text(
              "Yorem ipsum dolor sit amet, consectetur adipiscing elit. "
              "Nunc vulputate libero et velit interdum, ac aliquet odio mattis. "
              "Class aptent taciti sociosqu ad litora torquent.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Images
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://www.insidehook.com/wp-content/uploads/2021/07/cokezero-h.jpg?fit=1200%2C800",
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://www.insidehook.com/wp-content/uploads/2021/07/cokezero-h.jpg?fit=1200%2C800",
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.thumb_up, color: Colors.blue),
                    SizedBox(width: 5),
                    Text("5k+"),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.comment, color: Colors.grey),
                    SizedBox(width: 5),
                    Text("310"),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.share, color: Colors.grey),
                    SizedBox(width: 5),
                    Text("50"),
                  ],
                ),
              ],
            ),
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
