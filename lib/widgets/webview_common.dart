import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CommonWebView extends StatefulWidget {
  final String urlLink;
  final String urlTitle;
  final bool? hideAppBar;

  const CommonWebView({required this.urlLink, required this.urlTitle,  this.hideAppBar});

  @override
  State<CommonWebView> createState() => _CommonWebViewState();
}

class _CommonWebViewState extends State<CommonWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    final urlWithScheme = widget.urlLink.startsWith('http')
        ? widget.urlLink
        : 'https://${widget.urlLink}';
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(urlWithScheme));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:(widget.hideAppBar??false)?null: CommonBackAppBar(
        title: widget.urlTitle,
      ),
      body: SafeArea(
          child: Column(
        children: [
          // Padding(
          //   padding: EdgeInsets.symmetric(
          //     horizontal: SizeConfig.size8,
          //     vertical: SizeConfig.paddingM,
          //   ),
          //   child: HorizontalVideoPlayer(),
          // ),
          Expanded(child: WebViewWidget(controller: controller)),
        ],
      )),
    );
  }
}
