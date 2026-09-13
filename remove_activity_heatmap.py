with open('mobile/lib/features/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

target = """                const SizedBox(height: 22),
                ActivityHeatmap(stats: stats),"""

replacement = """"""

content = content.replace(target, replacement)

# Also remove the import for ActivityHeatmap if it exists
import re
content = re.sub(r"import 'activity_heatmap\.dart';\n", "", content)

with open('mobile/lib/features/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)
print("Removed ActivityHeatmap from dashboard")
