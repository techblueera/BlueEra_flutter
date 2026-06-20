import 'package:BlueEra/features/common/Discover/model/business_filter_res_model.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';

/// Adapts a `business/filter` record (`BusinessFilterData`) into the
/// legacy [HospitalFullData] shape consumed by `HospitalListScreen` /
/// `_HospitalCard` so the UI keeps working unchanged when the listing
/// pipeline switches over to `GET user-service/business/filter`.
///
/// Mirrors the school adapter at
/// `business_filter_res_model.dart::BusinessFilterDataMappers.toSchoolDetail`
/// — kept on the hospital side so the shared Discover model file does
/// not gain a hospital-module dependency.
///
/// Only fields the UI actually reads (logo, cover/gallery, name,
/// description, address + coordinates, primary phone via contacts,
/// department names/count + facility names/count) are mapped. OPD/IPD
/// detail and the emergency-care/other-facility booleans aren't in the
/// listing payload, so they stay null and the existing UI null-checks
/// (`ec?.icu ?? false`, etc.) handle them.
extension BusinessFilterDataHospitalMappers on BusinessFilterData {
  HospitalFullData toHospitalFullData() {
    final lat = businessLocation?.lat?.toDouble();
    final lon = businessLocation?.lon?.toDouble();
    // GeoJSON convention: [lng, lat]. Empty list when coords unavailable
    // — matches what `Location.fromJson` produces when the field is null.
    final coords = (lat != null && lon != null) ? <double>[lon, lat] : <double>[];

    // Live photos doubles as both gallery + cover so the existing card
    // (which falls back logo → cover → gallery) has imagery to render.
    final photos = livePhotos ?? const <String>[];
    final coverFromLive = photos.isNotEmpty ? photos.first : null;

    final gallery = photos.isEmpty
        ? null
        : <HospitalGallery>[
            HospitalGallery(
              id: id,
              title: businessName,
              uploadPhoto: coverFromLive,
              images: List<String>.from(photos),
              hospitalId: id,
              userId: userId,
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          ];

    // Synthesize a single-contact list from `business_number` so
    // `_HospitalCard._primaryPhone()` finds something to display.
    final mob = businessNumber?.officeMobNo?.number;
    final landline = businessNumber?.officeLandlineNo?.number;
    final phone = (mob != null && mob.trim().isNotEmpty)
        ? mob
        : ((landline != null && landline.trim().isNotEmpty) ? landline : null);

    final contacts = phone == null
        ? null
        : <HospitalContacts>[
            HospitalContacts(
              id: id,
              hospitalId: id,
              userId: userId,
              createdAt: createdAt,
              updatedAt: updatedAt,
              departments: <Departments>[
                Departments(
                  department: subCategoryDetails?.name ??
                      categoryDetails?.name ??
                      'General',
                  phone: phone,
                ),
              ],
            ),
          ];

    // Map the lightweight department descriptors onto the legacy
    // `IpdOpdDepartments` shape so `_HospitalCard._departmentNames()` keeps
    // reading `item.departments`. OPD/IPD detail isn't in the listing payload
    // — it's fetched on demand when a hospital is opened.
    final deptList = (departments ?? const [])
        .map((d) => IpdOpdDepartments(
              id: d.id,
              name: d.name,
              key: d.key,
              type: d.type,
            ))
        .toList();

    return HospitalFullData(
      id: id,
      userId: userId,
      name: businessName,
      description: businessDescription,
      logoUrl: logo,
      coverUrl: coverFromLive,
      gallery: gallery,
      contacts: contacts,
      createdAt: createdAt,
      updatedAt: updatedAt,
      departments: deptList.isEmpty ? null : deptList,
      departmentCount: departmentCount ?? deptList.length,
      facilityNames: facilities,
      facilityCount: facilityCount ?? (facilities?.length ?? 0),
      location: Location(
        name: address,
        type: 'Point',
        coordinates: coords,
      ),
    );
  }
}
