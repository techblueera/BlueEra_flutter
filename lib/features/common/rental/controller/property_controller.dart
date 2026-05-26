import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/rental/controller/property_dashboard_controller.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

class PropertyController extends GetxController {
  final PropertyRepo _repo = PropertyRepo();

  // ── Step 1 ──
  final listingType = ''.obs; // "Sell" or "Rent"
  final selectedPropertyTypeIndex = 0.obs;
  final selectedPropertyKind = 0.obs; // 0=Residential, 1=Commercial
  final projectName = ''.obs;
  final description = ''.obs;

  // ── Area unit (shared across step 2 screens) ──
  final areaUnit = 'sq.ft.'.obs;
  static const areaUnitOptions = ['sq.ft.', 'sq.m.', 'sq.yd.', 'acres'];

  // ── Location (shared across step 2 screens) ──
  final locationAddress = ''.obs;
  final locationLat = 0.0.obs;
  final locationLng = 0.0.obs;

  // ── Step 3 (shared) ──
  final photoPaths = <String>[].obs;
  final isPriceRange = false.obs;
  final price = ''.obs;
  final priceFrom = ''.obs;
  final priceTo = ''.obs;
  final priceType = 'PerMonth'.obs;
  static const priceTypeOptions = ['PerMonth', 'PerYear', 'OneTime'];
  static const priceTypeLabels = {
    'PerMonth': 'Per Month',
    'PerYear': 'Per Year',
    'OneTime': 'One Time',
  };
  final allInclusivePrice = false.obs;
  final priceNegotiable = false.obs;
  final taxAndGovtChargeExcluded = false.obs;
  final securityDeposit = false.obs;
  final electricityIncluded = false.obs;
  final waterChargesIncluded = false.obs;

  // ── House & Apartment ──
  final haPropertyLocation = ''.obs;
  final haType = 0.obs;
  final haBhk = 0.obs;
  final haBathrooms = 0.obs;
  final haAvailabilityStatus = 0.obs;
  final haFurnishing = 0.obs;
  final haListedBy = 0.obs;
  final haBachelorsAllowed = 0.obs;
  final haArea = ''.obs;
  final haMaintenance = ''.obs;
  final haTotalFloors = ''.obs;
  final haFloorNo = ''.obs;
  final haCarParking = 0.obs;
  final haFacing = 0.obs;

  // ── Land & Plots ──
  final lpPropertyLocation = ''.obs;
  final lpProjectType = 0.obs;
  final lpListedBy = 0.obs;
  final lpPlotArea = ''.obs;
  final lpLength = ''.obs;
  final lpBreadth = ''.obs;
  final lpFacing = 0.obs;

  // ── Shop & Offices ──
  final soPropertyLocation = ''.obs;
  final soFurnishing = 0.obs;
  final soProjectStatus = 0.obs;
  final soListedBy = 0.obs;
  final soArea = ''.obs;
  final soMaintenance = ''.obs;
  final soCarParking = 0.obs;
  final soWashrooms = 0.obs;

  // ── New Projects ──
  final npPropertyLocation = ''.obs;
  final npProjectType = 0.obs;
  final npProjectStatus = 0.obs;
  final npTypeOfProperty = 0.obs;
  final npArea = ''.obs;
  final npBuilderName = ''.obs;
  final npReraNo = ''.obs;
  final npLaunchMonth = ''.obs;
  final npLaunchYear = ''.obs;
  final npPossessionMonth = ''.obs;
  final npPossessionYear = ''.obs;
  final npKeyAmenities = ''.obs;
  final npNoOfTowers = 0.obs;
  final npNoOfFloors = 0.obs;
  final npFacing = 0.obs;

  // ── PG & Guest House ──
  final pgPropertyLocation = ''.obs;
  final pgSubtype = 0.obs;
  final pgRoomType = 0.obs;
  final pgAttachedBathroom = 0.obs;
  final pgFurnishing = 0.obs;
  final pgListedBy = 0.obs;
  final pgCarParking = 0.obs;
  final pgMealsIncluded = 0.obs;
  final pgKeyAmenities = ''.obs;

  // ── Loading ──
  final isLoading = false.obs;


  // ── Chip label maps ──
  static const saleTypes = [
    'Houses & Apartments',
    'New Projects & Properties',
    'Lands & Plots',
    'Shops & Offices',
  ];

  static const rentTypes = [
    'Houses & Apartments',
    'Lands & Plots',
    'Shops & Offices',
    'PG And Guest House',
  ];

