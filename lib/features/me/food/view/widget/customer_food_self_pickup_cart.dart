import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/view/customer/food_self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerFoodSelfPickupCart extends StatefulWidget {
  final FoodSelfPickupController controller;

  const CustomerFoodSelfPickupCart({super.key, required this.controller});

  @override
  State<CustomerFoodSelfPickupCart> createState() =>
      _CustomerFoodSelfPickupCartState();
}

class _CustomerFoodSelfPickupCartState
    extends State<CustomerFoodSelfPickupCart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  Worker? _cartWorker;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_pulseController);

    _lastCount = widget.controller.selectedFoodVariants.length;
    // Pulse whenever the cart grows (new variant added). Removals are
    // ignored so the cart doesn't bounce while the user is trimming.
    _cartWorker = ever(widget.controller.selectedFoodVariants, (_) {
      final newCount = widget.controller.selectedFoodVariants.length;
      if (newCount > _lastCount) {
        _pulseController.forward(from: 0);
      }
      _lastCount = newCount;
    });
  }

  @override
  void dispose() {
    _cartWorker?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        final selected = widget.controller.selectedFoodVariants;
        final displayImages = selected.take(3).map((v) {
          final img = widget.controller.cartProductImages[v.id];
          if (img != null && img.isNotEmpty) return img;
          return null;
        }).toList();

        return ScaleTransition(
          scale: _pulseScale,
          child: FloatingCartWidget(
            itemCount: selected.length,
            displayImages: displayImages,
            onTap: () => Get.to(() => const FoodSelfPickUpCartScreen()),
          ),
        );
      }),
    );
  }
}
