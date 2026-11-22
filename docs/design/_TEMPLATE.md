# Design: REQ-<N> <title>

Status: draft | approved   Risk: medium | high   Requirement: #<N>

## 1. Context and goal
Two or three sentences. Link the acceptance criteria (AC-1...).

## 2. Options considered
| Option | Pros | Cons |
|---|---|---|
| A (chosen) | | |
| B | | |

## 3. Decision
What we will build and why this option.

## 4. App changes
- Screens / routes / navigation:
- Components, hooks, services (file paths):
- State handling, loading/empty/error/offline behaviour:

## 5. Data and backend (Supabase)
- Tables / columns (SQL sketch):
- Row Level Security policies (who can select/insert/update/delete):
- Storage buckets, auth impact:
- Migration plan (additive? reversible?):

## 6. Dependencies and permissions
- New packages (name, why, native code? maintained?):
- New app permissions (should normally be none):

## 7. Threats and mitigations
Spoofing / tampering / information disclosure / abuse (spam, harassment) / denial of service - only what applies.

## 8. Test strategy hints (for the Test Designer)
Which ACs are unit/screen tests, what must be mocked (Supabase client, navigation).

## 9. Rollout and rollback
How it ships, how to revert, what happens to data on revert.

## 10. Open questions
Must be empty before approval.
