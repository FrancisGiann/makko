import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'widgets/makko_logo.dart';
import 'widgets/makko_mascot.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MakkoBootstrapGate());
}

typedef MakkoInitializer = Future<ThemeMode> Function();

enum _BootstrapPhase { starting, failed, ready }

/// Shows real startup work before constructing providers that require a
/// Supabase client. A timed-out attempt remains shared until it settles, so a
/// retry never overlaps the singleton client's initialization.
class MakkoBootstrapGate extends StatefulWidget {
  final MakkoInitializer? initialize;
  final Widget Function(ThemeMode mode)? readyBuilder;
  final Duration startupTimeout;

  const MakkoBootstrapGate({
    super.key,
    this.initialize,
    this.readyBuilder,
    this.startupTimeout = const Duration(seconds: 25),
  });

  @override
  State<MakkoBootstrapGate> createState() => _MakkoBootstrapGateState();
}

class _MakkoBootstrapGateState extends State<MakkoBootstrapGate>
    with WidgetsBindingObserver {
  _BootstrapPhase _phase = _BootstrapPhase.starting;
  ThemeMode _splashTheme = ThemeMode.dark;
  ThemeMode? _restoredTheme;
  Future<ThemeMode>? _inFlight;
  String? _errorMessage;

  bool get _reduceMotion {
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return features.disableAnimations || features.accessibleNavigation;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreSplashTheme());
    _beginInitialization();
  }

  Future<void> _restoreSplashTheme() async {
    final mode = await loadSavedThemeMode();
    if (!mounted || _phase == _BootstrapPhase.ready) return;
    setState(() => _splashTheme = mode);
  }

  Future<ThemeMode> _createInitialization() {
    try {
      return widget.initialize?.call() ?? _initializeMakko();
    } catch (error, stack) {
      return Future<ThemeMode>.error(error, stack);
    }
  }

  Future<ThemeMode> _initializeMakko() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final themeMode = loadSavedThemeMode();
    await _ensureSupabaseInitialized();
    return themeMode;
  }

  Future<void> _ensureSupabaseInitialized() async {
    try {
      Supabase.instance.client;
      return;
    } catch (_) {
      // The first launch has no client yet; initialize it below.
    }

    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://nbmombulxuxadtwwttfk.supabase.co',
      ),
      publishableKey: const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: 'sb_publishable_MoEUO1CO5mpHw2FOkGTdTw_SUQ2FDur',
      ),
    );
    Supabase.instance.client;
  }

  void _beginInitialization() {
    if (_phase == _BootstrapPhase.starting && _inFlight != null) return;

    setState(() {
      _phase = _BootstrapPhase.starting;
      _errorMessage = null;
    });
    final existing = _inFlight;
    final Future<ThemeMode> future;
    if (existing == null) {
      future = _createInitialization();
      _inFlight = future;
      unawaited(
        future.then<void>(
          (mode) => _finishInitialization(future, mode),
          onError: (Object _, StackTrace _) => _failInitialization(future),
        ),
      );
    } else {
      future = existing;
    }
    unawaited(_waitForInitialization(future));
  }

  Future<void> _waitForInitialization(Future<ThemeMode> future) async {
    try {
      final mode = await future.timeout(widget.startupTimeout);
      _finishInitialization(future, mode);
    } on TimeoutException {
      if (!mounted || !identical(_inFlight, future)) return;
      setState(() {
        _phase = _BootstrapPhase.failed;
        _errorMessage = 'Startup is taking longer than expected. Check connectivity or retry; Makko will keep waiting safely.';
      });
    } catch (_) {
      _failInitialization(future);
    }
  }

  void _finishInitialization(Future<ThemeMode> future, ThemeMode mode) {
    if (!mounted || !identical(_inFlight, future)) return;
    setState(() {
      _inFlight = null;
      _phase = _BootstrapPhase.ready;
      _splashTheme = mode;
      _restoredTheme = mode;
      _errorMessage = null;
    });
  }

  void _failInitialization(Future<ThemeMode> future) {
    if (!mounted || !identical(_inFlight, future)) return;
    setState(() {
      _inFlight = null;
      _phase = _BootstrapPhase.failed;
      _errorMessage = 'Makko could not prepare your secure session. Check your connection and retry.';
    });
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _phase == _BootstrapPhase.ready;
    final experience = ready
        ? ProviderScope(
            key: const ValueKey('makko-ready'),
            overrides: [
              themeModeProvider.overrideWith(
                (ref) => ThemeModeNotifier(
                  initialMode: _restoredTheme ?? ThemeMode.dark,
                  restore: false,
                ),
              ),
            ],
            child:
                widget.readyBuilder?.call(_restoredTheme ?? ThemeMode.dark) ??
                const MakkoApp(),
          )
        : MaterialApp(
            key: const ValueKey('makko-startup'),
            title: 'Makko',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _splashTheme,
            home: _StartupScreen(
              error: _phase == _BootstrapPhase.failed ? _errorMessage : null,
              reduceMotion: _reduceMotion,
              onRetry: _beginInitialization,
            ),
          );

    return AnimatedSwitcher(
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: experience,
    );
  }
}

class _StartupScreen extends StatelessWidget {
  final String? error;
  final bool reduceMotion;
  final VoidCallback onRetry;

  const _StartupScreen({
    required this.error,
    required this.reduceMotion,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError = error != null;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MakkoLogo(),
                        const SizedBox(height: 32),
                        MakkoMascot(visible: !isError, width: 132, height: 112),
                        const SizedBox(height: 22),
                        Text(
                          isError ? 'Let’s get Makko ready' : 'Preparing Makko',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error ?? 'Restoring your workspace and preferences…',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (isError) ...[
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry startup'),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          if (reduceMotion)
                            Icon(
                              Icons.more_horiz_rounded,
                              color: scheme.primary,
                            )
                          else
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: scheme.primary,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MakkoApp extends ConsumerWidget {
  const MakkoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Makko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
