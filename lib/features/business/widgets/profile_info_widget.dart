import 'package:BlueEra/features/business/widgets/stats_card_widget.dart';
import 'package:flutter/material.dart';

import '../auth/model/viewBusinessProfileModel.dart';


class ProfileInfoWidget extends StatelessWidget {
 ProfileInfoWidget({super.key});
  BusinessProfileDetails? data;

  @override
  Widget build(BuildContext context) {
    return  StatsCard(dateOfInCorp: "1/1/2023", rating: data?.rating??0,);
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        if (icon != null) ...[
          Icon(icon, color: Color(0xFF2399F5), size: 12),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Color(0xFF2399F5)),
        ),
      ],
    );
  }
}
