import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';

/// Snapshot of the laboratory being booked with. Denormalised so the
/// sheet header (and the eventual chat card) renders without a fetch.
class LabBookingListing {
  final String laboratoryId; // LaboratoryProfile._id — required by API
  final String ownerId; // opens the customer↔lab chat after submit
  final String labName;
  final String? labImage;
  final String? location;

  const LabBookingListing({
    required this.laboratoryId,
    required this.ownerId,
    required this.labName,
    this.labImage,
    this.location,
  });
}

/// One selectable test in the picker — slim projection of [PathologyTest]
/// so the widget doesn't couple to the model tree. Server-side snapshots
/// name/price/reportHours from the `PathologyTest._id`, so only `id` is
/// mandatory on the wire.
class LabBookingTestOption {
  final String id;
  final String name;
  final int? price;
  final int? reportHours;
  final String? category;

  const LabBookingTestOption({
    required this.id,
    required this.name,
    this.price,
    this.reportHours,
    this.category,
  });

  factory LabBookingTestOption.fromPathology(PathologyTest t) =>
      LabBookingTestOption(
        id: (t.id ?? '').trim(),
        name: (t.testName ?? '').trim(),
        price: t.customerPrice,
        reportHours: t.estimatedReportHours,
        category: t.collection,
      );
}
