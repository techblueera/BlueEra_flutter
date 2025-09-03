class PollModel {
  final String? id;
  final String? question;
  //final List<String>? options;
  final List<Map<String, String>>? options;

  final int? correctOption;
  final String? subTitle;
  final double? latitude;
  final double? longitude;
  final String? type;

  PollModel({
    this.id,
    this.question,
    this.options,
    this.correctOption,
    this.subTitle,
    this.latitude,
    this.longitude,
    this.type = 'POLL_POST',
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['_id'],
      question: json['question'],
      //options: List<String>.from(json['options'] ?? []),
      options: (json['options'] as List?)?.map((item) => Map<String, String>.from(item)).toList(),
      correctOption: json['correct_option'],
      subTitle: json['sub_title'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'question': question,
      'options': options?.map((opt) => {'text': opt}).toList(),
      'correct_option': correctOption,
      'sub_title': subTitle,
      'latitude': latitude,
      'longitude': longitude,
      'type': 'POLL_POST',
    };
  }
}
