// import 'dart:async';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/features/common/map/repo/map_service_repo.dart';
// import 'package:BlueEra/features/common/map/view/location_service.dart';
// import 'package:get/get.dart';
// import 'package:workmanager/workmanager.dart';
//
// import '../../../../core/api/apiService/api_keys.dart';
// import '../../../../core/constants/shared_preference_utils.dart';
//
// const backgroundTaskKey = "updateLocationTask";
//
// class LocationServiceProviderController extends GetxController {
//   bool shopOpen = false; // toggle based on your logic
//   Timer? _timer;
//
//   @override
//   Future<void> onInit() async {
//     super.onInit();
//     // shopOpen=
//     if (userProfessionGlobal.toUpperCase() == "SELF_EMPLOYED") {
//       await getServiceProviderStatusUtils();
//
//       if ((serviceProviderStatusGlobal.isNotEmpty) &&
//           (serviceProviderStatusGlobal.toUpperCase() ==
//               AppConstants.OPEN.toUpperCase())) {
//         shopOpen = true;
//         startForegroundUpdates();
//         // _initBackgroundTask();
//       }
//     } else {
//       shopOpen = false;
//     }
//   }
//
//   void startForegroundUpdates() {
//     _timer?.cancel();
//     _timer = Timer.periodic(Duration(seconds: 10), (_) async {
//       logs("shopOpen==== $shopOpen");
//       if (shopOpen) await _updateLocation();
//     });
//   }
//   /// 🛑 Stop all location updates (foreground + background)
//   Future<void> stopLocationUpdates() async {
//     _timer?.cancel();
//     // await Workmanager().cancelAll();
//     print("✅ All location updates stopped");
//   }
//   Future<void> _updateLocation() async {
//     final position = await LocationService.getCurrentPosition();
//     if (position != null) {
//       await MapServiceRepo().mapServiceLocationProviderRepo(queryParams: {
//         ApiKeys.userId: userId,
//         ApiKeys.lat: position.latitude,
//         ApiKeys.lng: position.longitude,
//       });
//     }
//   }
//
//   // Background updates (every 15 min on Android)
//   Future<void> _initBackgroundTask() async {
//     await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
//     await Workmanager().registerPeriodicTask(
//       "1",
//       backgroundTaskKey,
//       frequency: Duration(seconds: 10),
//     );
//   }
//
//   @override
//   void onClose() {
//     _timer?.cancel();
//     super.onClose();
//   }
// }
//
// // Background callback
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     final position = await LocationService.getCurrentPosition();
//     if (position != null) {
//       await MapServiceRepo().mapServiceLocationProviderRepo(queryParams: {
//         ApiKeys.userId: userId,
//         ApiKeys.lat: position.latitude,
//         ApiKeys.lng: position.longitude,
//       });
//     }
//     return Future.value(true);
//   });
// }
