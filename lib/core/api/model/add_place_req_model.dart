class AddPlaceReqModel {
  List<String> photoPath;
  List<String> category;
  String? visitingHours;
  String name;
  String latitude;
  String longitude;
  String address;
  String? shortDescription;
  String? phone;
  String? email;
  bool? isCommercial;

  AddPlaceReqModel({
    required this.photoPath,
    required this.category,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isCommercial,
    this.shortDescription,
    this.phone,
    this.email,
    this.visitingHours,
  });
}
