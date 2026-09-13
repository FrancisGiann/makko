with open('mobile/lib/services/issue_service.dart', 'r') as f:
    content = f.read()

target = """  IssuePage copyWith({String? paginationError}) => IssuePage(
    items: items,
    total: total,
    page: page,
    pageSize: pageSize,
    pageCount: pageCount,
    paginationError: paginationError,
  );"""

replacement = """  IssuePage copyWith({
    List<Issue>? items,
    int? total,
    int? page,
    int? pageSize,
    int? pageCount,
    String? paginationError,
  }) => IssuePage(
    items: items ?? this.items,
    total: total ?? this.total,
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    pageCount: pageCount ?? this.pageCount,
    paginationError: paginationError ?? this.paginationError,
  );"""

if target in content:
    content = content.replace(target, replacement)
    with open('mobile/lib/services/issue_service.dart', 'w') as f:
        f.write(content)
    print("Fixed IssuePage.copyWith")
else:
    print("Could not find target")
