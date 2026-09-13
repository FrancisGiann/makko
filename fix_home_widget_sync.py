import re

with open('mobile/lib/features/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

# Add ref.listen to dashboard_screen.dart
target = "final statsAsync = ref.watch(dashboardProvider);"
replacement = """final statsAsync = ref.watch(dashboardProvider);
    ref.listen<AsyncValue<DashboardStats>>(dashboardProvider, (prev, next) {
      next.whenData((stats) {
        HomeWidgetManager.updateAllWidgets(stats: stats);
      });
    });"""

content = content.replace(target, replacement)

# Add import for HomeWidgetManager if missing
if 'home_widget_manager.dart' not in content:
    content = re.sub(
        r"(import '\.\./\.\./models/dashboard_stats\.dart';)",
        r"\1\nimport '../home_widgets/home_widget_manager.dart';",
        content
    )

with open('mobile/lib/features/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

with open('mobile/lib/features/github/github_contribution_graph.dart', 'r') as f:
    content = f.read()

# In github_contribution_graph.dart, call updateHeatmapWidget
target2 = """      final parsed = GithubContributionsData.parseHtml(html);
      if (mounted) {
        setState(() {
          _data = parsed;
          _fetching = false;
        });
      }"""
replacement2 = """      final parsed = GithubContributionsData.parseHtml(html);
      if (mounted) {
        setState(() {
          _data = parsed;
          _fetching = false;
        });
      }
      HomeWidgetManager.updateHeatmapWidget(username: user, data: parsed);"""
      
content = content.replace(target2, replacement2)

if 'home_widget_manager.dart' not in content:
    content = re.sub(
        r"(import '\.\./\.\./core/theme/app_theme\.dart';)",
        r"\1\nimport '../home_widgets/home_widget_manager.dart';",
        content
    )

with open('mobile/lib/features/github/github_contribution_graph.dart', 'w') as f:
    f.write(content)
