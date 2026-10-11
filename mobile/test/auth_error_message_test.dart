import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/auth_error_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('authErrorMessage', () {
    test('explains invalid credentials without exposing account existence', () {
      expect(
        authErrorMessage(
          const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
          action: AuthAction.signIn,
        ),
        'Email or password is incorrect.',
      );
    });

    test('directs an unconfirmed user to confirm email', () {
      expect(
        authErrorMessage(
          const AuthApiException(
            'Email not confirmed',
            statusCode: '400',
            code: 'email_not_confirmed',
          ),
          action: AuthAction.signIn,
        ),
        'Confirm your email address, then try signing in again.',
      );
    });

    test('maps rate limits to a wait-and-retry instruction', () {
      expect(
        authErrorMessage(
          const AuthApiException(
            'rate limit exceeded',
            statusCode: '429',
            code: 'over_request_rate_limit',
          ),
          action: AuthAction.signIn,
        ),
        'Too many attempts. Wait a few minutes, then try again.',
      );
    });

    test('distinguishes server availability from connection failures', () {
      expect(
        authErrorMessage(
          AuthRetryableFetchException(
            message: '{"message":"Bad Gateway"}',
            statusCode: '502',
          ),
          action: AuthAction.signIn,
        ),
        'Authentication service unavailable. Please try again shortly.',
      );
      expect(
        authErrorMessage(
          AuthRetryableFetchException(message: 'SocketException: offline'),
          action: AuthAction.signIn,
        ),
        'Could not connect to the authentication service. Check your connection and try again.',
      );
    });

    test('keeps unknown exception details out of the UI', () {
      const fallback = 'Unable to sign in. Check your details and try again.';
      expect(
        authErrorMessage(
          StateError('private implementation detail'),
          action: AuthAction.signIn,
        ),
        fallback,
      );
      expect(
        authErrorMessage(
          const AuthApiException('Private server detail', code: 'unknown'),
          action: AuthAction.signIn,
        ),
        fallback,
      );
    });
  });
}
