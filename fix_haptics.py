with open('mobile/lib/features/projects/project_detail_screen.dart', 'r') as f:
    content = f.read()

import_stmt = "import 'package:flutter/services.dart';\n"
if "package:flutter/services.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmt)

target = """  Future<void> _setStatus(Issue issue, String status) async {
    if (_busy || issue.status == status) return;
    setState(() => _busy = true);"""

replacement = """  Future<void> _setStatus(Issue issue, String status) async {
    if (_busy || issue.status == status) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);"""

if target in content:
    content = content.replace(target, replacement)
    
target2 = """  Future<void> _confirmDeleteIssue(Issue issue) async {"""
replacement2 = """  Future<void> _confirmDeleteIssue(Issue issue) async {
    HapticFeedback.mediumImpact();"""

if target2 in content:
    content = content.replace(target2, replacement2)
    
with open('mobile/lib/features/projects/project_detail_screen.dart', 'w') as f:
    f.write(content)

print("Added haptics to ProjectDetailScreen")
