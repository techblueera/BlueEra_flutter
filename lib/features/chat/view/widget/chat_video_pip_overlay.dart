import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'chat_video_pip_controller.dart';

/// App-wide WhatsApp-style picture-in-picture player for a chat link. Mounted
/// once in the root [Stack] of `MyApp` so it floats above every screen. Driven
/// by [ChatVideoPipController]; visible only while a link is minimised.
///
/// Docked full-width at the bottom (like WhatsApp): the page/video on top and a
/// control bar below with elapsed time, a fullscreen (expand) button and a
/// close (✕) button. Tap the video to expand back to full screen.
class ChatVideoPipOverlay extends StatelessWidget {
  const ChatVideoPipOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ChatVideoPipController.to;

    return Obx(() {
      // Show only while minimised — never while the full-screen player owns the
      // WebView (a WebViewController drives only one WebViewWidget at a time).
      if (!controller.isPipVisible.value ||
          controller.isFullScreen.value ||
          controller.webController == null) {
        return const SizedBox.shrink();
      }
      return _DockedPip(controller: controller);
    });
  }
}

class _DockedPip extends StatefulWidget {
  final ChatVideoPipController controller;
  const _DockedPip({required this.controller});

  @override
  State<_DockedPip> createState() => _DockedPipState();
}

class _DockedPipState extends State<_DockedPip> {
  Timer? _ticker;

  ChatVideoPipController get ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    // Refresh the elapsed-time label once a second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double videoHeight = screenWidth * 9 / 16;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Material(
        color: Colors.black,
        elevation: 16,
        shadowColor: Colors.black,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Video — tap to expand. IgnorePointer so taps hit the expand
              // gesture rather than the page underneath.
              GestureDetector(
                onTap: ctrl.expandToFullScreen,
                child: SizedBox(
                  width: double.infinity,
                  height: videoHeight,
                  child: IgnorePointer(
                    child: WebViewWidget(controller: ctrl.webController!),
                  ),
                ),
              ),

              // Thin "playing" progress line (indeterminate — a WebView page
              // doesn't expose the real media position).
              const SizedBox(
                height: 2.5,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFF3A3A3A),
                  valueColor: AlwaysStoppedAnimation(Color(0xFFFF0000)),
                ),
              ),

              // Control bar: elapsed time • fullscreen • close
              Container(
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                child: Row(
                  children: [
                    Text(
                      _fmt(ctrl.watch.elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'OpenSans',
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: ctrl.expandToFullScreen,
                      icon: const Icon(Icons.fullscreen,
                          color: Colors.white, size: 26),
                    ),
                    IconButton(
                      onPressed: ctrl.close,
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
