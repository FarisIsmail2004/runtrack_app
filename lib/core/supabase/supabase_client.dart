import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project URL, injected at build time via
/// `--dart-define=SUPABASE_URL=...`. Empty when the build was not configured
/// for Supabase, in which case the app runs in fully offline mode.
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

/// Supabase anon (publishable) key, injected via
/// `--dart-define=SUPABASE_ANON_KEY=...`. This is the *public* anon key — it is
/// safe to ship in the client because Row Level Security is what actually
/// protects data. It is NOT a secret and is unrelated to user passwords.
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// True only when both the URL and anon key were provided at build time.
/// When false, every auth path short-circuits to a friendly "not configured"
/// failure and the rest of the app keeps working offline.
bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

/// Initialises Supabase if (and only if) the build was configured. A no-op
/// otherwise, so debug/test builds and offline use never touch the network.
///
/// SECURITY: This only wires up the Supabase SDK. No credential, password, or
/// derivative is ever read or written here — Supabase Auth handles password
/// hashing (bcrypt) server-side in `auth.users`.
Future<void> initSupabase() async {
  if (!isSupabaseConfigured) {
    debugPrint(
      'Supabase not configured (no SUPABASE_URL/ANON_KEY dart-define) — '
      'running in offline mode.',
    );
    return;
  }
  // The anon key is the public, RLS-protected key (per the task spec we wire
  // `anonKey`). It is being renamed to `publishableKey` in a future major
  // version; suppress that informational deprecation here.
  await Supabase.initialize(
    url: supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: supabaseAnonKey,
  );
}

/// Exposes whether this build has Supabase configured, so widgets/router can
/// branch on it without reading the top-level getter directly (and so tests can
/// override it).
final supabaseConfiguredProvider =
    Provider<bool>((_) => isSupabaseConfigured);
