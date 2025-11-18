// Do not Delete this file by - Boopathi
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:intl/intl.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
//
// class AudioCallScreen extends StatefulWidget {
//   final String currentUserId;
//   final String receiverUserId;
//   final bool isCaller;
//   final IO.Socket socket;
//   final String roomId;
//
//   const AudioCallScreen({
//     super.key,
//     required this.currentUserId,
//     required this.receiverUserId,
//     required this.isCaller,
//     required this.socket,
//     required this.roomId,
//   });
//
//   @override
//   State<AudioCallScreen> createState() => _AudioCallScreenState();
// }
//
// class _AudioCallScreenState extends State<AudioCallScreen> {
//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   bool _micEnabled = true;
//   bool _speakerEnabled = false;
//   bool _isCallConnected = false;
//   bool _isEnded = false;
//   Duration _callDuration = Duration.zero;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _initSocketEvents();
//     _startLocalAudio();
//
//     // Caller initiates call
//     if (widget.isCaller) {
//       Future.delayed(const Duration(seconds: 1), () => _startCall());
//     }
//   }
//
//   Future<void> _startLocalAudio() async {
//     _localStream = await navigator.mediaDevices.getUserMedia({
//       'audio': true,
//       'video': false,
//     });
//   }
//
//   void _initSocketEvents() {
//     widget.socket.on('offer', _onOffer);
//     widget.socket.on('answer', _onAnswer);
//     widget.socket.on('candidate', _onCandidate);
//     widget.socket.on('leave-call', (_) => _endCall());
//   }
//
//   Future<void> _createPeerConnection() async {
//     final config = {
//       'iceServers': [
//         {'urls': 'stun:stun.l.google.com:19302'},
//       ]
//     };
//
//     _peerConnection = await createPeerConnection(config);
//
//     // Add local audio track
//     if (_localStream != null) {
//       for (var track in _localStream!.getTracks()) {
//         _peerConnection!.addTrack(track, _localStream!);
//       }
//     }
//
//     // Handle remote stream
//     _peerConnection!.onTrack = (event) {
//       if (event.streams.isNotEmpty) {
//         setState(() => _isCallConnected = true);
//         _startTimer();
//       }
//     };
//
//     // ICE candidates
//     _peerConnection!.onIceCandidate = (candidate) {
//       if (candidate.candidate != null) {
//         widget.socket.emit('candidate', {
//           'room_id': widget.roomId,
//           'candidate': {
//             'sdpMid': candidate.sdpMid,
//             'sdpMLineIndex': candidate.sdpMLineIndex,
//             'candidate': candidate.candidate,
//           },
//         });
//       }
//     };
//   }
//
//   Future<void> _startCall() async {
//     await _createPeerConnection();
//
//     final offer = await _peerConnection!.createOffer();
//     await _peerConnection!.setLocalDescription(offer);
//
//     widget.socket.emit('offer', {
//       'room_id': widget.roomId,
//       'offer': offer.toMap(),
//       'from': widget.currentUserId,
//       'to': widget.receiverUserId,
//     });
//   }
//
//   Future<void> _onOffer(dynamic data) async {
//     if (!mounted) return;
//     await _createPeerConnection();
//
//     final offer = RTCSessionDescription(
//       data['offer']['sdp'],
//       data['offer']['type'],
//     );
//
//     await _peerConnection!.setRemoteDescription(offer);
//
//     final answer = await _peerConnection!.createAnswer();
//     await _peerConnection!.setLocalDescription(answer);
//
//     widget.socket.emit('answer', {
//       'room_id': widget.roomId,
//       'answer': answer.toMap(),
//       'from': widget.currentUserId,
//       'to': widget.receiverUserId,
//     });
//   }
//
//   Future<void> _onAnswer(dynamic data) async {
//     if (_peerConnection == null) return;
//
//     final answer = RTCSessionDescription(
//       data['answer']['sdp'],
//       data['answer']['type'],
//     );
//     await _peerConnection!.setRemoteDescription(answer);
//   }
//
//   Future<void> _onCandidate(dynamic data) async {
//     if (_peerConnection == null) return;
//
//     final candidateMap = data['candidate'];
//     final candidate = RTCIceCandidate(
//       candidateMap['candidate'],
//       candidateMap['sdpMid'],
//       candidateMap['sdpMLineIndex'],
//     );
//     await _peerConnection!.addCandidate(candidate);
//   }
//
//   void _toggleMic() {
//     if (_localStream != null) {
//       final track = _localStream!
//           .getAudioTracks()
//           .firstWhere((track) => track.kind == 'audio');
//       track.enabled = !_micEnabled;
//       setState(() => _micEnabled = !_micEnabled);
//     }
//   }
//
//   void _toggleSpeaker() async {
//     await Helper.setSpeakerphoneOn(!_speakerEnabled);
//     setState(() => _speakerEnabled = !_speakerEnabled);
//   }
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       setState(() => _callDuration += const Duration(seconds: 1));
//     });
//   }
//
//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }
//
//   void _endCall() async {
//     if (_isEnded) return;
//     _isEnded = true;
//
//     widget.socket.emit('leave-call', {'room_id': widget.roomId});
//
//     _timer?.cancel();
//     await _peerConnection?.close();
//     await _localStream?.dispose();
//
//     setState(() {
//       _peerConnection = null;
//       _localStream = null;
//       _isCallConnected = false;
//     });
//
//     if (mounted) Navigator.pop(context);
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     widget.socket.off('offer');
//     widget.socket.off('answer');
//     widget.socket.off('candidate');
//     widget.socket.off('leave-call');
//     _peerConnection?.close();
//     _localStream?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final timeText = _isCallConnected
//         ? _formatDuration(_callDuration)
//         : widget.isCaller
//         ? "Calling..."
//         : "Ringing...";
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.account_circle, color: Colors.white70, size: 120),
//             const SizedBox(height: 20),
//             Text(
//               widget.receiverUserId,
//               style: const TextStyle(color: Colors.white, fontSize: 22),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               timeText,
//               style: const TextStyle(color: Colors.white70, fontSize: 18),
//             ),
//             const SizedBox(height: 80),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _iconButton(
//                   icon: _micEnabled ? Icons.mic : Icons.mic_off,
//                   color: _micEnabled ? Colors.white : Colors.red,
//                   onPressed: _toggleMic,
//                 ),
//                 const SizedBox(width: 40),
//                 _iconButton(
//                   icon: Icons.call_end,
//                   color: Colors.red,
//                   onPressed: _endCall,
//                 ),
//                 const SizedBox(width: 40),
//                 _iconButton(
//                   icon: _speakerEnabled
//                       ? Icons.volume_up
//                       : Icons.volume_off_rounded,
//                   color: Colors.white,
//                   onPressed: _toggleSpeaker,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _iconButton({
//     required IconData icon,
//     required Color color,
//     required VoidCallback onPressed,
//   }) {
//     return InkWell(
//       onTap: onPressed,
//       child: CircleAvatar(
//         radius: 30,
//         backgroundColor: Colors.white10,
//         child: Icon(icon, color: color, size: 30),
//       ),
//     );
//   }
// }
