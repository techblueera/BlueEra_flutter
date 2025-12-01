import 'package:flutter/material.dart';

class GradientFloatingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final IconData? icon;
  final double? width;
  final double? height;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<Color> backgroundGradientColors;
  final List<BoxShadow>? boxShadow;
  final List<Color> borderGradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final bool isEnabled;

  const GradientFloatingButton({
    Key? key,
    this.onPressed,
    this.child,
    this.text,
    this.icon,
    this.width,
    this.height,
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.padding,
    this.backgroundGradientColors = const [
      Color(0xFF6A11CB),
      Color(0xFF2575FC),
    ],
    this.borderGradientColors = const [
      Color(0xFFFF6B9D),
      Color(0xFFC06C84),
    ],
    this.boxShadow,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 56.0,
      decoration: BoxDecoration(
        // Border gradient
        gradient: LinearGradient(
          colors: isEnabled
              ? borderGradientColors
              : [Colors.grey.shade400, Colors.grey.shade400],
          begin: gradientBegin,
          end: gradientEnd,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow
      ),
      child: Container(
        // Inner container with margin to show border
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          // Background gradient
          gradient: LinearGradient(
            colors: isEnabled
                ? backgroundGradientColors
                : [Colors.grey.shade300, Colors.grey.shade300],
            begin: gradientBegin,
            end: gradientEnd,
          ),
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            child: Container(
              padding: padding ??
                  const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
              alignment: Alignment.center,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (child != null) {
      return child!;
    }

    if (icon != null && text != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Text(
            text!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Icon(
        icon,
        color: Colors.white,
        size: 24.0,
      );
    }

    if (text != null) {
      return Text(
        text!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// Example Usage Widget
class GradientFloatingButtonExample extends StatelessWidget {
  const GradientFloatingButtonExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Gradient Floating Button'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Button with text only
              GradientFloatingButton(
                text: 'Submit',
                onPressed: () {
                  print('Submit pressed');
                },
              ),
              const SizedBox(height: 20),

              // Button with icon and text
              GradientFloatingButton(
                text: 'Add Item',
                icon: Icons.add,
                onPressed: () {
                  print('Add Item pressed');
                },
              ),
              const SizedBox(height: 20),

              // Button with icon only
              GradientFloatingButton(
                icon: Icons.favorite,
                width: 60,
                height: 60,
                borderRadius: 30,
                onPressed: () {
                  print('Favorite pressed');
                },
              ),
              const SizedBox(height: 20),

              // Custom gradient colors
              GradientFloatingButton(
                text: 'Custom Colors',
                icon: Icons.color_lens,
                backgroundGradientColors: const [
                  Color(0xFFFF512F),
                  Color(0xFFDD2476),
                ],
                borderGradientColors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFF8C00),
                ],
                onPressed: () {
                  print('Custom colors pressed');
                },
              ),
              const SizedBox(height: 20),

              // Full width button
              GradientFloatingButton(
                text: 'Continue',
                width: double.infinity,
                backgroundGradientColors: const [
                  Color(0xFF11998E),
                  Color(0xFF38EF7D),
                ],
                borderGradientColors: const [
                  Color(0xFF134E5E),
                  Color(0xFF71B280),
                ],
                onPressed: () {
                  print('Continue pressed');
                },
              ),
              const SizedBox(height: 20),

              // Disabled button
              GradientFloatingButton(
                text: 'Disabled',
                icon: Icons.block,
                isEnabled: false,
                onPressed: () {
                  print('This should not print');
                },
              ),
              const SizedBox(height: 20),

              // Custom border width and radius
              GradientFloatingButton(
                text: 'Thick Border',
                icon: Icons.border_all,
                borderWidth: 4.0,
                borderRadius: 20.0,
                backgroundGradientColors: const [
                  Color(0xFF4A00E0),
                  Color(0xFF8E2DE2),
                ],
                borderGradientColors: const [
                  Color(0xFFFFE000),
                  Color(0xFFFF6B00),
                ],
                onPressed: () {
                  print('Thick border pressed');
                },
              ),
              const SizedBox(height: 20),

              // Custom child widget
              GradientFloatingButton(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shopping_cart, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Buy Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
                backgroundGradientColors: const [
                  Color(0xFFDA4453),
                  Color(0xFF89216B),
                ],
                borderGradientColors: const [
                  Color(0xFFFC466B),
                  Color(0xFF3F5EFB),
                ],
                onPressed: () {
                  print('Buy Now pressed');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}