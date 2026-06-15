import 'dart:io';

import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';

/// Mutable working copy of a vehicle while the multi-step add flow is
/// open. Each step reads/writes the fields it owns; on submit
/// [toVehicle] folds everything into an immutable [Vehicle] whose
/// `toCreateJson()` already gates the NEW/USED specific blocks.
///
/// Media is kept as local [File]s here (uploaded by the controller on
/// submit) rather than URLs.
class VehicleDraft {
  String condition; // VehicleCondition.isNew / .used

  // Taxonomy (3 tiers)
  String? category;
  String? subCategory;
  String? type;

  // Shared
  String? brand;
  String? model;
  String? variant;
  String? description;
  VehicleFuelType? fuelType;
  VehicleTransmission? transmission;
  int? engineCapacityCc;
  String? mileage;

  // NEW
  String? availability;
  String? deliveryTime;
  double? exShowroomPrice;
  double? onRoadPrice;
  bool emiAvailable = false;
  double? downPayment;
  double? monthlyEmi;
  List<String> specialOffers = [];

  // USED
  int? manufacturingYear;
  int? registrationYear;
  String? registrationNo;
  String? ownership;
  String? conditionGrade;
  double? expectedPrice;
  bool isNegotiable = false;
  int? kmDriven;
  DateTime? insuranceValidTill;
  bool rcAvailable = false;
  bool pollutionCertificate = false;
  bool serviceHistory = false;
  String? color;

  // Location + seller contact
  String? state;
  String? city;
  String? area;
  int? pincode;
  String? sellerName;
  String? sellerMobile;

  // Local media picks (uploaded on submit)
  final List<File> photoFiles = [];
  final List<File> videoFiles = [];

  VehicleDraft({required this.condition});

  bool get isNew => condition == VehicleCondition.isNew;
  bool get isUsed => condition == VehicleCondition.used;

  /// A human title for the listing, assembled from brand/model/variant
  /// (the form has no separate "name" field). Falls back so `name` —
  /// which the API always requires — is never empty.
  String get listingName {
    final parts = [brand, model, variant]
        .map((e) => (e ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return 'Vehicle Listing';
  }

  VehicleLocation? get _location {
    final hasAny = (state ?? '').trim().isNotEmpty ||
        (city ?? '').trim().isNotEmpty ||
        (area ?? '').trim().isNotEmpty ||
        pincode != null;
    if (!hasAny) return null;
    return VehicleLocation(
      state: (state ?? '').trim().isEmpty ? null : state!.trim(),
      city: (city ?? '').trim().isEmpty ? null : city!.trim(),
      address: (area ?? '').trim().isEmpty ? null : area!.trim(),
      pincode: pincode,
    );
  }

  Vehicle toVehicle() {
    return Vehicle(
      name: listingName,
      condition: condition,
      category: category,
      subCategory: subCategory,
      type: type,
      brand: (brand ?? '').trim().isEmpty ? null : brand!.trim(),
      model: (model ?? '').trim().isEmpty ? null : model!.trim(),
      variant: (variant ?? '').trim().isEmpty ? null : variant!.trim(),
      description:
          (description ?? '').trim().isEmpty ? null : description!.trim(),
      fuelType: fuelType,
      transmission: transmission,
      engineCapacityCc: engineCapacityCc,
      mileage: (mileage ?? '').trim().isEmpty ? null : mileage!.trim(),
      currency: 'INR',
      location: _location,
      sellerName: (sellerName ?? '').trim().isEmpty ? null : sellerName!.trim(),
      sellerMobile:
          (sellerMobile ?? '').trim().isEmpty ? null : sellerMobile!.trim(),
      // NEW
      availability: availability,
      deliveryTime: deliveryTime,
      exShowroomPrice: exShowroomPrice,
      onRoadPrice: onRoadPrice,
      emiAvailable: isNew ? emiAvailable : null,
      downPayment: downPayment,
      monthlyEmi: monthlyEmi,
      specialOffers: specialOffers,
      // USED
      manufacturingYear: manufacturingYear,
      registrationYear: registrationYear,
      registrationNo: (registrationNo ?? '').trim().isEmpty
          ? null
          : registrationNo!.trim(),
      ownership: ownership,
      conditionGrade: conditionGrade,
      expectedPrice: expectedPrice,
      isNegotiable: isUsed ? isNegotiable : null,
      kmDriven: kmDriven,
      insuranceValidTill: insuranceValidTill,
      rcAvailable: isUsed ? rcAvailable : null,
      pollutionCertificate: isUsed ? pollutionCertificate : null,
      serviceHistory: isUsed ? serviceHistory : null,
      color: (color ?? '').trim().isEmpty ? null : color!.trim(),
    );
  }
}
