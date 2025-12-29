import 'package:get/get.dart';

class ItemsController extends GetxController {
  // Tracks selected store index
  var selectedStoreIndex = (-1).obs;

  // Tracks checked items in the bottom sheet (using index as key)
  var checkedItems = <int, bool>{}.obs;

  void toggleStore(int index) {
    selectedStoreIndex.value = index;
  }

  void toggleItem(int index) {
    bool isChecked = checkedItems[index] ?? false;
    checkedItems[index] = !isChecked;
  }
}