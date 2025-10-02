// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
//
// import '../../../auth/controller/call_controller.dart';
// import '../call_screen.dart';
//
// class IncomingCallScreen extends StatelessWidget {
//   final CallController callCtrl = Get.find<CallController>();
//   final String callerName;
//   final String callerId;
//   final String sdp;
//   final CallType callType;
//
//   IncomingCallScreen({
//     required this.callerName,
//     required this.callerId,
//     required this.sdp,
//     required this.callType,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black87,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.call, size: 100, color: Colors.greenAccent),
//             const SizedBox(height: 20),
//             Text(
//               "$callerName is calling...",
//               style: const TextStyle(color: Colors.white, fontSize: 20),
//             ),
//             const SizedBox(height: 30),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 FloatingActionButton(
//                   backgroundColor: Colors.red,
//                   onPressed: () {
//                     callCtrl.endCall();
//                     Get.back(); // close screen
//                   },
//                   child: const Icon(Icons.call_end, color: Colors.white),
//                 ),
//                 const SizedBox(width: 40),
//                 FloatingActionButton(
//                   backgroundColor: Colors.green,
//                   onPressed: () async {
//                      callCtrl.acceptCall();
//                     Get.off(() => VoiceCallScreen(callerId: 3442, callerName: 'fdvd', )); // navigate to call page
//                   },
//                   child: const Icon(Icons.call, color: Colors.white),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
