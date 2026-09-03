/// Which sections of the "other business" profile have been WRITTEN to since
/// the Overview tab last looked.
///
/// ## The problem this solves
///
/// The Overview tab (`other_overview_tab_v2.dart`) renders several sections of
/// the full business profile, and each one has a card that opens an editor on
/// its own route. Every one of those used to refetch on return:
///
/// ```dart
/// Get.to(() => ManagementScreen())?.then((_) => controller.getBusinessProfileFull());
/// ```
///
/// `.then` fires on ANY pop, so merely LOOKING at a section and pressing back
/// sent a `/business-profile/<id>/full` request that could not have returned
/// anything new. Five cards did this, so a merchant browsing their own profile
/// could fire the heaviest request on the screen half a dozen times without
/// changing a thing.
///
/// ## How it works
///
/// The editor's controller calls [mark] when a write actually SUCCEEDS. The
/// Overview tab calls [consume] on return, which reads and clears in one go —
/// so one write causes exactly one refetch, and a look-and-leave causes none.
///
/// ## Why static
///
/// The editors build their controllers with plain `Get.put`, so the instance
/// that recorded the change may already be replaced by the time the Overview
/// tab reads it. The record has to outlive the screen that made it. Being
/// static also means it works however the route was popped — hardware back,
/// swipe gesture or `Get.back` — which a `Get.back(result: true)` convention
/// would not.
enum OtherProfileSection {
  /// Service photo galleries — `OtherServicePhotoPhotoController`.
  gallery,

  /// Management / team members — `ManagementController`.
  management,

  /// Weekly business hours — `TimingController`.
  timings,
}

/// See [OtherProfileSection].
class OtherProfileDirty {
  OtherProfileDirty._();

  static final Set<OtherProfileSection> _dirty = <OtherProfileSection>{};

  /// Records that [section] changed. Call ONLY on a successful write — a
  /// failed save leaves the server holding what the screen already shows, so
  /// marking it would buy a refetch that changes nothing.
  static void mark(OtherProfileSection section) => _dirty.add(section);

  /// Whether [section] changed since this was last called, clearing the flag.
  static bool consume(OtherProfileSection section) => _dirty.remove(section);

  /// Drops every flag. For sign-out, so one account's pending refetch can't
  /// fire against the next account's profile.
  static void clear() => _dirty.clear();
}
