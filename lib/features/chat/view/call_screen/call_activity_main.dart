import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/firebase_crshanalitics_service.dart';
import 'package:BlueEra/core/theme/themes.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/service/call_activity_service.dart';
import 'package:BlueEra/features/chat/view/call_screen/incoming_call_screen.dart';
import 'package:BlueEra/features/chat/view/call_screen/outgoing_call_screen.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/size_config.dart';

/// Core logic for Android CallActivity entry point.
/// The actual @pragma entry point is in main.dart → callMain()
void callMainImpl() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint("CALL MAIN STARTED");

    final params = <String, dynamic>{};
    String? initError;

    try {
      /// ENV
      await projectKeys(environmentType: AppConstants.prod);

      /// FIREBASE
      await firebaseInitializeApp();

      /// HIVE
      await Hive.initFlutter();
      /// AUTH DATA
      authTokenGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.authToken);

      userId = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.loginUserId) ??
          '';

      userNameGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userName) ??
          '';

      userProfileGlobal = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.userProfile) ??
          '';

      if (kDebugMode) {
        debugPrint(
            'CallActivity: authToken=${authTokenGlobal != null}, userId=$userId');
      }

      /// mark this engine
      CallController.isCallActivityEngine = true;

      /// read params from Android Intent
      final intentParams = await CallActivityService.getCallParams();
      params.addAll(intentParams);

      if (kDebugMode) {
        debugPrint('CallActivity params = $params');
      }
    } catch (e, stack) {
      initError = e.toString();

      debugPrint("CallActivity init error: $e");
      debugPrint(stack.toString());
    }

    final isCaller = params['isCaller'] ?? true;

    runApp(
      CallApp(
        isCaller: isCaller,
        params: params,
        initError: initError,
      ),
    );
  }, (error, stack) {
    debugPrint("CALL ENGINE CRASH: $error");
    debugPrint(stack.toString());
  });
}

class CallApp extends StatelessWidget {
  final bool isCaller;
  final Map<String, dynamic> params;
  final String? initError;

  const CallApp({
    super.key,
    required this.isCaller,
    required this.params,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BlueEra Call',
      // home: Scaffold(
      //   appBar: AppBar(
      //     title: Text("Hello"),
      //   ),
      //   body: Text("Coming Soon"),
      // ),
      home: initError != null
          ? _CallActivityErrorScreen(error: initError!)
          : _CallActivityWrapper(isCaller: isCaller, params: params),
    );
  }
}

/// Error screen if initialization fails
class _CallActivityErrorScreen extends StatelessWidget {
  final String error;

  const _CallActivityErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init_Call(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Call initialization failed',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                textAlign: TextAlign.center,
                style:
                const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: CallActivityService.finishCallActivity,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActivityWrapper extends StatefulWidget {
  final bool isCaller;
  final Map<String, dynamic> params;

  const _CallActivityWrapper({
    required this.isCaller,
    required this.params,
  });

  @override
  State<_CallActivityWrapper> createState() =>
      _CallActivityWrapperState();
}

class _CallActivityWrapperState extends State<_CallActivityWrapper> {
  late Worker _statusWorker;
  bool _callInitiated = false;

  late final CallController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.put(CallController(), permanent: true);

    /// watch call status
    _statusWorker = ever(controller.callStatus, (status) {
      if (status == CallStatus.idle || status == CallStatus.ended) {
        Future.delayed(const Duration(milliseconds: 500), () {
          CallActivityService.finishCallActivity();
        });
      }
    });

    /// start call
    Future.microtask(() {
      if (_callInitiated) return;

      _callInitiated = true;
      log("kdjcksjcnscsdc ${widget.params}");
      if (widget.isCaller) {
        _initiateOutgoingCall();
      } else {
        _setupIncomingCall();
      }
    });
  }

  Future<void> _initiateOutgoingCall() async {
    final callTypeStr = widget.params['callType'] ?? 'audio';

    final type = (callTypeStr == 'video' || callTypeStr == 'video_call')
        ? CallType.video
        : CallType.audio;

    final success = await controller.initiateCall(
      type: type,
      otherUserId: widget.params['remoteUserId'] ?? '',
      existingConversationId: widget.params['conversationId'] ?? '',
      userName: widget.params['remoteUserName'] ??
          widget.params['callerName'] ??
          '',
      userImage: widget.params['remoteUserImage'] ??
          widget.params['callerImage'] ??
          '',
    );

    if (!success) {
      Future.delayed(const Duration(milliseconds: 300), () {
        CallActivityService.finishCallActivity();
      });
    }
  }

  Future<void> _setupIncomingCall() async {
    try {
      final callTypeStr = widget.params['callType'] ?? 'audio';

      controller.callType.value =
      (callTypeStr == 'video' || callTypeStr == 'video_call')
          ? CallType.video
          : CallType.audio;

      controller.callId.value = widget.params['callId'] ?? '';
      controller.roomId.value = widget.params['roomId'] ?? '';
      controller.conversationId.value =
          widget.params['conversationId'] ?? '';

      controller.callerName.value = widget.params['callerName'] ?? '';
      controller.callerImage.value =
          widget.params['callerImage'] ?? '';

      controller.remoteUserName.value =
          widget.params['remoteUserName'] ??
              widget.params['callerName'] ??
              '';

      controller.remoteUserImage.value =
          widget.params['remoteUserImage'] ??
              widget.params['callerImage'] ??
              '';

      controller.isCaller.value = false;
      controller.isGroupCall.value =
          widget.params['isGroupCall'] ?? false;

      final iceServers =
          widget.params['iceServers']?.toString() ?? '{}';

      if (kDebugMode) {
        debugPrint("iceServers = $iceServers");
      }

      if (iceServers.isNotEmpty && iceServers != '{}') {
        final accepted = await controller.setupAcceptedCall(
          iceServersJson: iceServers,
          remoteUserId: widget.params['remoteUserId'] ?? '',
        );

        if (!accepted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            CallActivityService.finishCallActivity();
          });
        }
      } else {
        controller.callStatus.value = CallStatus.ringing;
      }
    } catch (e, stack) {
      debugPrint("incoming call setup error: $e");
      debugPrint(stack.toString());

      Future.delayed(const Duration(milliseconds: 300), () {
        CallActivityService.finishCallActivity();
      });
    }
  }

  @override
  void dispose() {
    _statusWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init_Call(context);
    return Obx(() {
      final status = controller.callStatus.value;

      // if (!widget.isCaller && status == CallStatus.ringing) {
      //   return const IncomingCallScreen();
      // }

      if (status == CallStatus.outgoing ||
          status == CallStatus.ringing) {
        return const CallRoomScreen();
      }

      if (status == CallStatus.connecting ||
          status == CallStatus.connected ||
          status == CallStatus.accepting) {
        return const CallRoomScreen();
      }

      return const Scaffold(
        backgroundColor: Color(0xFF1a1a2e),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    });
  }
}