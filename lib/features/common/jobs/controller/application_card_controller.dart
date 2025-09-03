import 'package:get/get.dart';

class ApplicationCardController extends GetxController {

}

class ApplicationsController extends GetxController {
  RxInt selectedFilterIndex = 0.obs;
  RxBool selectAll = false.obs;

  final List<String> filter = [
    "All",
    "Shortlisted",
    "Interview",
    "Connect",
    "Hired",
  ];

  void toggleSelectAll() {
    selectAll.value = !selectAll.value;
  }

  void setFilterIndex(int index) {
    selectedFilterIndex.value = index;
    selectAll.value = false;
  }



  RxInt selectedCardIndex = (-1).obs;


  void selectCard(int index) {
    if (selectedCardIndex.value == index) {
      selectedCardIndex.value = -1;
    } else {
      selectedCardIndex.value = index;
    }
  }


  bool isSelected(int index) => selectedCardIndex.value == index;
}