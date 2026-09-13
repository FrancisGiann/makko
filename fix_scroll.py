import re

with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()

# Add SliverPersistentHeaderDelegate class at the bottom
if "class _TabBarDelegate" not in content:
    content += """

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
"""

# Replace Column body with NestedScrollView
target = """        body: Column(
          children: [
            // Pinned Compact Project Metadata Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _CompactProjectMetaCard(
                project: item,
                counts: countsAsync.valueOrNull ??
                    const {'todo': 0, 'in_progress': 0, 'done': 0},
              ),
            ),
            // TabBar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: TabBar(
                indicatorColor: scheme.primary,
                indicatorWeight: 3,
                labelColor: scheme.primary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Issues'),
                  Tab(text: 'GitHub'),
                  Tab(text: 'Activity'),
                ],
              ),
            ),
            // TabBarView content
            Expanded(
              child: TabBarView(
                children: ["""

replacement = """        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: _CompactProjectMetaCard(
                    project: item,
                    counts: countsAsync.valueOrNull ??
                        const {'todo': 0, 'in_progress': 0, 'done': 0},
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    indicatorColor: scheme.primary,
                    indicatorWeight: 3,
                    labelColor: scheme.primary,
                    unselectedLabelColor: scheme.onSurfaceVariant,
                    labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Issues'),
                      Tab(text: 'GitHub'),
                      Tab(text: 'Activity'),
                    ],
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: ["""

if target in content:
    content = content.replace(target, replacement)
    
    # We also need to remove the Expanded around TabBarView if it exists
    # Because TabBarView is the body of NestedScrollView
    # Wait, the target string ends with "Expanded(\n              child: TabBarView(\n                children: ["
    # So the replacement replaces it with "body: TabBarView(\n            children: ["
    # This means the Expanded is successfully removed! We just need to make sure we remove the closing parenthesis of Expanded at the end of TabBarView.
    
    # Let's find the end of TabBarView and Expanded
    # We can do this with regex or string replace.
    end_target = """                ],
              ),
            ),
          ],
        ),"""
        
    end_replacement = """                ],
          ),
        ),"""
        
    content = content.replace(end_target, end_replacement)
    
    with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
        f.write(content)
    print("Updated body to NestedScrollView")
else:
    print("Could not find target Column")
