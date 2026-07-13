import '../../../common/delivery_partner/model/grocery_order_details.dart';

/// Job descriptor attached to every order that reaches a rider. The backend
/// derives it from `orderFor` (a passenger **ride**, a **goods** pickup, or a
/// **parcel** delivery) and ships it under `jobInfo` on order/claim/route
/// responses (and as flat `jobType`/`jobLabel`/`riderTask` fields on
/// notifications + the fare-call payload).
///
/// Display rule everywhere a rider sees an order:
///   header  = [jobLabel]
///   subline = [riderTask]
///
/// Legacy responses omit `jobInfo`; use [JobInfo.fromOrderFor] to derive it
/// client-side from `orderFor`. See
/// docs/backend/RIDER_JOBTYPE_CALL_OTP_MASTER_FRONTEND_GUIDE.md §1.
class JobInfo {
  final String? jobType; // ride | goods | parcel
  final String? orderFor;
  final String? jobLabel;
  final String? riderTask;
  final String? callTitle;
  final String? callBody;

  JobInfo({
    this.jobType,
    this.orderFor,
    this.jobLabel,
    this.riderTask,
    this.callTitle,
    this.callBody,
  });

  bool get isRide => jobType == 'ride';
  bool get isGoods => jobType == 'goods';
  bool get isParcel => jobType == 'parcel';

  factory JobInfo.fromJson(Map<String, dynamic> json) => JobInfo(
        jobType: json['jobType']?.toString(),
        orderFor: json['orderFor']?.toString(),
        jobLabel: json['jobLabel']?.toString(),
        riderTask: json['riderTask']?.toString(),
        callTitle: json['callTitle']?.toString(),
        callBody: json['callBody']?.toString(),
      );

  /// Fallback descriptor derived purely from `orderFor`, for legacy responses
  /// that predate the backend `jobInfo` field. Mirrors the server's mapping
  /// table.
  factory JobInfo.fromOrderFor(String? orderFor) {
    final value = orderFor ?? '';
    String jobType;
    String jobLabel;
    switch (value) {
      case 'InCity':
        jobType = 'ride';
        jobLabel = 'Passenger ride';
        break;
      case 'OutStation':
        jobType = 'ride';
        jobLabel = 'Outstation ride';
        break;
      case 'HourlyRental':
        jobType = 'ride';
        jobLabel = 'Hourly rental ride';
        break;
      case 'Parcel':
        jobType = 'parcel';
        jobLabel = 'Parcel delivery';
        break;
      case 'grocery':
        jobType = 'goods';
        jobLabel = 'Grocery pickup';
        break;
      case 'food':
        jobType = 'goods';
        jobLabel = 'Food pickup';
        break;
      case 'medical':
        jobType = 'goods';
        jobLabel = 'Medicine pickup';
        break;
      case 'product':
        jobType = 'goods';
        jobLabel = 'Goods pickup';
        break;
      default:
        jobType = 'ride';
        jobLabel = 'Ride';
    }
    String riderTask;
    switch (jobType) {
      case 'parcel':
        riderTask = 'Collect the parcel and deliver it';
        break;
      case 'goods':
        riderTask = 'Collect the order from the shop and deliver it';
        break;
      default:
        riderTask = 'Pick up and drop the passenger';
    }
    return JobInfo(
      jobType: jobType,
      orderFor: value,
      jobLabel: jobLabel,
      riderTask: riderTask,
    );
  }

  Map<String, dynamic> toJson() => {
        'jobType': jobType,
        'orderFor': orderFor,
        'jobLabel': jobLabel,
        'riderTask': riderTask,
        'callTitle': callTitle,
        'callBody': callBody,
      };
}

class RiderOrdersDetailsModel {
  RiderOrdersDetailsModel({
    this.orderId,
    this.id,
    this.userId,
    this.receiverUserId,
    this.status,
    this.orderFor,
    this.orderType,
    this.orderSource,
    this.modeOfPayment,
    this.assignedRider,
    this.retryCount,
    this.createdAt,
    this.updatedAt,
    this.pickupLocation,
    this.dropLocation,
    this.fare,
    this.distanceToPickup,
    this.distancePickupToDrop,
    this.user,
    this.receiverUser,
    this.pickupOTP,
    this.deliveryOTP,
    this.orderNo,
    this.timestamps,
    this.potentialRiders,
    this.selectedRiders,
    this.rejectedRiders,
    this.groceryOrderDetails,
    this.jobInfo,
    this.isMultiStop,
    this.stops,
    this.version,
  });

