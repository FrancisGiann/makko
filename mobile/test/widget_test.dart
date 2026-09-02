import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/widgets/makko_logo.dart';
import 'package:mobile/widgets/status_chip.dart';

void main() {
  testWidgets('Makko visual shell uses branded Material roles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              MakkoLogo(),
              StatusChip(status: 'in_progress'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('makko'), findsOneWidget);
    expect(find.text('IN_PROGRESS'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(StatusChip))).useMaterial3,
      isTrue,
    );
  });

  testWidgets('Makko dark theme resolves a deep harbor surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: Text('Makko')),
      ),
    );
    final theme = Theme.of(tester.element(find.text('Makko')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, MakkoColors.deepHarbor);
  });
}
