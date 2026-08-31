// GENERATED-BY-HAND-ONCE: migrated from RouteHelper.generateRoute's 180-case
// switch. GetMaterialApp uses `getPages` INSTEAD OF `onGenerateRoute` -- the
// two are mutually exclusive (get_material_app.dart:288), so every route must
// live here. Adding a route to RouteConstant is not enough; add a GetPage too.
//
// Arguments: `settings.arguments` became `Get.arguments`, which GetObserver
// populates on every push (route_observer.dart:111) -- so Get.toNamed AND the
// remaining Navigator.pushNamed call sites both keep working.
//
// Controllers are still registered by the screens themselves (Get.put). Adding
// `binding:` here per route is the follow-up step.

import '../../features/chat/view/contacts/view/contact_list_page.dart';
import '../../features/common/store/add_update_product/add_update_product_screen.dart';
import '../../features/common/store/models/get_channel_product_model.dart';
import '../../features/contacts/view/blue_era_contacts_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/appointment_booking_form.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/bookings_enquiries.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/my_booking_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/received_booking_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/set_availability_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/videography_tutorial_screen.dart';
import '../../features/personal/personal_profile/view/booking_enquiries_screen/videography_tutorial_screen2.dart';
import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/business/business_verification/view/business_verification_screen.dart';
import 'package:BlueEra/features/business/business_verification/view/ownership_verification_screen.dart';
import 'package:BlueEra/features/business/onboarding/view/business_onboarding_address_screen.dart';
import 'package:BlueEra/features/business/onboarding/view/business_onboarding_category_screen.dart';
import 'package:BlueEra/features/business/onboarding/view/business_onboarding_description_screen.dart';
import 'package:BlueEra/features/business/onboarding/view/business_onboarding_hours_type_screen.dart';
import 'package:BlueEra/features/business/onboarding/view/business_onboarding_photo_screen.dart';
import 'package:BlueEra/features/business/onboarding/view/business_onboarding_select_hours_screen.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/chat/view/call_screen/audio_calling_handler.dart';
import 'package:BlueEra/features/chat/view/call_screen/rider_call/incoming_rider_order_screen.dart';
import 'package:BlueEra/features/chat/view/order_track/order_steps_screen.dart';
import 'package:BlueEra/features/common/address/model/address_ui_model.dart';
import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:BlueEra/features/common/address/view/add_edit_address_screen.dart';
import 'package:BlueEra/features/common/address/view/saved_address_list_screen.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/auth/views/screens/Individual/add_bio_via_ai_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/Individual/personal_account_new_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/business/create_business_account_new_step_four.dart';
import 'package:BlueEra/features/common/auth/views/screens/business/create_business_account_new_step_one.dart';
import 'package:BlueEra/features/common/auth/views/screens/business/create_business_account_new_step_three.dart';
import 'package:BlueEra/features/common/auth/views/screens/business/create_business_account_new_step_two.dart';
import 'package:BlueEra/features/common/auth/views/screens/create_account_type_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/create_account_type_v2_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/gst_verification_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/mobile_number_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/otp_page_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart';
import 'package:BlueEra/features/common/connect/view/connect_main_page.dart';
import 'package:BlueEra/features/common/delivery_partner/view/gig_work_options_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_me_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_store/rider_store_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_information_riding_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/near_by_rider_screen.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/food/view/food_upload_screen.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step2.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step3.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step_4.dart';
import 'package:BlueEra/features/common/jobs/view/applied_screen/applied_jobs_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_overview_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_qna_screen.dart';
import 'package:BlueEra/features/common/map/view/add_place_step_one.dart';
import 'package:BlueEra/features/common/map/view/add_place_step_two.dart';
import 'package:BlueEra/features/common/map/view/category_selection_screen.dart';
import 'package:BlueEra/features/common/map/view/customize_map_screen.dart';
import 'package:BlueEra/features/common/map/view/searchLocationScreen.dart';
import 'package:BlueEra/features/common/more/view/more_cards_screen.dart';
import 'package:BlueEra/features/common/notification/view/notification_screen.dart';
import 'package:BlueEra/features/common/onboarding/view/splash_screen.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_post_screen_new.dart';
import 'package:BlueEra/features/common/post/photo_post/photo_post_preview_screen.dart';
import 'package:BlueEra/features/common/post/photo_post/photo_post_review_screen.dart';
import 'package:BlueEra/features/common/post/photo_post/photo_post_screen.dart';
import 'package:BlueEra/features/common/post/poll_post/poll_input_screen.dart';
import 'package:BlueEra/features/common/post/poll_post/poll_review_screen.dart';
import 'package:BlueEra/features/common/reel/models/song_model.dart';
import 'package:BlueEra/features/common/reel/view/channel/channel_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/manage_channel_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/reel_upload_details_screen.dart';
import 'package:BlueEra/features/common/reel/view/music/add_song_screen.dart';
import 'package:BlueEra/features/common/reel/view/music/all_songs_screen.dart';
import 'package:BlueEra/features/common/reel/view/shorts/shorts_player_screen.dart';
import 'package:BlueEra/features/common/reel/view/tag_people_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/full_video_preview_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/video_player_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/video_recorder_screen.dart';
import 'package:BlueEra/features/common/search/view/global_search_screen.dart';
import 'package:BlueEra/features/common/service/view/service_upload_screen.dart';
import 'package:BlueEra/features/journey/view/journey_planning_screen.dart';
import 'package:BlueEra/features/journey/view/update_journy_screen.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_controller.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_generate_ai_product_content.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_product_nested_category_response.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_add_product_text_or_snap_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_add_product_variant_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_add_product_via_ai_step1.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_add_product_via_ai_step2.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_create_varient_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_my_product_products_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_parts_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_product_nested_category_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_product_nested_category_with_inventory_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_product_preview_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_product_selection_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_product_super_category_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_products_store_details_screen.dart';
import 'package:BlueEra/features/me/doctor/view/doctor_my_appointments_screen.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_snap_search_response.dart';
import 'package:BlueEra/features/me/food/view/admin/add_food_snap_search_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/add_single_food_product_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/food_ai_details_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/food_entry_ai_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/food_product_selection_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/missing_food_itmes_screen.dart';
import 'package:BlueEra/features/me/food/view/customer/food_customer_listing_screen.dart';
import 'package:BlueEra/features/me/food/view/customer/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/features/me/grocery/view/admin/add_grocery_snap_search_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/add_grocery_variant_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_nested_category_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_nested_category_with_inventory_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_products_selection_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_super_category_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/missing_grocery_items_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/my_grocery_listing/my_grocery_products_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_stores_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_rider/all_grocery_product_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_rider/grocery_cart_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_rider/grocery_confirm_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_rider/grocery_rider_snap_search_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/visit_grocery_products_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/visit_grocery_store_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/my_self_pickup_orders_screen.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_add_product_via_ai_step1.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_add_product_via_ai_step2.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_create_variant_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_nested_category_with_inventory_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_product_preview_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_product_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/my_manufacturer_products_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/customer/manufacturer_products_store_details_screen.dart';
import 'package:BlueEra/features/me/medical/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical/model/my_medical_products_response.dart';
import 'package:BlueEra/features/me/medical/view/add_medical_snap_search_screen.dart';
import 'package:BlueEra/features/me/medical/view/add_medical_variant_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_category_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_home_screen_v2.dart';
import 'package:BlueEra/features/me/medical/view/medical_listing/medical_cart_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_listing/medical_confirm_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_listing/medical_listing_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_product_selection_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_screen.dart';
import 'package:BlueEra/features/me/medical/view/my_medical_listing/my_medical_products_screen.dart';
import 'package:BlueEra/features/me/medical/view/my_medical_listing/my_medical_variant_screen.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/generate_ai_product_content.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/me/product/view/admin/add_product_text_or_snap_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/add_product_variant_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/add_product_via_ai_step1.dart';
import 'package:BlueEra/features/me/product/view/admin/add_product_via_ai_step2.dart';
import 'package:BlueEra/features/me/product/view/admin/create_varient_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/inventory_business_cards_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/my_product_products_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/product_cart_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/product_nested_category_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/product_nested_category_with_inventory_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/product_preview_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/product_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/product_selection_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/product_super_category_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/products_store_details_screen.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/customer/vehicle_discover_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/customer/vehicle_listing_detail_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/vehicle_screen_v3.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/my_enquires_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/received_enquiries_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/send_enquiry_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/choose_earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/view/add_document_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/add_bank_account_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_upi/add_accountupi_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/product_listing_screen/product_listing_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/add_flat_room_rental_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/home_stay_rental_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_service_full_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/vehicle_rental_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/add_self_work_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/see_all_transactions.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/wallet_screen.dart';
import 'package:BlueEra/features/personal/resume/create_resume_screen.dart';
import 'package:BlueEra/features/personal/resume/sections/resume_templates_screen.dart';
import 'package:BlueEra/permissionCentralize/permission_gate.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/common/auth/binding/bio_suggestion_binding.dart';
import 'package:BlueEra/features/common/delivery_partner/binding/vehicle_information_riding_screen_binding.dart';
import 'package:BlueEra/features/common/jobs/binding/create_job_post_binding.dart';
import 'package:BlueEra/features/common/jobs/binding/job_details_overview_binding.dart';
import 'package:BlueEra/features/common/jobs/binding/job_post_step3_binding.dart';
import 'package:BlueEra/features/common/jobs/binding/job_post_step4_binding.dart';
import 'package:BlueEra/features/common/map/binding/add_place_step_one_binding.dart';
import 'package:BlueEra/features/common/map/binding/add_place_step_two_binding.dart';
import 'package:BlueEra/features/common/map/binding/category_selection_binding.dart';
import 'package:BlueEra/features/common/map/binding/customize_map_binding.dart';
import 'package:BlueEra/features/common/post/binding/create_message_post_screen_binding.dart';
import 'package:BlueEra/features/common/post/binding/photo_post_binding.dart';
import 'package:BlueEra/features/common/post/binding/poll_binding.dart';
import 'package:BlueEra/features/common/reel/binding/all_songs_screen_binding.dart';
import 'package:BlueEra/features/common/reel/binding/channel_screen_binding.dart';
import 'package:BlueEra/features/common/reel/binding/create_reel_screen_binding.dart';
import 'package:BlueEra/features/common/reel/binding/manage_channel_binding.dart';
import 'package:BlueEra/features/common/reel/binding/tag_people_binding.dart';
import 'package:BlueEra/features/common/reel/binding/video_player_screen_binding.dart';
import 'package:BlueEra/features/common/store/binding/add_update_product_binding.dart';
import 'package:BlueEra/features/journey/binding/journey_planning_binding.dart';
import 'package:BlueEra/features/journey/binding/journey_update_binding.dart';
import 'package:BlueEra/features/me/automotive_products/binding/automotive_add_product_text_or_snap_screen_binding.dart';
import 'package:BlueEra/features/me/automotive_products/binding/automotive_add_product_variant_screen_binding.dart';
import 'package:BlueEra/features/me/automotive_products/binding/automotive_product_preview_screen_binding.dart';
import 'package:BlueEra/features/me/manufacturer/binding/manufacturer_product_preview_screen_binding.dart';
import 'package:BlueEra/features/me/manufacturer/binding/manufacturer_store_details_screen_binding.dart';
import 'package:BlueEra/features/me/product/binding/product_preview_screen_binding.dart';
import 'package:BlueEra/features/me/product/binding/products_store_details_screen_binding.dart';
import 'package:BlueEra/features/personal/personal_profile/binding/appointment_booking_screen_binding.dart';
import 'package:BlueEra/features/personal/personal_profile/binding/enquiry_form_binding.dart';
import 'package:BlueEra/features/personal/personal_profile/binding/my_booking_screen_binding.dart';
import 'package:BlueEra/features/personal/personal_profile/binding/my_enquires_screen_binding.dart';
import 'package:BlueEra/features/personal/personal_profile/binding/product_listing_binding.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/binding/rental_binding.dart';
import 'package:BlueEra/features/personal/resume/binding/resume_binding.dart';
import 'package:BlueEra/features/personal/resume/binding/resume_template_binding.dart';
import 'package:BlueEra/features/personal/personal_profile/binding/booking_binding.dart';
import 'package:get/get.dart';
import 'package:share_handler/share_handler.dart';

