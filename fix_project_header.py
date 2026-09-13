with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()

target = """    return MakkoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: MakkoShapes.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: ["""

replacement = """    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: ["""

if target in content:
    content = content.replace(target, replacement)
    
    # Also adjust the container padding in the main build method
    # Pinned Compact Project Metadata Card
    # Padding(
    #   padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    
    target2 = """            // Pinned Compact Project Metadata Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),"""
              
    replacement2 = """            // Pinned Compact Project Metadata Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),"""
              
    content = content.replace(target2, replacement2)
    
    with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
        f.write(content)
    print("Updated _CompactProjectMetaCard to remove the card background.")
else:
    print("Could not find target")
