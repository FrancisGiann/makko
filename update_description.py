with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()
    
target = """            Text(
              project.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),"""

replacement = """            Text(
              project.description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),"""
            
if target in content:
    content = content.replace(target, replacement)
    with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
        f.write(content)
    print("Updated description text style.")
else:
    print("Could not find description style target.")
