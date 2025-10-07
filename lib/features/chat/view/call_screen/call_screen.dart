// // ignore_for_file: must_be_immutable, depend_on_referenced_packages, constant_identifier_names, avoid_print, non_constant_identifier_names, unused_field, deprecated_member_use, unnecessary_null_comparison
//
// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:ui';
//
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
//
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:get/get.dart' as getx;
// import 'package:hive/hive.dart';
//
// import 'package:uuid/uuid.dart';
//
// import '../../../../environment_config.dart';
// import '../../auth/controller/call_controller.dart';
// import '../../auth/controller/room_id_controller.dart';
// import '../../auth/socket/chat_socket.dart';
//
// class AudioCallScreen extends StatefulWidget {
//   String? roomID;
//   String? isGroupCall;
//   String conversation_id;
//   String receiverImage;
//   String receiverUserName;
//   bool isCaller = false;
//   final String? conversationId;
//   final String? userId;
//   final String callerName;
//   AudioCallScreen(
//       {super.key,
//         this.roomID,
//         this.isGroupCall,
//         required this.conversation_id,
//         required this.receiverImage,
//         required this.receiverUserName,
//         this.isCaller = false, this.conversationId, this.userId, required this.callerName});
//
//   @override
//   State<AudioCallScreen> createState() => _AudioCallScreenState();
// }
//
// class _AudioCallScreenState extends State<AudioCallScreen> {
//   // Removed Peer / peerdart usage. Use RTCPeerConnection instead
//   // Map of remote peer connections (1 per remote peer)
//   final Map<String, RTCPeerConnection> _peerConnections = {};
//
//   // Renderer for local audio (we reuse RTCVideoRenderer for media streams)
//   RTCVideoRenderer localRenderer = RTCVideoRenderer();
//
//   // Renderer map for remote streams
//   final Map<String, RTCVideoRenderer> remoteRenderers = {};
//
//   // Local media stream
//   MediaStream? _localStream;
//
//   // final RoomIdController roomIdController = getx.Get.put(RoomIdController());
//   final callController = getx.Get.find<CallController>();
//
//   String? peerid;
//   bool inCall = false;
//   bool isScreenBig = true;
//   bool isReciverConnect = false;
//   bool isCallCutByMe = false;
//   bool isCallCutCall = false;
//   final socketIntilized = ChatSocketService();
//   bool isMuted = false;
//   bool isSpeakerOn = false;
//   bool isKeypadVisible = false;
//   bool showCallControls = true;
//
//   // ICE servers / config (kept from your original code)
//   String? CLOUD_HOST = "43.204.28.90";
//   static const CLOUD_PORT = 4001;
//
//   final Map<String, dynamic> defaultConfig = {
//     'iceServers': [
//       const {'urls': 'stun:stun.l.google.com:19302'},
//       {
//         'urls': "turn:43.204.28.90:4001",
//         'username': "peerjs",
//         'credential': "peerjsp"
//       }
//     ],
//   };
//
//   Timer? _timer;
//   int _seconds = 0;
//   Timer? _debugTimer;
//   late Future _delayedCheckFuture;
//
//   @override
//   void initState() {
//     super.initState();
//
//
//
//
//     _initializeRenderersAndMedia();
//
//     // Keep original socket handler for connected-user-list if used elsewhere
//     socketIntilized.listenEvent("connected-user-list", (data) {
//       if (kDebugMode) {
//         print("connected-user-list DATA  $data");
//       }
//       // connnectdUsersData.value =
//       // ConnectedUsersModel.fromJson(data).connectedUsers!;
//       //
//       // if (isCaller == false) {
//       //   if (callback != null) {
//       //     callback();
//       //     log("connnectdUsersData call back executed");
//       //   }
//       // }
//     });
//
//     // periodic debug
//     _debugTimer = Timer.periodic(const Duration(seconds: 3), (_) {
//       if (!mounted) {
//         _debugTimer?.cancel();
//         return;
//       }
//       _debugConnectionStatus();
//     });
//   }
//
//   Future<void> _initializeRenderersAndMedia() async {
//     await localRenderer.initialize();
//     print("ROOMID ${widget.roomID}");
//
//     try {
//       // get local audio only
//       final mediaConstraints = <String, dynamic>{
//         'audio': true,
//         'video': false,
//       };
//       _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
//
//       // assign to local renderer (works for audio-only too)
//       localRenderer.srcObject = _localStream;
//
//       // Setup socket signaling listeners after local stream is ready
//       _setupSocketSignaling();
//
//       // If caller is false, start timer as before
//       if (widget.isCaller == false) {
//         startTimer();
//       }
//     } catch (e, st) {
//       print('Error getting user media: $e\n$st');
//     }
//   }
//
//   // Create and configure a PeerConnection for a remote peer
//   Future<RTCPeerConnection> _createPeerConnectionForRemote(String remoteId, {bool createOffer = false}) async {
//     if (_peerConnections.containsKey(remoteId)) {
//       return _peerConnections[remoteId]!;
//     }
//
//     RTCPeerConnection pc;
//     try {
//       pc = await createPeerConnection(defaultConfig, {});
//
//       // Add local stream to be sent
//       if (_localStream != null) {
//         try {
//           // addStream still works on mobile
//           await pc.addStream(_localStream!);
//         } catch (e) {
//           // fallback: add tracks individually
//           for (var track in _localStream!.getTracks()) {
//             await pc.addTrack(track, _localStream!);
//           }
//         }
//       }
//
//       // ICE candidate handler
//       pc.onIceCandidate = (RTCIceCandidate? candidate) {
//         if (candidate == null) return;
//         try {
//           socketIntilized.emitEvent("signal-candidate", {
//             "to": remoteId,
//             "from": userId, // keep your global/available userId
//             "candidate": {
//               "candidate": candidate.candidate,
//               "sdpMid": candidate.sdpMid,
//               "sdpMLineIndex": candidate.sdpMLineIndex
//             }
//           });
//         } catch (e) {
//           print("Error emitting candidate: $e");
//         }
//       };
//
//       // Handle remote stream via onAddStream (works for addStream)
//       pc.onAddStream = (MediaStream stream) {
//         print("onAddStream from $remoteId stream: $stream");
//         _handleRemoteStream(remoteId, stream);
//       };
//
//       // Fallback: handle onTrack (some implementations prefer onTrack)
//       pc.onTrack = (RTCTrackEvent event) {
//         if (event.streams.isNotEmpty) {
//           print("onTrack from $remoteId, streams: ${event.streams}");
//           _handleRemoteStream(remoteId, event.streams[0]);
//         }
//       };
//
//       // Connection state monitoring
//       pc.onIceConnectionState = (RTCIceConnectionState state) {
//         print("ICE state for $remoteId -> $state");
//         if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
//             state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
//             state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
//           // cleanup that remote peer
//           _cleanupRemotePeer(remoteId);
//         }
//       };
//
//       _peerConnections[remoteId] = pc;
//
//       if (createOffer) {
//         // create offer and send via socket
//         RTCSessionDescription offer = await pc.createOffer({'offerToReceiveAudio': 1});
//         await pc.setLocalDescription(offer);
//         socketIntilized.emitEvent("signal-offer", {
//           "to": remoteId,
//           "from": userId,
//           "sdp": offer.sdp,
//           "type": offer.type
//         });
//         print("Sent offer to $remoteId");
//       }
//     } catch (e) {
//       print("Error creating peer connection for $remoteId: $e");
//       rethrow;
//     }
//     return _peerConnections[remoteId]!;
//   }
//
//   // Handle attaching remote stream to renderer
//   Future<void> _handleRemoteStream(String remoteId, MediaStream stream) async {
//     print("_handleRemoteStream: remoteId=$remoteId, stream=$stream");
//     if (!remoteRenderers.containsKey(remoteId)) {
//       RTCVideoRenderer renderer = RTCVideoRenderer();
//       await renderer.initialize();
//
//       // assign renderer
//       remoteRenderers[remoteId] = renderer;
//     }
//
//     setState(() {
//       remoteRenderers[remoteId]!.srcObject = stream;
//     });
//
//     // if caller false and timer not started, start it
//     if (widget.isCaller == false && _seconds == 0) {
//       startTimer();
//     }
//     isReciverConnect = true;
//   }
//
//   // Socket-based signaling handlers
//   void _setupSocketSignaling() {
//     // When someone joins the call (from your existing server logic)
//     socketIntilized.listenEvent("user-connected-to-call", (data) async {
//       print("RECEIVED user-connected-to-call data: $data");
//       String userIdRemote;
//       if (data is Map) {
//         userIdRemote = data['user_id']?.toString() ?? '';
//       } else {
//         userIdRemote = data.toString();
//       }
//
//       if (userIdRemote.isNotEmpty) {
//         if (widget.isCaller == true) {
//           // stopRingtone();
//         }
//         print("Connecting to remote peer (via socket event) -> $userIdRemote");
//         // Create peer connection and immediately create offer
//         await _createPeerConnectionForRemote(userIdRemote, createOffer: true);
//         isReciverConnect = true;
//         if (widget.isCaller == true && _seconds == 0) {
//           startTimer();
//         }
//       } else {
//         print("Invalid user id in user-connected-to-call: $data");
//       }
//     });
//
//     // Incoming offer from remote
//     socketIntilized.listenEvent("signal-offer", (data) async {
//       try {
//         print("Received signal-offer: $data");
//         if (data == null) return;
//         String from = (data['from'] ?? data['from_user'] ?? '')?.toString() ?? '';
//         String sdp = (data['sdp'] ?? '')?.toString() ?? '';
//         String type = (data['type'] ?? '')?.toString() ?? '';
//
//         if (from.isEmpty || sdp.isEmpty) {
//           print("Invalid offer payload: $data");
//           return;
//         }
//
//         // ensure we have a PeerConnection
//         RTCPeerConnection pc = await _createPeerConnectionForRemote(from, createOffer: false);
//
//         // set remote description
//         await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
//         print("Set remote description from offer from $from");
//
//         // create answer
//         RTCSessionDescription answer = await pc.createAnswer({'offerToReceiveAudio': 1});
//         await pc.setLocalDescription(answer);
//
//         // send answer back
//         socketIntilized.emitEvent("signal-answer", {
//           "to": from,
//           "from": userId,
//           "sdp": answer.sdp,
//           "type": answer.type
//         });
//
//         print("Sent answer to $from");
//       } catch (e) {
//         print("Error handling signal-offer: $e");
//       }
//     });
//
//     // Incoming answer for our offer
//     socketIntilized.listenEvent("signal-answer", (data) async {
//       try {
//         print("Received signal-answer: $data");
//         if (data == null) return;
//         String from = (data['from'] ?? data['from_user'] ?? '')?.toString() ?? '';
//         String sdp = (data['sdp'] ?? '')?.toString() ?? '';
//         String type = (data['type'] ?? '')?.toString() ?? '';
//
//         if (from.isEmpty || sdp.isEmpty) {
//           print("Invalid answer payload: $data");
//           return;
//         }
//
//         if (_peerConnections.containsKey(from)) {
//           final pc = _peerConnections[from]!;
//           await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
//           print("Set remote description from answer from $from");
//         } else {
//           print("No existing peerConnection for answer from $from");
//         }
//       } catch (e) {
//         print("Error handling signal-answer: $e");
//       }
//     });
//
//     // Incoming ICE candidate
//     socketIntilized.listenEvent("signal-candidate", (data) async {
//       try {
//         if (data == null) return;
//         final from = (data['from'] ?? '')?.toString() ?? '';
//         final candidateMap = data['candidate'] ?? data['ice'] ?? {};
//         if (from.isEmpty || candidateMap == null) {
//           print("Invalid candidate data: $data");
//           return;
//         }
//
//         final candidate = RTCIceCandidate(
//             candidateMap['candidate'],
//             candidateMap['sdpMid'],
//             candidateMap['sdpMLineIndex']);
//
//         if (_peerConnections.containsKey(from)) {
//           final pc = _peerConnections[from]!;
//           await pc.addCandidate(candidate);
//           print("Added ICE candidate from $from");
//         } else {
//           print("No peerConnection for candidate from $from, storing not implemented");
//           // Optionally store and add later when pc is created
//         }
//       } catch (e) {
//         print("Error handling signal-candidate: $e");
//       }
//     });
//
//     // User disconnected
//     socketIntilized.listenEvent("user-disconnected-from-call", (data) {
//       print("user-disconnected-from-call -> $data");
//       String userIdRemote = data?.toString() ?? '';
//       if (userIdRemote.isEmpty && data is Map) {
//         userIdRemote = (data['user_id'] ?? '')?.toString() ?? '';
//       }
//
//       if (userIdRemote.isNotEmpty) {
//         _cleanupRemotePeer(userIdRemote);
//       } else {
//         print("user-disconnected-from-call had invalid payload: $data");
//       }
//     });
//
//     // call declined
//     socketIntilized.listenEvent("call_decline", (data) {
//       print("call_decline data : $data");
//       // stopRingtone();
//       // getx.Get.find<ChatListController>().forChatList();
//       // getx.Get.offAll(
//       //   TabbarScreen(
//       //     currentTab: 0,
//       //   ),
//       // );
//       disposeLocalRender();
//       disposeRemoteRender();
//       // cleanup peer connections
//       _cleanupAllPeers();
//     });
//
//     // join-call emit to server (announce presence)
//     print("slkdjcmlsdkmclskdcms JOin Call");
//     try {
//       print("slkdjcmlsdkmclskdcms JOin Call __ ${socketIntilized.isConnected}");
//       socketIntilized.emitEvent("join-call", {"room_id": widget.roomID, "user_id": userId});
//     } catch (e) {
//       print("Error emitting join-call: $e");
//     }
//   }
//
//   // Cleanup a specific remote peer connection and renderer
//   Future<void> _cleanupRemotePeer(String remoteId) async {
//     print("Cleaning up remote peer: $remoteId");
//     if (_peerConnections.containsKey(remoteId)) {
//       try {
//         await _peerConnections[remoteId]!.close();
//       } catch (e) {
//         print("Error closing peer connection for $remoteId: $e");
//       }
//       _peerConnections.remove(remoteId);
//     }
//
//     if (remoteRenderers.containsKey(remoteId)) {
//       try {
//         final renderer = remoteRenderers[remoteId]!;
//         if (renderer.srcObject != null) {
//           final audioTracks = renderer.srcObject!.getAudioTracks();
//           for (var track in audioTracks) {
//             try {
//               track.stop();
//             } catch (_) {}
//           }
//           renderer.srcObject!.getAudioTracks().clear();
//           renderer.srcObject!.getVideoTracks().clear();
//         }
//         await renderer.dispose();
//       } catch (e) {
//         print("Error disposing renderer for $remoteId: $e");
//       }
//       remoteRenderers.remove(remoteId);
//       if (mounted) setState(() {});
//     }
//
//     // if no remote renderers left -> leave call
//     if (remoteRenderers.isEmpty) {
//       try {
//         socketIntilized.emitEvent("leave-call", {"room_id": widget.roomID, "user_id": userId});
//       } catch (e) {
//         print("Error emitting leave-call: $e");
//       }
//       disposeLocalRender();
//       disposeRemoteRender();
//
//     }
//   }
//
//   Future<void> _cleanupAllPeers() async {
//     for (final entry in _peerConnections.entries) {
//       try {
//         await entry.value.close();
//       } catch (e) {
//         print("Error closing peer ${entry.key}: $e");
//       }
//     }
//     _peerConnections.clear();
//   }
//
//   // End call (UI action)
//   void _endCall() {
//
//
//     if (widget.isCaller == true) {
//       isCallCutCall = true;
//       setState(() {});
//       // stopRingtone();
//     }
//     if (isReciverConnect == false && widget.isCaller == true) {
//       print("callCutByMe calling...");
//
//       // roomIdController.callCutByMe(
//       //     conversationID: widget.conversation_id, callType: "audio_call");
//     }
//
//     // Clear peer connections
//     _cleanupAllPeers();
//
//     try {
//       socketIntilized.emitEvent("leave-call", {"room_id": widget.roomID, "user_id": userId});
//     } catch (e) {
//       print("Error emitting leave-call: $e");
//     }
//
//     setState(() {
//       inCall = false;
//     });
//
//     disposeLocalRender();
//     disposeRemoteRender();
//
//     getx.Get.back();
//   }
//
//   bool microphone = false;
//   void _toggleMicrophone() {
//     microphone = !microphone;
//     if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
//       var track = _localStream!.getAudioTracks()[0];
//       track.enabled = !track.enabled;
//     }
//     setState(() {});
//   }
//
//   bool specker = false;
//   void _toggleSpecker() async {
//     specker == true
//         ? await Helper.setSpeakerphoneOn(false)
//         : await Helper.setSpeakerphoneOn(true);
//     specker = !specker;
//     setState(() {});
//   }
//
//   void _toggleScreenSize() {
//     setState(() {
//       isScreenBig = !isScreenBig;
//     });
//   }
//
//   void startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
//       setState(() {
//         _seconds++;
//       });
//     });
//   }
//
//   String getFormattedTime(int seconds) {
//     final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
//     final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
//     return "$minutes:$remainingSeconds";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleScreenSize,
//       child: Scaffold(
//         body: Stack(
//           children: [
//             forTwo(),
//             Positioned(
//                 top: 145,
//                 left: 20,
//                 right: 20,
//                 child: Column(
//                   children: [
//                     Text(
//                       widget.receiverUserName,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w500,
//                         fontSize: 20,
//                         fontFamily: "Poppins",
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 9,
//                     ),
//                     Text(
//                       'Audio Calling',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w400,
//                         fontSize: 12,
//                         fontFamily: "Poppins",
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 9,
//                     ),
//                     Text(
//                       remoteRenderers.isEmpty
//                           ? "00:00"
//                           : getFormattedTime(_seconds),
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w400,
//                         fontSize: 12,
//                         fontFamily: "Poppins",
//                       ),
//                     ),
//                     Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         // keep Lottie as before (if you have it)
//                         Icon(Icons.call),
//                         Container(
//                           decoration: const BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Colors.white,
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(100),
//                             child: Icon(Icons.person),
//                           ).paddingAll(4),
//                         ),
//                       ],
//                     ),
//                   ],
//                 )),
//             Positioned(
//               top: 40,
//               left: 20,
//               right: 20,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Icon(
//                     Icons.arrow_back,
//                   ),
//                   Text(
//                    'End-to-end encrypted',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w400,
//                       fontSize: 12,
//                       fontFamily: "Poppins",
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       joinUsers();
//                     },
//                     child: ClipRRect(
//                       borderRadius:
//                       const BorderRadius.all(Radius.circular(100)),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color:  AppColors.white.withOpacity(0.07),
//                             ),
//                             color:  AppColors.white.withOpacity(0.10),
//                           ),
//                           child: Icon(Icons.person_add_alt_1_rounded),
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//             Positioned(
//               bottom: 20,
//               left: 40,
//               right: 40,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(38),
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: AppColors.white.withOpacity(0.36),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         InkWell(
//                           onTap: _toggleMicrophone,
//                           child: Icon( microphone == false?  Icons.mic: Icons.mic_off,
//                           ),
//                         ),
//                         InkWell(
//                           onTap: _toggleMicrophone,
//                           child: Icon( specker == false?   Icons.volume_up : Icons.volume_off,
//                           ),
//                         ),
//
//                         GestureDetector(
//                           onTap: _endCall,
//                           child: Icon(Icons.call_end,color: Colors.red,),
//                         ),
//                       ],
//                     ).paddingSymmetric(
//                       horizontal: 22,
//                       vertical: 12,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   joinUsers() {
//     // return showDialog(
//     //     context: context,
//     //     barrierColor: const Color.fromRGBO(30, 30, 30, 0.37),
//     //     builder: (BuildContext context) {
//     //       return const JoinedUsers();
//     //     });
//   }
//
//   Widget forTwo() {
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         CachedNetworkImage(
//           imageUrl: widget.receiverImage,
//           fit: BoxFit.cover,
//           placeholder: (context, url) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 color: Colors.white,
//               ),
//             );
//           },
//           errorWidget: (context, url, error) {
//             return const Icon(
//               Icons.person,
//               size: 30,
//             );
//           },
//         ),
//         BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             color: Colors.white.withOpacity(0.053),
//           ),
//         ),
//       ],
//     );
//   }
//
//   endedCall(BuildContext context) {
//     return showDialog(
//       barrierColor: const Color.fromRGBO(30, 30, 30, 0.37),
//       context: context,
//       builder: (BuildContext context) {
//         return BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//           child: AlertDialog(
//             insetPadding: const EdgeInsets.all(8),
//             alignment: Alignment.bottomCenter,
//             backgroundColor: Colors.white,
//             elevation: 0,
//             shape: const RoundedRectangleBorder(
//               borderRadius: BorderRadius.all(
//                 Radius.circular(20),
//               ),
//             ),
//             content: SizedBox(
//               width: getx.Get.width,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const SizedBox(height: 10),
//                   Text(
//                     'This call has already ended.',
//                     style: const TextStyle(
//                         fontWeight: FontWeight.w600, fontSize: 16),
//                   ),
//                   Text(
//                     'Please call again.',
//                     style: const TextStyle(
//                         fontWeight: FontWeight.w600, fontSize: 16),
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       // Expanded(
//                       //   child: InkWell(
//                       //     onTap: () {
//                       //       getx.Get.offAll(
//                       //         TabbarScreen(
//                       //           currentTab: 0,
//                       //         ),
//                       //       );
//                       //     },
//                       //     child: Container(
//                       //       height: 40,
//                       //       decoration: BoxDecoration(
//                       //           border:
//                       //           Border.all(color: chatownColor, width: 1),
//                       //           borderRadius: BorderRadius.circular(12)),
//                       //       child: Center(
//                       //           child: Text(
//                       //             languageController.textTranslate('Cancel'),
//                       //             style: const TextStyle(
//                       //                 fontSize: 14,
//                       //                 fontWeight: FontWeight.w400,
//                       //                 color: chatColor),
//                       //           )),
//                       //     ),
//                       //   ),
//                       // ),
//                       // const SizedBox(
//                       //   width: 10,
//                       // ),
//                       // Expanded(
//                       //   child: InkWell(
//                       //     onTap: () {
//                       //       getx.Get.offAll(
//                       //         TabbarScreen(
//                       //           currentTab: 0,
//                       //         ),
//                       //       );
//                       //     },
//                       //     child: Container(
//                       //       height: 40,
//                       //       decoration: BoxDecoration(
//                       //           borderRadius: BorderRadius.circular(12),
//                       //           gradient: LinearGradient(
//                       //               colors: [secondaryColor, chatownColor],
//                       //               begin: Alignment.topCenter,
//                       //               end: Alignment.bottomCenter)),
//                       //       child: Center(
//                       //           child: Text(
//                       //             languageController.textTranslate('Call Again'),
//                       //             style: const TextStyle(
//                       //                 fontSize: 14,
//                       //                 fontWeight: FontWeight.w400,
//                       //                 color: chatColor),
//                       //           )),
//                       //     ),
//                       //   ),
//                       // ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> disposeLocalRender() async {
//     if (_localStream != null) {
//       try {
//         final audioTracks = _localStream!.getAudioTracks();
//         if (audioTracks.isNotEmpty) {
//           for (var track in audioTracks) {
//             track.stop();
//           }
//         }
//
//         final videoTracks = _localStream!.getVideoTracks();
//         if (videoTracks.isNotEmpty) {
//           for (var track in videoTracks) {
//             track.stop();
//           }
//         }
//
//         _localStream!.getAudioTracks().clear();
//         _localStream!.getVideoTracks().clear();
//       } catch (e) {
//         print("Error cleaning local stream: $e");
//       } finally {
//         _localStream = null;
//       }
//     }
//
//     try {
//       await localRenderer.dispose();
//     } catch (e) {
//       print("Error disposing local renderer: $e");
//     }
//   }
//
//   Future<void> disposeRemoteRender() async {
//     for (final entry in remoteRenderers.entries) {
//       final key = entry.key;
//       final renderer = entry.value;
//       try {
//         if (renderer.srcObject != null) {
//           final audioTracks = renderer.srcObject!.getAudioTracks();
//           if (audioTracks.isNotEmpty) {
//             for (var track in audioTracks) {
//               print('Stopping audio track for renderer $key');
//               track.stop();
//             }
//           }
//
//           final videoTracks = renderer.srcObject!.getVideoTracks();
//           if (videoTracks.isNotEmpty) {
//             for (var track in videoTracks) {
//               print('Stopping video track for renderer $key');
//               track.stop();
//             }
//           }
//
//           renderer.srcObject!.getAudioTracks().clear();
//           renderer.srcObject!.getVideoTracks().clear();
//         } else {
//           print('No srcObject found for renderer $key');
//         }
//
//         await renderer.dispose();
//         print('Renderer $key disposed');
//       } catch (e) {
//         print("Error disposing renderer $key: $e");
//       }
//     }
//     remoteRenderers.clear();
//   }
//
//   @override
//   void dispose() {
//     disposeLocalRender();
//     disposeRemoteRender();
//     _cleanupAllPeers();
//     _delayedCheckFuture = Future.value();
//     _timer?.cancel();
//     _debugTimer?.cancel();
//     super.dispose();
//   }
//
//   // Add this debug method to your class
//   void _debugConnectionStatus() {
//     print("\n===== AUDIO CALL STATUS =====");
//     print("LOCAL AUDIO: ${_localStream != null ? 'YES' : 'NO'}");
//
//     if (_localStream != null) {
//       final audioTracks = _localStream!.getAudioTracks();
//       print(
//           "  Local audio tracks: ${audioTracks.length} (enabled: ${audioTracks.isNotEmpty ? audioTracks[0].enabled : 'N/A'})");
//     }
//
//     print("REMOTE RENDERERS: ${remoteRenderers.length}");
//     remoteRenderers.forEach((key, renderer) {
//       print(
//           "  Renderer for peer $key: has stream = ${renderer.srcObject != null}");
//       if (renderer.srcObject != null) {
//         final audioTracks = renderer.srcObject!.getAudioTracks();
//         print(
//             "    Audio tracks: ${audioTracks.length} (enabled: ${audioTracks.isNotEmpty ? audioTracks[0].enabled : 'N/A'})");
//       }
//     });
//
//     print("PEER CONNECTIONS: ${_peerConnections.length}");
//     _peerConnections.forEach((userId, connection) {
//       print(
//           "  Connection with $userId: ${connection != null ? 'ACTIVE' : 'NULL'}");
//     });
//     print("============================\n");
//   }
// }
