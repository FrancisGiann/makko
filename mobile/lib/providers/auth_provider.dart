import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';

final authProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Exposes the session restored by Supabase before the auth event stream emits
/// its first value. Supabase initialization is completed by the app bootstrap
/// before this provider is used.
final currentAuthUserIdProvider = Provider<String?>((ref) {
  try {
    return supabase.auth.currentSession?.user.id;
  } catch (_) {
    return null;
  }
});

/// A dependency shared by user-owned providers so a logout/login transition
/// invalidates every cached read without a global mutable reset registry.
final authUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.when(
    data: (state) => state.session?.user.id,
    loading: () => ref.watch(currentAuthUserIdProvider),
    // A restored session is safe while the auth stream emits its initial
    // event. Once the stream fails, treat identity as unavailable so expired
    // sessions and user-owned caches cannot keep protected screens mounted.
    error: (_, _) => null,
  );
});
