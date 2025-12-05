import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class BuildSectionHeaderWidget extends StatelessWidget {
  const BuildSectionHeaderWidget(
      {super.key, required this.title, required this.isShowArrow, this.onTap});

  final String title;
  final bool isShowArrow;
  final VoidCallback? onTap; // 2. Define the callback type
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          if (isShowArrow)
            Material( // Required for InkWell ripple effect
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap, // 3. Connect the callback
                borderRadius: BorderRadius.circular(50), // Circular ripple
                child: const Padding(
                  padding: EdgeInsets.all(8.0), // 4. Increases touch area for better UX
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),        ],
      ),
    );
  }
}
