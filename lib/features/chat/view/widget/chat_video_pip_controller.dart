import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'chat_video_player_screen.dart';

/// Holds the single [WebViewController] used to play a video link tapped from a
/// chat message. The same controller is shared between the full-screen player
/// ([ChatVideoPlayerScreen]) and the floating PiP overlay
/// ([ChatVideoPipOverlay]) so playback continues when the user shrinks the
/// player to PiP (hits back) and when they expand it again.
///
/// Only one [WebViewWidget] references the controller at a time — full screen
/// OR pip, never both — which is required by webview_flutter.
class ChatVideoPipController extends GetxController {
  WebViewController? webController;

  /// The original link from the chat message (used for "open externally").
  final RxString sourceUrl = ''.obs;

  /// The actual page loaded in the WebView (a YouTube embed url, etc.).
  final RxString playUrl = ''.obs;

  final RxString title = ''.obs;

  /// PiP mini-player visible at the app root.
  final RxBool isPipVisible = false.obs;

  /// Full-screen player route is currently on top.
  final RxBool isFullScreen = false.obs;

  /// Convenience accessor used by the widgets.
  static ChatVideoPipController get to =>
      Get.isRegistered<ChatVideoPipController>()
          ? Get.find<ChatVideoPipController>()
          : Get.put(ChatVideoPipController(), permanent: true);

  /// Returns true when [url] looks like a playable video link we should open
  /// in the in-app player instead of the generic browser.
  static bool isVideoLink(String url) {
    final u = url.toLowerCase();
    return u.contains('youtube.com') ||
        u.contains('youtu.be') ||
        u.contains('vimeo.com') ||
        u.contains('dailymotion.com') ||
        u.contains('.mp4') ||
        u.contains('.m3u8') ||
        u.contains('.mov') ||
        u.contains('.webm') ||
        u.contains('.mkv');
  }

  /// Extracts a YouTube video id from any common YouTube url shape
  /// (watch?v=, youtu.be/, /shorts/, /embed/, /live/), or null.
  static String? _youTubeId(String url) {
    final patterns = <RegExp>[
      RegExp(r'youtu\.be/([A-Za-z0-9_-]{6,})'),
      RegExp(r'[?&]v=([A-Za-z0-9_-]{6,})'),
      RegExp(r'/shorts/([A-Za-z0-9_-]{6,})'),
      RegExp(r'/embed/([A-Za-z0-9_-]{6,})'),
      RegExp(r'/live/([A-Za-z0-9_-]{6,})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// Builds the URL actually loaded in the WebView. YouTube links become an
  /// inline embed so they play in-page (no "open YouTube app" bounce); any
  /// other link is loaded as-is.
  static String _resolvePlayUrl(String url) {
    final id = _youTubeId(url);
    if (id != null) {
      return 'https://www.youtube.com/embed/$id'
          '?autoplay=1&playsinline=1&rel=0&modestbranding=1';
    }
    return url.startsWith('http') ? url : 'https://$url';
  }

  /// Open [url] in the in-app full-screen player. Reuses the existing WebView
  /// when the same link is already loaded (e.g. expanding from PiP).
  void openInApp(String url, {String? videoTitle}) {
    final resolved = _resolvePlayUrl(url);

    final needsNewLoad = webController == null || playUrl.value != resolved;
    sourceUrl.value = url;
    playUrl.value = resolved;
    title.value = (videoTitle == null || videoTitle.trim().isEmpty)
        ? 'Video'
        : videoTitle.trim();

    if (needsNewLoad) {
      webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..loadRequest(Uri.parse(resolved));
    }

    isPipVisible.value = false;
    isFullScreen.value = true;
    Get.to(() => const ChatVideoPlayerScreen());
  }

  /// Called when the full-screen player is dismissed with back — shrink to the
  /// floating PiP while keeping the WebView (and its playback) alive.
  void enterPip() {
    if (webController == null) return;
    isFullScreen.value = false;
    isPipVisible.value = true;
  }

  /// Expand the PiP back to the full-screen player.
  void expandToFullScreen() {
    if (webController == null) return;
    isPipVisible.value = false;
    isFullScreen.value = true;
    Get.to(() => const ChatVideoPlayerScreen());
  }

  /// Stop playback and tear everything down.
  void close() {
    try {
      webController?.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
    webController = null;
    playUrl.value = '';
    sourceUrl.value = '';
    title.value = '';
    isPipVisible.value = false;
    isFullScreen.value = false;
  }
}
