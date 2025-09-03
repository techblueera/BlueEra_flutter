

import 'package:flutter/material.dart';

class TabButtonsBarWidget extends StatelessWidget {
  const TabButtonsBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tabItems = [
      {"label": "Profile", "isFilled": true},
      {"label": "Store"},
      {"label": "Posts"},
      {"label": "My Posts"},
      {"label": "Reviews"},
      {"label": "Our Branchs"},
    ];

    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabItems.map((item) {
            final bool isFilled = item["isFilled"] == true;
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              margin: const EdgeInsets.only(right: 16),
              child: Material(
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isFilled ? const Color(0xFF2399F5) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    // border: Border.all(color: const Color(0xFF2399F5)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  child: Text(
                    item["label"],
                    style: TextStyle(
                      color: isFilled ? Colors.white : const Color(0xFF2399F5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
