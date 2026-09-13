with open('mobile/lib/core/router/app_router.dart', 'r') as f:
    content = f.read()
    
# Import
import_stmt = "import 'transitions.dart';\n"
content = content.replace("import '../../providers/auth_provider.dart';", "import '../../providers/auth_provider.dart';\n" + import_stmt)

def replace_builder(match):
    # 'builder: (_, _) => const LoginScreen()' 
    # 'builder: (_, state) => ProjectDetailScreen('
    args = match.group(1)
    body = match.group(2)
    state_var = 'state' if 'state' in args else 'state'
    if args == '_, _':
        # we can just use `_, state`
        return f"pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: {body})"
    else:
        return f"pageBuilder: (_, {state_var}) => MakkoTransitionPage(key: {state_var}.pageKey, child: {body})"

import re

# We can replace all builder definitions inside GoRoute.
# Example: 
# builder: (_, _) => const DashboardScreen(),
# becomes
# pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: const DashboardScreen()),

content = content.replace("builder: (_, _) => const LoginScreen()", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: const LoginScreen())")
content = content.replace("builder: (_, _) => const SignupScreen()", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: const SignupScreen())")
content = content.replace("builder: (_, _) => const AccountScreen()", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: const AccountScreen())")
content = content.replace("builder: (_, _) => const DashboardScreen()", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: const DashboardScreen())")
content = content.replace("builder: (_, _) => const ProjectsScreen()", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: const ProjectsScreen())")
content = content.replace("builder: (_, _) => const CreateProjectSheet()", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: const CreateProjectSheet())")

content = content.replace("builder: (_, state) => ProjectDetailScreen(", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: ProjectDetailScreen(")
content = content.replace("builder: (_, state) => CreateProjectSheet(", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: CreateProjectSheet(")
content = content.replace("builder: (_, state) => CreateIssueSheet(", "pageBuilder: (_, state) => MakkoTransitionPage(key: state.pageKey, child: CreateIssueSheet(")

with open('mobile/lib/core/router/app_router.dart', 'w') as f:
    f.write(content)
print("Updated router pageBuilders")
