# runtrack_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running with Supabase auth

The app gates the entire auth flow behind two build-time `--dart-define`s
(`SUPABASE_URL`, `SUPABASE_ANON_KEY`). With neither set, `initSupabase()` is a
no-op and the app runs in **offline mode** — the router skips login/signup and
drops you straight on `/home`. To exercise the auth screens you must run with a
real Supabase project's credentials.

1. Copy the template and fill in your project's values (Supabase dashboard →
   Project Settings → API):

   ```sh
   cp dart_defines.example.json dart_defines.json
   # edit dart_defines.json — set SUPABASE_URL and the anon/publishable key
   ```

   `dart_defines.json` is gitignored, so your keys never get committed. The anon
   key is the public, RLS-protected key — safe on the client, unrelated to user
   passwords.

2. Run with the defines injected:

   - **VS Code:** pick **runtrack (Supabase auth)** from the Run and Debug menu.
   - **CLI:**

     ```sh
     flutter run --dart-define-from-file=dart_defines.json
     ```

To run offline again, use the **runtrack (offline)** launch config or plain
`flutter run`.

### Notes

- **Email confirmation:** new Supabase projects require email confirmation by
  default, so signup won't create a session until the link is clicked (the
  signup screen shows a "check your email" message). For quick testing, disable
  it under Auth → Providers → Email → "Confirm email" in the dashboard.
- **Google/Apple sign-in** needs extra native + provider setup (OAuth redirect
  URLs, client IDs) beyond these two defines; email/password works with just the
  project URL + anon key.
- The `profiles`/`runs` tables aren't required to test auth — Supabase Auth is
  built in. Those land with the background-sync phase.
