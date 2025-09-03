import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AnimatedActionButtons extends StatefulWidget {
  const AnimatedActionButtons({Key? key}) : super(key: key);

  @override
  State<AnimatedActionButtons> createState() => _AnimatedActionButtonsState();
}

class _AnimatedActionButtonsState extends State<AnimatedActionButtons> with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  void _toggleMenu() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _controller.forward() : _controller.reverse();
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, {bool showFilters = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: showFilters ? 6 : 0, horizontal: 2.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black25,
              spreadRadius: 0,
              blurRadius: 4,
            ),
          ],
        ),
        child: FloatingActionButton(
          mini: true,
          heroTag: icon.toString(),
          backgroundColor: showFilters ? AppColors.primaryColor : AppColors.black23,
          onPressed: onTap,
          shape: CircleBorder(),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 20,
      child: Column(
        children: [
          // Toggle Button (Open/Close)
          _buildActionButton(_isOpen ? Icons.close : Icons.menu, _toggleMenu, showFilters: false),

          // Animated Expandable Buttons
          SizeTransition(
            sizeFactor: _expandAnimation,
            axis: Axis.vertical,
            axisAlignment: -1.0,
            child: Column(
              children: [
                _buildActionButton(Icons.flash_on, () {
                  // Flash toggle
                }),
                _buildActionButton(Icons.photo_library, () {
                  // Pick gallery image
                }),
                _buildActionButton(Icons.music_note, () {
                  // Add music
                }),
                _buildActionButton(Icons.auto_awesome, () {
                  // Effects
                }),
                _buildActionButton(Icons.text_fields, () {
                  // Add text
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
