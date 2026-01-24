class ProfessionalContact {
  String? name;
  String? conversationId;
  String? contactNo;
  String? profileImage;
  String? designation;
  String? accountType;
  String? id;

  ProfessionalContact({
    this.name,
    this.conversationId,
    this.contactNo,
    this.profileImage,
    this.designation,
    this.accountType,
    this.id,
  });

  factory ProfessionalContact.fromJson(Map<String, dynamic> json) {
    return ProfessionalContact(
      name: json['name'],
      conversationId: json['conversationId'],
      contactNo: json['contactNo'],
      profileImage: json['profileImage'],
      designation: json['designation'],
      accountType: json['accountType'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'conversationId': conversationId,
      'contactNo': contactNo,
      'profileImage': profileImage,
      'designation': designation,
      'accountType': accountType,
      'id': id,
    };
  }
}
