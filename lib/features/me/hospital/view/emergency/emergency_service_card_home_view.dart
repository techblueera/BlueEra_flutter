import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class EmergencyServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String? icon; // Or use an Image.asset for custom icons

  const EmergencyServiceCard({
    required this.title,
    required this.description,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Box
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: LocalAssets(imagePath: icon??""),
          ),
          const SizedBox(width: 16),
          CustomText(
            title,
              fontSize: 18,
              // color: Colors.black87,
          ),
          // Text Content
      /*    Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // const SizedBox(height: 4),
                // Text(
                //   description,
                //   style: TextStyle(
                //     fontSize: 13,
                //     color: Colors.grey.shade600,
                //     height: 1.4,
                //   ),
                //   maxLines: 2,
                //   overflow: TextOverflow.ellipsis,
                // ),
              ],
            ),
          ),*/
        ],
      ),
    );
  }
}