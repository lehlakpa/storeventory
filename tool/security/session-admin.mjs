import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const [action, projectId, uid] = process.argv.slice(2);
if (!['revoke', 'disable', 'enable'].includes(action) || !projectId || !uid) {
  console.error('Usage: node session-admin.mjs <revoke|disable|enable> <project-id> <uid>');
  process.exit(1);
}
initializeApp({ credential: applicationDefault(), projectId });
const auth = getAuth();
const control = getFirestore().collection('session_controls').doc(uid);
// Verify the target first; never log credentials or tokens.
await auth.getUser(uid);
if (action === 'enable') {
  await auth.updateUser(uid, { disabled: false });
  // Preserve the cutoff so previously revoked sessions stay revoked.
  await control.set({ disabled: false }, { merge: true });
} else {
  // Block current Firestore access before invalidating refresh tokens.
  const cutoff = Math.floor(Date.now() / 1000);
  await control.set({ revokedBefore: cutoff,
    ...(action === 'disable' ? { disabled: true } : {}) }, { merge: true });
  if (action === 'disable') await auth.updateUser(uid, { disabled: true });
  await auth.revokeRefreshTokens(uid);
  const user = await auth.getUser(uid);
  const authCutoff = Math.floor(Date.parse(user.tokensValidAfterTime) / 1000);
  await control.set({ revokedBefore: Math.max(cutoff, authCutoff) }, { merge: true });
}
console.log(`${action} completed for ${uid} in ${projectId}.`);
