import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../models/dashboard_stats.dart';
import '../github/github_contribution_graph.dart';
import 'companion_widget_render.dart';
import 'heatmap_widget_render.dart';

/// Centralized manager for Android Home Screen Widgets using the `home_widget` plugin.
class HomeWidgetManager {
  static const String quickCaptureWidget = 'QuickCaptureWidgetReceiver';
  static const String companionWidget = 'CompanionWidgetReceiver';
  static const String heatmapWidget = 'GithubHeatmapWidgetReceiver';

  static const String companionImageKey = 'companion_image';
  static const String heatmapImageKey = 'github_heatmap_image';

  static const String captureScheme = 'makko';
  static const String captureHost = 'makko';
  static const String capturePath = '/capture';
  static const String captureDeepLink = '$captureScheme://$captureHost';

  static StreamSubscription<Uri?>? _widgetClickedSubscription;

  /// Check if a given URI corresponds to the Makko Quick Capture action.
  static bool isCaptureUri(Uri? uri) {
    if (uri == null) return false;
    return uri.scheme == captureScheme && uri.host == captureHost && uri.path == capturePath;
  }

  /// Initialize deep-link listening for home screen widget clicks.
  static Future<void> initialize({
    required VoidCallback onQuickCapture,
  }) async {
    try {
      // 1. Check if the app was launched cold from a home widget click
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (isCaptureUri(initialUri)) {
        onQuickCapture();
      }

      // 2. Listen for clicks when the app is already in the background/foreground
      _widgetClickedSubscription?.cancel();
      _widgetClickedSubscription = HomeWidget.widgetClicked.listen((uri) {
        if (isCaptureUri(uri)) {
          onQuickCapture();
        }
      });
    } catch (e) {
      debugPrint('HomeWidgetManager initialization error: $e');
    }
  }

  /// Dispose listeners.
  static void dispose() {
    _widgetClickedSubscription?.cancel();
    _widgetClickedSubscription = null;
  }

  /// Updates the Quick Capture widget.
  static Future<void> updateQuickCaptureWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: quickCaptureWidget,
        androidName: quickCaptureWidget,
      );
    } catch (e) {
      debugPrint('Error updating Quick Capture widget: $e');
    }
  }

  /// Renders a small version of the Makko companion and saves it to Android widget storage.
  static Future<String?> updateCompanionWidget({
    DashboardStats? stats,
    String? greeting,
    String? customMessage,
  }) async {
    try {
      final imagePath = await HomeWidget.renderFlutterWidget(
        CompanionWidgetRender(
          stats: stats,
          greeting: greeting,
          customMessage: customMessage,
        ),
        key: companionImageKey,
        logicalSize: const Size(380, 180),
      );

      await HomeWidget.updateWidget(
        name: companionWidget,
        androidName: companionWidget,
      );

      return imagePath;
    } catch (e) {
      debugPrint('Error rendering Companion widget: $e');
      return null;
    }
  }

  /// Renders the GitHub contribution heatmap and saves it to Android widget storage.
  static Future<String?> updateHeatmapWidget({
    String? username,
    GithubContributionsData? data,
  }) async {
    try {
      final imagePath = await HomeWidget.renderFlutterWidget(
        HeatmapWidgetRender(
          username: username,
          data: data,
        ),
        key: heatmapImageKey,
        logicalSize: const Size(380, 180),
      );

      await HomeWidget.updateWidget(
        name: heatmapWidget,
        androidName: heatmapWidget,
      );

      return imagePath;
    } catch (e) {
      debugPrint('Error rendering Heatmap widget: $e');
      return null;
    }
  }

  /// Convenience method to refresh all 3 home screen widgets.
  static Future<void> updateAllWidgets({
    DashboardStats? stats,
    String? username,
    GithubContributionsData? githubData,
  }) async {
    await updateQuickCaptureWidget();
    await updateCompanionWidget(stats: stats);
    await updateHeatmapWidget(username: username, data: githubData);
  }
}
