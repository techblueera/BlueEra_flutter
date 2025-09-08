import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reelsModule/font_style.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';

class BussinessProfileNewscreen extends StatelessWidget {
  const BussinessProfileNewscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size10),
      child: Column(
        children: [
          widget_profileHeader(),
          SizedBox(
            height: SizeConfig.size12,
          ),
          buildCustomTabRow(
            selectedIndex: 0,
            onTabSelected: (p0) {},
          ),
          SizedBox(
            height: SizeConfig.size8,
          ),
          buildRatingSummary(
            rating: 3,
            totalReviews: 18,
          ),
          SizedBox(
            height: 20,
          ),
          buildLocationContainer(
            address:
                "Form ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum.",
            onSendLocation: () {
              print("Send location tapped!");
            },
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
          buildPostCard(),
          SizedBox(
            height: 20,
          ),
          buildJobCard(),
          SizedBox(
            height: 100,
          ),
        ],
      ),
    );
  }

  widget_profileHeader() {
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
                              "McDonalds King Burger",
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
                            title: "Follow",
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
                          _buildTag("Closed",
                              borderColor: AppColors.red,
                              textColor: AppColors.red),
                          SizedBox(width: SizeConfig.size6),
                          _buildTag("14.2 KM Far"),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                CustomText(
                  "View Channel",
                  color: AppColors.skyBlueDF,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.skyBlueDF,
                ),
                SizedBox(
                  width: SizeConfig.size12,
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: SizeConfig.size16, color: AppColors.black),
                      SizedBox(width: SizeConfig.size1),
                      Expanded(
                        child: CustomText(
                          "Gomti Nagar, Lucknow",
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
              "Korem ipsum dolor sit amet, consectetur adipiscing elit. Nunc "
              "vulputate libero et velit interdum, ac Korem ipsum dolor sit amet, consectetur adipiscing elit. Nunc Korem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ",
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
                      _buildInfo("Rating", "★ 4.8"),
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
                        "1/1/2024",
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

  Widget buildCustomTabRow({
    required int selectedIndex,
    required Function(int) onTabSelected,
  }) {
    final tabs = ["Overview", "Product", "Reviews", "Post", "Jobs"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size6, vertical: SizeConfig.size8),
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.skyBlueDF : AppColors.white,
                borderRadius: BorderRadius.circular(SizeConfig.size12),
                border: Border.all(
                  color: isSelected ? AppColors.skyBlueDF : AppColors.black,
                  width: 1,
                ),
              ),
              child: CustomText(
                tabs[index],
                color: isSelected ? AppColors.white : AppColors.coloGreyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
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

  Widget buildLocationContainer({
    required String address,
    required VoidCallback onSendLocation,
  }) {
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.black1A),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                    child: CustomText(
                  address,
                  fontSize: SizeConfig.size14,
                  color: AppColors.black1A,
                )),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SizeConfig.size12),
                  child: Image.asset(
                    "assets/images/map_image.jpeg",
                    height: SizeConfig.size180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onSendLocation,
                    child: Container(
                      padding: EdgeInsets.all(SizeConfig.size12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.blueDF, width: 2),
                      ),
                      child: Transform.rotate(
                        angle: -0.6,
                        child: const Icon(
                          Icons.send_outlined,
                          color: AppColors.blueDF,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget buildPostCard() {
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
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(SizeConfig.size12),
                        topRight: Radius.circular(SizeConfig.size12)),
                    child: Image.asset(
                      "assets/images/burger.png",
                      height: SizeConfig.size200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "Top 10 AI Tools You Should Know in 2025",
                          fontSize: SizeConfig.size16,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          "Stay Ahead with These Game-Changing AI Tools",
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
                  SizedBox(
                    height: SizeConfig.size16,
                  ),
                ],
              ),
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
}
