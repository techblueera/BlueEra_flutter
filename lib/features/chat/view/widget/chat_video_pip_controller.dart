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

  /// Elapsed watch time since the current link was opened — drives the docked
  /// PiP's time label. (A WebView page doesn't expose the media position, so
  /// this is wall-clock since open, which tracks playback closely enough.)
  final Stopwatch watch = Stopwatch();

  /// Convenience accessor used by the widgets.
  static ChatVideoPipController get to =>
      Get.isRegistered<ChatVideoPipController>()
          ? Get.find<ChatVideoPipController>()
          : Get.put(ChatVideoPipController(), permanent: true);

  /// The URL loaded in the WebView — the raw link (scheme ensured). Loading the
  /// page as-is (rather than a forced YouTube embed) keeps it robust: YouTube /
  /// video pages play in-page after a tap, exactly like the WhatsApp in-app
  /// browser, and a minimised PiP keeps that page (and its playback) alive.
  static String _resolvePlayUrl(String url) =>
      url.startsWith('http') ? url : 'https://$url';

  /// Short, human label for the app-bar/title — the link's host (e.g.
  /// "youtube.com"), or "Link" when it can't be parsed.
  static String _hostTitle(String url) {
    try {
      final host = Uri.parse(_resolvePlayUrl(url)).host;
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return 'Link';
    }
  }

  /// Open [url] in the in-app full-screen player. Reuses the existing WebView
  /// when the same link is already loaded (e.g. expanding from PiP).
  void openInApp(String url, {String? videoTitle}) {
    final resolved = _resolvePlayUrl(url);

    final needsNewLoad = webController == null || playUrl.value != resolved;
    sourceUrl.value = url;
    playUrl.value = resolved;
    title.value = (videoTitle == null || videoTitle.trim().isEmpty)
        ? _hostTitle(url)
        : videoTitle.trim();

    if (needsNewLoad) {
      webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..loadRequest(Uri.parse(resolved));
      watch
        ..reset()
        ..start();
    }

    isPipVisible.value = false;
    isFullScreen.value = true;
    Get.to(() => const ChatVideoPlayerScreen());
  }

  /// Called when the full-screen player is dismissed with back — shrink to the
  /// floating PiP while keeping the WebView (and its playback) alive.
  ///
  /// [isFullScreen] flips off immediately so the full-screen player releases
  /// the shared [WebViewController]; the PiP is then shown one pop-animation
  /// later so the overlay re-attaches that controller to a fresh WebViewWidget
  /// without the two briefly fighting over it (which left the PiP blank/absent).
  void enterPip() {
    if (webController == null) return;
    isFullScreen.value = false;
    Future.delayed(const Duration(milliseconds: 320), () {
      if (webController != null && !isFullScreen.value) {
        isPipVisible.value = true;
      }
    });
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
    watch
      ..stop()
      ..reset();
  }
}
