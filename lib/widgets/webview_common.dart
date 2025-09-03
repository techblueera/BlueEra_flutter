import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CommonWebView extends StatefulWidget {
  final String urlLink;
  final String urlTitle;

  const CommonWebView({required this.urlLink, required this.urlTitle});

  @override
  State<CommonWebView> createState() => _CommonWebViewState();
}

class _CommonWebViewState extends State<CommonWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()..loadRequest(Uri.parse(widget.urlLink));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.urlTitle,
      ),
      body: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}
