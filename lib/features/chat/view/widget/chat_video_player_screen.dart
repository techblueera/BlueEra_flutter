import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'chat_video_pip_controller.dart';

/// Full-screen in-app player for a video link tapped in a chat message.
///
/// Pressing back (hardware or the app-bar arrow) minimises the player into the
/// floating PiP overlay instead of stopping it — playback continues because the
/// [WebViewController] lives on [ChatVideoPipController], not on this screen.
/// The close (✕) button fully stops and tears down the player.
class ChatVideoPlayerScreen extends StatefulWidget {
  const ChatVideoPlayerScreen({super.key});

  @override
  State<ChatVideoPlayerScreen> createState() => _ChatVideoPlayerScreenState();
}

class _ChatVideoPlayerScreenState extends State<ChatVideoPlayerScreen> {
  final controller = ChatVideoPipController.to;

  /// Set when the user explicitly closes (✕) so the pop handler doesn't also
  /// spawn a PiP for a player that was meant to be dismissed.
  bool _intentionalClose = false;

  void _minimizeToPip() {
    controller.enterPip();
    if (Navigator.of(context).canPop()) Get.back();
  }

  void _closeCompletely() {
    _intentionalClose = true;
    controller.close();
    if (Navigator.of(context).canPop()) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Own the back ourselves (canPop:false) so Android's predictive back
      // can't finish the activity before we minimise — that's why pressing
      // back used to exit instead of showing the PiP.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // already popped via an explicit Get.back()
        if (_intentionalClose) return;
        // Hardware / system back → minimise to the floating PiP.
        _minimizeToPip();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            // App-bar back mirrors hardware back: minimise to PiP.
            onPressed: _minimizeToPip,
          ),
          title: Obx(() => Text(
                controller.title.value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
          actions: [
            IconButton(
              tooltip: 'Minimize',
              icon: const Icon(Icons.picture_in_picture_alt,
                  color: Colors.white),
              onPressed: _minimizeToPip,
            ),
            IconButton(
              tooltip: 'Open externally',
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              onPressed: () {
                final url = controller.sourceUrl.value;
                if (url.isNotEmpty) {
                  launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _closeCompletely,
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Obx(() {
              final web = controller.webController;
              if (web == null) {
                return const CircularProgressIndicator(color: Colors.white);
              }
              // Release this WebView the instant we switch to PiP so the
              // floating overlay can attach the SAME controller without a
              // conflict — a WebViewController drives only one WebViewWidget
              // at a time, and keeping both mounted during the pop animation
              // is exactly why the PiP failed to appear.
              if (!controller.isFullScreen.value) {
                return const SizedBox.shrink();
              }
              return WebViewWidget(controller: web);
            }),
          ),
        ),
      ),
    );
  }
}
