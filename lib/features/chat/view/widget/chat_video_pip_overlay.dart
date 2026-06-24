import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'chat_video_pip_controller.dart';

/// App-wide floating mini-player (PiP) for a chat video link. Mounted once in
/// the root [Stack] of `MyApp` so it floats above every screen. Driven by
/// [ChatVideoPipController]; visible only while a video is minimised.
///
/// Tap to expand back to full screen, drag to reposition, ✕ to close.
class ChatVideoPipOverlay extends StatelessWidget {
  const ChatVideoPipOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ChatVideoPipController.to;

    return Obx(() {
      // Show only while minimised — never while the full-screen player owns the
      // WebView (a WebViewController can drive only one WebViewWidget at a time).
      if (!controller.isPipVisible.value ||
          controller.isFullScreen.value ||
          controller.webController == null) {
        return const SizedBox.shrink();
      }
      return _DraggablePip(controller: controller);
    });
  }
}

class _DraggablePip extends StatefulWidget {
  final ChatVideoPipController controller;
  const _DraggablePip({required this.controller});

  @override
  State<_DraggablePip> createState() => _DraggablePipState();
}

class _DraggablePipState extends State<_DraggablePip> {
  double? _xPos;
  double? _yPos;

  /// Mini-player width as a fraction of the screen width. Bumped above the
  /// requested 20% to a clamped range so a 16:9 video stays watchable; tweak
  /// [_widthFactor] / the clamp to resize.
  static const double _widthFactor = 0.40;

  ChatVideoPipController get ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final double width = (screen.width * _widthFactor).clamp(140.0, 240.0);
    final double videoHeight = width * 9 / 16;
    final double totalHeight = videoHeight + 26; // + control strip

    // Default position: bottom-right above the nav bar.
    _xPos ??= screen.width - width - 12;
    _yPos ??= screen.height - totalHeight - 120;

    return Positioned(
      left: _xPos!.clamp(0.0, screen.width - width),
      top: _yPos!.clamp(0.0, screen.height - totalHeight),
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _xPos = (_xPos! + d.delta.dx).clamp(0.0, screen.width - width);
            _yPos = (_yPos! + d.delta.dy).clamp(0.0, screen.height - totalHeight);
          });
        },
        // Tap anywhere on the player area expands back to full screen.
        onTap: ctrl.expandToFullScreen,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black54,
          color: Colors.black,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: width,
              height: totalHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Video — IgnorePointer so taps hit the expand gesture above.
                  SizedBox(
                    width: width,
                    height: videoHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: WebViewWidget(controller: ctrl.webController!),
                          ),
                        ),
                        // Close (stop & dismiss)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: ctrl.close,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Control strip: expand hint.
                  Container(
                    width: width,
                    height: 26,
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: const [
                        Icon(Icons.fullscreen, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tap to expand',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              decoration: TextDecoration.none,
                              fontFamily: 'OpenSans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
