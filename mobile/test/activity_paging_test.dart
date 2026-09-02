import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/activity_log.dart';
import 'package:mobile/services/activity_service.dart';

ActivityLog _log(String id) => ActivityLog(
  id: id,
  projectId: 'project-1',
  type: 'issue_updated',
  description: 'Updated issue $id',
  createdAt: DateTime(2026, 1, int.parse(id)),
);

void main() {
  test('activity page merges without duplicate rows', () {
    final merged = mergeActivityItems(
      [_log('1'), _log('2')],
      [_log('2'), _log('3')],
    );
    expect(merged.map((item) => item.id), ['1', '2', '3']);
  });
}
