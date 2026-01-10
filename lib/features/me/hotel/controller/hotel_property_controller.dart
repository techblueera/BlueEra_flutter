import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get.dart';

class HotelPropertyController extends GetxController {
  // Mocking the raw response from your input
  var policyData = {}.obs;
  var is24Hours = false.obs;

  // This map stores the user selections: { "catalogNodeId": value }
  var userSelections = <String, dynamic>{}.obs;
  // This map stores toggle states (isActive/isEnabled)
  var activeStates = <String, bool>{}.obs;

  List<String> timeSlots = List.generate(24, (i) => "${i.toString().padLeft(2, '0')}:00");
// Helper to find a specific child node by its KEY

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void loadInitialData() {
    // In a real app, this comes from your API service
    // For now, initializing based on your provided keys
    List children = [
      {"id": "695ca7339d3f021dcc32cbdf", "key": "CHECKIN_TIME", "name": "Check-in Time", "val": "10:00"},
      {"id": "695ca7339d3f021dcc32cbe2", "key": "CHECKOUT_TIME", "name": "Check-out Time", "val": "23:00"},
      {"id": "695ca7339d3f021dcc32cbe5", "key": "EARLY_CHECKIN_ALLOWED", "name": "Early Check-in Allowed"},
      {"id": "695ca7349d3f021dcc32cbfd", "key": "FOOD_RESTRICTIONS", "name": "Food Habit Restrictions", "val": <String>[]}
    ];

    for (var item in children) {
      activeStates[item['id']] = false;
      if (item.containsKey('val')) {
        userSelections[item['id']] = item['val'];
      }
    }
  }

  void submitData() {
    // Map the local state back to your requested format
    var result = {
      "nodes": activeStates.entries.map((e) {
        var node = {
          "catalogNodeId": e.key,
          "isActive": e.value,
        };
        if (userSelections.containsKey(e.key)) {
          node["data"] = userSelections[e.key];
        }
        return node;
      }).toList()
    };

    print("SUBMITTING TO BACKEND: $result");
    Get.snackbar("Success", "Data formatted for API");
  }
}
class HotelPropertyController_ extends GetxController {

  // Store selected times as Strings for the dropdown
  var selectedCheckIn = "10:00".obs;
  var selectedCheckOut = "23:00".obs;

  // Generate a list of times (e.g., 00:00 to 23:00)
  List<String> timeSlots = List.generate(24, (index) {
    return "${index.toString().padLeft(2, '0')}:00";
  });
  // Toggles
  Rx<bool> is24Hours = false.obs;
  var earlyCheckIn = false.obs;
  var lateCheckOut = false.obs;
  var allowUnmarried = false.obs;
  var allowBachelors = false.obs;
  var freeCancellation = false.obs;
  var localIdAllowed = false.obs;
  var aadharMandatory = false.obs;
  var smokingDrinking = false.obs;
  var foodRestrictions = true.obs;

  // Time Selection
  var checkInTime = const TimeOfDay(hour: 10, minute: 0).obs;
  var checkOutTime = const TimeOfDay(hour: 23, minute: 0).obs;

  // Food Habits
  var selectedFoodHabits = <String>[].obs;

  void toggleFoodHabit(String habit) {
    if (habit == "All") {
      selectedFoodHabits.value = ["All", "Vegetarian", "Non-Vegetarian"];
    } else {
      if (selectedFoodHabits.contains(habit)) {
        selectedFoodHabits.remove(habit);
        selectedFoodHabits.remove("All");
      } else {
        selectedFoodHabits.add(habit);
        if (selectedFoodHabits.length == 2 && !selectedFoodHabits.contains("All")) {
          selectedFoodHabits.add("All");
        }
      }
    }
  }

  void submitForm() {
    // Validation Logic




    // if (foodRestrictions.value && selectedFoodHabits.isEmpty) {
    //   Get.snackbar("Error", "Please select at least one food habit restriction",
    //       snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    //   return;
    // }
    //
    // Get.snackbar("Success", "Settings updated successfully!",
    //     snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    //
    //
    //
  }
}