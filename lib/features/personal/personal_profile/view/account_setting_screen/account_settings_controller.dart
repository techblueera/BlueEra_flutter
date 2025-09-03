import 'package:get/get.dart';

class AccountSettingsController extends GetxController {

  RxBool allnotify = true.obs;
    RxString title = ' '.obs;
    
    RxString index = ' '.obs;


  @override
    void setTitle(String value) {
    title.value = value;
  }
  void setIndex( String value) {
    index.value = value;
  } 
   void toggleAllNotification() {
    allnotify.value = !allnotify.value;
  }
} 