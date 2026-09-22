import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class SinglePhotoPostEditingScreen extends StatefulWidget {
  final File photo;
  final bool isPortrait;
  const SinglePhotoPostEditingScreen({super.key, required this.photo, required this.isPortrait});

  @override
  State<SinglePhotoPostEditingScreen> createState() => _SinglePhotoPostEditingScreenState();
}

class _SinglePhotoPostEditingScreenState extends State<SinglePhotoPostEditingScreen> {

  double get _cropRatio => widget.isPortrait ? 9 / 16 : 1;


  // bool _isCompleted = false;

  // Future<bool> _showExitConfirmation(BuildContext context) async {
  //   if (_isCompleted) return true;
  //
  //   final result = await showModalBottomSheet<String>(
  //     context: context,
  //     backgroundColor: Colors.grey[900],
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (context) {
  //       return SafeArea(
  //         child: Wrap(
  //           children: [
  //             Padding(
  //               padding: const EdgeInsets.all(16.0),
  //               child: Row(
  //                 children: [
  //                   const Text(
  //                     "Start over?",
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   const Text(
  //                     "If you go back now, you will lose this draft.",
  //                     style: TextStyle(color: Colors.white70),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //
  //             const SizedBox(height: 20),
  //
  //             ListTile(
  //               title: const Text("Start over", style: TextStyle(color: Colors.red)),
  //               onTap: () => Navigator.pop(context, "start_over"),
  //             ),
  //             ListTile(
  //               title: const Text("Keep editing", style: TextStyle(color: Colors.white)),
  //               onTap: () => Navigator.pop(context, "keep_editing"),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  //
  //   if (result == "start_over") {
  //     Navigator.pop(context); // exit screen
  //     return true;
  //   }
  //   return false;
  //
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false,
      // onPopInvokedWithResult: (didPop, result) => _showExitConfirmation(context),
      child: ProImageEditor.file(
        widget.photo,
        configs: ProImageEditorConfigs(
          // KEEP cupertino — it is load-bearing, not cosmetic.
          //
          // pro_image_editor's PlatformPopupBtn (shared/widgets/platform/
          // platform_popup_menu.dart) branches on this: cupertino opens a
          // `showCupertinoModalPopup`, material builds a raw
          // `PopupMenuButton`. That widget re-measures its anchor on every
          // layout of the open menu and never checks the anchor has been laid
          // out, which throws
          //
          //   Bad state: RenderBox was not laid out: RenderFractionalTranslation
          //
          // when the menu survives into a frame where its page is offstage —
          // the crash AppPopupMenuButton exists to make impossible. That
          // replacement covers OUR call sites; it cannot reach inside a
          // package. The paint and text editor app bars both render this
          // button, so switching to material here, or adding a second
          // ProImageEditor entry point without a designMode, puts an
          // unprotected PopupMenuButton back into a pushed sub-route.
          //
          // AnchoredMenuDismissObserver still covers the navigation trigger,
          // but it is a workaround; this line is what keeps the widget out of
          // the tree altogether.
          designMode: ImageEditorDesignMode.cupertino,
          cropRotateEditor: CropRotateEditorConfigs(
            initAspectRatio: _cropRatio,          // lock ratio
            aspectRatios: [AspectRatioItem(value: _cropRatio, text: '')],
          ),
        ),
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List bytes) async {
            print('bytes--> $bytes');
            // _isCompleted = true;

            // Get temp directory
            final tempDir = await getTemporaryDirectory();

            // Generate unique file path
            final file = File('${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg');

            // Write bytes to file
            await file.writeAsBytes(bytes);

            print('Saved file path: ${file.path}');

            // Pop with file path string
            if (!context.mounted) return;
            Navigator.pop(context, file.path);
          },
          // onCloseEditor: (EditorMode editorMode) {
          //   // _showExitConfirmation(context);
          // }
        ),
      ),
    );
  }
}

