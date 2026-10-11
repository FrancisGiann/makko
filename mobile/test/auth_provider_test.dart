import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/models/dashboard_stats.dart';
import 'package:mobile/models/project.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/dashboard_provider.dart';
import 'package:mobile/providers/projects_provider.dart';
import 'package:mobile/services/project_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SessionProjectService extends ProjectService {
  final Project project;
  _SessionProjectService(this.project);

  @override
  Future<List<Project>> listProjects(String ownerId) async => [project];
}

void main() {
  testWidgets(
    'successful sign-in stream event sends the login route to dashboard',
    (tester) async {
      final events = StreamController<AuthState>();
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => events.stream),
          currentAuthUserIdProvider.overrideWith((ref) => null),
          dashboardStatsProvider.overrideWith(
            (ref) async => DashboardStats(
              projectCount: 0,
              totalIssues: 0,
              openIssues: 0,
              completedIssues: 0,
              byStatus: const {'todo': 0, 'in_progress': 0, 'done': 0},
              byType: const {'task': 0, 'bug': 0},
              byPriority: const {'low': 0, 'medium': 0, 'high': 0},
              projects: const [],
            ),
          ),
        ],
      );
      final router = container.read(routerProvider);
      addTearDown(() async {
        router.dispose();
        await events.close();
        container.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(find.text('Sign in'), findsOneWidget);

      events.add(const AuthState(AuthChangeEvent.initialSession, null));
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/login');

      final session = Session(
        accessToken: 'test-access-token',
        tokenType: 'bearer',
        user: User(
          id: 'user-1',
          appMetadata: const {},
          userMetadata: null,
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00.000Z',
        ),
      );
      events.add(AuthState(AuthChangeEvent.signedIn, session));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
      expect(find.text('Workspace at a glance'), findsOneWidget);
    },
  );

  test('uses a restored session while auth is loading, then clears on sign-out/error', () async {
    final events = StreamController<AuthState>();
    final project = Project(
      id: 'project-1',
      ownerId: 'user-1',
      name: 'Private workspace',
      description: null,
      tags: const [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => events.stream),
        currentAuthUserIdProvider.overrideWith((ref) => 'user-1'),
        projectServiceProvider.overrideWith(
          (ref) => _SessionProjectService(project),
        ),
      ],
    );
    addTearDown(() async {
      await events.close();
      container.dispose();
    });

    final projectsSubscription = container.listen(projectsProvider, (_, _) {});
    addTearDown(projectsSubscription.close);
    expect(await container.read(projectsProvider.future), [project]);
    expect(container.read(authUserIdProvider), 'user-1');
    final restoredUserId = container.read(currentAuthUserIdProvider);
    expect(
      routerHasSession(container.read(authProvider), restoredUserId),
      isTrue,
    );

    events.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authUserIdProvider), isNull);
    expect(container.read(projectsProvider).valueOrNull, isEmpty);
    expect(
      routerHasSession(container.read(authProvider), restoredUserId),
      isFalse,
      reason: 'a warmed persisted-session read must not override signed-out',
    );
    expect(
      resolveAuthRedirect(
        authResolved: true,
        hasSession: routerHasSession(
          container.read(authProvider),
          restoredUserId,
        ),
        isPublicRoute: false,
      ),
      '/login',
    );

    events.addError(StateError('auth refresh failed'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authUserIdProvider), isNull);
    expect(
      resolveAuthRedirect(
        authResolved: false,
        hasSession: false,
        isPublicRoute: false,
      ),
      '/login',
    );
  });
}
