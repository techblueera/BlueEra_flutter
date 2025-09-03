import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class EarnBlueeraScreen extends StatefulWidget {
  const EarnBlueeraScreen({super.key});

  @override
  State<EarnBlueeraScreen> createState() => _EarnBlueeraScreenState();
}

class _EarnBlueeraScreenState extends State<EarnBlueeraScreen> {
  String? selectCategory = "Select Category"; // Stores the selected value
  final List<String> selectCategoryList = [
    "All",
    "Via Online tutorial",
    "Via Offline servies",
    "Via Online Counselling ",
    "Book Appointment",
    "Sponsorship"
  ];
  // late VideoPlayerController _controller;
  // List<String> videoUrls = [
  //   'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  //   'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  //   'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  //   'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
  //   'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Icon(Icons.arrow_back_ios)),
        title: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText("Earn With BlueEra",
                fontSize: SizeConfig.large,
                color: AppColors.black,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(width: SizeConfig.size14),
            Expanded(
              child: CommonDropdown<String>(
                items: selectCategoryList,
                selectedValue: selectCategory,
                hintText: 'Select Category',
                onChanged: (val) {
                  setState(() {
                    selectCategory = val;
                  });
                },
                displayValue: (item) => item,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              physics: AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Widget_vedioContainer();
              },
            ),
          )
        ],
      ),
    );
  }

  Widget_vedioContainer() {
    return Container(
      margin: EdgeInsets.all(10),
      color: AppColors.white,
      child: Column(
        children: [
          Container(
              margin: EdgeInsets.all(5),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child:
                      Image.network("https://jpeg.org/images/aic-home.jpg"))),
          ListTile(
            leading: Card(
              // margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.person),
              ),
            ),
            title: CustomText(
              'Math Made Easy -Learn Smarter, Not Harder',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            subtitle: Row(
              children: [
                CustomText(
                  'BlueEra ',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
                CustomText(
                  '3.5lakh views ',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
                CustomText(
                  '12 days ago ',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ],
            ),
            trailing: Icon(Icons.window),
          )
        ],
      ),
    );
  }
}
