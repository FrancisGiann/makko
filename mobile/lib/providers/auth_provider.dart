import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';

final authProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// A dependency shared by user-owned providers so a logout/login transition
/// invalidates every cached read without a global mutable reset registry.
final authUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).valueOrNull?.session?.user.id;
});
