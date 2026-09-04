import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/provider/dashboard/provider_dashboard_screen.dart';

void main() {
  testWidgets('ProviderDashboardScreen renders core elements and opens Add Service modal', (WidgetTester tester) async {
    // Simulate desktop screen
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ProviderDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Brand / Header
    expect(find.text('PawStay'), findsWidgets);
    expect(find.text('HOST DASHBOARD'), findsOneWidget);
    expect(find.text('Priya Rathore'), findsOneWidget);
    expect(find.textContaining('Online'), findsOneWidget);

    // Verify Stats
    expect(find.text("Today's Bookings"), findsOneWidget);
    expect(find.text('Active Pets'), findsOneWidget);
    expect(find.text('Monthly Earnings'), findsOneWidget);
    expect(find.text('Pending Requests'), findsOneWidget);
    expect(find.text('Upcoming Visits'), findsOneWidget);

    // Verify Published Services & Bookings Table
    expect(find.text('Published Services'), findsOneWidget);
    expect(find.text('Recent Bookings Overview'), findsOneWidget);
    expect(find.text('Weekly Schedule & Calendar'), findsOneWidget);
    expect(find.text('Recent Verified Reviews'), findsOneWidget);
    expect(find.text('Live Capacity & Occupancy'), findsOneWidget);

    // Verify FAB & Modal Open
    final addServiceFab = find.text('Add New Service');
    expect(addServiceFab, findsOneWidget);

    await tester.tap(addServiceFab);
    await tester.pumpAndSettle();

    // Verify Add Service Modal is opened
    expect(find.text('Create Pet Boarding Service'), findsOneWidget);
    expect(find.text('1. Basic Service Information'), findsOneWidget);
    expect(find.text('2. Location & Facility Address'), findsOneWidget);
    expect(find.text('3. Pets Accepted & Sizing'), findsOneWidget);
    expect(find.text('4. Care Inclusions & Amenities'), findsOneWidget);
    expect(find.text('Publish Service'), findsOneWidget);
  });
}