class AppPages {
  AppPages._();

  static final List<GetPage> routes = <GetPage>[
    GetPage(
      name: RouteConstant.PermissionScreen,
      page: () => PermissionGate(),
    ),
    GetPage(
      name: RouteConstant.SplashScreen,
      page: () => SplashScreen(),
    ),
    GetPage(
      name: RouteConstant.MobileNumberScreen,
      page: () => MobileNumberScreen(),
    ),
    GetPage(
      name: RouteConstant.OtpPageScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final mobileNumber = args[ApiKeys.argMobileNumber] as String;
        return OtpPageScreen(
          mobileNumber: mobileNumber,
        );
      },
    ),
    GetPage(
      name: RouteConstant.HomeScreen,
      page: () => const ConnectMainPage(),
    ),
    GetPage(
      name: RouteConstant.BottomNavigationBarScreen,
      page: () {
        final args = Get.arguments as Map<dynamic, dynamic>?;
        int? initialIndex = args?[ApiKeys.initialIndex];
        SharedMedia? sharedMedia = args?['sharedMedia'] as SharedMedia?;
        final bool deferHeavyInit = args?['deferHeavyInit'] == true;
        final bool runRiderGoLiveGate = args?['runRiderGoLiveGate'] == true;
        final bool landOnDiscover = args?['landOnDiscover'] == true;
        return BottomNavigationBarScreen(
          initialIndex: initialIndex,
          sharedMedia: sharedMedia,
          deferHeavyInit: deferHeavyInit,
          runRiderGoLiveGate: runRiderGoLiveGate,
          landOnDiscover: landOnDiscover,
        );
      },
    ),
    GetPage(
      name: RouteConstant.BusinessOwnProfileScreen,
      page: () => BusinessOwnProfileScreen(),
    ),
    GetPage(
      name: RouteConstant.BusinessOnboardingCategoryScreen,
      page: () => const BusinessOnboardingCategoryScreen(),
    ),
    GetPage(
      name: RouteConstant.BusinessOnboardingHoursTypeScreen,
      page: () => BusinessOnboardingHoursTypeScreen(),
    ),
    GetPage(
      name: RouteConstant.BusinessOnboardingSelectHoursScreen,
      page: () => BusinessOnboardingSelectHoursScreen(),
    ),
    GetPage(
      name: RouteConstant.BusinessOnboardingPhotoScreen,
      page: () => BusinessOnboardingPhotoScreen(),
    ),
    GetPage(
      name: RouteConstant.BusinessOnboardingAddressScreen,
      page: () => const BusinessOnboardingAddressScreen(),
    ),
    GetPage(
      name: RouteConstant.BusinessOnboardingDescriptionScreen,
      page: () => BusinessOnboardingDescriptionScreen(),
    ),
    GetPage(
      name: RouteConstant.FeedScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final onHeaderVisibilityChanged =
            args[ApiKeys.onHeaderVisibilityChanged] as Function(bool)?;
        final postFilterType = args[ApiKeys.postFilterType] as PostType;
        final id = args[ApiKeys.id] as String;
        return FeedScreen(
            onHeaderVisibilityChanged: onHeaderVisibilityChanged,
            postFilterType: postFilterType,
            id: id);
      },
    ),
    GetPage(
      name: RouteConstant.BusinessVerificationScreen,
      page: () => BusinessVerificationScreen(),
    ),
    GetPage(
      name: RouteConstant.OwnershipVerificationScreen,
      page: () => OwnershipVerificationScreen(),
    ),
    GetPage(
      name: RouteConstant.NotificationScreen,
      page: () => NotificationScreen(),
    ),
    GetPage(
      name: RouteConstant.ChannelScreen,
      binding: ChannelScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;
        final channelId = args[ApiKeys.channelId] as String;
        final authorId = args[ApiKeys.authorId] as String;
        return ChannelScreen(
            accountType: accountType, channelId: channelId, authorId: authorId);
      },
    ),
    GetPage(
      name: RouteConstant.ManageChannelScreen,
      binding: ManageChannelBinding(),
      page: () => ManageChannelScreen(),
    ),
    GetPage(
      name: RouteConstant.CreateReelScreen,
      binding: CreateReelScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final videoPath = args[ApiKeys.videoPath] as String;
        final videoType = args[ApiKeys.videoType] as Video;
        final videoId = args[ApiKeys.videoId] as String?;
        final argPostVia = args[ApiKeys.argPostVia] as PostVia?;
        return ReelUploadDetailsScreen(
            videoPath: videoPath,
            videoType: videoType,
            videoId: videoId,
            postVia: argPostVia);
      },
    ),
    GetPage(
      name: RouteConstant.CustomizeMapScreen,
      binding: CustomizeMapBinding(),
      page: () => CustomizeMapScreen(),
    ),
    GetPage(
      name: RouteConstant.SearchLocationScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final onPlaceSelected = args?[ApiKeys.onPlaceSelected] as Function(
            double?, double?, String?)?;
        final fromScreen = args?[ApiKeys.fromScreen] as String;
        return SearchLocationScreen(
            onPlaceSelected: onPlaceSelected, fromScreen: fromScreen);
      },
    ),
    GetPage(
      name: RouteConstant.addPlaceStepOne,
      binding: AddPlaceStepOneBinding(),
      page: () => AddPlaceStepOneScreen(),
    ),
    GetPage(
      name: RouteConstant.addPlaceStepTwo,
      binding: AddPlaceStepTwoBinding(),
      page: () => AddPlaceStepTwoScreen(),
    ),
    GetPage(
      name: RouteConstant.categorySelectionScreen,
      binding: CategorySelectionBinding(),
      page: () => CategorySelectionScreen(),
    ),
    GetPage(
      name: RouteConstant.JobQnaScreen,
      page: () => JobQNAScreen(),
    ),
    GetPage(
      name: RouteConstant.JobDetailsOverviewScreen,
      binding: JobDetailsOverviewBinding(),
      page: () => JobDetailsOverviewScreen(),
    ),
    GetPage(
      name: RouteConstant.AppliedJobsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final headerHeight = args?[ApiKeys.headerHeight] as double;
        return AppliedJobsScreen(
          onHeaderVisibilityChanged: (bool isVisible) {},
          headerHeight: headerHeight,
        );
      },
    ),
    GetPage(
      name: RouteConstant.ChatContactsScreen,
      page: () => ContactsPage(),
    ),
    GetPage(
      name: RouteConstant.BlueEraContactsScreen,
      page: () => const BlueEraContactsScreen(),
    ),
    GetPage(
      name: RouteConstant.CreateJobPostScreen,
      binding: CreateJobPostBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final isEditMode = args?['isEditMode'] as bool? ?? false;
        final jobId = args?['jobId'] as String? ?? '';
        final createJobVia = args?['createJobVia'] as String? ?? '';
        return CreateJobPostScreen(
          isEditMode: isEditMode,
          jobId: jobId,
          createJobVia: createJobVia,
        );
      },
    ),
    GetPage(
      name: RouteConstant.CreateJobPostStep2,
      page: () => CreateJobPostStep2(),
    ),
    GetPage(
      name: RouteConstant.CreateJobPostStep3,
      binding: JobPostStep3Binding(),
      page: () => CreateJobPostStep3(),
    ),
    GetPage(
      name: RouteConstant.CreateJobPostStep4,
      binding: JobPostStep4Binding(),
      page: () => CreateJobPostStep4(),
    ),
    GetPage(
      name: RouteConstant.tagPeopleScreen,
      binding: TagPeopleBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final previouslySelectedItems =
            args[ApiKeys.previouslySelectedItems] as Map<String, String>?;
        return TagPeopleScreen(
            previouslySelectedItems: previouslySelectedItems);
      },
    ),
    GetPage(
      name: RouteConstant.videoRecorderScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final postVia = args[ApiKeys.argPostVia] as PostVia?;
        return VideoReelRecorderScreen(postVia: postVia);
      },
    ),
    GetPage(
      name: RouteConstant.fullVideoPreview,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final videoPath = args[ApiKeys.videoPath] as String;
        final argPostVia = args[ApiKeys.argPostVia] as PostVia;
        return FullVideoPreview(videoPath: videoPath, argPostVia: argPostVia);
      },
    ),
    GetPage(
      name: RouteConstant.allSongsScreen,
      binding: AllSongsScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final videoPath = args[ApiKeys.videoPath] as String?;
        final images = args[ApiKeys.filePath] as List<String>?;
        return AllSongsScreen(video: videoPath, images: images);
      },
    ),
    GetPage(
      name: RouteConstant.addSongScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final videoPath = args[ApiKeys.videoPath] as String?;
        final images = args[ApiKeys.filePath] as List<String>?;
        final audioUrl = args[ApiKeys.audioUrl] as String;
        final song = args[ApiKeys.song] as SongModel;
        return AddSongScreen(
            video: videoPath, images: images, audioUrl: audioUrl, song: song);
      },
    ),
    GetPage(
      name: RouteConstant.PollReviewScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final postVia = args[ApiKeys.argPostVia] as PostVia?;
        return PollReviewScreen(postVia: postVia);
      },
    ),
    GetPage(
      name: RouteConstant.PhotoPostPreviewScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final postVia = args[ApiKeys.argPostVia] as PostVia?;
        return PhotoPostPreviewScreen(postVia: postVia);
      },
    ),
    GetPage(
      name: RouteConstant.PhotoPostReviewScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final postVia = args[ApiKeys.argPostVia] as PostVia?;
        return PhotoPostReviewScreen(postVia: postVia);
      },
    ),
    GetPage(
      name: RouteConstant.videoPlayerScreen,
      binding: VideoPlayerScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final videoItem = args[ApiKeys.videoItem] as ShortFeedItem;
        final videoType = args[ApiKeys.videoType] as VideoType;
        return VideoPlayerScreen(videoItem: videoItem, videoType: videoType);
      },
    ),
    GetPage(
      name: RouteConstant.journeyPlanningScreen,
      binding: JourneyPlanningBinding(),
      page: () => JourneyPlanningScreen(),
    ),
    GetPage(
      name: RouteConstant.UpdateJourneyScreen,
      binding: JourneyUpdateBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final journeyId = args[ApiKeys.journey_id] as String;
        return UpdateJourneyScreen(
          journeyId: journeyId,
        );
      },
    ),
    GetPage(
      name: RouteConstant.shortsPlayerScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final Shorts shorts = args[ApiKeys.shorts] as Shorts;
        final List<ShortFeedItem> videoItem =
            args[ApiKeys.videoItem] as List<ShortFeedItem>;
        final int initialIndex = args[ApiKeys.initialIndex] as int;
        return ShortsPlayerScreen(
            shorts: shorts,
            initialShorts: videoItem,
            initialIndex: initialIndex);
      },
    ),
    GetPage(
      name: RouteConstant.CreateResumeScreen,
      binding: ResumeBinding(),
      page: () => CreateResumeScreen(),
    ),
    GetPage(
      name: RouteConstant.ResumeTemplateScreen,
      binding: ResumeTemplateBinding(),
      page: () => ResumeTemplateScreen(),
    ),
    GetPage(
      name: RouteConstant.ProductListingScreen,
      binding: ProductListingBinding(),
      page: () => const ProductListingScreen(),
    ),
    GetPage(
      name: RouteConstant.MyBookingScreen,
      binding: MyBookingScreenBinding(),
      page: () => const MyBookingsScreen(),
    ),
    GetPage(
      name: RouteConstant.DoctorMyAppointmentsScreen,
      binding: BookingBinding(),
      page: () => const DoctorMyAppointmentsScreen(),
    ),
    GetPage(
      name: RouteConstant.ReceivedBookingScreen,
      page: () => ReceivedBookingsScreen(),
    ),
    GetPage(
      name: RouteConstant.VideographyTutorialScreen,
      binding: BookingBinding(),
      page: () => VideographyTutorialScreen(),
    ),
    GetPage(
      name: RouteConstant.ReceivedEnquiriesScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final channelId = args[ApiKeys.channelId] as String;
        return ReceivedEnquiriesScreen(
          channelId: channelId,
        );
      },
    ),
    GetPage(
      name: RouteConstant.VideographyTutorialScreen2,
      page: () => const VideographyTutorialScreen2(),
    ),
    GetPage(
      name: RouteConstant.MyEnquiresScreen,
      binding: MyEnquiresScreenBinding(),
      page: () => MyEnquiriesPage(),
    ),
    GetPage(
      name: RouteConstant.setAvailabilityScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String argId = args[ApiKeys.argId] as String;
        return SetAvailabilityScreen(id: argId);
      },
    ),
    GetPage(
      name: RouteConstant.AppointmentBookingScreen,
      binding: AppointmentBookingScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final channelId = args[ApiKeys.channelId] as String;
        final videoId = args[ApiKeys.videoId] as String;
        return AppointmentBookingScreen(
          channelId: channelId,
          videoId: videoId,
        );
      },
    ),
    GetPage(
      name: RouteConstant.EnquiryForm,
      binding: EnquiryFormBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final channelId = args[ApiKeys.channelId] as String;
        final videoId = args[ApiKeys.videoId] as String;
        return SendEnquiryScreen(
          channelId: channelId,
          videoId: videoId,
        );
      },
    ),
    GetPage(
      name: RouteConstant.BookingAndEnquiresScreen,
      page: () => BookingsScreen(),
    ),
    GetPage(
      name: RouteConstant.addUpdateProductScreen,
      binding: AddUpdateProductBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String channelId = args[ApiKeys.channelId] as String;
        final ProductData? productData =
            args[ApiKeys.argProductData] as ProductData?;
        return AddUpdateProductScreen(
            channelId: channelId, productData: productData);
      },
    ),
    GetPage(
      name: RouteConstant.addBankAccountScreen,
      page: () => AddBankAccountScreen(),
    ),
    GetPage(
      name: RouteConstant.addAccountUpiScreen,
      page: () => AddAccountUpiScreen(),
    ),
    GetPage(
      name: RouteConstant.walletScreen,
      page: () => WalletScreen(),
    ),
    GetPage(
      name: RouteConstant.allTransactionsScreen,
      page: () => SeeAllTransactionsView(),
    ),
    GetPage(
      name: RouteConstant.addDocumentScreen,
      page: () {
        final Map<String, dynamic>? args =
            Get.arguments as Map<String, dynamic>?;
        final String argDocumentVia =
            args?[ApiKeys.argDocumentVia] as String? ?? "";
        final bool showViewDocProof =
            args?[ApiKeys.showViewDocProof] as bool? ?? false;
        return AddDocumentScreen(
            showViewDocProof: showViewDocProof, documentVia: argDocumentVia);
      },
    ),
    GetPage(
      name: RouteConstant.postDetailPage,
      page: () => PostDeatilPage(),
    ),
    GetPage(
      name: RouteConstant.moreCardsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final bool isFromHomeScreen = args[ApiKeys.isFromHomeScreen] as bool;
        final double? headerHeight = args[ApiKeys.headerHeight] as double?;
        final onHeaderVisibilityChanged =
            args[ApiKeys.onHeaderVisibilityChanged] as Function(bool)?;
        return MoreCardsScreen(
          isFromHomeScreen: isFromHomeScreen,
          headerHeight: headerHeight,
          onHeaderVisibilityChanged: onHeaderVisibilityChanged,
        );
      },
    ),
    GetPage(
      name: RouteConstant.addProductTextOrSnapSearchScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return AddProductTextOrSnapSearchScreen(
          id: id,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.productScreen,
      page: () => ProductScreen(),
    ),
    GetPage(
      name: RouteConstant.manufacturerScreen,
      page: () => ManufacturerProductScreen(),
    ),
    GetPage(
      name: RouteConstant.manufacturerAddProductViaAiStep1,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return ManufacturerAddProductViaAiStep1(
            id: id, providerType: providerType);
      },
    ),
    GetPage(
      name: RouteConstant.manufacturerAddProductViaAiStep2,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ManufacturerProductController controller =
            args[ApiKeys.controller] as ManufacturerProductController;
        final GenerateAiProductContent generateAiProductContent =
            args[ApiKeys.generateAiProductContent] as GenerateAiProductContent;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return ManufacturerAddProductViaAiStep2(
          controller: controller,
          generateAiProductContent: generateAiProductContent,
          id: id,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.manufacturerProductPreviewScreen,
      binding: ManufacturerProductPreviewScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final ManufacturerProductPreviewArgs? argProductData =
            args?[ApiKeys.argProductData] as ManufacturerProductPreviewArgs?;
        final bool? isFromProductCreation =
            args?[ApiKeys.isFromProductCreation] as bool?;
        final bool? isUserCanCreateVariants =
            args?[ApiKeys.isUserCanCreateVariants] as bool?;
        final String? id = args?[ApiKeys.id] as String?;
        final ProviderType? providerType =
            args?[ApiKeys.providerType] as ProviderType?;
        return ManufacturerProductPreviewScreen(
          id: id,
          providerType: providerType,
          productPreviewArgs: argProductData,
          isFromProductCreation: isFromProductCreation ?? false,
          isUserCanCreateVariants: isUserCanCreateVariants ?? true,
        );
      },
    ),
    GetPage(
      name: RouteConstant.manufacturerCreateVariantScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ManufacturerProductController controller =
            args[ApiKeys.controller] as ManufacturerProductController;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return ManufacturerCreateVariantScreen(
          controller: controller,
          id: id,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.addServicesScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        final String? channelId = args[ApiKeys.channelId] as String?;
        return ServiceUploadScreen(
          providerType: providerType,
          channelId: channelId,
        );
      },
    ),
    GetPage(
      name: RouteConstant.addProductViaAiStep1,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return AddProductViaAiStep1(id: id, providerType: providerType);
      },
    ),
    GetPage(
      name: RouteConstant.addProductViaAiStep2,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ProductController controller =
            args[ApiKeys.controller] as ProductController;
        final GenerateAiProductContent generateAiProductContent =
            args[ApiKeys.generateAiProductContent] as GenerateAiProductContent;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return AddProductViaAiStep2(
          controller: controller,
          generateAiProductContent: generateAiProductContent,
          id: id,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.productPreviewScreen,
      binding: ProductPreviewScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final ProductPreviewArgs? argProductData =
            args?[ApiKeys.argProductData] as ProductPreviewArgs?;
        final bool? isFromProductCreation =
            args?[ApiKeys.isFromProductCreation] as bool?;
        final String? id = args?[ApiKeys.id] as String?;
        final ProviderType? providerType =
            args?[ApiKeys.providerType] as ProviderType?;
        return ProductPreviewScreen(
          id: id,
          providerType: providerType,
          productPreviewArgs: argProductData,
          isFromProductCreation: isFromProductCreation ?? false,
        );
      },
    ),
    GetPage(
      name: RouteConstant.productsStoreDetailsScreen,
      binding: ProductsStoreDetailsScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ProductStore? productStore =
            args[ApiKeys.argProductData] as ProductStore?;
        // final bool? productDataBool = args["isShowBusinessInfo"] as bool?;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return ProductsStoreDetailsScreen(
            productStore: productStore,
            // isShowBusinessInfo: productDataBool,
            id: id,
            providerType: providerType);
      },
    ),
    GetPage(
      name: RouteConstant.manufacturerStoreDetailsScreen,
      binding: ManufacturerStoreDetailsScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ProductStore? productStore =
            args[ApiKeys.argProductData] as ProductStore?;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return ManufacturerProductsStoreDetailsScreen(
            productStore: productStore, id: id, providerType: providerType);
      },
    ),
    GetPage(
      name: RouteConstant.createVariantScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ProductController controller =
            args[ApiKeys.controller] as ProductController;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return CreateVariantScreen(
          controller: controller,
          id: id,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.selfEmployeeScreen,
      page: () => SelfEmployeeScreen(),
    ),
    GetPage(
      name: RouteConstant.inventoryBusinessCardsScreen,
      page: () => InventoryBusinessCardsScreen(),
    ),
    GetPage(
      name: RouteConstant.foodUploadScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        final String? serviceSubType = args[ApiKeys.serviceSubType] as String?;
        final String? category = args[ApiKeys.category] as String?;
        return FoodUploadScreen(
            providerType: providerType,
            serviceSubType: serviceSubType,
            category: category);
      },
    ),
    GetPage(
      name: RouteConstant.addFlatRoomRentalServiceScreen,
      page: () => AddFlatRoomRentalServiceScreen(),
    ),
    GetPage(
      name: RouteConstant.vehicleInformationRidingScreen,
      binding: VehicleInformationRidingScreenBinding(),
      page: () => VehicleInformationRidingScreen(
        screeName: '',
      ),
    ),
    GetPage(
      name: RouteConstant.homeStayRentalService,
      page: () => HomeStayRentalService(),
    ),
    GetPage(
      name: RouteConstant.vehicleRentalService,
      page: () => VehicleRentalService(),
    ),
    GetPage(
      name: RouteConstant.rentalServiceScreen,
      binding: RentalBinding(),
      page: () => RentalServiceScreen(),
    ),
    GetPage(
      name: RouteConstant.rentalServiceFullDetailsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final RentalServiceData rentalServiceData =
            args[ApiKeys.argRentalData] as RentalServiceData;
        return RentalServiceFullDetailsScreen(
            rentalServiceData: rentalServiceData);
      },
    ),
    GetPage(
      name: RouteConstant.createBusinessAccountNewStepOne,
      page: () => CreateBusinessAccountNewStepOne(),
    ),
    GetPage(
      name: RouteConstant.createBusinessAccountNewStepTwo,
      page: () => CreateBusinessAccountNewStepTwo(),
    ),
    GetPage(
      name: RouteConstant.createBusinessAccountNewStepThree,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String? city = args[ApiKeys.city] as String?;
        return CreateBusinessAccountNewStepThree(city: city);
      },
    ),
    GetPage(
      name: RouteConstant.createBusinessAccountNewStepFour,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final String? city = args?[ApiKeys.city] as String?;
        return CreateBusinessAccountNewStepFour(city: city);
      },
    ),
    GetPage(
      name: RouteConstant.personalAccountNewScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;
        final profileType =
            args[ApiKeys.argProfileType] as IndividualProfileType;
        final argProfessionTagId = args[ApiKeys.argProfessionTagId] as String;
        final argProfession = args[ApiKeys.argProfession] as String;

        /// old
        // final professionTagId = args[ApiKeys.argProfessionTagId] as String;
        final professionSubCategory = args[ApiKeys.argProfessionSubCategory]
            as List<SubcategoriesFiledName>?;
        final selfEmployment = args[ApiKeys.argSelfEmployment] as String?;
        final selfEmploymentTagId =
            args[ApiKeys.argSelfEmploymentTagId] as String?;
        // Present only on the gig-work path, which verifies Aadhaar first and
        // forwards what the card said. Absent everywhere else.
        final prefillName = args[ApiKeys.argPrefillName] as String?;
        final prefillGender = args[ApiKeys.argPrefillGender] as GenderType?;
        final prefillDateOfBirth =
            args[ApiKeys.argPrefillDateOfBirth] as DateTime?;
        return PersonalAccountNewScreen(
          accountType: accountType,
          profileType: profileType,
          profession: argProfession,
          professionTagId: argProfessionTagId,
          professionSubCategory: professionSubCategory,
          selfEmployment: selfEmployment,
          selfEmploymentTagId: selfEmploymentTagId,
          prefillName: prefillName,
          prefillGender: prefillGender,
          prefillDateOfBirth: prefillDateOfBirth,
        );
      },
    ),
    GetPage(
      name: RouteConstant.gstNumberScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final accountType = args[ApiKeys.argAccountType] as String;
        final businessType = args[ApiKeys.argBusinessType] as BusinessType;
        final argCategorySlugId = args[ApiKeys.argCategoryId] as String;
        final argCategoryName = args[ApiKeys.argCategoryName] as String;
        final argSubCategory = args[ApiKeys.argSubCategory] as SubCategories?;
        final argIsGstMandatory =
            args[ApiKeys.argIsGstMandatory] as bool? ?? false;
        // final categoryData = args[ApiKeys.argCategoryData] as CategoryData?;
        return GstNumberScreen(
          accountType: accountType,
          businessType: businessType,
          // categoryData: categoryData,
          categorySlugId: argCategorySlugId,
          categoryName: argCategoryName,
          subCategory: argSubCategory,
          isGstMandatory: argIsGstMandatory,
        );
      },
    ),
    GetPage(
      name: RouteConstant.addBioViaAiScreen,
      binding: BioSuggestionBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final profession = args[ApiKeys.argProfession] as String;
        final designation = args[ApiKeys.argDesignation] as String?;
        final selectedDay = args[ApiKeys.argSelectedDay] as int?;
        final selectedMonth = args[ApiKeys.argSelectedMonth] as int?;
        final selectedYear = args[ApiKeys.argSelectedYear] as int?;
        return AddBioViaAiScreen(
            profession: profession,
            designation: designation,
            selectedDay: selectedDay,
            selectedMonth: selectedMonth,
            selectedYear: selectedYear);
      },
    ),
    GetPage(
      name: RouteConstant.groceryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final bool? argFromBottomNavBar =
            args[ApiKeys.argFromBottomNavBar] as bool?;
        return GroceryScreen(fromBottomNavBar: argFromBottomNavBar);
      },
    ),
    GetPage(
      name: RouteConstant.groceryNestedCategoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        // final bool argMyGrocery = args[ApiKeys.argMyGrocery] as bool;
        final String argArrGroceryCatName =
            args[ApiKeys.argArrGroceryCatName] as String;
        final String argArrGroceryCatKey =
            args[ApiKeys.argArrGroceryCatKey] as String;
        final List<GroceryNestedCategoryModel> argArrGrocerySuperCat =
            args[ApiKeys.argArrGrocerySuperCategory]
                as List<GroceryNestedCategoryModel>;
        return GroceryNestedCategoryScreen(
          argArrGrocerySuperCat: argArrGrocerySuperCat,
          argArrGroceryCatKey: argArrGroceryCatKey,
          argArrGroceryCatName: argArrGroceryCatName,
          // isMyGrocery: argMyGrocery
        );
      },
    ),
    GetPage(
      name: RouteConstant.groceryNestedCategoryWithInventoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String userId = args[ApiKeys.userId] as String;
        final List<GroceryCategoryWithInventoryModel>
            argGroceryCategoryWithInventory =
            args[ApiKeys.argGroceryCategoryWithInventory]
                as List<GroceryCategoryWithInventoryModel>;
        final String argArrGroceryCatName =
            args[ApiKeys.argArrGroceryCatName] as String;
        final String argArrGroceryCatKey =
            args[ApiKeys.argArrGroceryCatKey] as String;
        return GroceryNestedCategoryWithInventoryScreen(
          userId: userId,
          argGroceryCategoryWithInventory: argGroceryCategoryWithInventory,
          argArrGroceryCatKey: argArrGroceryCatKey,
          argArrGroceryCatName: argArrGroceryCatName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.groceryProductsSelectionScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<GroceryNestedCategoryModel> argGroceries =
            args[ApiKeys.argGroceries] as List<GroceryNestedCategoryModel>;
        // final GroceryNestedCategoryModel argSelectedGroceryData =
        //     args[ApiKeys.argSelectedGroceryData] as GroceryNestedCategoryModel;
        return GroceryProductsSelectionScreen(
          arrGroceries: argGroceries,
          // selectedGroceryData: argSelectedGroceryData
        );
      },
    ),
    GetPage(
      name: RouteConstant.addGroceryVariantScreen,
      page: () => AddGroceryVariantScreen(),
    ),
    GetPage(
      name: RouteConstant.myGroceryProductsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String userId = args[ApiKeys.userId] as String;
        final List<GroceryNestedCategoryModel> argGroceries =
            args[ApiKeys.argGroceries] as List<GroceryNestedCategoryModel>;
        return MyGroceryProductsScreen(
            userId: userId, arrGroceries: argGroceries);
      },
    ),
    GetPage(
      name: RouteConstant.visitGroceryProductsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String userId = (args[ApiKeys.userId] as String?) ?? '';
        final String visitBusinessId =
            (args[ApiKeys.businessId] as String?) ?? '';
        final String argArrGroceryCatName =
            (args[ApiKeys.argArrGroceryCatName] as String?) ?? '';
        final String argArrGroceryCatKey =
            (args[ApiKeys.argArrGroceryCatKey] as String?) ?? '';
        return VisitGroceryProductsScreen(
          userId: userId,
          visitBusinessId: visitBusinessId,
          argArrGroceryCatKey: argArrGroceryCatKey,
          argArrGroceryCatName: argArrGroceryCatName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.allGroceryCategorizeProductsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<GroceryNestedCategoryModel> argCategories =
            args[ApiKeys.argCategories] as List<GroceryNestedCategoryModel>;
        return AllGroceryProductsScreen(
          argSubCategory: argCategories,
        );
      },
    ),
    GetPage(
      name: RouteConstant.riderServiceScreen,
      page: () {
        // final args = Get.arguments as Map<String, dynamic>;
        // final List<CollapsibleGridModel> argGroceries = args[ApiKeys.argGroceries] as List<CollapsibleGridModel>;
        // final CollapsibleGridModel argSelectedGroceryData = args[ApiKeys.argSelectedGroceryData] as CollapsibleGridModel;
        return RiderServiceScreen(
            // arrGroceries: argGroceries,
            // selectedGroceryData: argSelectedGroceryData
            );
      },
    ),
    GetPage(
      name: RouteConstant.riderMeScreen,
      page: () => const RiderMeScreen(),
    ),
    GetPage(
      name: RouteConstant.groceryCartScreen,
      page: () => GroceryCartScreen(),
    ),
    GetPage(
      name: RouteConstant.grocerySuperCategoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final bool argBulkUpload = args[ApiKeys.argBulkUpload] as bool;
        return GrocerySuperCategoryScreen(isAvailBulkUpload: argBulkUpload);
      },
    ),
    GetPage(
      name: RouteConstant.productSuperCategoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final String? ownerID = args?[ApiKeys.id] as String?;
        final ProviderType? providerType =
            args?[ApiKeys.providerType] as ProviderType?;
        return ProductSuperCategoryScreen(
          ownerID: ownerID,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.productNestedCategoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<ProductNestedCategoryResponse> superCats =
            args[ApiKeys.argArrProductSuperCategory]
                as List<ProductNestedCategoryResponse>;
        final String catId = args[ApiKeys.argArrProductCatId] as String;
        final String catName = args[ApiKeys.argArrProductCatName] as String;
        final List<ProductNestedCategoryResponse> nestedChildren =
            (args[ApiKeys.argProducts] as List?)
                    ?.cast<ProductNestedCategoryResponse>() ??
                const [];
        return ProductNestedCategoryScreen(
          argArrProductSuperCat: superCats,
          argArrProductCatId: catId,
          argArrProductCatName: catName,
          children: nestedChildren,
        );
      },
    ),
    GetPage(
      name: RouteConstant.storeProductSelectionScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<ProductNestedCategoryResponse> products =
            args[ApiKeys.argProducts] as List<ProductNestedCategoryResponse>;
        final String? categoryName =
            args[ApiKeys.argArrProductCatName] as String?;
        return ProductSelectionScreen(
          arrProducts: products,
          categoryName: categoryName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.productCartScreen,
      page: () => ProductCartScreen(),
    ),
    GetPage(
      name: RouteConstant.addProductVariantScreen,
      page: () => AddProductVariantScreen(),
    ),
    GetPage(
      name: RouteConstant.paymentSettingScreen,
      page: () => PaymentSettingScreen(),
    ),
    GetPage(
      name: RouteConstant.riderStoreScreen,
      page: () => RiderStoreScreen(),
    ),
    GetPage(
      name: RouteConstant.groceryConfirmScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String argOrderId = args[ApiKeys.argOrderId] as String;
        return GroceryConfirmScreen(orderId: argOrderId);
      },
    ),
    GetPage(
      name: RouteConstant.addSelfServiceScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final bool argFromBottomNavBar =
            args[ApiKeys.argFromBottomNavBar] as bool;
        final String serviceSubType = args[ApiKeys.serviceSubType] as String;
        final String professionCategory = args[ApiKeys.profession] as String;
        return AddSelfServiceScreen(
            fromBottomNavBar: argFromBottomNavBar,
            professionCategory: professionCategory,
            serviceSubType: serviceSubType);
      },
    ),
    GetPage(
      name: RouteConstant.createAccountTypeScreen,
      page: () => CreateAccountTypeScreen(),
    ),
    GetPage(
      name: RouteConstant.createAccountTypeV2Screen,
      page: () => const CreateAccountTypeV2Screen(),
    ),
    GetPage(
      name: RouteConstant.gigWorkerOptionsScreen,
      page: () => GigWorkOptionsScreen(),
    ),
    GetPage(
      name: RouteConstant.medicalScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final bool? argFromBottomNavBar =
            args[ApiKeys.argFromBottomNavBar] as bool?;
        return MedicalScreen(fromBottomNavBar: argFromBottomNavBar);
      },
    ),
    GetPage(
      name: RouteConstant.medicalCategoryScreen,
      page: () => MedicalCategoryScreen(),
    ),
    GetPage(
      name: RouteConstant.medicalSubCategoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<MedicalNestedCategoryModel> argGroceries =
            args[ApiKeys.argGroceries] as List<MedicalNestedCategoryModel>;
        // final GroceryNestedCategoryModel argSelectedGroceryData =
        //     args[ApiKeys.argSelectedGroceryData] as GroceryNestedCategoryModel;
        return MedicalProductSelectionScreen(
          arrLevel3Category: argGroceries,
        );
      },
    ),
    GetPage(
      name: RouteConstant.addMedicalVariantScreen,
      page: () => AddMedicalVariantScreen(),
    ),
    GetPage(
      name: RouteConstant.myMedicalProductsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String argCategoryId = args[ApiKeys.argCategoryId] as String;
        final String argCategoryName = args[ApiKeys.argCategoryName] as String;
        return MyMedicalProductsScreen(
          categoryId: argCategoryId,
          categoryName: argCategoryName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.myMedicalVariantScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        // Optional now: the category-card path passes no variants (the screen
        // fetches them from categoryId); the legacy path still passes a list.
        final List<MedicalProductVariants>? variants =
            args[ApiKeys.argVariants] as List<MedicalProductVariants>?;
        final bool? argIsShowInGrid = args[ApiKeys.argIsShowInGrid] as bool?;
        final String? argMedCategoryId = args[ApiKeys.argCategoryId] as String?;
        final String? argMedCategoryName =
            args[ApiKeys.argCategoryName] as String?;
        return MyMedicalVariantScreen(
          variants: variants,
          isShowInGrid: argIsShowInGrid ?? true,
          categoryId: argMedCategoryId,
          categoryName: argMedCategoryName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.medicalListingScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<MedicalNestedCategoryModel> argGroceries =
            args[ApiKeys.argGroceries] as List<MedicalNestedCategoryModel>;
        return MedicalListingScreen(
          arrLevel3Category: argGroceries,
        );
      },
    ),
    GetPage(
      name: RouteConstant.medicalCartScreen,
      page: () => MedicalCartScreen(),
    ),
    GetPage(
      name: RouteConstant.medicalConfirmScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String argOrderId = args[ApiKeys.argOrderId] as String;
        return MedicalConfirmScreen(orderId: argOrderId);
      },
    ),
    GetPage(
      name: RouteConstant.medicalHomeScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String argBusinessId = args[ApiKeys.argBusinessId] as String;
        return MedicalHomeScreenV2(businessId: argBusinessId);
      },
    ),
    GetPage(
      name: RouteConstant.groceryStoresScreen,
      page: () {
        // Optional `arguments`: the grocery category tab to open on, as a bare
        // tagId String. Absent (the usual case) opens on "All Grocery".
        final groceryTagId =
            Get.arguments is String ? Get.arguments as String : null;
        return GroceryStoresScreen(initialCategoryTagId: groceryTagId);
      },
    ),
    GetPage(
      name: RouteConstant.addGrocerySnapSearchScreen,
      page: () => AddGrocerySnapSearchScreen(),
    ),
    GetPage(
      name: RouteConstant.groceryRiderSnapSearchScreen,
      page: () => GroceryRiderSnapSearchScreen(),
    ),
    GetPage(
      name: RouteConstant.addMedicalSnapSearchScreen,
      page: () => AddMedicalSnapSearchScreen(),
    ),
    GetPage(
      name: RouteConstant.missingGroceryItemsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final GroceryController controller =
            args[ApiKeys.controller] as GroceryController;
        final List<MissingProducts> argMissingProducts =
            args[ApiKeys.argMissingProducts] as List<MissingProducts>;
        return MissingGroceryItemsScreen(
            controller: controller, missingProducts: argMissingProducts);
      },
    ),
    GetPage(
      name: RouteConstant.missingFoodItemsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final FoodServiceController controller =
            args[ApiKeys.controller] as FoodServiceController;
        final List<MissingFoodProducts> argMissingProducts =
            args[ApiKeys.argMissingProducts] as List<MissingFoodProducts>;
        return MissingFoodItemsScreen(
            controller: controller, missingProducts: argMissingProducts);
      },
    ),
    GetPage(
      name: RouteConstant.visitGroceryStoreScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String businessId = args[ApiKeys.businessId] as String;
        final String userId = args[ApiKeys.userId] as String;
        return VisitGroceryStoreScreen(
          visitBusinessId: businessId,
          userId: userId,
        );
      },
    ),
    GetPage(
      name: RouteConstant.visitFoodStoreDetailsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String businessId = args[ApiKeys.businessId] as String;
        return VisitFoodStoreDetailsScreen(
          visitBusinessId: businessId,
        );
      },
    ),
    GetPage(
      name: RouteConstant.addFoodSnapSearchScreen,
      page: () => AddFoodSnapSearchScreen(),
    ),
    GetPage(
      name: RouteConstant.addSingleProductScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String productId = args[ApiKeys.productId] as String;
        final int? createMissingProductIndex =
            args[ApiKeys.argCreateMissingProductIndex] as int?;
        return AddSingleFoodProductScreen(
            foodProductId: productId,
            createMissingProductIndex: createMissingProductIndex);
      },
    ),
    GetPage(
      name: RouteConstant.foodProductSelectionScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final GroceryNestedCategoryModel foodCategoryData =
            args[ApiKeys.argCategoryData] as GroceryNestedCategoryModel;
        return FoodProductSelectionScreen(foodCategoryData: foodCategoryData);
      },
    ),
    GetPage(
      name: RouteConstant.productNestedCategoryWithInventoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<ProductCategoryWithInventoryModel>
            argProductCategoryWithInventory =
            args[ApiKeys.argProductCategoryWithInventory]
                as List<ProductCategoryWithInventoryModel>;
        final String argProductCatName =
            args[ApiKeys.argProductCatName] as String;
        final String argProductCatKey =
            args[ApiKeys.argProductCatKey] as String;
        return ProductNestedCategoryWithInventoryScreen(
          argProductCategoryWithInventory: argProductCategoryWithInventory,
          argProductCatKey: argProductCatKey,
          argProductCatName: argProductCatName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.myProductProductsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<ProductCategoryWithInventoryModel> argProductCategories =
            args[ApiKeys.argProductCategories]
                as List<ProductCategoryWithInventoryModel>;
        return MyProductProductsScreen(
          arrCategories: argProductCategories,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotivePartsScreen,
      page: () => AutomotivePartsScreen(),
    ),
    GetPage(
      name: RouteConstant.automotiveAddProductTextOrSnapScreen,
      binding: AutomotiveAddProductTextOrSnapScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return AutomotiveAddProductTextOrSnapSearchScreen(
          id: id,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotiveAddProductViaAiStep1,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return AutomotiveAddProductViaAiStep1(
            id: id, providerType: providerType);
      },
    ),
    GetPage(
      name: RouteConstant.automotiveAddProductViaAiStep2,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final AutomotiveProductController controller =
            args[ApiKeys.controller] as AutomotiveProductController;
        final AutomotiveGenerateAiProductContent generateAiProductContent =
            args[ApiKeys.generateAiProductContent]
                as AutomotiveGenerateAiProductContent;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return AutomotiveAddProductViaAiStep2(
          controller: controller,
          generateAiProductContent: generateAiProductContent,
          id: id,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotiveProductPreviewScreen,
      binding: AutomotiveProductPreviewScreenBinding(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final AutomotiveProductPreviewArgs? argProductData =
            args?[ApiKeys.argProductData] as AutomotiveProductPreviewArgs?;
        final bool? isFromProductCreation =
            args?[ApiKeys.isFromProductCreation] as bool?;
        final String? id = args?[ApiKeys.id] as String?;
        final ProviderType? providerType =
            args?[ApiKeys.providerType] as ProviderType?;
        return AutomotiveProductPreviewScreen(
          id: id,
          providerType: providerType,
          productPreviewArgs: argProductData,
          isFromProductCreation: isFromProductCreation ?? false,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotiveProductsStoreDetailsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final ProductStore? productStore =
            args[ApiKeys.argProductData] as ProductStore?;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return AutomotiveProductsStoreDetailsScreen(
            productStore: productStore, id: id, providerType: providerType);
      },
    ),
    GetPage(
      name: RouteConstant.automotiveCreateVariantScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final AutomotiveProductController controller =
            args[ApiKeys.controller] as AutomotiveProductController;
        final String id = args[ApiKeys.id] as String;
        final ProviderType providerType =
            args[ApiKeys.providerType] as ProviderType;
        return AutomotiveCreateVariantScreen(
          controller: controller,
          id: id,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotiveProductSuperCategoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final String? ownerID = args?[ApiKeys.id] as String?;
        final ProviderType? providerType =
            args?[ApiKeys.providerType] as ProviderType?;
        return AutomotiveProductSuperCategoryScreen(
          ownerID: ownerID,
          providerType: providerType,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotiveProductNestedCategoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<AutomotiveProductNestedCategoryResponse> superCats =
            args[ApiKeys.argArrProductSuperCategory]
                as List<AutomotiveProductNestedCategoryResponse>;
        final String catId = args[ApiKeys.argArrProductCatId] as String;
        final String catName = args[ApiKeys.argArrProductCatName] as String;
        final List<AutomotiveProductNestedCategoryResponse> nestedChildren =
            (args[ApiKeys.argProducts] as List?)
                    ?.cast<AutomotiveProductNestedCategoryResponse>() ??
                const [];
        return AutomotiveProductNestedCategoryScreen(
          argArrProductSuperCat: superCats,
          argArrProductCatId: catId,
          argArrProductCatName: catName,
          children: nestedChildren,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotiveStoreProductSelectionScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<AutomotiveProductNestedCategoryResponse> products =
            args[ApiKeys.argProducts]
                as List<AutomotiveProductNestedCategoryResponse>;
        final String? categoryName =
            args[ApiKeys.argArrProductCatName] as String?;
        return AutomotiveProductSelectionScreen(
          arrProducts: products,
          categoryName: categoryName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotiveAddProductVariantScreen,
      binding: AutomotiveAddProductVariantScreenBinding(),
      page: () => AutomotiveAddProductVariantScreen(),
    ),
    GetPage(
      name: RouteConstant.automotiveProductNestedCategoryWithInventoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<AutomotiveProductCategoryWithInventoryModel>
            argProductCategoryWithInventory =
            args[ApiKeys.argProductCategoryWithInventory]
                as List<AutomotiveProductCategoryWithInventoryModel>;
        final String argProductCatName =
            args[ApiKeys.argProductCatName] as String;
        final String argProductCatKey =
            args[ApiKeys.argProductCatKey] as String;
        return AutomotiveProductNestedCategoryWithInventoryScreen(
          argProductCategoryWithInventory: argProductCategoryWithInventory,
          argProductCatKey: argProductCatKey,
          argProductCatName: argProductCatName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.automotiveMyProductProductsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<AutomotiveProductCategoryWithInventoryModel>
            argProductCategories = args[ApiKeys.argProductCategories]
                as List<AutomotiveProductCategoryWithInventoryModel>;
        return AutomotiveMyProductProductsScreen(
          arrCategories: argProductCategories,
        );
      },
    ),
    GetPage(
      name: RouteConstant.myManufacturerProductsScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<ProductCategoryWithInventoryModel> argProductCategories =
            args[ApiKeys.argProductCategories]
                as List<ProductCategoryWithInventoryModel>;
        return MyManufacturerProductsScreen(
          arrCategories: argProductCategories,
        );
      },
    ),
    GetPage(
      name: RouteConstant.manufacturerNestedCategoryWithInventoryScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final List<ProductCategoryWithInventoryModel>
            argProductCategoryWithInventory =
            args[ApiKeys.argProductCategoryWithInventory]
                as List<ProductCategoryWithInventoryModel>;
        final String argProductCatName =
            args[ApiKeys.argProductCatName] as String;
        final String argProductCatKey =
            args[ApiKeys.argProductCatKey] as String;
        return ManufacturerNestedCategoryWithInventoryScreen(
          argProductCategoryWithInventory: argProductCategoryWithInventory,
          argProductCatKey: argProductCatKey,
          argProductCatName: argProductCatName,
        );
      },
    ),
    GetPage(
      name: RouteConstant.foodEntryAiScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final int? createMissingProductIndex =
            args[ApiKeys.argCreateMissingProductIndex] as int?;
        final String? foodCategoryType =
            args[ApiKeys.argFoodCategoryType] as String?;
        return FoodEntryAiScreen(
            createMissingProductIndex: createMissingProductIndex,
            categoryType: foodCategoryType);
      },
    ),
    GetPage(
      name: RouteConstant.foodAiDetailScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final FoodGenAiResModel foodGenAiResModel =
            args[ApiKeys.argFoodGenAiResModel] as FoodGenAiResModel;
        final int? createMissingProductIndex =
            args[ApiKeys.argCreateMissingProductIndex] as int?;
        return FoodAiDetailScreen(
            foodData: foodGenAiResModel,
            createMissingProductIndex: createMissingProductIndex);
      },
    ),
    GetPage(
      name: RouteConstant.foodCustomerListingScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final GroceryNestedCategoryModel foodCategoryData =
            args[ApiKeys.argCategoryData] as GroceryNestedCategoryModel;
        final String? visitBusinessId = args[ApiKeys.argBusinessId] as String?;
        return FoodCustomerListingScreen(
          foodCategoryData: foodCategoryData,
          visitBusinessId: visitBusinessId,
        );
      },
    ),
    GetPage(
      name: RouteConstant.nearByRidersScreen,
      page: () => NearByRidersScreen(),
    ),
    GetPage(
      name: RouteConstant.globalSearchScreen,
      page: () {
        final initialQuery =
            Get.arguments is String ? Get.arguments as String : null;
        return GlobalSearchScreen(initialQuery: initialQuery);
      },
    ),
    GetPage(
      name: RouteConstant.IncomingCallScreen,
      page: () {
        // case RouteConstant.IncomingRiderOrderScreen:
        return const CallActivityRoomScreen();
      },
    ),
    GetPage(
      name: RouteConstant.vehicleHomeScreen,
      page: () => const VehicleScreenV3(),
    ),
    GetPage(
      name: RouteConstant.vehicleListingScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return VehicleDiscoverScreenV3(
          initialCondition: args?['condition'] as String?,
        );
      },
    ),
    GetPage(
      name: RouteConstant.vehicleDetailScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return VehicleListingDetailScreenV3(
          listingId: args['vehicleId'] as String,
        );
      },
    ),
    GetPage(
      name: RouteConstant.chooseEarnServiceScreen,
      page: () => const ChooseEarnServiceScreen(),
    ),
    GetPage(
      name: RouteConstant.earnServiceDashboardView,
      page: () => const EarnServiceDashboardView(),
    ),
    GetPage(
      name: RouteConstant.savedAddressListScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return SavedAddressListScreen(
          onAddressSelected:
              args?['onAddressSelected'] as AddressSelectedCallback?,
          isSelectionMode: args?['isSelectionMode'] as bool? ?? true,
        );
      },
    ),
    GetPage(
      name: RouteConstant.addEditAddressScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return AddEditAddressScreen(
          address: args?['address'] as UserAddress?,
        );
      },
    ),
    GetPage(
      name: RouteConstant.orderStepsScreen,
      page: () {
        final args = Get.arguments;
        final resolved = args is OrderStepsArgs
            ? args
            : OrderStepsArgs(
                orderId:
                    (args is Map ? args['orderId'] : null)?.toString() ?? '',
                service: (args is Map ? args['service'] : null)?.toString() ??
                    OrderServiceApi.groceryOrderService,
                isOwner: args is Map && args['isOwner'] == true,
              );
        return OrderStepsScreen(args: resolved);
      },
    ),
    GetPage(
      name: RouteConstant.mySelfPickupOrdersScreen,
      page: () => const MySelfPickupOrdersScreen(),
    ),

    // ── Cases the switch expressed as branching / custom routes ──────────

    // The original switch branched on whether arguments were supplied at
    // all. Both branches are preserved verbatim, including the else-branch
    // cast that throws when arguments really are null (pre-existing).
    GetPage(
      name: RouteConstant.CreateMessagePostScreen,
      binding: CreateMessagePostScreenBinding(),
      page: () {
        if ((Get.arguments != null)) {
          final args = Get.arguments as Map<String, dynamic>;
          final postData =
              (args[ApiKeys.post] != null) ? args[ApiKeys.post] as Post : null;
          final isEdit = (args[ApiKeys.isEdit] != null)
              ? args[ApiKeys.isEdit] as bool
              : false;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;

          ///CHANGE IN ELSE BLOCK ALSO....
          return CreateMessagePostScreenNew(
              isEdit: isEdit, post: postData, postVia: postVia);
        } else {
          final args = Get.arguments as Map<String, dynamic>;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return CreateMessagePostScreenNew(isEdit: false, postVia: postVia);
        }
      },
    ),
    GetPage(
      name: RouteConstant.PollInputScreen,
      binding: PollBinding(),
      page: () {
        if ((Get.arguments != null)) {
          final args = Get.arguments as Map<String, dynamic>;
          final postData =
              (args[ApiKeys.post] != null) ? args[ApiKeys.post] as Post : null;
          final isEdit = (args[ApiKeys.isEdit] != null)
              ? args[ApiKeys.isEdit] as bool
              : false;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return PollInputScreen(
              isEdit: isEdit, post: postData, postVia: postVia);
        } else {
          final args = Get.arguments as Map<String, dynamic>;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return PollInputScreen(isEdit: false, postVia: postVia);
        }
      },
    ),
    GetPage(
      name: RouteConstant.PhotoPostScreen,
      binding: PhotoPostBinding(),
      page: () {
        if ((Get.arguments != null)) {
          final args = Get.arguments as Map<String, dynamic>;
          final postData =
              (args[ApiKeys.post] != null) ? args[ApiKeys.post] as Post : null;
          final isEdit = (args[ApiKeys.isEdit] != null)
              ? args[ApiKeys.isEdit] as bool
              : false;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return PhotoPostScreen(
              isEdit: isEdit, post: postData, postVia: postVia);
        } else {
          final args = Get.arguments as Map<String, dynamic>;
          final postVia = args[ApiKeys.argPostVia] as PostVia?;
          return PhotoPostScreen(isEdit: false, postVia: postVia);
        }
      },
    ),

    // OutgoingCallScreen fell through to IncomingCallScreen in the switch;
    // both names resolve to the same screen.
    GetPage(
      name: RouteConstant.OutgoingCallScreen,
      page: () => const CallActivityRoomScreen(),
    ),

    // Transparent route: the ride offer is a SHEET, so whatever the rider was
    // looking at has to keep painting behind the scrim. `opaque: false` is
    // what an opaque MaterialPageRoute could not give us.
    //
    // NOTE: the old PageRouteBuilder also set reverseTransitionDuration (200ms).
    // GetPage has no such field, so the 260ms duration applies both ways.
    GetPage(
      name: RouteConstant.IncomingRiderOrderScreen,
      page: () => const IncomingRiderOrderScreen(),
      opaque: false,
      fullscreenDialog: true,
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 260),
    ),
  ];

  /// Replaces the switch's `default:` branch.
  static final GetPage unknownRoute = GetPage(
    name: '/not-found',
    page: () => const Scaffold(
      body: Center(child: CustomText('No route found')),
    ),
  );
}
