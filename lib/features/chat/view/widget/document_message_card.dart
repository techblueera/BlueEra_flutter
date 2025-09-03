import 'dart:io';

import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import 'component_widgets.dart';

class PdfPreviewCard extends StatelessWidget {
  final String pdfUrl;
  final String fileName;
  final String time;
  final bool isMyMessage;
  final Messages message;
  final ChatThemeController chatThemeController;

  const PdfPreviewCard({
    super.key,
    required this.pdfUrl,
    required this.message,
    required this.chatThemeController,
    required this.fileName,
    required this.time,
    required this.isMyMessage,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return GestureDetector(
      onLongPress: (){
        chatThemeController.activateSelection(message);
      },
      onTap: () {
        if(!(message.sendStatus=="pending")){
          FocusScope.of(context).unfocus();
          if(chatThemeController.isMessageSelectionActive.value){
            chatThemeController.selectMoreMessage(message);
          }else{
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerPage(pdfUrl: pdfUrl,pdfName: fileName,),
              ),
            );
          }
        }

      },
      child: Align(
        alignment: !isMyMessage? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: 1,),
          decoration: BoxDecoration(
            color:isMyMessage?chatThemeController.receiveMessageBgColor.value: chatThemeController.myMessageBgColor.value,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(Icons.picture_as_pdf, color:(isMyMessage)?Colors.black: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 197,
                    child: CustomText(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      color:(isMyMessage)?Colors.black: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                   Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       CustomText(
                        "Tap to view full PDF",
                        fontSize: 12,
                        color: (isMyMessage)?Colors.black:Colors.white,),
                       const SizedBox(width: 22,),
                       timeAndReadInfoWidget(message: message,isMyMessage: message.myMessage??false,time: time,timeColor: (message.myMessage??false) ? Colors.white : Colors.black54,indicateColor:message.messageRead==1?Colors.blue:Colors.grey)
                     ],
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String pdfName;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.pdfName});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? _localFilePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      if (widget.pdfUrl.toLowerCase().startsWith('http')) {
        // URL-based PDF, download it
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(widget.pdfUrl));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes);
        _localFilePath = file.path;
      } else {
        // Local file path directly
        _localFilePath = widget.pdfUrl;
      }
    } catch (e) {
      debugPrint("Error loading PDF: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.pdfName,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localFilePath != null
          ? PDFView(
        fitEachPage: true,
        filePath: _localFilePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: true,
        onRender: (_pages) {},
        onError: (error) => debugPrint(error.toString()),
        onPageError: (page, error) =>
            debugPrint('$page: ${error.toString()}'),
      )
          : const Center(child: Text('Failed to load PDF')),
    );
  }
}

