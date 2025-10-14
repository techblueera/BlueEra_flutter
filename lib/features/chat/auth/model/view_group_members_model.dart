class GroupMembersListModel {
  String? id;
  String? accountType;
  String? name;
  String? contact;
  String? businessId;
  String? profileImage;
  bool? isAdmin;

  GroupMembersListModel(
      {this.id,
        this.accountType,
        this.name,
        this.contact,
        this.businessId,
        this.profileImage,
        this.isAdmin});

  GroupMembersListModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accountType = json['account_type'];
    name = json['name'];
    contact = json['contact'];
    businessId = json['business_id'];
    profileImage = json['profile_image'];
    isAdmin = json['is_admin'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['account_type'] = this.accountType;
    data['name'] = this.name;
    data['contact'] = this.contact;
    data['business_id'] = this.businessId;
    data['profile_image'] = this.profileImage;
    data['is_admin'] = this.isAdmin;
    return data;
  }
}
