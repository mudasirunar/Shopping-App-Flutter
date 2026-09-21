import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/core/theme/app_theme.dart';
import 'package:shopping_app/core/utils/app_snackbar.dart';

void main() {
  group('AppSnackBar Tests', () {
    testWidgets('Shows message and immediately clears previous snackbars', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppSnackBar.show(context, message: 'First message'),
                    child: const Text('Show First'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppSnackBar.show(context, message: 'Second message'),
                    child: const Text('Show Second'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Trigger first snackbar
      await tester.tap(find.text('Show First'));
      await tester.pump();
      expect(find.text('First message'), findsOneWidget);

      // Rapidly trigger second snackbar - first should be cleared immediately
      await tester.tap(find.text('Show Second'));
      await tester.pump();
      expect(find.text('First message'), findsNothing);
      expect(find.text('Second message'), findsOneWidget);
    });

    testWidgets('Action button executes callback and dismisses cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackBar.show(
                  context,
                  message: 'Saved to Wishlist',
                  actionLabel: 'View Wishlist',
                  onAction: () => actionTriggered = true,
                ),
                child: const Text('Save Item'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save Item'));
      await tester.pumpAndSettle();

      expect(find.text('Saved to Wishlist'), findsOneWidget);
      expect(find.text('View Wishlist'), findsOneWidget);

      // Tap the action button
      await tester.tap(find.text('View Wishlist'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
      expect(find.text('Saved to Wishlist'), findsNothing);
    });

    testWidgets('Standard snackbar auto-dismisses after 1600ms', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackBar.show(context, message: 'Quick alert'),
                child: const Text('Show Alert'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Alert'));
      await tester.pump(); // start entrance animation
      await tester.pump(const Duration(milliseconds: 300)); // complete entrance animation
      expect(find.text('Quick alert'), findsOneWidget);

      // Advance by display duration (1600ms)
      await tester.pump(const Duration(milliseconds: 1700)); // timer triggers reverse animation
      await tester.pump(const Duration(milliseconds: 300)); // complete exit animation
      expect(find.text('Quick alert'), findsNothing);
    });

    testWidgets('Action snackbar stays visible longer and auto-dismisses after 3200ms', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackBar.show(
                  context,
                  message: 'Action alert',
                  actionLabel: 'Undo',
                  onAction: () {},
                ),
                child: const Text('Show Action'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Action'));
      await tester.pump(); // start entrance
      await tester.pump(const Duration(milliseconds: 300)); // complete entrance
      final sb = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(sb.duration, const Duration(milliseconds: 3200));
      expect(find.text('Action alert'), findsOneWidget);

      // At 2000ms, it should still be visible (standard snackbar would have gone)
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.text('Action alert'), findsOneWidget);

      // Advance by 2000ms more (total 4000ms from start)
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 500));
      // Wait, is there a timer remaining?
      await tester.pumpAndSettle();
      expect(find.text('Action alert'), findsNothing);
    });

    testWidgets('isError applies error background color', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackBar.show(
                  context,
                  message: 'Error occurred',
                  isError: true,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);
      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, AppTheme.error);
    });
  });
}
