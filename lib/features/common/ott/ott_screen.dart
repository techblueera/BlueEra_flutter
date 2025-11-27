import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// -----------------------------------------------------------------------------
// 1. DATA MODELS & STATIC DATA
// -----------------------------------------------------------------------------

class ChannelModelNew {
  final String name;
  final String imageUrl;
  final Color color;

  ChannelModelNew(this.name, this.imageUrl, this.color);
}

class VideoModel {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String channelIcon;
  final String views;
  final bool isLive;

  VideoModel({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.channelIcon,
    this.views = "27K views • 1 day ago",
    this.isLive = false,
  });
}

// -----------------------------------------------------------------------------
// 2. GETX CONTROLLER (State Management)
// -----------------------------------------------------------------------------

class HomeController extends GetxController {
  // Reactive variable for the carousel current index
  var currentCarouselIndex = 0.obs;

  // --- HARD CODED STATIC DATA ---

  final List<String> carouselImages = [
    "https://media.istockphoto.com/id/1183338499/vector/0547.jpg?s=612x612&w=0&k=20&c=yNkIf4DxCEkOb0EXoq5kQ0XX1k5T53QYQLgL_j2Rg5M=",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcScvOOUHSd2NfqUfwdapGmMSelaucVhgInkRg&s",
    "https://mir-s3-cdn-cf.behance.net/projects/404/351796219634157.Y3JvcCw5ODMsNzY5LDE0OCww.jpg",
  ];

  final List<ChannelModelNew> joinedChannels = [
    ChannelModelNew(
        "Memes",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRr78LHeesQnqsZ2Wn_0gtsMfnW7R7np8cF3Q&s",
        Colors.red),
    ChannelModelNew(
        "Aaj Tak",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSMx4iIwuXN06vqEOkxCd7dzurVykyDu0pdoQ&s",
        Colors.redAccent),
    ChannelModelNew(
        "ABP News",
        "https://exchange4media.gumlet.io/news-photo/109657-abplogo.jpg",
        Colors.red),
    ChannelModelNew(
        "Yoga Live",
        "https://yt3.googleusercontent.com/gC3DWxd3mXGoqF6hbbhFKMPX1BIOe-G8uHKg5w8M0aEP5W3Q24asx0oceTl_Y6vA0JZ2L2CGOw=s900-c-k-c0x00ffffff-no-rj",
        Colors.grey),
    ChannelModelNew(
        "FUTURE",
        "https://i.pinimg.com/280x280_RS/17/11/55/1711550cc94f7837430b514475df73cb.jpg",
        Colors.blue),
  ];

  final List<VideoModel> continueWatching = [
    VideoModel(
      title: "SSC EXAMS 2024",
      subtitle: "Best way to crack...",
      imageUrl:
          "https://img.freepik.com/free-psd/education-youtube-thumbnail-design-template_23-2149225648.jpg",
      channelIcon: "",
    ),
    VideoModel(
      title: "Daily Current Affairs",
      subtitle: "MCQs + Statics GK",
      imageUrl:
          "https://img.freepik.com/free-vector/modern-youtube-thumbnail-with-flat-design_23-2147924446.jpg",
      channelIcon: "",
    ),
    VideoModel(
      title: "Biology Class 12",
      subtitle: "Zoology Special",
      imageUrl:
          "https://img.freepik.com/free-psd/education-youtube-thumbnail-template_23-2148995572.jpg",
      channelIcon: "",
    ),
  ];

  final List<VideoModel> recommended = [
    VideoModel(
      title: "Shrimad Bhagavad Gita Sar",
      subtitle: "Corem ipsum dolor sit amet, consect adipiscing eli...",
      imageUrl: "https://i.ytimg.com/vi/vCmpH-qQx_w/maxresdefault.jpg",
      channelIcon: "https://i.pravatar.cc/150?u=99",
    ),
    VideoModel(
      title: "PM MODI LIVE",
      subtitle: "Corem ipsum dolor sit amet, consect adipiscing eli...",
      imageUrl:
          "https://imgs.etvbharat.com/etvbharat/prod-images/17-09-2025/640-480-25029922-thumbnail-16x9-modi-thumbnail-live.jpg",
      channelIcon:
          "https://upload.wikimedia.org/wikipedia/en/thumb/4/41/Flag_of_India.svg/1200px-Flag_of_India.svg.png",
      isLive: true,
    ),
  ];

  // Method to update carousel index
  void updateIndex(int index) {
    currentCarouselIndex.value = index;
  }
}

// -----------------------------------------------------------------------------
// 3. UI IMPLEMENTATION
// -----------------------------------------------------------------------------

class OttScreen extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());

  OttScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // 1. CAROUSEL SLIDER SECTION
              _buildCarouselSection(),

              const SizedBox(height: 20),

              // 2. JOINED CHANNELS (Horizontal List)
              _buildSectionHeader("Joined Channels"),
              const SizedBox(height: 10),
              _buildJoinedChannelsList(),

              const SizedBox(height: 20),

              // 3. CONTINUE WATCHING (Horizontal List)
              _buildSectionHeader("Continue Watching"),
              const SizedBox(height: 10),
              _buildHorizontalVideoList(controller.continueWatching,
                  isCompact: true),

              const SizedBox(height: 20),

              // 4. RECOMMENDED FOR YOU (Horizontal List)
              _buildSectionHeader("Recommended for you"),
              const SizedBox(height: 10),
              _buildHorizontalVideoList(controller.recommended,
                  isCompact: false),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildCarouselSection() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200.0,
            autoPlay: true,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              controller.updateIndex(index);
            },
          ),
          items: controller.carouselImages.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Dots Indicator
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: controller.carouselImages.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.currentCarouselIndex.value == entry.key
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.5),
                    // color: (Theme.of(Get.context!).primaryColor).withOpacity(controller.currentCarouselIndex.value == entry.key ? 0.9 : 0.4),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildJoinedChannelsList() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: controller.joinedChannels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final item = controller.joinedChannels[index];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(item.imageUrl),
                ),
              ),
              const SizedBox(height: 8),
              CustomText(
                item.name,
                color: AppColors.mainTextColor,
                fontSize: 12,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHorizontalVideoList(List<VideoModel> videos,
      {required bool isCompact}) {
    // If isCompact is true, we show "Continue Watching" style (smaller, no channel icon)
    // If isCompact is false, we show "Recommended" style (larger, with details)

    double height = isCompact ? 140 : 260;
    double width = isCompact ? 160 : 300;

    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final video = videos[index];
          return SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(video.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (video.isLive)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            color: Colors.red,
                            child: const Text("LIVE",
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Details
                if (!isCompact) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (video.channelIcon.isNotEmpty)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(video.channelIcon),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            CustomText(
                              video.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              video.views,
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ] else ...[
                  CustomText(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainTextColor,
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
