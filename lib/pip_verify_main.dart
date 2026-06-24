// THROWAWAY verification harness for the chat video-link in-app player + PiP.
// Reproduces main.dart's root-Stack overlay wiring so the real feature widgets
// (ChatVideoPipController / ChatVideoPlayerScreen / ChatVideoPipOverlay) can be
// driven via UI without the full login + chat surface. Delete after verifying.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'features/chat/view/widget/chat_video_pip_controller.dart';
import 'features/chat/view/widget/chat_video_pip_overlay.dart';

void main() {
  runApp(const _PipVerifyApp());
}

class _PipVerifyApp extends StatelessWidget {
  const _PipVerifyApp();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Mirror MyApp: global PiP overlay floats above every screen.
        return Stack(
          children: [
            if (child != null) child,
            const ChatVideoPipOverlay(),
          ],
        );
      },
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PiP Verify')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => ChatVideoPipController.to
              .openInApp('https://youtu.be/dQw4w9WgXcQ', videoTitle: 'Test Video'),
          child: const Text('Open YouTube link'),
        ),
      ),
    );
  }
}