  RiderOrdersDetailsModel.fromJson(dynamic json) {
    orderId = json['orderId'];
    id = json['_id'];
    userId = json['userId'];
    receiverUserId = json['receiverUserId'];
    status = json['status'];
    orderFor = json['orderFor'];
    orderType = json['orderType'];
    orderSource = json['orderSource'];
    modeOfPayment = json['modeOfPayment'];
    assignedRider = json['assignedRider'];
    retryCount = json['retryCount'];
    orderNo = json['orderNo']?.toString();
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    version = json['__v'];

    pickupLocation =
    json['pickupLocation'] != null ? PickupLocation.fromJson(json['pickupLocation']) : null;

    dropLocation =
    json['dropLocation'] != null ? DropLocation.fromJson(json['dropLocation']) : null;

    fare = json['fare'];
    distanceToPickup = json['distanceToPickup']?.toString();
    distancePickupToDrop = json['distancePickupToDrop']?.toString();

    user = json['user'] != null ? User.fromJson(json['user']) : null;
    receiverUser =
    json['receiverUser'] != null ? ReceiverUser.fromJson(json['receiverUser']) : null;

    pickupOTP = json['pickupOTP']?.toString();
    deliveryOTP = json['deliveryOTP']?.toString();

    timestamps = json['timestamps'];

    potentialRiders = json['potentialRiders'] != null
        ? List<String>.from(json['potentialRiders'])
        : [];

    selectedRiders = json['selectedRiders'] != null
        ? List<String>.from(json['selectedRiders'])
        : [];

    rejectedRiders = json['rejectedRiders'] != null
        ? List<String>.from(json['rejectedRiders'])
        : [];

    groceryOrderDetails =
    json['groceryOrderDetails'] != null ? GroceryOrderDetails.fromJson(json['groceryOrderDetails']) : null;

    // Job descriptor: prefer the server-supplied `jobInfo`; fall back to
    // deriving it from `orderFor` for legacy responses that omit it.
    jobInfo = json['jobInfo'] != null
        ? JobInfo.fromJson(Map<String, dynamic>.from(json['jobInfo']))
        : JobInfo.fromOrderFor(orderFor);

    // Multi-shop: one pickup OTP per shop, carried in `stops[]` keyed by
    // businessId (RIDER_FRONTEND_INTEGRATION_GUIDE §5 / §8.3).
    isMultiStop = json['isMultiStop'] == true;
    stops = json['stops'] is List
        ? (json['stops'] as List)
            .map((e) => RideStop.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : null;
  }

  String? orderId;
  String? id;
  String? userId;
  String? receiverUserId;
  String? status;
  String? orderFor;
  String? orderType;

  /// How the order was created — `"chat-dispatch"` (rider dispatched from a
  /// self-pickup chat card), `"standard"`, etc. Used to recognise a chat-grocery
  /// handoff so single-shop orders render the unified rider card.
  String? orderSource;
  String? modeOfPayment;
  String? assignedRider;
  int? retryCount;
  String? createdAt;
  String? updatedAt;
  String? orderNo;
  int? version;

  PickupLocation? pickupLocation;
  DropLocation? dropLocation;

  num? fare;
  String? distanceToPickup;
  String? distancePickupToDrop;

  User? user;
  ReceiverUser? receiverUser;

  String? pickupOTP;
  String? deliveryOTP;

  Map<String, dynamic>? timestamps;

  List<String>? potentialRiders;
  List<String>? selectedRiders;
  List<String>? rejectedRiders;

  GroceryOrderDetails? groceryOrderDetails;

  JobInfo? jobInfo;

  bool? isMultiStop;
  List<RideStop>? stops;

  /// A grocery order that uses the chat → rider handoff (two-OTP) flow: a
  /// multi-stop order, or a single-shop chat-dispatch order. Such orders have
  /// their shop(s) chosen at booking, so the rider works them via the unified
  /// per-shop OTP card instead of re-selecting shops.
  ///
  /// Deliberately does NOT key off `groceryOrderDetails.businesses` — legacy
  /// grocery orders also gain a businesses list once accepted, and those must
  /// stay on the legacy [OrderCard] flow.
  bool get isChatGroceryHandoff {
    final isGrocery = (orderFor ?? '').toLowerCase() == 'grocery';
    if (!isGrocery) return false;
    return (isMultiStop == true) || (orderSource == 'chat-dispatch');
  }

  /// That shop's pickup OTP from `stops[]` (matched by businessId). Falls back
  /// to the order-level [pickupOTP] for legacy orders without per-stop OTPs.
  String? pickupOtpForBusiness(String businessId) {
    final stop = stops?.firstWhere(
      (s) => s.businessId == businessId,
      orElse: () => RideStop(),
    );
    final otp = stop?.pickupOTP;
    return (otp != null && otp.isNotEmpty) ? otp : pickupOTP;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['orderId'] = orderId;
    map['_id'] = id;
    map['userId'] = userId;
    map['receiverUserId'] = receiverUserId;
    map['status'] = status;
    map['orderFor'] = orderFor;
    map['orderType'] = orderType;
    map['orderSource'] = orderSource;
    map['modeOfPayment'] = modeOfPayment;
    map['assignedRider'] = assignedRider;
    map['retryCount'] = retryCount;
    map['orderNo'] = orderNo;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = version;
    map['fare'] = fare;
    map['distanceToPickup'] = distanceToPickup;
    map['distancePickupToDrop'] = distancePickupToDrop;
    map['pickupOTP'] = pickupOTP;
    map['deliveryOTP'] = deliveryOTP;
    map['timestamps'] = timestamps;
    map['potentialRiders'] = potentialRiders;
    map['selectedRiders'] = selectedRiders;
    map['rejectedRiders'] = rejectedRiders;
    map['groceryOrderDetails'] = groceryOrderDetails;
    map['jobInfo'] = jobInfo?.toJson();
    map['isMultiStop'] = isMultiStop;
    map['stops'] = stops?.map((e) => e.toJson()).toList();

    if (groceryOrderDetails != null) {
      map['groceryOrderDetails'] = groceryOrderDetails!.toJson();
    }
    if (pickupLocation != null) {
      map['pickupLocation'] = pickupLocation!.toJson();
    }
    if (dropLocation != null) {
      map['dropLocation'] = dropLocation!.toJson();
    }
    if (user != null) {
      map['user'] = user!.toJson();
    }
    if (receiverUser != null) {
      map['receiverUser'] = receiverUser!.toJson();
    }
    return map;
  }
}

/// One pickup stop of a multi-shop order. Each shop carries its own
/// [pickupOTP] (shown read-only to the rider, entered by that shopkeeper) and
/// a [sequence] (0 = furthest, visited first). See guide §5 / §8.3.
class RideStop {
  RideStop({
    this.businessId,
    this.shopName,
    this.address,
    this.sequence,
    this.status,
    this.pickupOTP,
    this.location,
    this.contactNo,
  });