  static const haTypeOptions = [
    'Flat/Apartments',
    'Independent / Builder Floor',
    'Farm House',
    'House & Villa',
    'Duplex',
  ];
  static const bhkOptions = ['1', '2', '3', '4+'];
  static const bathroomOptions = ['1', '2', '3', '4+'];
  static const furnishingOptions = ['Furnished', 'Semi-Furnished', 'Unfurnished'];
  static const listedByOptions = ['Owner', 'Builder', 'Dealer'];
  static const availabilityOptions = ['Ready to Move', 'Under Construction'];
  static const parkingOptions = ['1', '2', '3', '4+'];
  static const facingOptions = [
    'North', 'South', 'East', 'West',
    'North-East', 'North-West', 'South-East', 'South-West',
  ];
  static const lpProjectTypeOptions = ['For Rent', 'For Sale'];
  static const soProjectStatusOptions = [
    'New Launch', 'Ready to Move', 'Under Construction',
  ];
  static const npPropertyTypeOptions = [
    '1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '4 BHK+', 'Office',
  ];
  static const towersOptions = ['1 to 3', '3 to 5', '5 to 10', '10 +'];
  static const floorsOptions = ['1 to 5', '6 to 10', '10 to 20', '20+'];
  static const pgSubtypeOptions = ['Guest House', 'PG', 'Roommate'];
  static const pgRoomTypeOptions = [
    'Single Sharing', 'Double Sharing', 'Triple Sharing', 'Dormitory',
  ];
  static const bachelorOptions = ['Yes Allowed', 'Not Allowed'];
  static const attachedBathroomOptions = ['Yes Attached', 'Not Attached'];
  static const mealsOptions = ['Yes Included', 'Not Included'];
  static const propertyKindOptions = ['Residential', 'Commercial'];
  static const washroomOptions = ['1', '2', '3', '4+'];

  void resetAll() {
    projectName.value = '';
    description.value = '';
    locationAddress.value = '';
    locationLat.value = 0.0;
    locationLng.value = 0.0;
    photoPaths.clear();
    isPriceRange.value = false;
    price.value = '';
    priceFrom.value = '';
    priceTo.value = '';
    allInclusivePrice.value = false;
    priceNegotiable.value = false;
    taxAndGovtChargeExcluded.value = false;
    securityDeposit.value = false;
    electricityIncluded.value = false;
    waterChargesIncluded.value = false;
  }

  // ── Validation ──

  String? validateStep1() {
    if (projectName.value.trim().isEmpty) return 'Please enter project name';
    if (description.value.trim().isEmpty) return 'Please add a description';
    return null;
  }


  String? validateStep3() {
    if (photoPaths.length < 2) return 'Please upload at least 2 images';
    if (isPriceRange.value) {
      if (priceFrom.value.trim().isEmpty) return 'Please enter minimum price';
      if (priceTo.value.trim().isEmpty) return 'Please enter maximum price';
    } else {
      if (price.value.trim().isEmpty) return 'Please enter price';
    }
    return null;
  }

  // ── Property type key for API ──

  String get _propertyTypeKey {
    if (listingType.value == 'Sell') {
      switch (selectedPropertyTypeIndex.value) {
        case 0: return 'HouseAndApartment';
        case 1: return 'NewProjectsAndProperties';
        case 2: return 'LandAndPlots';
        case 3: return 'ShopAndOffices';
      }
    } else {
      switch (selectedPropertyTypeIndex.value) {
        case 0: return 'HouseAndApartment';
        case 1: return 'LandAndPlots';
        case 2: return 'ShopAndOffices';
        case 3: return 'PGAndGuestHouse';
      }
    }
    return 'HouseAndApartment';
  }

  // ── Build request body ──

  Map<String, dynamic> _buildRequestBody() {
    final body = <String, dynamic>{
      'propertyName': projectName.value.trim(),
      'description': description.value.trim(),
      'propertyType': _propertyTypeKey,
      'listingType': listingType.value,
    };

    if (isPriceRange.value) {
      body['priceRange'] = {
        'min': int.tryParse(priceFrom.value.trim()) ?? 0,
        'max': int.tryParse(priceTo.value.trim()) ?? 0,
      };
    } else {
      body['price'] = int.tryParse(price.value.trim()) ?? 0;
    }

    body['allInclusivePrice'] = allInclusivePrice.value;
    body['priceNegotiable'] = priceNegotiable.value;
    body['taxAndGovtChargeExcluded'] = taxAndGovtChargeExcluded.value;

    if (locationLat.value != 0.0 || locationLng.value != 0.0) {
      body['location'] = {
        'type': 'Point',
        'coordinates': [locationLng.value, locationLat.value],
      };
    }

    if (listingType.value == 'Rent') {
      body['priceType'] = priceType.value;
      body['securityDeposit'] = securityDeposit.value;
      body['electricityIncluded'] = electricityIncluded.value;
      body['waterChargesIncluded'] = waterChargesIncluded.value;
    }

    switch (_propertyTypeKey) {
      case 'HouseAndApartment':
        body['houseAndApartment'] = _buildHouseApartment();
        break;
      case 'LandAndPlots':
        body['landAndPlots'] = _buildLandPlots();
        break;
      case 'ShopAndOffices':
        body['shopAndOffices'] = _buildShopOffices();
        break;
      case 'NewProjectsAndProperties':
        body['newProjectsAndProperties'] = _buildNewProject();
        break;
      case 'PGAndGuestHouse':
        body['pgAndGuestHouse'] = _buildPgGuestHouse();
        break;
    }

    return body;
  }

