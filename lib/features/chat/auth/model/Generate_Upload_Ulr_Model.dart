/// files : [{"uploadUrl":"https://be-post-service-bck.s3.ap-south-1.amazonaws.com/uploads/1754126839682-56cb111d-0d57-4eae-815c-7fea961409f2.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAXYKJVYM5PSWCXEO2%2F20250802%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20250802T092719Z&X-Amz-Expires=1800&X-Amz-Signature=9acd3e78b25f3a9464da31217f62f289c855e499f318afcb8e76913a225a52fa&X-Amz-SignedHeaders=host&x-amz-acl=public-read&x-amz-checksum-crc32=AAAAAA%3D%3D&x-amz-sdk-checksum-algorithm=CRC32&x-id=PutObject","publicUrl":"https://be-post-service-bck.s3.ap-south-1.amazonaws.com/uploads%2F1754126839682-56cb111d-0d57-4eae-815c-7fea961409f2.mp4","fileKey":"uploads/1754126839682-56cb111d-0d57-4eae-815c-7fea961409f2.mp4","fileName":"VID_20250802_145647.mp4","fileType":"video/mp4"}]

class GenerateUploadUlrModel {
  GenerateUploadUlrModel({
      this.files,});

  GenerateUploadUlrModel.fromJson(dynamic json) {
    if (json['files'] != null) {
      files = [];
      json['files'].forEach((v) {
        files?.add(Files.fromJson(v));
      });
    }
  }
  List<Files>? files;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (files != null) {
      map['files'] = files?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// uploadUrl : "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/uploads/1754126839682-56cb111d-0d57-4eae-815c-7fea961409f2.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAXYKJVYM5PSWCXEO2%2F20250802%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20250802T092719Z&X-Amz-Expires=1800&X-Amz-Signature=9acd3e78b25f3a9464da31217f62f289c855e499f318afcb8e76913a225a52fa&X-Amz-SignedHeaders=host&x-amz-acl=public-read&x-amz-checksum-crc32=AAAAAA%3D%3D&x-amz-sdk-checksum-algorithm=CRC32&x-id=PutObject"
/// publicUrl : "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/uploads%2F1754126839682-56cb111d-0d57-4eae-815c-7fea961409f2.mp4"
/// fileKey : "uploads/1754126839682-56cb111d-0d57-4eae-815c-7fea961409f2.mp4"
/// fileName : "VID_20250802_145647.mp4"
/// fileType : "video/mp4"

class Files {
  Files({
      this.uploadUrl, 
      this.publicUrl, 
      this.fileKey, 
      this.fileName, 
      this.fileType,});

  Files.fromJson(dynamic json) {
    uploadUrl = json['uploadUrl'];
    publicUrl = json['publicUrl'];
    fileKey = json['fileKey'];
    fileName = json['fileName'];
    fileType = json['fileType'];
  }
  String? uploadUrl;
  String? publicUrl;
  String? fileKey;
  String? fileName;
  String? fileType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['uploadUrl'] = uploadUrl;
    map['publicUrl'] = publicUrl;
    map['fileKey'] = fileKey;
    map['fileName'] = fileName;
    map['fileType'] = fileType;
    return map;
  }

}