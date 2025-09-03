class VersionControlModel {
  String? status;
  String? message;
  String? latestVersion;
  String? storeUrl;

  VersionControlModel(
      {this.status, this.message, this.latestVersion, this.storeUrl});

  VersionControlModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    latestVersion = json['latestVersion'];
    storeUrl = json['storeUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['latestVersion'] = this.latestVersion;
    data['storeUrl'] = this.storeUrl;
    return data;
  }
}