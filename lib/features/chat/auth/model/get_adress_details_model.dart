/// status : true
/// message : "Addresses retrieved successfully"
/// data : [{"_id":"68fc64f103d45bf9264269a5","userId":"689e28a878385d314533ec64","name":"Boopathi","phone":"6381213588","house_no":"raths house","street":"extrabs","landmark":"near templ","city":"salem","state":"tamilnadu","zip_code":"636012","note":"","country":"india","type":"Home","is_default":false,"lat":20.5937,"lng":78.96289999999999,"created_at":"2025-10-25T05:49:37.932Z","updated_at":"2025-10-25T05:49:37.932Z","__v":0}]

class GetAdressDetailsModel {
  GetAdressDetailsModel({
      this.status, 
      this.message, 
      this.data,});

  GetAdressDetailsModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(AddressDetails.fromJson(v));
      });
    }
  }
  bool? status;
  String? message;
  List<AddressDetails>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// _id : "68fc64f103d45bf9264269a5"
/// userId : "689e28a878385d314533ec64"
/// name : "Boopathi"
/// phone : "6381213588"
/// house_no : "raths house"
/// street : "extrabs"
/// landmark : "near templ"
/// city : "salem"
/// state : "tamilnadu"
/// zip_code : "636012"
/// note : ""
/// country : "india"
/// type : "Home"
/// is_default : false
/// lat : 20.5937
/// lng : 78.96289999999999
/// created_at : "2025-10-25T05:49:37.932Z"
/// updated_at : "2025-10-25T05:49:37.932Z"
/// __v : 0

class AddressDetails {
  AddressDetails({
      this.id, 
      this.userId, 
      this.name, 
      this.phone, 
      this.houseNo, 
      this.street, 
      this.landmark, 
      this.city, 
      this.state, 
      this.zipCode, 
      this.note, 
      this.country, 
      this.type, 
      this.isDefault, 
      this.lat, 
      this.lng, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  AddressDetails.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    name = json['name'];
    phone = json['phone'];
    houseNo = json['house_no'];
    street = json['street'];
    landmark = json['landmark'];
    city = json['city'];
    state = json['state'];
    zipCode = json['zip_code'];
    note = json['note'];
    country = json['country'];
    type = json['type'];
    isDefault = json['is_default'];
    lat = json['lat'];
    lng = json['lng'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    v = json['__v'];
  }
  String? id;
  String? userId;
  String? name;
  String? phone;
  String? houseNo;
  String? street;
  String? landmark;
  String? city;
  String? state;
  String? zipCode;
  String? note;
  String? country;
  String? type;
  bool? isDefault;
  num? lat;
  num? lng;
  String? createdAt;
  String? updatedAt;
  num? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['name'] = name;
    map['phone'] = phone;
    map['house_no'] = houseNo;
    map['street'] = street;
    map['landmark'] = landmark;
    map['city'] = city;
    map['state'] = state;
    map['zip_code'] = zipCode;
    map['note'] = note;
    map['country'] = country;
    map['type'] = type;
    map['is_default'] = isDefault;
    map['lat'] = lat;
    map['lng'] = lng;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}