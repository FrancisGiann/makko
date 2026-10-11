import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/account/account_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/global_create_issue_sheet.dart';
import '../../features/home_widgets/home_widget_manager.dart';
import '../../features/home_widgets/quick_capture_queue.dart';
import '../../features/projects/create_issue_sheet.dart';
import '../../features/projects/create_project_sheet.dart';
import '../../features/projects/project_detail_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../providers/auth_provider.dart';
import 'transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ValueNotifier<AsyncValue<AuthState>>(
    const AsyncLoading(),
  );
  ref.listen<AsyncValue<AuthState>>(
    authProvider,
    (_, next) => authStateNotifier.value = next,
    fireImmediately: true,
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = authStateNotifier.value;
      final isPublic =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/invalid-link';
      final restoredUserId = authState.isLoading
          ? ref.read(currentAuthUserIdProvider)
          : null;
      final hasSession = routerHasSession(authState, restoredUserId);

      final captureRedirect = resolveCaptureRedirect(state.uri);
      if (captureRedirect != null) return captureRedirect;
      if (state.matchedLocation == '/dashboard' &&
          state.uri.queryParametersAll.containsKey('capture')) {
        final query = state.uri.queryParametersAll;
        if (query.length == 1 &&
            query['capture']?.length == 1 &&
            query['capture']!.single == 'true') {
          QuickCaptureQueue.request();
          return '/dashboard';
        }
        return '/invalid-link';
      }

      final authRedirect = resolveAuthRedirect(
        authResolved: !authState.isLoading && !authState.hasError,
        hasSession: hasSession,
        isPublicRoute: isPublic,
      );
      if (authRedirect != null) return authRedirect;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/dashboard'),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) =>
            MakkoPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (_, state) =>
            MakkoPage(key: state.pageKey, child: const SignupScreen()),
      ),
      GoRoute(
        path: '/invalid-link',
        pageBuilder: (_, state) => MakkoPage(
          key: state.pageKey,
          child: const MakkoInvalidLinkScreen(),
        ),
      ),
      GoRoute(
        path: '/account',
        pageBuilder: (_, state) =>
            MakkoPage(key: state.pageKey, child: const AccountScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            MakkoNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (_, state) => MakkoPage(
                  key: state.pageKey,
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                pageBuilder: (_, state) => MakkoPage(
                  key: state.pageKey,
                  child: const ProjectsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) => MakkoPage(
                      key: state.pageKey,
                      child: const CreateProjectSheet(),
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, state) => MakkoPage(
                      key: state.pageKey,
                      child: ProjectDetailScreen(
                        projectId: state.pathParameters['id']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => MakkoPage(
                          key: state.pageKey,
                          child: CreateProjectSheet(
                            projectId: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'issues/new',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => MakkoPage(
                          key: state.pageKey,
                          child: CreateIssueSheet(
                            projectId: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'issues/:issueId/edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (_, state) => MakkoPage(
                          key: state.pageKey,
                          child: CreateIssueSheet(
                            projectId: state.pathParameters['id']!,
                            issueId: state.pathParameters['issueId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Consume only supported quick-capture routes and send malformed capture
/// links to a safe, explanatory screen instead of opening an unrelated page.
String? resolveCaptureRedirect(Uri uri) {
  if (!QuickCaptureQueue.isCaptureCandidate(uri)) return null;
  return QuickCaptureQueue.acceptCaptureLocation(uri)
      ? '/dashboard'
      : '/invalid-link';
}

/// Authenticated routes remain inaccessible while session restoration is
/// pending and no persisted session is available.
String? resolveAuthRedirect({
  required bool authResolved,
  required bool hasSession,
  required bool isPublicRoute,
}) {
  if (!authResolved) {
    return hasSession || isPublicRoute ? null : '/login';
  }
  if (!hasSession && !isPublicRoute) return '/login';
  if (hasSession && isPublicRoute) return '/dashboard';
  return null;
}

bool routerHasSession(AsyncValue<AuthState> authState, String? restoredUserId) {
  return authState.when(
    data: (event) => event.session?.user.id != null,
    loading: () => restoredUserId != null,
    error: (_, _) => false,
  );
}

class MakkoInvalidLinkScreen extends StatelessWidget {
  const MakkoInvalidLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                        Icon(
                          Icons.link_off_rounded,
                          size: 42,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'This Makko link is not supported',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The link may be old or incomplete. You can open Makko and continue from your workspace.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go('/dashboard'),
                          child: const Text('Open Makko'),
                        ),
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

class MakkoNavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MakkoNavigationShell({super.key, required this.navigationShell});

  @override
  State<MakkoNavigationShell> createState() => _MakkoNavigationShellState();
}

class _MakkoNavigationShellState extends State<MakkoNavigationShell> {
  bool _captureOpen = false;
  bool _captureCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    unawaited(HomeWidgetManager.initialize(onQuickCapture: _queueCapture));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedulePendingCapture();
  }

  @override
  void dispose() {
    HomeWidgetManager.dispose();
    super.dispose();
  }

  void _queueCapture() {
    if (_captureOpen) return;
    QuickCaptureQueue.request();
    _schedulePendingCapture();
  }

  void _schedulePendingCapture() {
    if (_captureOpen ||
        _captureCheckScheduled ||
        !QuickCaptureQueue.hasPending) {
      return;
    }
    _captureCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureCheckScheduled = false;
      if (!mounted ||
          _captureOpen ||
          !(ModalRoute.isCurrentOf(context) ?? true) ||
          !QuickCaptureQueue.consume()) {
        return;
      }
      setState(() => _captureOpen = true);
      unawaited(_openCapture());
    });
  }

  Future<void> _openCapture() async {
    try {
      await GlobalCreateIssueSheet.show(context);
    } finally {
      if (mounted) {
        setState(() => _captureOpen = false);
        _schedulePendingCapture();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: 'Projects',
      ),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final shellIsCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (QuickCaptureQueue.hasPending) _schedulePendingCapture();
    return TickerMode(
      enabled: shellIsCurrent,
      child: Scaffold(
        body: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: (index) =>
                        navigationShell.goBranch(index),
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -0.7,
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 28),
                      child: Icon(
                        Icons.waves_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    destinations: destinations
                        .map(
                          (destination) => NavigationRailDestination(
                            icon: destination.icon,
                            selectedIcon:
                                destination.selectedIcon ?? destination.icon,
                            label: Text(destination.label),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: navigationShell),
                ],
              )
            : navigationShell,
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) =>
                    navigationShell.goBranch(index),
                destinations: destinations,
              ),
      ),
    );
  }
}
