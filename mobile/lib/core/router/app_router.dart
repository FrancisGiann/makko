import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/account/account_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/projects/create_issue_sheet.dart';
import '../../features/projects/create_project_sheet.dart';
import '../../features/projects/project_detail_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../providers/auth_provider.dart';

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
          state.matchedLocation == '/signup';
      if (authState.isLoading) return null;
      final session =
          authState.valueOrNull?.session ??
          Supabase.instance.client.auth.currentSession;
      if (session == null && !isPublic) return '/login';
      if (session != null && isPublic) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            MakkoNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (_, _) => const ProjectsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, _) => const CreateProjectSheet(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ProjectDetailScreen(
                      projectId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (_, state) => CreateProjectSheet(
                          projectId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'issues/new',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (_, state) => CreateIssueSheet(
                          projectId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'issues/:issueId/edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (_, state) => CreateIssueSheet(
                          projectId: state.pathParameters['id']!,
                          issueId: state.pathParameters['issueId']!,
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

class MakkoNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MakkoNavigationShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
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
              onDestinationSelected: (index) => navigationShell.goBranch(index),
              destinations: destinations,
            ),
    );
  }
}
