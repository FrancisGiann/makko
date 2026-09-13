with open('mobile/lib/features/home_widgets/home_widget_manager.dart', 'r') as f:
    content = f.read()

content = content.replace("logicalSize: const Size(320, 160)", "logicalSize: const Size(380, 180)")

with open('mobile/lib/features/home_widgets/home_widget_manager.dart', 'w') as f:
    f.write(content)
