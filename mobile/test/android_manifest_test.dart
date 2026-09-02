import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main Android manifest grants Supabase networking access', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    expect(manifest.existsSync(), isTrue);
    expect(
      manifest.readAsStringSync(),
      contains(
        '<uses-permission android:name="android.permission.INTERNET" />',
      ),
    );
  });
}
