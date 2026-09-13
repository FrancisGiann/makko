import re

def update_dashboard():
    with open('mobile/lib/features/dashboard/dashboard_screen.dart', 'r') as f:
        content = f.read()
    
    # We want to replace the LayoutBuilder with just a Row
    target = """    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSpeechBubbleCard(
                  context,
                  moodTag,
                  moodColor,
                  message,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(context),
            const SizedBox(height: 12),
            _buildSpeechBubbleCard(context, moodTag, moodColor, message),
          ],
        );
      },
    );"""
    
    replacement = """    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(context),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSpeechBubbleCard(
            context,
            moodTag,
            moodColor,
            message,
          ),
        ),
      ],
    );"""
    
    if target in content:
        content = content.replace(target, replacement)
        with open('mobile/lib/features/dashboard/dashboard_screen.dart', 'w') as f:
            f.write(content)
        print("Updated dashboard_screen.dart")
    else:
        print("Could not find target in dashboard_screen.dart")

def update_issue_service():
    with open('mobile/lib/services/issue_service.dart', 'r') as f:
        content = f.read()
        
    target = """    dynamic orderQuery = query;

    switch (filters.sort) {"""
    
    replacement = """    dynamic orderQuery = query.order('status', ascending: true);

    switch (filters.sort) {"""
    
    if target in content:
        content = content.replace(target, replacement)
        with open('mobile/lib/services/issue_service.dart', 'w') as f:
            f.write(content)
        print("Updated issue_service.dart")
    else:
        print("Could not find target in issue_service.dart")

update_dashboard()
update_issue_service()
