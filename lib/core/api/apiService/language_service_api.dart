/// All `language-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin LanguageServiceApi {
  final String languages = "language-service/languages/names";
  final String languagesDownload = "language-service/languages";
}
