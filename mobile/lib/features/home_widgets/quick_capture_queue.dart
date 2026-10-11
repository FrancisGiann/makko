/// Holds a quick-capture tap until the signed-in shell can present its form.
/// The queue stores only a boolean intent, never widget payload or user data.
class QuickCaptureQueue {
  static bool _pending = false;

  static bool get hasPending => _pending;

  static void request() => _pending = true;

  static bool isWidgetCaptureUri(Uri? uri) {
    if (uri == null || uri.scheme != 'makko') return false;
    final query = uri.queryParametersAll;
    final knownQuery =
        query.isEmpty ||
        (query.length == 1 &&
            query['ref']?.length == 1 &&
            query['ref']!.single == 'widget');
    final canonical =
        uri.host == 'makko' && uri.path == '/capture' && knownQuery;
    final legacy =
        uri.host == 'capture' &&
        uri.path.isEmpty &&
        query.length == 1 &&
        query['ref']?.length == 1 &&
        query['ref']!.single == 'widget';
    return canonical || legacy;
  }

  static bool isCaptureCandidate(Uri uri) {
    final pathCandidate =
        uri.path == '/capture' || uri.path.startsWith('/capture/');
    final legacyHostCandidate = uri.scheme == 'makko' && uri.host == 'capture';
    return pathCandidate || legacyHostCandidate;
  }

  static bool consume() {
    if (!_pending) return false;
    _pending = false;
    return true;
  }

  static bool acceptCaptureLocation(Uri uri) {
    final internalLocation = uri.scheme.isEmpty && uri.host.isEmpty;
    if (internalLocation) {
      if (uri.path != '/capture') return false;
      final query = uri.queryParametersAll;
      final knownQuery =
          query.isEmpty ||
          (query.length == 1 &&
              query['ref']?.length == 1 &&
              query['ref']!.single == 'widget');
      if (!knownQuery) return false;
    } else if (!isWidgetCaptureUri(uri)) {
      return false;
    }
    request();
    return true;
  }

  static void resetForTest() => _pending = false;
}
