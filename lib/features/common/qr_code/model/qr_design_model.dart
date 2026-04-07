import 'package:flutter/material.dart';

enum QrDesignShape { house, rectangle, circle, rounded, captionedCard }

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

  /// ─── Captioned-card extras (used by [QrDesignShape.captionedCard]) ──────
  /// All optional so existing shapes are unaffected.

  /// Pill header above the QR. e.g. "QR Connects".
  final String? headerTitle;

  /// Small line under the header. e.g. "A smarter way to reach the vehicle Owner".
  final String? headerSubtitle;

  /// Bold caption right above the QR. e.g. "Parking or emergency? Scan here."
  final String? captionText;

  /// Short feature labels rendered as chips under the QR.
  /// e.g. ["Parking issue", "Emergency", "Vehicle alert"]
  final List<String> featureChips;

  /// Footer tagline. e.g. "Start using your phone camera or any QR app".
  final String? footerTagline;

  /// Background gradient — when set, replaces [backgroundColor].
  final Gradient? backgroundGradient;

  /// Accent color used for header pill, chips and footer code.
  /// Defaults to [borderColor] when null.
  final Color? accentColor;

  /// Color used for headline text on top of the card. Defaults to dark.
  final Color? headlineColor;

  /// Color used for body text on top of the card. Defaults to dark/grey.
  final Color? captionColor;

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
    this.headerTitle,
    this.headerSubtitle,
    this.captionText,
    this.featureChips = const [],
    this.footerTagline,
    this.backgroundGradient,
    this.accentColor,
    this.headlineColor,
    this.captionColor,
  });

  static List<QrDesignModel> get designs => [
        // ─── Featured: Bright yellow captioned card (matches mock) ───
        const QrDesignModel(
          id: 'qr_connects_yellow',
          name: 'QR Connects',
          shape: QrDesignShape.captionedCard,
          backgroundColor: Color(0xFFFFD400),
          qrColor: Color(0xFF1A1A2E),
          borderColor: Color(0xFF1A1A2E),
          borderWidth: 2.5,
          showLabel: false,
          showBranding: true,
          headerTitle: 'QR Connects',
          headerSubtitle: 'A smarter way to reach the vehicle Owner',
          captionText: 'Parking or emergency? Scan here.',
          featureChips: ['Parking issue', 'Emergency', 'Vehicle alert'],
          footerTagline:
              'Start using your phone camera or any QR app',
          accentColor: Color(0xFF1A1A2E),
          headlineColor: Color(0xFF1A1A2E),
          captionColor: Color(0xFF3D3A1F),
        ),

        // ─── Insta-style colorful gradient captioned card ───
        QrDesignModel(
          id: 'qr_connects_insta',
          name: 'Insta Vibes',
          shape: QrDesignShape.captionedCard,
          backgroundColor: const Color(0xFFFEDA77),
          qrColor: const Color(0xFF1A1A2E),
          borderColor: Colors.white,
          borderWidth: 3.0,
          showLabel: false,
          showBranding: true,
          headerTitle: 'BlueEra Connect',
          headerSubtitle: 'Reach the owner in one tap',
          captionText: 'Scan to call or chat instantly',
          featureChips: const ['Call', 'Chat', 'Locate'],
          footerTagline: 'Powered by BlueEra Safety',
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFEDA77),
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          accentColor: Colors.white,
          headlineColor: Colors.white,
          captionColor: Colors.white,
        ),

        // ─── Mint captioned ───
        const QrDesignModel(
          id: 'qr_connects_mint',
          name: 'Fresh Mint',
          shape: QrDesignShape.captionedCard,
          backgroundColor: Color(0xFFB8F2D6),
          qrColor: Color(0xFF0F3D2E),
          borderColor: Color(0xFF0F3D2E),
          borderWidth: 2.5,
          showLabel: false,
          showBranding: true,
          headerTitle: 'QR Connects',
          headerSubtitle: 'A smarter way to reach the vehicle Owner',
          captionText: 'Parking or emergency? Scan here.',
          featureChips: ['Parking issue', 'Emergency', 'Vehicle alert'],
          footerTagline: 'Start using your phone camera or any QR app',
          accentColor: Color(0xFF0F3D2E),
          headlineColor: Color(0xFF0F3D2E),
          captionColor: Color(0xFF1F4A38),
        ),

        // ─── Coral captioned ───
        const QrDesignModel(
          id: 'qr_connects_coral',
          name: 'Sunset Coral',
          shape: QrDesignShape.captionedCard,
          backgroundColor: Color(0xFFFFB5A7),
          qrColor: Color(0xFF3D1F1F),
          borderColor: Color(0xFF3D1F1F),
          borderWidth: 2.5,
          showLabel: false,
          showBranding: true,
          headerTitle: 'QR Connects',
          headerSubtitle: 'Reach the owner in one tap',
          captionText: 'Need help? Just scan & connect.',
          featureChips: ['Parking', 'Emergency', 'Tow alert'],
          footerTagline: 'Open camera or any QR app to scan',
          accentColor: Color(0xFF3D1F1F),
          headlineColor: Color(0xFF3D1F1F),
          captionColor: Color(0xFF5A2A2A),
        ),

        // ─── Sky blue captioned ───
        const QrDesignModel(
          id: 'qr_connects_sky',
          name: 'Sky Blue',
          shape: QrDesignShape.captionedCard,
          backgroundColor: Color(0xFFB3E5FC),
          qrColor: Color(0xFF0D2A4D),
          borderColor: Color(0xFF0D2A4D),
          borderWidth: 2.5,
          showLabel: false,
          showBranding: true,
          headerTitle: 'QR Connects',
          headerSubtitle: 'Smart way to reach vehicle owner',
          captionText: 'Parking or emergency? Scan here.',
          featureChips: ['Parking issue', 'Emergency', 'Vehicle alert'],
          footerTagline: 'Start using your phone camera or any QR app',
          accentColor: Color(0xFF0D2A4D),
          headlineColor: Color(0xFF0D2A4D),
          captionColor: Color(0xFF1F3D5C),
        ),

      ];
}
