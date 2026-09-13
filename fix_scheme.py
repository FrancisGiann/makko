import re
with open('mobile/lib/features/github/github_contribution_graph.dart', 'r') as f:
    content = f.read()

# Find all Widget build(BuildContext context) { and inject final scheme = Theme.of(context).colorScheme;
content = re.sub(r"(Widget build\(BuildContext context\) \{)", r"\1\n    final scheme = Theme.of(context).colorScheme;", content)

with open('mobile/lib/features/github/github_contribution_graph.dart', 'w') as f:
    f.write(content)
