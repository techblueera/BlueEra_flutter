import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef ProgressUpdater = void Function(double);

class UploadProgressDialog {
  static ProgressUpdater? _updateProgressUI;

  /// Show progress dialog (GetX)
  static void show({double initialProgress = 0.0, String? title}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: _ProgressContent(initialProgress: initialProgress, title: title),
      ),
      barrierDismissible: false,
    );
  }

  /// Update progress
  static void update(double value) {
    if (_updateProgressUI != null) {
      _updateProgressUI!(value);
    }
  }

  /// Close dialog
  static void close() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    _updateProgressUI = null;
  }
}

class _ProgressContent extends StatefulWidget {
  final double initialProgress;
  final String? title;

  const _ProgressContent({Key? key, required this.initialProgress, this.title})
      : super(key: key);

  @override
  State<_ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends State<_ProgressContent> {
  late double progress;

  @override
  void initState() {
    super.initState();
    progress = widget.initialProgress;

    // bind updater
    UploadProgressDialog._updateProgressUI = (double newProgress) {
      if (mounted) {
        setState(() {
          progress = newProgress.clamp(0.0, 1.0);
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title ?? "Uploading...",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          Text(
            "${(progress * 100).toStringAsFixed(0)}% completed",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
