# Supabase

- `migrations/` holds SQL migrations, one timestamped file per change (`YYYYMMDDHHMMSS_name.sql`).
- Agents WRITE migrations; they never apply them and never touch a real database (HARD-RULES 10).
- Every table gets Row Level Security and explicit policies in the same migration (HARD-RULES 9).
- You apply migrations yourself, after the PR is merged and before shipping the app version that needs them:
  1. Install the Supabase CLI and log in: `npx supabase login`
  2. Link the project once: `npx supabase link --project-ref <your-project-ref>`
  3. Review pending migrations, then apply: `npx supabase db push`
- Never commit database passwords, the service_role key, or access tokens.
