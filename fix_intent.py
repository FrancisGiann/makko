import re

# Fix AndroidManifest
with open('mobile/android/app/src/main/AndroidManifest.xml', 'r') as f:
    content = f.read()
target = """                <data
                    android:scheme="makko"
                    android:host="capture" />"""
replacement = """                <data
                    android:scheme="makko"
                    android:host="makko"
                    android:pathPrefix="/capture" />"""
content = content.replace(target, replacement)
with open('mobile/android/app/src/main/AndroidManifest.xml', 'w') as f:
    f.write(content)

# Fix Kotlin
with open('mobile/android/app/src/main/kotlin/com/example/mobile/QuickCaptureWidgetReceiver.kt', 'r') as f:
    content = f.read()
content = content.replace('Uri.parse("makko://capture")', 'Uri.parse("makko://makko/capture")')
with open('mobile/android/app/src/main/kotlin/com/example/mobile/QuickCaptureWidgetReceiver.kt', 'w') as f:
    f.write(content)

# Fix Dart Manager
with open('mobile/lib/features/home_widgets/home_widget_manager.dart', 'r') as f:
    content = f.read()
content = content.replace("static const String captureHost = 'capture';", "static const String captureHost = 'makko';\n  static const String capturePath = '/capture';")
content = content.replace("uri.scheme == captureScheme && uri.host == captureHost", "uri.scheme == captureScheme && uri.host == captureHost && uri.path == capturePath")
with open('mobile/lib/features/home_widgets/home_widget_manager.dart', 'w') as f:
    f.write(content)

# Fix app router: handle capture parameter in dashboard
with open('mobile/lib/core/router/app_router.dart', 'r') as f:
    content = f.read()

# Make the dashboard route handle ?capture=true query string.
# But wait, HomeWidgetManager already listens globally and triggers GlobalCreateIssueSheet!
# We just need GoRouter to NOT show "page not found" for /capture.
# We already have GoRoute(path: '/capture', redirect: (_, state) => '/dashboard?capture=true'),
# Wait, dashboard doesn't read ?capture=true.
# Actually, since HomeWidgetManager triggers it, we don't even need Dashboard to read it. Just redirecting to /dashboard is enough!
content = content.replace("redirect: (_, state) => '/dashboard?capture=true'", "redirect: (_, state) => '/dashboard'")
with open('mobile/lib/core/router/app_router.dart', 'w') as f:
    f.write(content)
