import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/validation.dart';

void main() {
  test('validates and trims project names', () {
    expect(Validation.validateName('  Project  '), isNull);
    expect(Validation.validateName('   '), 'Name is required');
    expect(Validation.validateName('a' * 121), contains('120'));
  });

  test('validates exact issue and repository input shapes', () {
    expect(Validation.validateIssueTitle('Fix sync'), isNull);
    expect(Validation.validateIssueTitle(''), 'Title is required');
    expect(Validation.validateRepository('owner/repo'), isNull);
    expect(
      Validation.validateRepository('https://github.com/owner/repo'),
      'Use owner/repository format',
    );
    expect(
      Validation.validateRepository('owner'),
      contains('owner/repository'),
    );
  });

  test('validates password and email requirements', () {
    expect(Validation.validateEmail('builder@example.com'), isNull);
    expect(Validation.validateEmail('builder'), contains('valid'));
    expect(Validation.validatePassword('12345'), contains('6'));
    expect(Validation.validatePassword('123456'), isNull);
  });
}
