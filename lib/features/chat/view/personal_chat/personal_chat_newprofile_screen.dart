import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reelsModule/font_style.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

class BusinessProfilePersonalNewScreen extends StatelessWidget {
  const BusinessProfilePersonalNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return 
    Padding(
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
            rating: 4,
            totalReviews: "5,455",
          ),
          SizedBox(
            height: 20,
          ),
          buildTestimonialsCard(),
          SizedBox(
            height: 20,
          ),
          buildPostCard(),
          SizedBox(
            height: 20,
          ),
          buildHorizontalSortsList(),
          SizedBox(
            height: 20,
          ),
          customVideoCard(),
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
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
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
                    // SizedBox(height: SizeConfig.size6,),
                    CustomText(
                      "View Channel",
                      color: AppColors.skyBlueDF,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.skyBlueDF,
                    ),
                  ],
                ),
                SizedBox(
                  width: SizeConfig.size8,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CustomText(
                                  "Alex John",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: SizeConfig.size18,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(
                                  width: SizeConfig.size2,
                                ),
                                Icon(
                                  Icons.verified,
                                  color: AppColors.skyBlueDF,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: SizeConfig.size10,
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
                      SizedBox(height: SizeConfig.size1),
                      CustomText(
                        "$countryCode 23434544353",
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      SizedBox(height: SizeConfig.size6),
                      Row(
                        children: [
                          _buildTag("@alex_john"),
                          SizedBox(width: SizeConfig.size6),
                          _buildTag("UI/UX designer"),
                        ],
                      ),
                      SizedBox(
                        height: SizeConfig.size8,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: SizeConfig.size16,
                                    color: AppColors.black),
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
                          SizedBox(
                            width: SizeConfig.size8,
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: SizeConfig.size16,
                                    color: AppColors.black),
                                SizedBox(width: SizeConfig.size1),
                                Expanded(
                                  child: CustomText(
                                    "21 Sep, 2020",
                                    overflow: TextOverflow.ellipsis,
                                    color: AppColors.black,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: SizeConfig.size8,
                      ),
                      Row(
                        children: [
                          RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                  text: "20 ",
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: 16,
                                  ),
                                  children: [
                                    TextSpan(
                                        text: "Posts",
                                        style: TextStyle(
                                            color: AppColors.coloGreyText))
                                  ])),
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
                                    text: "500 ",
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
                                    text: "10K ",
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
          ],
        ),
      ),
    );
  }

  Widget _buildTag(
    String text, {
    Color borderColor = AppColors.greyA5,
    Color textColor = AppColors.black,
  }) {
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size4),
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
    required String totalReviews,
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

  Widget buildTestimonialsCard() {
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
              "Testimonials",
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
                    padding: EdgeInsets.all(SizeConfig.size10),
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

  Widget buildHorizontalSortsList() {
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
              "Sorts",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            SizedBox(
              height: SizeConfig.size300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Container(
                    width: SizeConfig.size190,
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
              "Videos",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SizeConfig.size12),
                  border: Border.all(color: AppColors.borderGray, width: 2)),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(SizeConfig.size12),
                              ),
                              child: Stack(
                                children: [
                                  Image.asset(
                                    "assets/images/first.jpg",
                                    height: SizeConfig.size220,
                                    width: double.infinity,
                                    fit: BoxFit.fill,
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 12,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.size12,
                                          vertical: SizeConfig.size4),
                                      decoration: BoxDecoration(
                                        color: AppColors.black1A,
                                        borderRadius: BorderRadius.circular(
                                            SizeConfig.size12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.thumb_up,
                                              size: SizeConfig.size20,
                                              color: Colors.blue),
                                          SizedBox(width: 4),
                                          Icon(Icons.favorite,
                                              size: SizeConfig.size20,
                                              color: Colors.red),
                                          SizedBox(width: 4),
                                          Icon(Icons.emoji_emotions,
                                              size: SizeConfig.size20,
                                              color: Colors.amber),
                                          SizedBox(width: 6),
                                          Text(
                                            "5k+",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: SizeConfig.size20,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: SizeConfig.size6,
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(SizeConfig.size12),
                              ),
                              child: Stack(
                                children: [
                                  Image.asset(
                                    "assets/images/first.jpg",
                                    height: SizeConfig.size220,
                                    width: double.infinity,
                                    fit: BoxFit.fill,
                                  ),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.size12,
                                          vertical: SizeConfig.size4),
                                      decoration: BoxDecoration(
                                        color: AppColors.black1A,
                                        borderRadius: BorderRadius.circular(
                                            SizeConfig.size12),
                                      ),
                                      child: Text(
                                        "02:53",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: SizeConfig.size20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: SizeConfig.size12,
                                          vertical: SizeConfig.size4),
                                      decoration: BoxDecoration(
                                        color: AppColors.black1A,
                                        borderRadius: BorderRadius.circular(
                                            SizeConfig.size12),
                                      ),
                                      child: Icon(
                                        Icons.volume_off,
                                        color: Colors.white,
                                        size: SizeConfig.size20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    child: Row(
                      children: [
                        Container(
                          height: SizeConfig.size40,
                          width: SizeConfig.size40,
                          decoration: BoxDecoration(
                              color: AppColors.red,
                              border: Border.all(
                                  color: AppColors.skyBlueDF, width: 2),
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.size12),
                              image: DecorationImage(
                                  image: AssetImage(
                                      "assets/images/brand_logo.png"))),
                        ),
                        SizedBox(width: SizeConfig.size8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                "Trying MC’s Burger for the first time!!! let's go and check ",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                fontWeight: FontWeight.w500,
                              ),
                              SizedBox(height: 4),
                              CustomText(
                                "TechSavvy   3.5 lakhs views   12 days ago",
                                color: AppColors.borderGray,
                                fontSize: SizeConfig.size12,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.grid_view,
                            size: SizeConfig.size20,
                            color: AppColors.borderGray),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }


}