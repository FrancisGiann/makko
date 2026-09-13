with open('mobile/test/issue_filtering_test.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "const IssueFilters(type: 'task', sort: 'priority')",
    "const IssueFilters(status: 'all', type: 'task', sort: 'priority')"
)

content = content.replace(
    "const IssueFilters(sort: 'priority')",
    "const IssueFilters(status: 'all', sort: 'priority')"
)

with open('mobile/test/issue_filtering_test.dart', 'w') as f:
    f.write(content)
print("Fixed issue_filtering_test")
