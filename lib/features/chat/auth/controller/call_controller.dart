// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:get/get.dart' hide navigator;
// import 'package:flutter_callkit_incoming/entities/android_params.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/entities/ios_params.dart';
// import 'package:flutter_callkit_incoming/entities/notification_params.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../../../core/api/apiService/response_model.dart';
// import '../../../../core/constants/app_strings.dart';
// import '../../../../core/constants/snackbar_helper.dart';
// import '../repo/call_repo.dart';
//
// enum CallType { audio, video }
// enum CallStatus { idle, ringing, ongoing, ended, hold }
//
// class CallController extends GetxController {
//   late IO.Socket callSocket;
//   MediaStream? _localStream;
//   final Map<String, RTCPeerConnection> peerConnections = {};
//   final Map<String, RTCVideoRenderer> remoteRenderers = {};
//   final RTCVideoRenderer localRenderer = RTCVideoRenderer();
//
//   /// Observables
//   var callType = CallType.audio.obs;
//   var callStatus = CallStatus.idle.obs;
//   var callerName = "".obs;
//   var targetUserId = 0.obs;
//   var isMicOn = true.obs;
//   var isSpeakerOn = false.obs;
//
//   final _config = {
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'},
//       {
//         'urls': [
//           'turn:server.srivelavantraders.com:3478?transport=udp',
//           'turn:server.srivelavantraders.com:3478?transport=tcp',
//           'turns:server.srivelavantraders.com:5349?transport=tcp'
//         ],
//         'username': 'demo',
//         'credential': 'password@123'
//       }
//     ],
//     'sdpSemantics': 'unified-plan',
//   };
//   Future<void> callToUser(Map<String, dynamic> params) async {
//     // try {
//
//
//       ResponseModel responseModel =
//       await CallRepo().callToUser(params);
//       if (responseModel.isSuccess) {
//         final data = responseModel.response?.data;
//         print(" lkdclskmclskdcmsdc ${data}");
//
//       } else {
//         commonSnackBar(
//             message: responseModel.message ?? AppStrings.somethingWentWrong);
//       }
//
//   }
//   Future<void> initSocket() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? userId = prefs.getString("user_id");
//
//     callSocket = IO.io(
//       'https://picturoenglish.com:2027',
//       IO.OptionBuilder()
//           .setTransports(['websocket'])
//           .disableAutoConnect()
//           .setQuery({'userId': userId})
//           .build(),
//     );
//
//     await localRenderer.initialize();
//     callSocket.connect();
//
//     callSocket.onConnect((_) {
//       callSocket.emit('register', {"userId": userId});
//     });
//
//     /// Incoming Call
//     callSocket.on('incoming-call', (data) {
//       targetUserId.value = int.parse(data['from']);
//       callerName.value = data['userName'];
//       callStatus.value = CallStatus.ringing;
//
//       showFlutterCallNotification(
//         callSessionId: "call_${DateTime.now().millisecondsSinceEpoch}",
//         userId: data['from'],
//         callerName: callerName.value,
//         callerId: int.parse(data['from']),
//         receiverId: int.parse(userId ?? "0"),
//       );
//     });
//
//     /// Call accepted
//     callSocket.on('call-accepted', (data) {
//       callStatus.value = CallStatus.ongoing;
//       FlutterCallkitIncoming.setCallConnected("active_call");
//     });
//
//     /// Call rejected
//     callSocket.on('call-rejected', (_) {
//       endCall();
//     });
//
//     /// WebRTC signaling
//     callSocket.on('signal', (data) async {
//       final from = data['from'];
//       final description = data['description'];
//       final candidate = data['candidate'];
//
//       if (description != null) {
//         final rtcDesc =
//         RTCSessionDescription(description['sdp'], description['type']);
//
//         if (rtcDesc.type == 'offer') {
//           await connectNewUser(from);
//           await peerConnections[from.toString()]?.setRemoteDescription(rtcDesc);
//           final answer =
//           await peerConnections[from.toString()]!.createAnswer();
//           await peerConnections[from.toString()]!.setLocalDescription(answer);
//           callSocket.emit('signal', {
//             'to': from,
//             'description': answer.toMap(),
//           });
//         } else if (rtcDesc.type == 'answer') {
//           await peerConnections[from.toString()]?.setRemoteDescription(rtcDesc);
//         }
//       }
//
//       if (candidate != null) {
//         final ice = RTCIceCandidate(
//           candidate['candidate'],
//           candidate['sdpMid'],
//           candidate['sdpMLineIndex'],
//         );
//         await peerConnections[from.toString()]?.addCandidate(ice);
//       }
//     });
//
//     /// Call ended
//     callSocket.on('call-ended', (_) {
//       endCall();
//     });
//   }
//
//   /// Connect peer
//   Future<void> connectNewUser(int userId) async {
//     final prefs = await SharedPreferences.getInstance();
//     String? currentUserId = prefs.getString("user_id");
//
//     final pc = await createPeerConnection(_config);
//
//     _localStream =
//     await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
//     _localStream!.getTracks().forEach((t) => pc.addTrack(t, _localStream!));
//
//     pc.onIceCandidate = (RTCIceCandidate cand) {
//       if (cand.candidate != null) {
//         callSocket.emit('signal', {
//           'to': userId,
//           'from': currentUserId,
//           'candidate': {
//             'candidate': cand.candidate,
//             'sdpMid': cand.sdpMid,
//             'sdpMLineIndex': cand.sdpMLineIndex,
//           }
//         });
//       }
//     };
//
//     pc.onTrack = (event) async {
//       final stream = event.streams.first;
//       if (!remoteRenderers.containsKey(userId.toString())) {
//         final renderer = RTCVideoRenderer();
//         await renderer.initialize();
//         remoteRenderers[userId.toString()] = renderer;
//       }
//       remoteRenderers[userId.toString()]?.srcObject = stream;
//     };
//
//     peerConnections[userId.toString()] = pc;
//     localRenderer.srcObject = _localStream;
//   }
//
//   /// Accept Call
//   void acceptCall() {
//     callSocket.emit("call-accepted", {"to": targetUserId.value});
//     callStatus.value = CallStatus.ongoing;
//   }
//
//   /// Reject Call
//   void rejectCall() {
//     callSocket.emit("call-rejected", {"to": targetUserId.value});
//     endCall();
//   }
//
//   /// End Call
//   Future<void> endCall() async {
//     callStatus.value = CallStatus.ended;
//     callSocket.emit('end-call', {'to': targetUserId.value});
//
//     _localStream?.getTracks().forEach((t) => t.stop());
//     _localStream?.dispose();
//     localRenderer.srcObject = null;
//
//     for (var pc in peerConnections.values) {
//       await pc.close();
//     }
//     peerConnections.clear();
//
//     for (var renderer in remoteRenderers.values) {
//       await renderer.dispose();
//     }
//     remoteRenderers.clear();
//
//     await FlutterCallkitIncoming.endAllCalls();
//   }
//
//   /// Toggle Mic
//   void toggleMic() {
//     isMicOn.value = !isMicOn.value;
//     _localStream?.getAudioTracks().forEach((t) {
//       t.enabled = isMicOn.value;
//     });
//   }
//
//   /// Toggle Speaker
//   Future<void> toggleSpeaker() async {
//     isSpeakerOn.value = !isSpeakerOn.value;
//     await Helper.setSpeakerphoneOn(isSpeakerOn.value);
//   }
//
//
//   @override
//   void onClose() {
//     endCall();
//     super.onClose();
//   }
// }
//
// /// CallKit notification helper
// void showFlutterCallNotification({
//   required String callSessionId,
//   required String userId,
//   required String callerName,
//   int callerId = 0,
//   int receiverId = 0,
// }) async {
//   final params = CallKitParams(
//     id: callSessionId,
//     nameCaller: callerName,
//     appName: 'Picturo',
//     handle: "Call From $callerName",
//     type: 0,
//     duration: 30000,
//     textAccept: 'Accept',
//     textDecline: 'Decline',
//     missedCallNotification: const NotificationParams(
//       showNotification: true,
//       subtitle: 'Missed call',
//     ),
//     extra: {
//       'userId': userId,
//       'callerId': callerId.toString(),
//       'receiverId': receiverId.toString(),
//     },
//     android: const AndroidParams(
//       isShowLogo: true,
//       isShowFullLockedScreen: true,
//       isImportant: true,
//     ),
//     ios: const IOSParams(
//       supportsVideo: true,
//       supportsDTMF: true,
//       supportsHolding: true,
//     ),
//   );
//
//   await FlutterCallkitIncoming.showCallkitIncoming(params);
// }
