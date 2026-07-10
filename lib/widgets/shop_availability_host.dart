import 'package:BlueEra/features/business/auth/model/shop_open_status.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:get/get.dart';

/// Contract the shared shop-status sheet + weekly-hours editor depend on, so the
/// same UI works over either the business availability document
/// (`ViewBusinessDetailsController`) or the individual one
/// (`ViewPersonalDetailsController`, used by professionals/consultants). Each
/// controller reads/writes its own endpoints; the sheet only needs these.
abstract class ShopAvailabilityHost {
  /// The full weekly open/close schedule (one row per weekday).
  RxList<Schedule> get weeklySchedule;

  /// Rich effective status (open-now, open-today, close time, override flag).
  Rx<ShopOpenStatus> get shopStatus;

  /// True while a today-override / hours call is in flight (drives the sheet
  /// spinner + disables its controls).
  RxBool get isAvailabilityUpdating;

  /// Force the shop OPEN for today only (auto-reverts tomorrow).
  Future<void> setOpenToday();

  /// Force the shop CLOSED for today only (auto-reverts tomorrow).
  Future<void> setClosedToday();

  /// Clear today's override, back to the weekly schedule immediately.
  Future<void> revertTodayOverride();

  /// Open the weekly-hours editor and re-hydrate on save.
  Future<void> openWeeklyEditor();
}
