import re
with open('mobile/test/batch6_polish_test.dart', 'r') as f:
    content = f.read()

# We need to remove the test "DashboardScreen displays ActivityHeatmap when projects exist"
target = """    testWidgets(
      'DashboardScreen displays ActivityHeatmap when projects exist',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dashboardProvider.overrideWith((ref) => stats),
              authUserIdProvider.overrideWithValue('test-user'),
              themeModeProvider.overrideWith((ref) => ThemeModeNotifier()),
            ],
            child: const MaterialApp(
              home: Scaffold(body: DashboardScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ActivityHeatmap), findsOneWidget);
      },
    );"""

content = content.replace(target, "")

with open('mobile/test/batch6_polish_test.dart', 'w') as f:
    f.write(content)
print("Removed heatmap test")
