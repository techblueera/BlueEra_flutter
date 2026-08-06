import 'package:get/get.dart';

/// Bumped whenever the customer's ongoing-ride state materially changes: a ride
/// is booked, restored from [OngoingRideStore] after a relaunch, moves status,
/// or ends.
///
/// ## Why a separate signal rather than just watching the controllers
///
/// The Discover chip can't subscribe to a controller that doesn't exist yet.
/// `RideBookingController` is deliberately NOT constructed on a Discover render
/// (that would spin up location bootstrap and place loads for a user who has
/// never booked a ride), so on a cold start the chip builds while no ride
/// controller is registered. When the restorer creates one moments later and
/// fills in the booking, there is no observable the chip was already listening
/// to — its `Obx` never re-runs and the ride silently never appears.
///
/// This is that missing observable: always present, cheap, and readable from an
/// `Obx` before any ride controller exists. Reading it inside the chip's `Obx`
/// is what lets a ride that materialises later push itself onto the screen.
final RxInt ongoingRideRevision = 0.obs;

/// Nudge every widget watching [ongoingRideRevision].
void bumpOngoingRideRevision() => ongoingRideRevision.value++;
