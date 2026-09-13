with open('mobile/lib/core/router/app_router.dart', 'r') as f:
    content = f.read()

# Fix ProjectDetailScreen
target1 = """                    pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: ProjectDetailScreen(
                      projectId: state.pathParameters['id']!,
                    ),
                    routes: ["""
                    
replacement1 = """                    pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: ProjectDetailScreen(
                      projectId: state.pathParameters['id']!,
                    )),
                    routes: ["""

# Fix CreateProjectSheet edit
target2 = """                        pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: CreateProjectSheet(
                          projectId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute("""
                      
replacement2 = """                        pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: CreateProjectSheet(
                          projectId: state.pathParameters['id']!,
                        )),
                      ),
                      GoRoute("""

# Fix CreateIssueSheet new
target3 = """                        pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: CreateIssueSheet(
                          projectId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute("""
                      
replacement3 = """                        pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: CreateIssueSheet(
                          projectId: state.pathParameters['id']!,
                        )),
                      ),
                      GoRoute("""

# Fix CreateIssueSheet edit
target4 = """                        pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: CreateIssueSheet(
                          projectId: state.pathParameters['id']!,
                          issueId: state.pathParameters['issueId']!,
                        ),
                      ),
                    ],"""

replacement4 = """                        pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: CreateIssueSheet(
                          projectId: state.pathParameters['id']!,
                          issueId: state.pathParameters['issueId']!,
                        )),
                      ),
                    ],"""


content = content.replace(target1, replacement1)
content = content.replace(target2, replacement2)
content = content.replace(target3, replacement3)
content = content.replace(target4, replacement4)

with open('mobile/lib/core/router/app_router.dart', 'w') as f:
    f.write(content)

print("Fixed parentheses")
