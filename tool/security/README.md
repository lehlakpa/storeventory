# Session security

The app keeps a fixed deadline 30 days after Firebase password authentication.
Biometric unlock refreshes the ID token without moving this deadline. Sensitive
password verification carries the existing deadline into the new authentication
record. An explicit password login starts a new session. ID token lifetime stays
under Firebase control (one hour); this does not configure refresh-token TTL.

## Enforcement

- `auth_sessions/{uid}/sessions/{auth_time}` stores an immutable `expiresAt`.
  Creation requires password authentication within the past five minutes and
  cannot exceed `auth_time + 30 days`. Token refresh cannot create a new session.
- Every inventory request checks both authentication age and the saved deadline
  using Firestore server time. A client clock/storage edit cannot extend access.
- Product deletion, receipt editing/deletion, and protected profile/settings
  writes require password authentication within five minutes. The current UI
  asks for the password on every product delete or receipt edit/delete.
- `session_controls/{uid}` is writable only through a trusted Admin SDK/backend.
  `disabled: true` blocks all inventory access. `revokedBefore` is an integer UTC
  epoch timestamp in seconds; authentication at or before it is denied.
- Biometric unlock and password login require online server validation. The app
  listens for control changes and signs out a revoked/disabled open session.
  Revocation cannot erase data already downloaded to an offline device.
- Firebase cannot distinguish a password reauthentication from a new password
  login in rules. Both prove possession of the password; the normal app preserves
  the original deadline during sensitive-action verification.

## Rollout

Deploy the updated app and rules together. Old app versions cannot create the new
session records. Existing local sessions without a server record must sign in
with a password once. Rules are not deployed by running tests.

From the repository root, deploy when ready:

```powershell
firebase deploy --only firestore:rules --project storeventory-f69d5
```

## Revoke or disable a user

Use Node.js 22.12+ and Application Default Credentials with Firebase Auth and
Firestore admin permissions. Keep service account credentials outside this repo
and the app. Never ship this tool or admin credentials in the Flutter bundle.

```powershell
npm --prefix tool/security ci
node tool/security/session-admin.mjs revoke storeventory-f69d5 USER_UID
node tool/security/session-admin.mjs disable storeventory-f69d5 USER_UID
node tool/security/session-admin.mjs enable storeventory-f69d5 USER_UID
```

`revoke` signs out existing sessions across devices; a later password login is
allowed. `disable` also prevents future login. `enable` preserves the revocation
cutoff, so old sessions do not recover. The tool blocks Firestore access before
revoking refresh tokens; if a later step fails, retry the same command.
Using only the Firebase console's disable/revoke operation does not update the
Firestore cutoff for already-issued ID tokens; use this tool for immediate
server-side denial. No live user is changed by the test suite.

Expired session documents can be cleaned up by a trusted scheduled backend or
Firestore TTL on `expiresAt`; configure that separately if desired.

## Verification

```powershell
flutter analyze
flutter test
firebase emulators:exec --only firestore --project demo-storeventory --config firebase.security-test.json "npm --prefix tool/security test"
```

The emulator suite tests unauthenticated access, session creation/immutability,
30-day expiry, recent-password requirements, stock/receipt batch writes,
revocation, and disabling. It uses only the isolated `demo-storeventory` project.
