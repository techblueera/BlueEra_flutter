import 'package:get/get.dart';

class ChannelSettingController extends GetxController {
  // Toggle switches
  RxBool hideMobileNumber = true.obs;
  RxBool under18Restriction = false.obs;

  // Comment Control: "Allow" or "Block"
  RxString commentControl = "Allow".obs;

  // Video Quality: "144p", "240p", "360p", "480p", "720p", "1080p", "1440p"
  RxString videoQuality = "480p".obs;

  // Channel Verified Tag
  RxBool channelVerifiedTag = true.obs;

  // Audio Control: "Mute" or "Auto Play"
  RxString audioControl = "Mute".obs;

  // Video Control: "Stop" or "Auto Play"
  RxString videoControl = "Stop".obs;

  void toggleHideMobileNumber() {
    hideMobileNumber.value = !hideMobileNumber.value;
  }

  void toggleUnder18Restriction() {
    under18Restriction.value = !under18Restriction.value;
  }

  void setCommentControl(String value) {
    commentControl.value = value;
  }

  void setVideoQuality(String quality) {
    videoQuality.value = quality;
  }

  void toggleChannelVerifiedTag() {
    channelVerifiedTag.value = !channelVerifiedTag.value;
  }

  void setAudioControl(String value) {
    audioControl.value = value;
  }

  void setVideoControl(String value) {
    videoControl.value = value;
  }
} 