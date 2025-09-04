import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/abourt_business_widget.dart';
import 'package:BlueEra/features/business/widgets/header_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_info_widget.dart';
import 'package:BlueEra/features/business/widgets/rating_widget.dart';
import 'package:BlueEra/features/chat/view/business_chat/bussiness_chat_newprofile_screen.dart';
import 'package:BlueEra/features/chat/view/widget/business_chat_header.dart';
import 'package:BlueEra/features/chat/view/widget/business_chat_overview.dart';

import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../common/reel/view/sections/shorts_channel_section.dart';
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
    return BussinessProfileNewscreen();

    print("sdns${widget.userId}");
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
          // if (controller.viewBusinessResponse.status == Status.ERROR) {
          //   return  Center(child: CustomText("No business found"));
          // }
          final businessData = controller.visitedBusinessProfileDetails?.data;
          return DefaultTabController(
            length: tabs.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 18.0, left: 18, right: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeaderWidgets(
                          businessId: widget.userId,
                          userId: businessData?.userId ?? "",
                          businessName:
                              businessData?.businessName ?? "Business Name",
                          logoUrl: businessData?.logo ?? "",
                          businessType:
                              businessData?.typeOfBusiness ?? "Business",
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
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BusinessChatProfileOverview(
                          userId: '',
                        ),
                        const SizedBox(height: 30),
                        BusinessLocationWidget(
                          latitude:
                              businessData?.businessLocation?.lat?.toDouble() ??
                                  0.0,
                          longitude:
                              businessData?.businessLocation?.lon?.toDouble() ??
                                  0.0,
                          businessName: businessData?.businessName ?? "N/A",
                          isTitleShow: true,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        CustomText(
                          "Products",
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return buildProductCard(
                                imageUrl: product["imageUrl"],
                                title: product["title"],
                                price: product["price"],
                                oldPrice: product["price"],
                                discount: product["discount"],
                                rating: product["rating"],
                                reviews: product["reviews"].toString(),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Courtney Henry",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Row(
                                          children: const [
                                            Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                            Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                            Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                            Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                            Icon(Icons.star_half,
                                                color: Colors.amber, size: 16),
                                            SizedBox(width: 6),
                                            Text("2 mins ago",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
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
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.thumb_up,
                                            color: Colors.blue),
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
                        ),
                        const SizedBox(height: 24),
                        //Add product ui here
                        const Text('Post',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 500,
                          child: FeedScreen(
                            key: ValueKey(
                                'feedScreen_user_posts_${widget.userId}'),
                            postFilterType: PostType.otherPosts,
                            isInParentScroll: true,
                            id: widget.userId,
                          ),
                        ),
                        const SizedBox(height: 16),
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

  Widget buildProductCard({
    required String imageUrl,
    required String title,
    required String price,
    required String oldPrice,
    required String discount,
    required String rating,
    required String reviews,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported, size: 50),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black),
                ),
                Row(
                  children: [
                    Text(
                      oldPrice,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      discount,
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      "$rating ",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    // Text(
                    //   "($reviews reviews)",
                    //   style: const TextStyle(color: Colors.grey, fontSize: 12),
                    // ),
                  ],
                ),
              ],
            ),
          ),
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
