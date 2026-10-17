# Supabase status

## Done (and how it was tested)
- `env.js` holds the public settings. `index.html` reads it, refuses any secret or service_role key, and creates the client with the publishable key only. Tested with fake responses (`node tests/supabase-config-test.js`).
- `#/sbcheck` (open `https://your-site/#/sbcheck`) shows a pass/fail list: settings, key accepted, phone sign-in on, library loaded, each table found.
- `supabase/schema.sql`: tables and Row Level Security. **Never run, never tested** (no Postgres was available here).

## Not done yet (on purpose)
- Login still uses Firebase phone OTP. Supabase Row Level Security needs a Supabase sign-in, so the next step is moving login to Supabase phone OTP (needs an SMS provider in Supabase).
- The app's data (`S`) is not yet read from or written to Supabase. The UI and all working features are untouched.

## You must provide
1. `SUPABASE_URL` (Project Settings > API > Project URL), written into `env.js`.
2. Decision: Supabase phone OTP with which SMS provider (Twilio, MessageBird, Vonage, Textlocal).
3. Run `supabase/schema.sql` in the SQL Editor, then open `#/sbcheck`.
