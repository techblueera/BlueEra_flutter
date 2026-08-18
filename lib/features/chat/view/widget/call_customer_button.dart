import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/call_customer_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Wraps a chat message list and hangs a "Call Customer" pill over its
/// bottom-right corner once a packing PDF has been sent in [conversationId].
///
/// Wrapping the *list* rather than the whole screen keeps the pill clear of the
/// message input bar, and it renders nothing at all until
/// [CallCustomerController] has a target — so it is always safe to wrap with.
///
/// Tap behaviour lives in [CallCustomerController.onTap]: the first tap places
/// the in-app call, later taps ask internet-vs-dialler. Long-press dismisses.
class CallCustomerOverlay extends StatelessWidget {
  const CallCustomerOverlay({
    super.key,
    required this.child,
    required this.conversationId,
  });

  final Widget child;
  final String? conversationId;

  @override
  Widget build(BuildContext context) {
    if ((conversationId ?? '').isEmpty) return child;

    return Stack(
      children: [
        child,
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(
              right: SizeConfig.size12,
              bottom: SizeConfig.size12,
            ),
            child: CallCustomerFab(conversationId: conversationId),
          ),
        ),
      ],
    );
  }
}

/// The bare "Call Customer" pill, for screens that already own a positioned
/// stack (e.g. the personal chat, which stacks it above the scroll-to-bottom
/// FAB). Renders nothing until a packing PDF has been sent in [conversationId].
class CallCustomerFab extends StatelessWidget {
  const CallCustomerFab({super.key, required this.conversationId});

  final String? conversationId;

  @override
  Widget build(BuildContext context) {
    if ((conversationId ?? '').isEmpty) return const SizedBox.shrink();
    final controller = getOrPut(() => CallCustomerController());

    return Obx(() {
      final target = controller.targetFor(conversationId);
      if (target == null) return const SizedBox.shrink();
      return _CallCustomerPill(
        onTap: () => controller.onTap(context, target),
        onLongPress: () => controller.dismiss(target.conversationId),
      );
    });
  }
}

class _CallCustomerPill extends StatelessWidget {
  const _CallCustomerPill({required this.onTap, required this.onLongPress});

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.call_rounded, color: Colors.white, size: 18),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                AppStrings.callCustomer.tr,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
