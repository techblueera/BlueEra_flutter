/// All `ai-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin AiServiceApi {
  final String generateAiContent = "ai-service/api/ai-product/generate-content";
  final String aiFoodGenerateContent =
      'ai-service/api/ai-food/generate-content';
  final String aiServiceGenerateContent =
      'ai-service/api/ai-service/generate-content';
  final String aiGenerateBusinessDescription =
      'ai-service/api/ai-business/generate-description';
  final String appMaintenance = 'ai-service/api/maintenance';
  final String aiGenerateBio = 'ai-service/api/ai-profile/generate-bio';
  final String aiSocialPostGenerate = "ai-service/api/ai-social-post/generate";
  final String aiCommentSuggestion =
      "ai-service/api/ai-comment/generate-suggestions";
  final String aiCommentReplySuggestion =
      "ai-service/api/ai-reply/generate-suggestions";
  final String generateHomeDescription =
      "ai-service/api/ai-property/generate-description";
  final String aiInventoryAsk = 'ai-service/api/ai-inventory/ask';
  final String aiInstitutionFetchDetails =
      'ai-service/api/ai-institution/fetch-details';
  final String foodAiGenerate = 'ai-service/api/ai-food/generate';
  final String aiGenerateSelfProfession =
      'ai-service/api/ai-earn/generate-about';
  final String generateAIDescription =
      'ai-service/api/ai-description/generate-description';
  final String generateOtherService =
      "ai-service/api/ai-other/generate-other-service";
  final String generateProductBusiness =
      "ai-service/api/ai-store/generate-store";
  final String aiExpertise = 'ai-service/api/ai-expertise/generate';
}
