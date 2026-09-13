with open('mobile/lib/core/theme/app_theme.dart', 'r') as f:
    content = f.read()

target = """      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,"""

replacement = """      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,"""

if target in content:
    content = content.replace(target, replacement)
    with open('mobile/lib/core/theme/app_theme.dart', 'w') as f:
        f.write(content)
    print("Updated navigationBarTheme height")
else:
    print("Could not find target")
