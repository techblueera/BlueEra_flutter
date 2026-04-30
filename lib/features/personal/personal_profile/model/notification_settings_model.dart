class NotificationChannelPrefs {
  bool push;
  bool inApp;

  NotificationChannelPrefs({this.push = false, this.inApp = false});

  factory NotificationChannelPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationChannelPrefs();
    return NotificationChannelPrefs(
      push: json['push'] == true,
      inApp: json['inApp'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'push': push, 'inApp': inApp};

  NotificationChannelPrefs copy() =>
      NotificationChannelPrefs(push: push, inApp: inApp);

  bool get hasAny => push || inApp;
}

class NotificationSettingsModel {
  final Map<String, NotificationChannelPrefs> preferences;

  NotificationSettingsModel({required this.preferences});

  factory NotificationSettingsModel.fromJson(Map<String, dynamic>? json) {
    final root = json ?? const <String, dynamic>{};
    final raw = (root['preferences'] ?? root['data']?['preferences']) as Map?;
    final map = <String, NotificationChannelPrefs>{};
    if (raw != null) {
      raw.forEach((key, value) {
        if (value is Map) {
          map[key.toString()] =
              NotificationChannelPrefs.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return NotificationSettingsModel(preferences: map);
  }

  Map<String, dynamic> toRequestBody() {
    return {
      'preferences': preferences.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  NotificationSettingsModel copy() {
    return NotificationSettingsModel(
      preferences: preferences.map((k, v) => MapEntry(k, v.copy())),
    );
  }
}
