import re
# Fix issue_filtering_test
with open('mobile/test/issue_filtering_test.dart', 'r') as f:
    content = f.read()

content = content.replace("expect(IssueFilters().status, 'all');", "expect(IssueFilters().status, 'open');")
# If it specifically checks 'all' in tests
content = content.replace("const IssueFilters(status: 'all')", "const IssueFilters(status: 'open')")

with open('mobile/test/issue_filtering_test.dart', 'w') as f:
    f.write(content)

# Fix project_detail_ux_test
with open('mobile/test/project_detail_ux_test.dart', 'r') as f:
    content = f.read()

content = content.replace("find.text('All status')", "find.text('Open')")
content = content.replace("find.text('All types')", "find.text('All types')") # no change
content = content.replace("find.text('All priorities')", "find.text('All priorities')") # no change

with open('mobile/test/project_detail_ux_test.dart', 'w') as f:
    f.write(content)

print("Updated tests")
