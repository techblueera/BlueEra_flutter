/// All `travel-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin TravelServiceApi {
  final String addPlace = "travel-service/places/add";
  final String placeCategory = "travel-service/categories";
  final String travelServiceJourney = "travel-service/journey";
  final String travelJourneyPost = "travel-service/journey-post";
  final String journeyStatus = "travel-service/journey/status";
}
