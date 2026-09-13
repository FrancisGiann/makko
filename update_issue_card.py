with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()

target = """                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _IssueCard(
                          issue: issue,
                          onEdit: () => onEdit(issue),
                          onDelete: () => onDelete(issue),
                          onStatusChange: (status) =>
                              onStatusChange(issue, status),
                        ),
                      );"""

replacement = """                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _IssueCard(
                            key: ValueKey('${issue.id}-${issue.status}-${issue.updatedAt}'),
                            issue: issue,
                            onEdit: () => onEdit(issue),
                            onDelete: () => onDelete(issue),
                            onStatusChange: (status) =>
                                onStatusChange(issue, status),
                          ),
                        ),
                      );"""

if target in content:
    content = content.replace(target, replacement)
    
    # Check if _IssueCard accepts key
    if 'const _IssueCard({' in content and 'Key? key,' not in content:
        content = content.replace('const _IssueCard({', 'const _IssueCard({\n    super.key,')
    
    with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
        f.write(content)
    print("Updated AnimatedSwitcher in project_detail_screen.dart")
else:
    print("Could not find target padding")
