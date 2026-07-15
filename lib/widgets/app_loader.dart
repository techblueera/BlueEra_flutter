import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-wide loader.
///
/// - `AppLoader.show()` → small circular staggered-dots dialog (no message).
/// - `AppLoader.show(message: 'Uploading…')` → rounded card with a spinner
///   ring, live-updating message, and an indeterminate progress bar.
/// - `AppLoader.showLogout()` → dedicated logout variant.
class AppLoader {
  AppLoader._();

  static final RxString _message = ''.obs;
  static bool _isShowing = false;

  /// Set when [hide] is called before the dialog route has finished mounting
  /// (fast action between show/hide). The pending close is retried each frame
  /// until the route exists, so the loader can never get "stuck" open.
  static bool _hideRequested = false;
  static int _hideAttempts = 0;

  static void show({String? message}) {
    if (_isShowing) {
      if (message != null) _message.value = message;
      return;
    }
    _isShowing = true;
    _hideRequested = false;

    final dialogChild = (message == null || message.isEmpty)
        ? _buildPlain()
        : () {
            _message.value = message;
            return _AppLoaderActionCard(message: _message);
          }();

    Get.dialog(
      dialogChild,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    ).whenComplete(() {
      _isShowing = false;
      _hideRequested = false;
    });
  }

  /// Update the message while an action loader is visible.
  static void updateMessage(String message) {
    _message.value = message;
  }

  static void hide() {
    if (!_isShowing) return;
    if (Get.isDialogOpen ?? false) {
      Get.back();
      _isShowing = false;
      _hideRequested = false;
    } else {
      // Dialog route hasn't mounted yet — hide() raced ahead of show()'s push.
      // Defer the close and retry on the next frame(s) so it dismisses
      // smoothly instead of leaving the loader on screen.
      _hideRequested = true;
      _hideAttempts = 0;
      _closeWhenReady();
    }
  }

  static void _closeWhenReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isShowing || !_hideRequested) {
        _hideRequested = false;
        return;
      }
      if (Get.isDialogOpen ?? false) {
        Get.back();
        _isShowing = false;
        _hideRequested = false;
      } else if (_hideAttempts++ < 20) {
        _closeWhenReady();
      } else {
        // Give up gracefully rather than spin forever.
        _hideRequested = false;
      }
    });
  }

  static Widget _buildPlain() {
    return Center(
      child: Container(
        width: SizeConfig.size90,
        height: SizeConfig.size90,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
        ),
        child: staggeredDotsWaveLoading(color: AppColors.primaryColor),
      ),
    );
  }

  static void showLogout() {
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logging out...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }
}

class _AppLoaderActionCard extends StatelessWidget {
  final RxString message;
  const _AppLoaderActionCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 260,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryColor.withValues(alpha: 0.15),
                            AppColors.primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => CustomText(
                    message.value,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    textAlign: TextAlign.center,
                  )),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
