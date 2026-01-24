import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FullScreenPdfViewer extends StatelessWidget {
  final String fileUrl;
  final String title;

  const FullScreenPdfViewer({super.key, required this.fileUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: title,
      ),
      body: SafeArea(child: SfPdfViewer.network(fileUrl)),
    );
  }
}
