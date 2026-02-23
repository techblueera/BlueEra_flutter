import 'dart:ui';

class SubscriptionPlanStyleModel {
  final String bg;
  final Color color;

  SubscriptionPlanStyleModel({
    required this.bg,
    required this.color,
  });

  factory SubscriptionPlanStyleModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlanStyleModel(
      bg: map['bg'] as String,
      color: map['textColor'] as Color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bg': bg,
      'textColor': color,
    };
  }

  SubscriptionPlanStyleModel copyWith({
    String? bg,
    Color? textColor,
  }) {
    return SubscriptionPlanStyleModel(
      bg: bg ?? this.bg,
      color: textColor ?? this.color,
    );
  }
}