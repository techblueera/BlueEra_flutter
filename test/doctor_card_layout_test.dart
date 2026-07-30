import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/model/doctor_discover_summary.dart';
import 'package:BlueEra/features/common/Discover/widget/doctor_discover_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

DoctorDiscoverSummary _summary(Map<String, dynamic> overrides) {
  return DoctorDiscoverSummary.fromJson({
    '_id': 'b1',
    'user_id': 'u1',
    'business_name': 'Dr. Umesh Gupta',
    'headline': 'General Physician',
    'specialization': ['General Physician', 'Cardiologist'],
    'degree': ['MBBS', 'MD (General Medicine)', 'DM (Cardiology)'],
    'languagesSpoken': ['English', 'Hindi', 'Bengali', 'Marathi', 'Tamil'],
    'experienceYears': 10,
    'consultationFee': 1000,
    'feeType': 'Per Visit',
    'certificate_count': 3,
    'avg_rating': 4.8,
    'total_ratings': 48,
    'address': '123 Park Street, Near Metro Station, Kolkata - 700016',
    'timing': {
      'today': {
        'day': 'Monday',
        'isOpen': true,
        'shopOpenTime': '09:00',
        'shopCloseTime': '18:00',
      },
      'schedule': [
        {
          'day': 'Monday',
          'isOpen': true,
          'shopOpenTime': '09:00',
          'shopCloseTime': '18:00'
        },
        {'day': 'Sunday', 'isOpen': false},
      ],
    },
    ...overrides,
  });
}

/// Renders at a narrow phone width — the card is dense, and 800x600 (the test
/// default) is wider than any real device, so it would hide overflows.
Future<void> _pump(WidgetTester tester, DoctorDiscoverSummary doctor) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return Scaffold(
          body: SingleChildScrollView(
            child: DoctorDiscoverCard(doctor: doctor, onTap: () {}),
          ),
        );
      }),
    ),
  );
  await tester.pump();
}

/// Today's window is a RichText (three coloured spans), so it can't be found
/// with `find.text`.
bool _richTextContaining(WidgetTester tester, String expected) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .any((w) => w.text.toPlainText().contains(expected));
}

void main() {
  testWidgets('renders a fully-populated doctor', (tester) async {
    await _pump(tester, _summary({}));
    expect(find.text('Dr. Umesh Gupta'), findsOneWidget);
    expect(find.text('10 Years Experience'), findsOneWidget);
    expect(find.text('+3 More'), findsOneWidget);
    expect(find.text('Book Now'), findsOneWidget);
    // Today's window is a RichText (three coloured spans), so it needs a
    // predicate finder rather than find.text.
    expect(_richTextContaining(tester, 'Monday: 9:00 AM – 6:00 PM'), isTrue);
  });

  testWidgets('hides the fee block when consultationFee is null',
      (tester) async {
    await _pump(tester, _summary({'consultationFee': null}));
    expect(find.text('Consultation Fee'), findsNothing);
    expect(find.textContaining('₹0'), findsNothing);
    expect(find.text('Book Now'), findsOneWidget);
  });

  testWidgets('degraded listing (empty arrays, no timing) still renders',
      (tester) async {
    await _pump(
      tester,
      _summary({
        'specialization': <String>[],
        'headline': '',
        'degree': <String>[],
        'languagesSpoken': <String>[],
        'experienceYears': 0,
        'consultationFee': null,
        'avg_rating': 0,
        'timing': null,
      }),
    );
    expect(find.text('Timing not set'), findsOneWidget);
  });

  testWidgets('expands the weekly schedule on chevron tap', (tester) async {
    await _pump(tester, _summary({}));
    expect(find.text('Sunday'), findsNothing);
    await tester.tap(find.text('Availability'));
    await tester.pumpAndSettle();
    expect(find.text('Sunday'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('closed today shows the closed state', (tester) async {
    await _pump(
      tester,
      _summary({
        'timing': {
          'today': {'day': 'Sunday', 'isOpen': false},
          'schedule': [
            {'day': 'Sunday', 'isOpen': false}
          ],
        },
      }),
    );
    expect(find.text('Closed today'), findsOneWidget);
  });
}
