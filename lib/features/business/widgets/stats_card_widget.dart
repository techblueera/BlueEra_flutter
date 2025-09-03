import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.dateOfInCorp, required this.rating});

  final String dateOfInCorp;
  final int rating;


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD3E4F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  CustomText(
                    'Rating: ',
                    fontSize: 13,
                    color: Color.fromRGBO(38, 50, 56, 1),
                  ),
                  Icon(Icons.star, size: 14, color: Colors.black87),
                  SizedBox(width: 4),
                  CustomText(
                    '0',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(38, 50, 56, 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CustomText(
                    'Views: ',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(38, 50, 56, 1),
                  ),
                  CustomText(
                    rating.toString(),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(38, 50, 56, 1),
                  ),
                ],
              ),
            ],
          ),

          // Vertical Divider
          const SizedBox(
            height: 40,
            child: VerticalDivider(
              color: Colors.black26,
              thickness: 1,
              width: 32,
            ),
          ),

          // Middle Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  CustomText(
                    'Inquiries: ',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(38, 50, 56, 1),
                  ),
                  CustomText(
                    '0',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(38, 50, 56, 1),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  CustomText(
                    'Followers: ',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(38, 50, 56, 1),
                  ),
                  CustomText(
                    '0',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(38, 50, 56, 1),
                  ),
                ],
              ),
            ],
          ),

          // Vertical Divider
          const SizedBox(
            height: 40,
            child: VerticalDivider(
              color: Colors.black26,
              thickness: 1,
              width: 32,
            ),
          ),

          // Right Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                'Joined',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color.fromRGBO(38, 50, 56, 1),
              ),
              SizedBox(height: 8),
              CustomText(
                '${dateOfInCorp}',
                // style: TextStyle(
                fontSize: 13,

                color: Color.fromRGBO(38, 50, 56, 1),
                // ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
