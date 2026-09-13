with open('mobile/lib/features/github/github_contribution_graph.dart', 'r') as f:
    content = f.read()

target = """        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title "G I T H U B\""""

replacement = """        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title "G I T H U B\""""

content = content.replace(target, replacement)

target2 = """            ),
          ],
        ),
        if (_username != null && _username!.isNotEmpty)
          Row("""

replacement2 = """            ),
            ],
          ),
        ),
        if (_username != null && _username!.isNotEmpty)
          Row("""

content = content.replace(target2, replacement2)

with open('mobile/lib/features/github/github_contribution_graph.dart', 'w') as f:
    f.write(content)
