import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/core/theme/app_theme.dart';

void main() {
  test('AppTheme loads primary slate color properly', () {
    final theme = AppTheme.lightTheme;
    expect(theme.scaffoldBackgroundColor, AppTheme.surface);
    expect(theme.colorScheme.primary, AppTheme.primary);
  });
}
