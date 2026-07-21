import 'package:BlueEra/core/api/apiService/ai_service_api.dart';
import 'package:BlueEra/core/api/apiService/auth_service_api.dart';
import 'package:BlueEra/core/api/apiService/automotive_service_api.dart';
import 'package:BlueEra/core/api/apiService/booking_enquiry_service_api.dart';
import 'package:BlueEra/core/api/apiService/channel_product_service_api.dart';
import 'package:BlueEra/core/api/apiService/channel_service_api.dart';
import 'package:BlueEra/core/api/apiService/chat_service_api.dart';
import 'package:BlueEra/core/api/apiService/document_service_api.dart';
import 'package:BlueEra/core/api/apiService/earn_service_api.dart';
import 'package:BlueEra/core/api/apiService/education_service_api.dart';
import 'package:BlueEra/core/api/apiService/emergency_service_api.dart';
import 'package:BlueEra/core/api/apiService/food_service_api.dart';
import 'package:BlueEra/core/api/apiService/grocery_service_api.dart';
import 'package:BlueEra/core/api/apiService/health_service_api.dart';
import 'package:BlueEra/core/api/apiService/hospital_service_api.dart';
import 'package:BlueEra/core/api/apiService/hotel_service_api.dart';
import 'package:BlueEra/core/api/apiService/inventory_service_api.dart';
import 'package:BlueEra/core/api/apiService/job_service_api.dart';
import 'package:BlueEra/core/api/apiService/lab_service_api.dart';
import 'package:BlueEra/core/api/apiService/language_service_api.dart';
import 'package:BlueEra/core/api/apiService/map_service_api.dart';
import 'package:BlueEra/core/api/apiService/medical_service_api.dart';
import 'package:BlueEra/core/api/apiService/notification_service_api.dart';
import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/api/apiService/other_service_api.dart';
import 'package:BlueEra/core/api/apiService/post_service_api.dart';
import 'package:BlueEra/core/api/apiService/product_service_api.dart';
import 'package:BlueEra/core/api/apiService/rider_service_api.dart';
import 'package:BlueEra/core/api/apiService/services_service_api.dart';
import 'package:BlueEra/core/api/apiService/social_service_api.dart';
import 'package:BlueEra/core/api/apiService/subscription_service_api.dart';
import 'package:BlueEra/core/api/apiService/symbols_service_api.dart';
import 'package:BlueEra/core/api/apiService/travel_service_api.dart';
import 'package:BlueEra/core/api/apiService/user_service_api.dart';
import 'package:BlueEra/core/api/apiService/userfeed_service_api.dart';
import 'package:BlueEra/core/api/apiService/vehicle_service_api.dart';
import 'package:BlueEra/core/api/apiService/video_service_api.dart';
import 'package:BlueEra/core/api/apiService/videofeed_service_api.dart';
import 'package:BlueEra/core/api/apiService/wallet_service_api.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/environment_config.dart';

/// ----------------- BASE URL START -----------------------
///DEV BASE URL......
String? baseURL = baseUrl;

/// File-scope (not a class member). Multiple call sites import this
/// constant directly from `base_service.dart` — keep it here to preserve
/// that import.
final String initUpload = "video-service/upload/init";

/// API URL constants for the app, grouped by service.
///
/// Each `*-service/*` prefix has its own mixin file under
/// `lib/core/api/apiService/`. `BaseService` composes them all via
/// `with`, so any repo that already extends `BaseService` inherits every
/// constant transparently — no call site needs to change.
///
/// Where to add a new endpoint:
///   1. Find the matching `<service>_service_api.dart` file and add it
///      there.
///   2. If the path has no `*-service/` prefix (rare — e.g. `poll/answer`,
///      bare `resumes`, the `riders/orders/stream/...` SSE paths, or the
///      `callBaseUrl`-prefixed `callHistory`), drop it in the small
///      leftover block on this class.
///
/// Companion reference: `lib/docs/api-services-index.md`.
abstract class BaseService
    with
        UserServiceApi,
        AuthServiceApi,
        ChannelServiceApi,
        SocialServiceApi,
        VideoServiceApi,
        VideofeedServiceApi,
        BookingEnquiryServiceApi,
        ChatServiceApi,
        PostServiceApi,
        JobServiceApi,
        MapServiceApi,
        TravelServiceApi,
        LanguageServiceApi,
        InventoryServiceApi,
        ChannelProductServiceApi,
        UserfeedServiceApi,
        ProductServiceApi,
        AutomotiveServiceApi,
        ServicesServiceApi,
        AiServiceApi,
        OrderServiceApi,
        WalletServiceApi,
        NotificationServiceApi,
        RiderServiceApi,
        EarnServiceApi,
        GroceryServiceApi,
        FoodServiceApi,
        MedicalServiceApi,
        LabServiceApi,
        HospitalServiceApi,
        EmergencyServiceApi,
        DocumentServiceApi,
        EducationServiceApi,
        SymbolsServiceApi,
        HotelServiceApi,
        OtherServiceApi,
        HealthServiceApi,
        SubscriptionServiceApi,
        VehicleServiceApi {

  /// Polling endpoint (no service prefix in the source URL).
  final String pollAnswer = "poll/answer";

  /// Bare `resumes` path used by some legacy call sites.
  final String resumes = "resumes";

  /// Call Service — different host (`callBaseUrl`), not the main `baseURL`.
  String get callHistory => '${callBaseUrl ?? ''}call/history';

  /// SSE order streams. Paths are intentionally rooted at `riders/...`
  /// (no service prefix) — these are kept as `static final` so non-mixin
  /// call sites can read them as `BaseService.groceryRiderOrderStream`.
  static final String groceryRiderOrderStream =
      "riders/orders/stream/grocery/$userId";
  static final String medicalRiderOrderStream =
      "riders/orders/stream/medical/$userId";
}
