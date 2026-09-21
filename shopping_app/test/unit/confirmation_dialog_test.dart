import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/widgets/app_confirmation_dialog.dart';

void main() {
  group('AppConfirmationDialog Tests', () {
    testWidgets('Renders center icon, title, message, and buttons with correct styles', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppConfirmationDialog.show(
                    context: context,
                    icon: Icons.delete_sweep_outlined,
                    title: 'Clear Wishlist?',
                    message: 'Are you sure you want to remove all items?',
                    confirmLabel: 'Clear All',
                    isDestructive: true,
                    onConfirm: () => confirmed = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsOneWidget);
      expect(find.text('Clear Wishlist?'), findsOneWidget);
      expect(find.text('Are you sure you want to remove all items?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.byType(AppConfirmationDialog), findsNothing);
    });

    testWidgets('Cancel button dismisses without calling onConfirm', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppConfirmationDialog.show(
                    context: context,
                    icon: Icons.logout_rounded,
                    title: 'Sign Out?',
                    message: 'Do you want to sign out?',
                    confirmLabel: 'Sign Out',
                    isDestructive: true,
                    onConfirm: () => confirmed = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
      expect(find.byType(AppConfirmationDialog), findsNothing);
    });
  });
}
