import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthAction { signIn, signUp }

/// Converts expected Supabase Auth errors into messages a user can act on.
/// Unknown errors intentionally stay generic so implementation details never
/// leak into the sign-in form.
String authErrorMessage(Object error, {required AuthAction action}) {
  final fallback = action == AuthAction.signIn
      ? 'Unable to sign in. Check your details and try again.'
      : 'Unable to create your account. Check your details and try again.';

  if (error is AuthRetryableFetchException) {
    final statusCode = int.tryParse(error.statusCode ?? '');
    if (statusCode != null && statusCode >= 500) {
      return 'Authentication service unavailable. Please try again shortly.';
    }
    return 'Could not connect to the authentication service. Check your connection and try again.';
  }

  if (error is! AuthException) return fallback;

  final normalizedMessage = error.message.toLowerCase();
  switch (error.code) {
    case 'email_not_confirmed':
      return 'Confirm your email address, then try signing in again.';
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return 'Too many attempts. Wait a few minutes, then try again.';
    case 'invalid_credentials':
    case 'invalid_login_credentials':
    case 'user_not_found':
      return action == AuthAction.signIn
          ? 'Email or password is incorrect.'
          : fallback;
    case 'email_exists':
    case 'user_already_exists':
      return action == AuthAction.signUp
          ? 'An account with this email already exists. Sign in instead.'
          : 'Email or password is incorrect.';
    case 'signup_disabled':
      return 'New account creation is currently disabled.';
  }

  // Some GoTrue versions omit the structured code for these established
  // responses, so recognize the known text without exposing arbitrary details.
  if (normalizedMessage.contains('email not confirmed')) {
    return 'Confirm your email address, then try signing in again.';
  }
  if (normalizedMessage.contains('invalid login credentials') ||
      normalizedMessage.contains('invalid credentials')) {
    return action == AuthAction.signIn
        ? 'Email or password is incorrect.'
        : fallback;
  }
  if (normalizedMessage.contains('too many requests') ||
      normalizedMessage.contains('rate limit')) {
    return 'Too many attempts. Wait a few minutes, then try again.';
  }

  return fallback;
}
