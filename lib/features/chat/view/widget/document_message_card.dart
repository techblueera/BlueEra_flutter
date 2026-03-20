import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../../../../core/services/chat_media_storage_service.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import 'component_widgets.dart';

class PdfPreviewCard extends StatefulWidget {
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
  State<PdfPreviewCard> createState() => _PdfPreviewCardState();
}

enum _DocDlState { idle, downloading, ready }

class _PdfPreviewCardState extends State<PdfPreviewCard> {
  _DocDlState _dlState = _DocDlState.idle;
  double _dlProgress = 0;
  String? _localPath;
  Uint8List? _thumbnailBytes;
  bool _thumbnailLoaded = false;

  bool get _isReceived => widget.isMyMessage; // isMyMessage is inverted in the original code

  @override
  void initState() {
    super.initState();
    if (_isReceived && widget.message.myMessage != true) {
      _checkLocalFile();
    } else {
      _dlState = _DocDlState.ready;
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    try {
      final path = _localPath ?? widget.pdfUrl;
      if (path.isEmpty) return;

      pdfx.PdfDocument? doc;
      if (path.startsWith('http')) {
        // Download first for thumbnail
        final existing = await ChatMediaStorageService.findExistingFile(
          url: path, messageType: 'document', fileName: widget.fileName,
        );
        if (existing != null) {
          doc = await pdfx.PdfDocument.openFile(existing.path);
        }
      } else {
        doc = await pdfx.PdfDocument.openFile(path);
      }

      if (doc != null) {
        final page = await doc.getPage(1);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: pdfx.PdfPageImageFormat.png,
        );
        await page.close();
        await doc.close();

        if (mounted && pageImage?.bytes != null) {
          setState(() {
            _thumbnailBytes = pageImage!.bytes;
            _thumbnailLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading PDF thumbnail: $e');
    }
  }

  Future<void> _checkLocalFile() async {
    if (widget.pdfUrl.isEmpty) return;
    final existing = await ChatMediaStorageService.findExistingFile(
      url: widget.pdfUrl, messageType: 'document', fileName: widget.fileName,
    );
    if (existing != null && mounted) {
      setState(() { _dlState = _DocDlState.ready; _localPath = existing.path; });
      _loadThumbnail();
    }
  }

  Future<void> _download() async {
    if (widget.pdfUrl.isEmpty) return;
    setState(() { _dlState = _DocDlState.downloading; _dlProgress = 0; });
    final file = await ChatMediaStorageService.downloadAndSave(
      url: widget.pdfUrl, messageType: 'document', fileName: widget.fileName,
      onProgress: (r, t) { if (t > 0 && mounted) setState(() => _dlProgress = r / t); },
    );
    if (!mounted) return;
    if (file != null) {
      setState(() { _dlState = _DocDlState.ready; _localPath = file.path; });
      _loadThumbnail();
    } else {
      setState(() => _dlState = _DocDlState.idle);
    }
  }

  void _openPdf(BuildContext context) {
    if (widget.message.sendStatus == "pending") return;
    FocusScope.of(context).unfocus();
    if (widget.chatThemeController.isMessageSelectionActive.value) {
      widget.chatThemeController.selectMoreMessage(widget.message);
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          pdfUrl: _localPath ?? widget.pdfUrl,
          pdfName: widget.fileName,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isMyMessage
        ? widget.chatThemeController.receiveMessageBgColor.value
        : widget.chatThemeController.myMessageBgColor.value;
    final textColor = widget.isMyMessage ? Colors.black : Colors.white;

    // If needs download and not ready, show download overlay
    if (_dlState != _DocDlState.ready && widget.message.myMessage != true) {
      return Align(
        alignment: !widget.isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Blurred PDF icon
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Icon(Icons.picture_as_pdf, color: textColor.withValues(alpha: 0.4), size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 170,
                      child: CustomText(widget.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    _dlState == _DocDlState.downloading
                        ? _buildInlineProgress(textColor)
                        : _buildInlineDownloadBtn(textColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Ready state — PDF card with thumbnail preview
    return GestureDetector(
      onTap: () => _openPdf(context),
      child: Align(
        alignment: !widget.isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          width: 240,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail preview
              if (_thumbnailLoaded && _thumbnailBytes != null)
                Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey.shade100,
                  child: Image.memory(
                    _thumbnailBytes!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 100,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(Icons.picture_as_pdf, color: Colors.red.shade300, size: 48),
                  ),
                ),

              // File info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: textColor, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: CustomText(widget.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, color: textColor, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      CustomText("Tap to view", fontSize: 11, color: textColor.withValues(alpha: 0.7)),
                      timeAndReadInfoWidget(
                        message: widget.message,
                        isMyMessage: widget.message.myMessage ?? false,
                        time: widget.time,
                        timeColor: (widget.message.myMessage ?? false) ? Colors.white : Colors.black54,
                        indicateColor: widget.message.messageRead == 1 ? Colors.blue : Colors.grey,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineDownloadBtn(Color textColor) {
    return GestureDetector(
      onTap: _download,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.download_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text('Download', style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildInlineProgress(Color textColor) {
    final pct = (_dlProgress * 100).toInt();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 100, child: LinearProgressIndicator(
        value: _dlProgress > 0 ? _dlProgress : null,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation(Colors.white),
        minHeight: 3,
      )),
      const SizedBox(width: 8),
      Text('$pct%', style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
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

