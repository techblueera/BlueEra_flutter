import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/custom_carousel_slider.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/common_card_widget.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../../../widgets/local_assets.dart';
import '../../food/view/widget/km_away_text_widget.dart';

class ShopFeedScreen extends StatelessWidget {
  const ShopFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isTablet = width > 600;

    double dynamicSize(double base) => base * (width / 390); // Responsive scale base on 390px width

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        title: const Text("Shop Feed"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔹 Background Image
              Container(
                width: double.infinity,
                height: dynamicSize(270),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppImageAssets.storeNewbackground),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 🔹 Foreground White Container (with overlap effect)
              Transform.translate(
                offset: Offset(0, -dynamicSize(20)), // slight overlap for same look
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: dynamicSize(15)),
                  decoration: const BoxDecoration(
                    color: AppColors.whiteF1,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: dynamicSize(10)),
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 2,
                            width: 60,
                            color: AppColors.secondaryTextColor,
                          )
                        ],
                      ),
                      SizedBox(height: dynamicSize(24)),
                      HorizontalTabSelector(
                        horizontalMargin: 0,
                        horizontalPadding: 7,
                        verticalPadding: 2.5,
                        tabs: [
                          "All",
                          "Product",
                          "Service",
                          "Food",
                          "Store"
                        ],
                        selectedIndex: 0,
                        onTabSelected: (index, value) {

                        },
                        labelBuilder: (label) => label,
                      ),
                      SizedBox(height: dynamicSize(18)),
                      _buildMainPostCard(context, dynamicSize),
                      SizedBox(height: dynamicSize(10)),
                      Container(
                        margin: EdgeInsets.only(right: 20),
                        width: MediaQuery.of(context).size.width * 0.45,
                        // responsive width
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              child: CustomImageSlideshow(
                                isLoading: false,
                                width: double.infinity,
                                height: 170,
                                imagePaths: [],
                                borderRadius: BorderRadius.zero,
                              ),
                            ),

                            SizedBox(height: SizeConfig.size5),

                            // Title & price
                            Container(
                              height: SizeConfig.size20,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                              child: CustomText(
                                "Paneer Butter Masala Lorem Ipsum..",
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size5),
                            Container(
                              // height: SizeConfig.size20,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                              child: CustomText(
                                "Category of business",
                                fontSize: SizeConfig.small,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),

                            SizedBox(height: SizeConfig.size5),
                            Container(
                              // height: SizeConfig.size20,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                              child: CustomText(
                                "Business Name",
                                fontSize: SizeConfig.small,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size5),
                            Container(
                              // alignment: Alignment.center,
                              margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.green, borderRadius: BorderRadius.circular(30)),
                              child: CustomText(
                                "0% Off",
                                fontSize: SizeConfig.size10,
                                color: Colors.white,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size5),
                            KmAwayTextWidget(
                                lat:
                                "",
                                long:
                                ""),

                            SizedBox(height: SizeConfig.size5),
                          ],
                        ),
                      ),
                      SizedBox(height: dynamicSize(10)),
                      _buildProductCard(

                        imageUrl: "assets/store/shirt.png",
                        title: "Nike Sports Shoe Lorem Ipsum",
                        price: "₹61,499",
                        oldPrice: "₹88,000",
                        discount: "50% Off",

                      ),
                      SizedBox(height: dynamicSize(10)),
                      _buildProductCard(

                        imageUrl: "assets/store/shirt.png",
                        title: "Formal Shirt Men Lorem Ipsum",
                        price: "₹1,499",
                        oldPrice: "₹2,000",
                        discount: "50% Off",

                      ),
                      SizedBox(height: dynamicSize(10)),
                      _buildMainPostCard(context, dynamicSize),
                      SizedBox(height: dynamicSize(10)),


                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🏪 Main Post Card
  Widget _buildMainPostCard(BuildContext context, double Function(double) ds) {
    return Container(
      padding: EdgeInsets.all(ds(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ds(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: ds(1),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: ds(20),
                backgroundColor: Colors.black,
                child: Icon(Icons.store, color: Colors.white, size: ds(20)),
              ),
              SizedBox(width: ds(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store name and follow
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                "Gupta General St..",
                                style: TextStyle(
                                  fontSize: ds(15),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.whiteF1,
                                    ),
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                child: Center(
                                  child: CustomText("Since 1975",fontSize: 10,color: AppColors.secondaryTextColor,),
                                ),
                              )
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ds(8),
                            vertical: ds(4),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(ds(20)),
                          ),
                          child: Text(
                            "Follow",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ds(11),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ds(4)),
                    Row(
                      children: [
                        Text(
                          "Nursing Home  ",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: ds(12),
                          ),
                        ),
                        Row(
                          children: [
                            LocalAssets(imagePath: AppIconAssets.star,height: 12,width: 12,),
                            Text(
                              " 4.5",
                              style: TextStyle(
                                color: AppColors.orangelite,
                                fontSize: ds(12),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          " Rating",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: ds(12),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ds(4)),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.whiteF1,
                              ),
                              borderRadius: BorderRadius.circular(10)
                          ),
                          child: Center(
                            child: CustomText("4.5Km Away",fontSize: 10,color: AppColors.secondaryTextColor,),
                          ),
                        ),
                        SizedBox(width: ds(4)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.whiteF1,
                              ),
                              borderRadius: BorderRadius.circular(10)
                          ),
                          child: Center(
                            child: CustomText("Pratap Nagar, Lucknow",fontSize: 10,color: AppColors.secondaryTextColor,),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: ds(10)),
          Text(
            "Lorem ipsum dolor sit amet, consectetur adipis elit. Nunc vulputate libero et velit interdum...",
            style: TextStyle(fontSize: ds(13), color: Colors.black),
          ),
          SizedBox(height: ds(6)),
          Text(
            "https://blueera.ai",
            style: TextStyle(
              color: Colors.blue,
              fontSize: ds(13),
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: ds(12)),

          // Image grid
          ClipRRect(
            borderRadius: BorderRadius.circular(ds(12)),
            child: Row(
              children: [
                Expanded(
                  child: Image.asset(
                    "assets/store/shoe1.png",
                    height: ds(180),
                    fit: BoxFit.cover,
                  ),
                ),

                Expanded(
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/store/shoe2.png",
                        height: ds(90),
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: ds(2)),
                      Image.asset(
                        "assets/store/shoe3.png",
                        height: ds(90),
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: ds(12)),

          // Interaction row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  LocalAssets(imagePath: AppIconAssets.store_watch),
                  SizedBox(width: ds(4)),
                  CustomText("5 days ago",
                    fontSize: ds(8),
                    color: AppColors.secondaryTextColor,

                  ),
                  SizedBox(width: ds(6)),
                  LocalAssets(imagePath: AppIconAssets.eye_new),
                  SizedBox(width: ds(4)),
                  CustomText("25K",
                    fontSize: ds(8),
                    color: AppColors.secondaryTextColor,

                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4,vertical: 4),
                    decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: AppColors.whiteF1,
                        ),
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Center(
                      child: Icon(Icons.star_border, size: ds(13)),
                    ),
                  ),

                  SizedBox(width: ds(6)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4,vertical: 4),
                    decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: AppColors.whiteF1,
                        ),
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Center(
                      child: LocalAssets(imagePath: AppIconAssets.share_bold,height: 13,width: 13,),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildProductCard({
    required String imageUrl,
    required String title,
    required String price,
    required String oldPrice,
    required String discount,
  }) {
    return Container(

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🖼️ Product Image
          ClipRRect(
            child: Image.asset(
              imageUrl,
              height: 220, // Increased height
              width: 140,
              fit: BoxFit.cover,
            ),
          ),

          SizedBox(width: 14),

          /// 📄 Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 9.0,bottom: 8,right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Title + 3-dot menu row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),

                  SizedBox(height: 6),

                  /// Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        discount,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        oldPrice,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  /// Size Chips
                  Row(
                    children: [
                      _buildSizeChip("7UK"),
                      SizedBox(width: 8),
                      _buildSizeChip("8UK"),
                      SizedBox(width: 8),
                      _buildSizeChip("9UK"),
                      SizedBox(width: 8),
                      _buildSizeChip("+2"),
                    ],
                  ),

                  SizedBox(height: 10),

                  /// Color Dots - removed spacing between dots
                  Row(
                    children: [
                      _buildColorDot(Colors.black),
                      _buildColorDot(Colors.grey.shade400),
                      _buildColorDot(Colors.red),
                      _buildColorDot(Colors.orange),
                      _buildColorDot(Colors.purple),
                      _buildColorDot(Colors.grey.shade200, hasMore: true),
                    ],
                  ),

                  SizedBox(height: 12),

                  /// Shop + Location Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.deepPurple.shade700,
                        child: Icon(Icons.store, size: 12, color: Colors.white),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Pervez Mobile Shop",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),

                    ],
                  ),
                  const SizedBox(height: 8,),
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border:Border.all(
                        color: Colors.blue,
                      )
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on,
                            size: 10, color: Colors.blue.shade600),
                        SizedBox(width: 4),
                        CustomText(
                          "100 Km away",
                             fontSize: 8,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSizeChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        text,
        // style: TextStyle(
          fontSize: 12,
          color: AppColors.secondaryTextColor,
          fontWeight: FontWeight.w500,
        // ),
      ),
    );
  }

  Widget _buildColorDot(Color color, {bool hasMore = false}) {
    return Container(
      height: 18,
      width: 18,
      decoration: BoxDecoration(
        color: hasMore ? Colors.white : color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: hasMore
          ? Center(
        child: Text(
          "+2",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      )
          : null,
    );
  }

// 🛍️ Product Card
  // Widget _buildProductCard(
  //     BuildContext context, {
  //       required String imageUrl,
  //       required String title,
  //       required String price,
  //       required String oldPrice,
  //       required String discount,
  //       required double Function(double) dynamicSize,
  //     }) {
  //   return Container(
  //     margin: EdgeInsets.all(dynamicSize(10)),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(dynamicSize(14)),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black12,
  //           blurRadius: dynamicSize(6),
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: Padding(
  //       padding: EdgeInsets.all(dynamicSize(12)),
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Product image
  //           ClipRRect(
  //             borderRadius: BorderRadius.circular(dynamicSize(10)),
  //             child: Image.asset(
  //               imageUrl,
  //               height: dynamicSize(130),
  //               width: dynamicSize(110),
  //               fit: BoxFit.cover,
  //             ),
  //           ),
  //           SizedBox(width: dynamicSize(10)),
  //
  //           // Product details
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // Title
  //                 Text(
  //                   title,
  //                   style: TextStyle(
  //                     fontSize: dynamicSize(14),
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                   maxLines: 2,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //                 SizedBox(height: dynamicSize(6)),
  //
  //                 // Price
  //                 Row(
  //                   children: [
  //                     Text(
  //                       price,
  //                       style: TextStyle(
  //                         fontSize: dynamicSize(16),
  //                         color: Colors.blue.shade700,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     SizedBox(width: dynamicSize(6)),
  //                     Text(
  //                       discount,
  //                       style: TextStyle(
  //                         color: Colors.green,
  //                         fontSize: dynamicSize(12),
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                     SizedBox(width: dynamicSize(6)),
  //                     Text(
  //                       oldPrice,
  //                       style: TextStyle(
  //                         color: Colors.grey,
  //                         fontSize: dynamicSize(12),
  //                         decoration: TextDecoration.lineThrough,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //
  //                 SizedBox(height: dynamicSize(8)),
  //
  //                 // Shop Info
  //                 Row(
  //                   children: [
  //                     const Icon(Icons.store, size: 14, color: Colors.blue),
  //                     SizedBox(width: dynamicSize(4)),
  //                     Text(
  //                       "Pervez Mobile Shop",
  //                       style: TextStyle(fontSize: dynamicSize(12)),
  //                     ),
  //                     const Spacer(),
  //                     Icon(Icons.location_on, size: 14, color: Colors.blue),
  //                     Text(
  //                       " 100 Km",
  //                       style: TextStyle(fontSize: dynamicSize(12), color: Colors.blue),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

