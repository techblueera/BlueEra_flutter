import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class ResumeWebPreview extends StatefulWidget {
  final String htmlContent;

  const ResumeWebPreview({required this.htmlContent});

  @override
  State<ResumeWebPreview> createState() => _ResumeWebPreviewState();
}

class _ResumeWebPreviewState extends State<ResumeWebPreview> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: WebViewWidget(controller: controller),
    );
  }
}

