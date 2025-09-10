import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class SinglePhotoPostEditingScreen extends StatefulWidget {
  final File photo;
  const SinglePhotoPostEditingScreen({super.key, required this.photo});

  @override
  State<SinglePhotoPostEditingScreen> createState() => _SinglePhotoPostEditingScreenState();
}

class _SinglePhotoPostEditingScreenState extends State<SinglePhotoPostEditingScreen> {
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
          designMode: ImageEditorDesignMode.cupertino,
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