  RideStop.fromJson(Map<String, dynamic> json) {
    businessId = json['businessId']?.toString();
    shopName = json['shopName']?.toString();
    address = json['address']?.toString();
    sequence = json['sequence'] is int
        ? json['sequence'] as int
        : int.tryParse(json['sequence']?.toString() ?? '');
    status = json['status']?.toString();
    pickupOTP = json['pickupOTP']?.toString();
    location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
    contactNo = json['contactNo']?.toString();
  }

  String? businessId;
  String? shopName;
  String? address;
  int? sequence;
  String? status;
  String? pickupOTP;
  Location? location;
  String? contactNo;

  /// Shop latitude from the GeoJSON `[lng, lat]` coordinate pair, if present.
  double? get latitude {
    final c = location?.coordinates;
    return (c != null && c.length >= 2) ? c[1].toDouble() : null;
  }

  /// Shop longitude from the GeoJSON `[lng, lat]` coordinate pair, if present.
  double? get longitude {
    final c = location?.coordinates;
    return (c != null && c.length >= 2) ? c[0].toDouble() : null;
  }

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'shopName': shopName,
        'address': address,
        'sequence': sequence,
        'status': status,
        'pickupOTP': pickupOTP,
        'location': location?.toJson(),
        'contactNo': contactNo,
      };
}

/* ---------------- SUB MODELS ---------------- */

class ReceiverUser {
  ReceiverUser({this.id, this.name, this.profileImage, this.contactNo});

  ReceiverUser.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profileImage = json['profile_image'];
    contactNo = json['contact_no'];
  }

  String? id;
  String? name;
  String? profileImage;
  String? contactNo;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'profile_image': profileImage,
    'contact_no': contactNo,
  };
}

class User {
  User({this.id, this.name, this.profileImage, this.contactNo});

  User.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profileImage = json['profile_image'];
    contactNo = json['contact_no'];
  }

  String? id;
  String? name;
  String? profileImage;
  String? contactNo;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'profile_image': profileImage,
    'contact_no': contactNo,
  };
}

class DropLocation {
  DropLocation({this.address, this.location});

  DropLocation.fromJson(dynamic json) {
    address = json['address'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
  }

  String? address;
  Location? location;

  Map<String, dynamic> toJson() => {
    'address': address,
    'location': location?.toJson(),
  };
}

class PickupLocation {
  PickupLocation({this.address, this.location});

  PickupLocation.fromJson(dynamic json) {
    address = json['address'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
  }

  String? address;
  Location? location;

  Map<String, dynamic> toJson() => {
    'address': address,
    'location': location?.toJson(),
  };
}

class Location {
  Location({this.type, this.coordinates});

  Location.fromJson(dynamic json) {
    type = json['type'];
    coordinates =
    json['coordinates'] != null ? List<num>.from(json['coordinates']) : [];
  }

  String? type;
  List<num>? coordinates;

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
  };
}
