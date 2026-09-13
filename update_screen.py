with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()

target = """        return Dismissible(
          key: ValueKey(issue.id),"""

replacement = """        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Dismissible(
            key: ValueKey('${issue.id}-${issue.status}'),"""

if target in content:
    content = content.replace(target, replacement)
    
    # Also need to fix the key inside Dismissible to pass down correctly, wait, Dismissible needs a key.
    # The child of AnimatedSwitcher also needs a key to animate correctly.
    # Actually, Dismissible's key is what AnimatedSwitcher will look at!
    
    with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
        f.write(content)
    print("Updated project_detail_screen.dart")
else:
    print("Could not find target")