  Map<String, dynamic> _buildHouseApartment() {
    final data = <String, dynamic>{
      'propertyLocation': locationAddress.value.trim(),
      'houseApartmentType': haTypeOptions[haType.value],
      'bhk': bhkOptions[haBhk.value],
      'bathrooms': bathroomOptions[haBathrooms.value],
      'listedBy': listedByOptions[haListedBy.value],
      'areaDetails': haArea.value.trim(),
      'carParking': parkingOptions[haCarParking.value],
      'facing': facingOptions[haFacing.value],
    };

    if (listingType.value == 'Sell') {
      data['availabilityStatus'] = availabilityOptions[haAvailabilityStatus.value];
    } else {
      data['furnishing'] = furnishingOptions[haFurnishing.value];
      data['bachelorsAllowed'] = bachelorOptions[haBachelorsAllowed.value];
    }

    if (haMaintenance.value.trim().isNotEmpty) {
      data['maintenance'] = haMaintenance.value.trim();
    }
    if (haTotalFloors.value.trim().isNotEmpty) {
      data['totalFloors'] = haTotalFloors.value.trim();
    }
    if (haFloorNo.value.trim().isNotEmpty) {
      data['floorNo'] = haFloorNo.value.trim();
    }

    return data;
  }

  Map<String, dynamic> _buildLandPlots() {
    return {
      'propertyLocation': locationAddress.value.trim(),
      'projectType': lpProjectTypeOptions[lpProjectType.value],
      'listedBy': listedByOptions[lpListedBy.value],
      'plotAreaDetails': {
        'totalArea': lpPlotArea.value.trim(),
        'length': lpLength.value.trim(),
        'breadth': lpBreadth.value.trim(),
      },
      'facing': facingOptions[lpFacing.value],
    };
  }

  Map<String, dynamic> _buildShopOffices() {
    final data = <String, dynamic>{
      'propertyLocation': locationAddress.value.trim(),
      'furnishing': furnishingOptions[soFurnishing.value],
      'listedBy': listedByOptions[soListedBy.value],
      'superBuiltupArea': soArea.value.trim(),
      'carParkings': parkingOptions[soCarParking.value],
      'washrooms': washroomOptions[soWashrooms.value],
    };
    if (listingType.value == 'Sell') {
      data['projectStatus'] = soProjectStatusOptions[soProjectStatus.value];
    }
    if (soMaintenance.value.trim().isNotEmpty) {
      data['maintenance'] = soMaintenance.value.trim();
    }
    return data;
  }

  Map<String, dynamic> _buildNewProject() {
    return {
      'propertyLocation': locationAddress.value.trim(),
      'projectType': propertyKindOptions[npProjectType.value],
      'projectStatus': availabilityOptions[npProjectStatus.value],
      'typeOfProperty': npPropertyTypeOptions[npTypeOfProperty.value],
      'area': npArea.value.trim(),
      'projectLaunchInformation': {
        'builderName': npBuilderName.value.trim(),
        'reraRegistrationNumber': npReraNo.value.trim(),
        'projectLaunchMonth': npLaunchMonth.value,
        'launchYear': npLaunchYear.value,
        'expectedPossessionMonth': npPossessionMonth.value,
        'expectedPossessionYear': npPossessionYear.value,
      },
      'keyAmenities': npKeyAmenities.value.trim(),
      'noOfTowers': towersOptions[npNoOfTowers.value],
      'noOfFloors': floorsOptions[npNoOfFloors.value],
      'facing': facingOptions[npFacing.value],
    };
  }

  Map<String, dynamic> _buildPgGuestHouse() {
    return {
      'propertyLocation': locationAddress.value.trim(),
      'subType': pgSubtypeOptions[pgSubtype.value],
      'roomType': pgRoomTypeOptions[pgRoomType.value],
      'attachedBathroom': attachedBathroomOptions[pgAttachedBathroom.value],
      'furnishing': furnishingOptions[pgFurnishing.value],
      'listedBy': listedByOptions[pgListedBy.value],
      'carParking': parkingOptions[pgCarParking.value],
      'mealsIncluded': mealsOptions[pgMealsIncluded.value],
      'keyAmenities': pgKeyAmenities.value.trim(),
    };
  }

  // ── API Calls ──

  Future<bool> submitProperty() async {
    final error = validateStep3();
    if (error != null) {
      commonSnackBar(message: error);
      return false;
    }

    isLoading.value = true;
    try {
      final body = _buildRequestBody();

      if (photoPaths.isNotEmpty) {
        final images = <dio.MultipartFile>[];
        for (final path in photoPaths) {
          images.add(await dio.MultipartFile.fromFile(path));
        }
        body['propertyImages'] = images;
      }

      final response = await _repo.createProperty(body);

      if (response.isSuccess) {
        commonSnackBar(message: 'Property listed successfully');
        _refreshDashboard();
        return true;
      } else {
        commonSnackBar(
          message: response.message ?? 'Failed to list property',
        );
        return false;
      }
    } catch (e) {
      commonSnackBar(message: 'Something went wrong');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _refreshDashboard() {
    if (Get.isRegistered<PropertyDashboardController>()) {
      Get.find<PropertyDashboardController>().fetchStats();
    }
  }
}
