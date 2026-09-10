import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/github_provider.dart';
import 'package:mobile/services/github_service.dart';

class _FakeGithubService extends GithubService {
  bool failConnect = false;
  bool failSync = false;
  bool failDisconnect = false;
  int reads = 0;

  @override
  Future<GithubProjectData> getProjectData(String projectId) async {
    reads++;
    return GithubProjectData(link: null, commits: const [], issues: const []);
  }

  @override
  Future<void> connect(String projectId, String owner, String repo) async {
    if (failConnect) throw StateError('connect failed');
  }

  @override
  Future<void> syncGithub(String projectId) async {
    if (failSync) throw StateError('sync failed');
  }

  @override
  Future<void> disconnect(String projectId, String linkId) async {
    if (failDisconnect) throw StateError('disconnect failed');
  }
}

void main() {
  test('GitHub sync response parser enforces server contract', () {
    final result = parseGithubSyncResponse({
      'data': {
        'project_id': 'project-1',
        'repo_full_name': 'owner/repo',
        'commits_synced': 30,
        'issues_synced': 500,
        'last_synced_at': '2026-01-03T00:00:00.000Z',
      },
    }, projectId: 'project-1');
    expect(result.repoFullName, 'owner/repo');
    expect(result.commitsSynced, 30);
    expect(result.issuesSynced, 500);
  });

  test('GitHub sync response parser rejects mismatch, fractional, and overflow data', () {
    Map<String, dynamic> body({
      Object projectId = 'project-1',
      Object repository = 'owner/repo',
      Object commits = 1,
      Object issues = 1,
      Object timestamp = '2026-01-03T00:00:00.000Z',
    }) {
      return {
        'data': {
          'project_id': projectId,
          'repo_full_name': repository,
          'commits_synced': commits,
          'issues_synced': issues,
          'last_synced_at': timestamp,
        },
      };
    }

    expect(
      () => parseGithubSyncResponse(
        body(projectId: 'other'),
        projectId: 'project-1',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => parseGithubSyncResponse(body(commits: 1.5), projectId: 'project-1'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => parseGithubSyncResponse(body(issues: 501), projectId: 'project-1'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => parseGithubSyncResponse(
        body(repository: 'bad repo'),
        projectId: 'project-1',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('GitHub connect failure remains visible and propagates', () async {
    final fake = _FakeGithubService()..failConnect = true;
    final container = ProviderContainer(
      overrides: [githubServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(githubNotifierProvider.notifier);

    await expectLater(
      notifier.connect('project-1', 'owner', 'repo'),
      throwsA(isA<StateError>()),
    );
    expect(container.read(githubNotifierProvider).hasError, isTrue);
  });

  test('GitHub sync and disconnect failures propagate', () async {
    final fake = _FakeGithubService()
      ..failSync = true
      ..failDisconnect = true;
    final container = ProviderContainer(
      overrides: [githubServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(githubNotifierProvider.notifier);

    await expectLater(
      notifier.syncGithub('project-1'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      notifier.disconnect('project-1', 'link-1'),
      throwsA(isA<StateError>()),
    );
    expect(container.read(githubNotifierProvider).hasError, isTrue);
  });

  test('successful GitHub actions settle notifier state', () async {
    final fake = _FakeGithubService();
    final container = ProviderContainer(
      overrides: [
        githubServiceProvider.overrideWithValue(fake),
        authUserIdProvider.overrideWithValue('user-1'),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      githubProvider('project-1'),
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    final initialReads = fake.reads;
    final notifier = container.read(githubNotifierProvider.notifier);

    await notifier.connect('project-1', 'owner', 'repo');
    expect(container.read(githubNotifierProvider), const AsyncData<void>(null));
    await notifier.syncGithub('project-1');
    await notifier.disconnect('project-1', 'link-1');
    expect(container.read(githubNotifierProvider).hasError, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(fake.reads, greaterThan(initialReads));
  });
}
