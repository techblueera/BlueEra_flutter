// class Certification {
//   final String id;
//   final String title;
//   final String issuingOrg;
//   final CertificationDate? certificateDate;
//   final String? certificateAttachment;
//   final DateTime? parsedDate;

//   Certification({
//     required this.id,
//     required this.title,
//     required this.issuingOrg,
//     this.certificateDate,
//     this.certificateAttachment,
//   }) : parsedDate = _parseDate(certificateDate);


//   factory Certification.fromMap(Map<String, dynamic> map) {
//     final id = map['_id'] ?? map['id'] ?? map['certificationId'] ?? '';
//     final dateData = map['certificateDate'] ?? map['date'] ?? map['issueDate'];
//     return Certification(
//       id: id.toString(),
//       title: map['title']?.toString() ?? 'Untitled',
//       issuingOrg: map['issuingOrg']?.toString() ?? 'Unknown',
//       certificateDate: dateData is Map ? CertificationDate.fromMap(dateData) : null,
//       certificateAttachment: map['certificateAttachment']?.toString(),
//     );
//   }


//   static DateTime? _parseDate(CertificationDate? date) {
//     if (date == null) return null;
//     try {
//       return DateTime(date.year, date.month, date.date);
//     } catch (e) {
//       return null;
//     }
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'title': title,
//       'issuingOrg': issuingOrg,
//       if (certificateDate != null) 'certificateDate': certificateDate!.toMap(),
//       if (certificateAttachment != null)
//         'certificateAttachment': certificateAttachment,
//     };
//   }

//   String get formattedDate {
//     if (certificateDate == null) return 'Date not specified';
//     return '${certificateDate!.date}/${certificateDate!.month.toString().padLeft(2, '0')}/${certificateDate!.year}';
//   }
// }

// class CertificationDate {
//   final int date;
//   final int month;
//   final int year;

//   CertificationDate({
//     required this.date,
//     required this.month,
//     required this.year,
//   });


//   factory CertificationDate.fromMap(Map map) {
//     final safeMap = map.map((k, v) => MapEntry(k.toString(), v));

//     return CertificationDate(
//       date: _parseInt(safeMap['date']),
//       month: _parseInt(safeMap['month']),
//       year: _parseInt(safeMap['year']),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'date': date,
//       'month': month,
//       'year': year,
//     };
//   }

//   static int _parseInt(dynamic value) {
//     if (value is int) return value;
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
// }


class Certification {
  final String id;
  final String title;
  final String issuingOrg;
  final CertificationDate? certificateDate;
  final String? certificateAttachment;
  final DateTime? parsedDate;

  Certification({
    required this.id,
    required this.title,
    required this.issuingOrg,
    this.certificateDate,
    this.certificateAttachment,
  }) : parsedDate = _parseDate(certificateDate);

  factory Certification.fromMap(Map<String, dynamic> map) {
    print('Parsing Certification: $map');
    final id = map['_id'] ?? map['id'] ?? map['certificationId'] ?? '';
    final dynamic dateData = map['certificateDate'] ?? map['date'] ?? map['issueDate'];
    print('date data: $dateData');
    print('date data type: ${dateData.runtimeType}');

    CertificationDate? certDate;
    if (dateData is Map) {
      try {
        certDate = CertificationDate.fromMap(Map<String, dynamic>.from(dateData));
      } catch (e) {
        print('Error parsing CertificationDate: $e');
        certDate = null;
      }
    } else {
      certDate = null;
    }

    return Certification(
      id: id.toString(),
      title: map['title']?.toString() ?? 'Untitled',
      issuingOrg: map['issuingOrg']?.toString() ?? 'Unknown',
      certificateDate: certDate,
      certificateAttachment: map['certificateAttachment']?.toString(),
    );
  }

  static DateTime? _parseDate(CertificationDate? date) {
    if (date == null) return null;
    try {
      return DateTime(date.year, date.month, date.date);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'issuingOrg': issuingOrg,
      if (certificateDate != null) 'certificateDate': certificateDate!.toMap(),
      if (certificateAttachment != null) 'certificateAttachment': certificateAttachment,
    };
  }

  String get formattedDate {
    if (certificateDate == null) return 'Date not specified';
    return '${certificateDate!.date}/${certificateDate!.month.toString().padLeft(2, '0')}/${certificateDate!.year}';
  }
}

class CertificationDate {
  final int date;
  final int month;
  final int year;

  CertificationDate({
    required this.date,
    required this.month,
    required this.year,
  });

  factory CertificationDate.fromMap(Map<String, dynamic> map) {
    print('Parsing CertificationDate: $map');
    map.forEach((key, value) => print('Key: $key, Value: $value'));
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    final safeMap = map.map((k, v) => MapEntry(k.toString(), v));
    return CertificationDate(
      date: parseInt(safeMap['date']),
      month: parseInt(safeMap['month']),
      year: parseInt(safeMap['year']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'month': month,
      'year': year,
    };
  }
}
