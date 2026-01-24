import 'package:BlueEra/features/common/ott/model/channel_model_new.dart';
import 'package:get/get.dart';

class OttHomeController extends GetxController {
  // Reactive variable for the carousel current index
  var currentCarouselIndex = 0.obs;

  // --- HARD CODED STATIC DATA ---

  final List<String> carouselImages = [
    "https://media.istockphoto.com/id/1183338499/vector/0547.jpg?s=612x612&w=0&k=20&c=yNkIf4DxCEkOb0EXoq5kQ0XX1k5T53QYQLgL_j2Rg5M=",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcScvOOUHSd2NfqUfwdapGmMSelaucVhgInkRg&s",
    "https://mir-s3-cdn-cf.behance.net/projects/404/351796219634157.Y3JvcCw5ODMsNzY5LDE0OCww.jpg",
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
