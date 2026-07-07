/// Profile-section testimonial for a lab (customer quote card). See
/// lib/docs/LABORATORY_INTEGRATION.md §2. `authorName` + `message` are
/// required by the server; `designation` + `photoUrl` are optional.
class LabTestimonial {
  String? id;
  String? authorName;
  String? designation;
  String? message;
  String? photoUrl;
  String? userId;
  String? laboratoryId;
  String? createdAt;
  String? updatedAt;

  LabTestimonial({
    this.id,
    this.authorName,
    this.designation,
    this.message,
    this.photoUrl,
    this.userId,
    this.laboratoryId,
    this.createdAt,
    this.updatedAt,
  });

  factory LabTestimonial.fromJson(Map<String, dynamic> json) => LabTestimonial(
        id: json['_id']?.toString(),
        authorName: json['authorName']?.toString(),
        designation: json['designation']?.toString(),
        message: json['message']?.toString(),
        photoUrl: json['photoUrl']?.toString(),
        userId: json['userId']?.toString(),
        laboratoryId: json['laboratoryId']?.toString(),
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
      );

  /// Wire-shape for POST /testimonials and PUT /testimonials/:id. userId
  /// and laboratoryId are server-derived — never send them.
  Map<String, dynamic> toCreateJson() => {
        'authorName': authorName,
        if ((designation ?? '').isNotEmpty) 'designation': designation,
        'message': message,
        if ((photoUrl ?? '').isNotEmpty) 'photoUrl': photoUrl,
      };
}
