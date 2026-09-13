with open('mobile/lib/features/home_widgets/companion_widget_render.dart', 'r') as f:
    content = f.read()

content = content.replace("stats?.issueCount ?? 0", "stats?.totalIssues ?? 0")
content = content.replace("stats?.doneIssues ?? 0", "stats?.completedIssues ?? 0")

with open('mobile/lib/features/home_widgets/companion_widget_render.dart', 'w') as f:
    f.write(content)
