class VideoStatusModel {
  final bool? canUpload;
  final String? message;
  final RemainingTime? remainingTime;

  VideoStatusModel({
    this.canUpload,
    this.message,
    this.remainingTime,
  });

  factory VideoStatusModel.fromJson(Map<String, dynamic> json) {
    return VideoStatusModel(
      canUpload: json['canUpload'] as bool?,
      message: json['message'] as String?,
      remainingTime: json['remainingTime'] != null
          ? RemainingTime.fromJson(json['remainingTime'])
          : null,
    );
  }
}

class RemainingTime {
  final int? minutes;
  final int? seconds;
  final String? formatted;

  RemainingTime({
    this.minutes,
    this.seconds,
    this.formatted,
  });

  factory RemainingTime.fromJson(Map<String, dynamic> json) {
    return RemainingTime(
      minutes: json['minutes'] as int?,
      seconds: json['seconds'] as int?,
      formatted: json['formatted'] as String?,
    );
  }
}
