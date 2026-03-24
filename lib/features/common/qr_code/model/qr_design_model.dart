import 'package:flutter/material.dart';

enum QrDesignShape { house, rectangle, circle, rounded }

class QrDesignModel {
  final String id;
  final String name;
  final QrDesignShape shape;
  final Color backgroundColor;
  final Color qrColor;
  final Color borderColor;
  final double borderWidth;
  final bool showLabel;
  final bool showBranding;
  final String? subtitle;

  const QrDesignModel({
    required this.id,
    required this.name,
    required this.shape,
    this.backgroundColor = Colors.white,
    this.qrColor = const Color(0xFF1A1A2E),
    this.borderColor = const Color(0xFF1A1A2E),
    this.borderWidth = 2.0,
    this.showLabel = true,
    this.showBranding = true,
    this.subtitle,
  });

  static List<QrDesignModel> get designs => [
        const QrDesignModel(
          id: 'scan_contact',
          name: 'Scan Me for Contact',
          shape: QrDesignShape.house,
          backgroundColor: Colors.white,
          qrColor: Color(0xFF1A1A2E),
          borderColor: Color(0xFF0086FF),
          borderWidth: 3.0,
          subtitle: 'BlueEra Safety',
        ),
        const QrDesignModel(
          id: 'emergency_alert',
          name: 'Emergency Contact',
          shape: QrDesignShape.house,
          backgroundColor: Color(0xFFFFF8E1),
          qrColor: Color(0xFF1A1A2E),
          borderColor: Color(0xFFFFC300),
          borderWidth: 3.0,
          subtitle: 'BlueEra Safety',
        ),
        const QrDesignModel(
          id: 'vehicle_safety',
          name: 'Vehicle Safety QR',
          shape: QrDesignShape.rectangle,
          backgroundColor: Colors.white,
          qrColor: Color(0xFF1A1A2E),
          borderColor: Color(0xFF1A1A2E),
          borderWidth: 2.0,
          subtitle: 'Scan & Visit',
        ),
        const QrDesignModel(
          id: 'minimal_round',
          name: 'Minimal Round',
          shape: QrDesignShape.circle,
          backgroundColor: Colors.white,
          qrColor: Color(0xFF1A1A2E),
          borderColor: Color(0xFF0086FF),
          borderWidth: 2.5,
          subtitle: 'BlueEra Safety',
        ),
        const QrDesignModel(
          id: 'rounded_card',
          name: 'Rounded Card',
          shape: QrDesignShape.rounded,
          backgroundColor: Color(0xFFF5F5F5),
          qrColor: Color(0xFF1A1A2E),
          borderColor: Color(0xFF505050),
          borderWidth: 1.5,
          subtitle: 'Scan for Info',
        ),
      ];
}
