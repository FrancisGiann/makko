with open('mobile/lib/core/theme/app_theme.dart', 'r') as f:
    content = f.read()

target = """        height: 64,
        backgroundColor: scheme.surfaceContainerLow,"""

replacement = """        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: scheme.surfaceContainerLow,"""

if target in content:
    content = content.replace(target, replacement)
    with open('mobile/lib/core/theme/app_theme.dart', 'w') as f:
        f.write(content)
    print("Added labelBehavior")
else:
    print("Could not find target")
