//
// import 'dart:developer';
//
// import 'package:BlueEra/video_calling/call_api_service.dart';
// import 'package:flutter/material.dart';
// import 'package:jitsimeet/jitsi_meet_flutter_sdk.dart';
//
// class MyAppMeeting extends StatefulWidget {
//   const MyAppMeeting({super.key});
//
//   @override
//   State<MyAppMeeting> createState() => _MyAppMeetingState();
// }
//
// class _MyAppMeetingState extends State<MyAppMeeting> {
//   bool audioMuted = true;
//   bool videoMuted = true;
//   bool screenShareOn = false;
//   List<String> participants = [];
//   final _jitsiMeetPlugin = JitsiMeet();
//
//   join() async {
//
// try{
//
//
//   var options = JitsiMeetConferenceOptions(
//     room:"vpaas-magic-cookie-ece47c0a6b174ea695311a07cf724f7a/demo-room",
//     serverURL: "https://8x8.vc",
//     token:"eyJraWQiOiJ2cGFhcy1tYWdpYy1jb29raWUtZWNlNDdjMGE2YjE3NGVhNjk1MzExYTA3Y2Y3MjRmN2EvYTc1ZjQ2LVNBTVBMRV9BUFAiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJqaXRzaSIsImlzcyI6ImNoYXQiLCJpYXQiOjE3NTk5ODQ4OTQsImV4cCI6MTc1OTk5MjA5NCwibmJmIjoxNzU5OTg0ODg5LCJzdWIiOiJ2cGFhcy1tYWdpYy1jb29raWUtZWNlNDdjMGE2YjE3NGVhNjk1MzExYTA3Y2Y3MjRmN2EiLCJjb250ZXh0Ijp7ImZlYXR1cmVzIjp7ImxpdmVzdHJlYW1pbmciOnRydWUsImZpbGUtdXBsb2FkIjp0cnVlLCJvdXRib3VuZC1jYWxsIjp0cnVlLCJzaXAtb3V0Ym91bmQtY2FsbCI6ZmFsc2UsInRyYW5zY3JpcHRpb24iOnRydWUsImxpc3QtdmlzaXRvcnMiOmZhbHNlLCJyZWNvcmRpbmciOnRydWUsImZsaXAiOmZhbHNlfSwidXNlciI6eyJoaWRkZW4tZnJvbS1yZWNvcmRlciI6ZmFsc2UsIm1vZGVyYXRvciI6dHJ1ZSwibmFtZSI6ImFtb2wyMCIsImlkIjoiZ29vZ2xlLW9hdXRoMnwxMTc0MTI1Mzc1MDU1ODY4MDU4MjQiLCJhdmF0YXIiOiIiLCJlbWFpbCI6ImFtb2wyMEBuYXZndXJ1a3VsLm9yZyJ9fSwicm9vbSI6IioifQ.VfoXYY1a5U640cOS1k0XVoIRR6G3RZ15w54sqi06bgdW1v7KI9BYQ1Wbft5VV8OhdYU3fvXUo1is4y8LAuWwkCZWkc-Yj2so-RQrNOm2sgUYJYzX3FC3ygn81rPstcK9L0jko7bXT7CtfBz8hpdCuYvz01cYqrRkuD4Zyz_AxPMKorNjBRqKtVEEDF49gpzkncdrEsXT3cBSCKiJdNU6TH1LLkjJedRizv-tSPNfuxDqNj4c_qYMu49k7k7pcyFYQsy2zTMLrnIEPG_aWsk0LPFQgkr3x5uUYxNqcfwX9Rhltul505hCEBz0gLwZFpgFBJ0tVRKGQDBbcZFxFKWQVQ",
//     configOverrides: {
//       "startWithAudioMuted": false,
//       "startWithVideoMuted": false,
//     },
//     featureFlags: {
//       "chat.enabled": true,
//     },
//   );
//   await _jitsiMeetPlugin.join(options,);
// }
//     catch (e){
//   log("ERROR ${e}");
//     }
//   }
//
//   joinOld() async {
//
//     try {
//       final res = await CallApiService.startAudioCall(
//         conversationId: "68e5fcbd702191d5c4b83153",
//         callType: "audio_call",
//       );
//       if (res != null && res.success) {
//         print("✅ Call started with Room ID: ${res.roomId}");
//         print("🔑 Jitsi Token: ${res.jitsiToken}");
//         print("📞 Sender ID: ${res.message.senderId}");
//
//         var options = JitsiMeetConferenceOptions(
//           room:"${res.roomId}",
//           // token: "eyJraWQiOiJ2cGFhcy1tYWdpYy1jb29raWUtZWNlNDdjMGE2YjE3NGVhNjk1MzExYTA3Y2Y3MjRmN2EvYTc1ZjQ2LVNBTVBMRV9BUFAiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJqaXRzaSIsImlzcyI6ImNoYXQiLCJpYXQiOjE3NTk5ODQ4OTQsImV4cCI6MTc1OTk5MjA5NCwibmJmIjoxNzU5OTg0ODg5LCJzdWIiOiJ2cGFhcy1tYWdpYy1jb29raWUtZWNlNDdjMGE2YjE3NGVhNjk1MzExYTA3Y2Y3MjRmN2EiLCJjb250ZXh0Ijp7ImZlYXR1cmVzIjp7ImxpdmVzdHJlYW1pbmciOnRydWUsImZpbGUtdXBsb2FkIjp0cnVlLCJvdXRib3VuZC1jYWxsIjp0cnVlLCJzaXAtb3V0Ym91bmQtY2FsbCI6ZmFsc2UsInRyYW5zY3JpcHRpb24iOnRydWUsImxpc3QtdmlzaXRvcnMiOmZhbHNlLCJyZWNvcmRpbmciOnRydWUsImZsaXAiOmZhbHNlfSwidXNlciI6eyJoaWRkZW4tZnJvbS1yZWNvcmRlciI6ZmFsc2UsIm1vZGVyYXRvciI6dHJ1ZSwibmFtZSI6ImFtb2wyMCIsImlkIjoiZ29vZ2xlLW9hdXRoMnwxMTc0MTI1Mzc1MDU1ODY4MDU4MjQiLCJhdmF0YXIiOiIiLCJlbWFpbCI6ImFtb2wyMEBuYXZndXJ1a3VsLm9yZyJ9fSwicm9vbSI6IioifQ.VfoXYY1a5U640cOS1k0XVoIRR6G3RZ15w54sqi06bgdW1v7KI9BYQ1Wbft5VV8OhdYU3fvXUo1is4y8LAuWwkCZWkc-Yj2so-RQrNOm2sgUYJYzX3FC3ygn81rPstcK9L0jko7bXT7CtfBz8hpdCuYvz01cYqrRkuD4Zyz_AxPMKorNjBRqKtVEEDF49gpzkncdrEsXT3cBSCKiJdNU6TH1LLkjJedRizv-tSPNfuxDqNj4c_qYMu49k7k7pcyFYQsy2zTMLrnIEPG_aWsk0LPFQgkr3x5uUYxNqcfwX9Rhltul505hCEBz0gLwZFpgFBJ0tVRKGQDBbcZFxFKWQVQ",
//           token: "${res.jitsiToken}",
//           // serverURL: "https://8x8.vc",
//           // serverURL: "https://api.blueera.ai",
//
//           configOverrides: {
//             "startWithAudioMuted": false,
//             "startWithVideoMuted": false,
//           },
//           featureFlags: {
//             "chat.enabled": true,
//           },
//         );
//         await _jitsiMeetPlugin.join(options,);
//
//       } else {
//         print("❌ Failed to start call");
//       }
//
//
//     } on Exception catch (e) {
//       print("ERROR===== $e");
//       // TODO
//     }
//   }
//
//   hangUp() async {
//     await _jitsiMeetPlugin.hangUp();
//   }
//
//   setAudioMuted(bool? muted) async {
//     var a = await _jitsiMeetPlugin.setAudioMuted(muted!);
//     debugPrint("$a");
//     setState(() {
//       audioMuted = muted;
//     });
//   }
//
//   setVideoMuted(bool? muted) async {
//     var a = await _jitsiMeetPlugin.setVideoMuted(muted!);
//     debugPrint("$a");
//     setState(() {
//       videoMuted = muted;
//     });
//   }
//
//   sendEndpointTextMessage() async {
//     var a = await _jitsiMeetPlugin.sendEndpointTextMessage(message: "HEY");
//     debugPrint("$a");
//
//     for (var p in participants) {
//       var b =
//       await _jitsiMeetPlugin.sendEndpointTextMessage(to: p, message: "HEY");
//       debugPrint("$b");
//     }
//   }
//
//   toggleScreenShare(bool? enabled) async {
//     await _jitsiMeetPlugin.toggleScreenShare(enabled!);
//
//     setState(() {
//       screenShareOn = enabled;
//     });
//   }
//
//   openChat() async {
//     await _jitsiMeetPlugin.openChat();
//   }
//
//   sendChatMessage() async {
//     var a = await _jitsiMeetPlugin.sendChatMessage(message: "HEY1");
//     debugPrint("$a");
//
//     for (var p in participants) {
//       a = await _jitsiMeetPlugin.sendChatMessage(to: p, message: "HEY2");
//       debugPrint("$a");
//     }
//   }
//
//   closeChat() async {
//     await _jitsiMeetPlugin.closeChat();
//   }
//
//   retrieveParticipantsInfo() async {
//     var a = await _jitsiMeetPlugin.retrieveParticipantsInfo();
//     debugPrint("$a");
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//           appBar: AppBar(
//             title: const Text('Plugin example app'),
//           ),
//           body: Center(
//             child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: <Widget>[
//                   TextButton(
//                     onPressed: join,
//                     child: const Text("Join"),
//                   ),
//
//                 ]),
//           )),
//     );
//   }
// }