class ResumeTemplateModel {
  final String name;
  final String url;

  ResumeTemplateModel({required this.name, required this.url});

  factory ResumeTemplateModel.fromJson(Map<String, dynamic> json) {
    return ResumeTemplateModel(
      name: json['name'],
      url: json['url'],
    );
  }
}
