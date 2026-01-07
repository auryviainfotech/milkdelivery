import 'package:flutter_test/flutter_test.dart';

import 'package:milk_core/milk_core.dart';

void main() {
  test('AppTheme has light and dark themes', () {
    expect(AppTheme.lightTheme, isNotNull);
    expect(AppTheme.darkTheme, isNotNull);
  });
}
