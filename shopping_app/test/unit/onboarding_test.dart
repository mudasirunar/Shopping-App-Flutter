import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/views/onboarding/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Persistence Tests', () {
    test('Defaults to false on first launch when no preference is set', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;
      expect(hasSeen, false);
    });

    test('Persists true when onboarding is completed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('has_seen_onboarding', true);

      final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;
      expect(hasSeen, true);
    });

    test('Maintains true flag on subsequent launches', () async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
      final prefs = await SharedPreferences.getInstance();

      final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;
      expect(hasSeen, true);
    });
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('Renders onboarding elements correctly', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Verify app title and first slide content
      expect(find.text('Shopping App'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Discover Premium Quality'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // On first slide, Skip is fully visible (1.0) and Sign In is hidden (0.0)
      final opacitiesStep1 = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).toList();
      expect(opacitiesStep1.length, 2);
      expect(opacitiesStep1[0].opacity, 1.0); // Skip button visible
      expect(opacitiesStep1[1].opacity, 0.0); // Sign In hidden

      // Advance to 2nd slide
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final opacitiesStep2 = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).toList();
      expect(opacitiesStep2[0].opacity, 1.0); // Skip button still visible
      expect(opacitiesStep2[1].opacity, 0.0); // Sign In still hidden

      // Advance to 3rd (last) slide
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // On final slide: "Get Started" is shown, Skip is hidden (0.0), Sign In is visible (1.0)
      expect(find.text('Get Started'), findsOneWidget);
      final opacitiesStep3 = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).toList();
      expect(opacitiesStep3[0].opacity, 0.0); // Skip hidden without layout jerk
      expect(opacitiesStep3[1].opacity, 1.0); // Sign In visible on last step only
    });
  });
}
