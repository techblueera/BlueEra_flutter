import 'dart:io';

import 'package:flutter/services.dart';

import 'package:get/get.dart';


class PipFloatingPageController extends GetxController {
  final MethodChannel platformData =
  const MethodChannel('com.vahcare.lab/pip');

  RxBool isPipModeOn = false.obs;



  Future<void> setPipStatus(bool isEnabled) async {
    if(Platform.isAndroid) {
      await platformData.invokeMethod(
        'updatePipStatus',
        {"isEnabled": isEnabled},
      );
    }
  }



/*  Future<bool> isInPipMode() async {
    final result = await platformData.invokeMethod<bool>('isInPipMode');
    isPipModeOn.value = result ?? false;
    return result ?? false;
  }*/
}

/*class FloatingController {
  static final FloatingController _instance = FloatingController._internal();
  factory FloatingController() => _instance;
  FloatingController._internal();

  OverlayEntry? _overlayEntry;
  Offset position = const Offset(20, 100);

  bool _canClose = true;

  void show({
    required BuildContext context,
    required Widget child,
    required VoidCallback onMaximize,
    bool canClose = true,
  }) {
    if (_overlayEntry != null) return;

    _canClose = canClose;

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            color: Colors.transparent,
            child: Draggable(
              feedback: _wrap(child, onMaximize),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                position = details.offset;
              },
              child: _wrap(child, onMaximize),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void hide() {
    // if (!_canClose) return; // 🚫 cannot close
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _wrap(Widget child, VoidCallback onMaximize) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        if (_canClose)
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: hide,
              child: Container(
                height: 28,
                width: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}*/
