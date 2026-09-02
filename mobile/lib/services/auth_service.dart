import '../core/supabase/supabase_client.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpResult {
  final Session? session;
  final bool requiresEmailConfirmation;

  const SignUpResult({
    required this.session,
    required this.requiresEmailConfirmation,
  });
}

class AuthService {
  Future<void> signInWithPassword(String email, String password) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty)
      throw const AuthException('Enter your email and password to continue.');
    await supabase.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<SignUpResult> signUp(String email, String password) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.length < 6)
      throw const AuthException(
        'Use a valid email and a password of at least 6 characters.',
      );
    final result = await supabase.auth.signUp(
      email: normalizedEmail,
      password: password,
    );
    return SignUpResult(
      session: result.session,
      requiresEmailConfirmation: result.user != null && result.session == null,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
