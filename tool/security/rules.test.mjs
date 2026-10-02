import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, Timestamp,
  writeBatch } from 'firebase/firestore';

let env;
const DAY = 86400;
const now = () => Math.floor(Date.now() / 1000);
const sessionPath = (uid, authTime) => `auth_sessions/${uid}/sessions/${authTime}`;
function client(authTime, uid = 'admin') {
  return env.authenticatedContext(uid, {
    auth_time: authTime, firebase: { sign_in_provider: 'password' },
  }).firestore();
}
async function seed(authTime, { uid = 'admin', expires = authTime + 30 * DAY,
  control } = {}) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, sessionPath(uid, authTime)), {
      expiresAt: Timestamp.fromMillis(expires * 1000),
    });
    await setDoc(doc(db, 'products/p'), { quantity: 10 });
    await setDoc(doc(db, 'sales/s'), { quantity: 2 });
    if (control) await setDoc(doc(db, `session_controls/${uid}`), control);
  });
}
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-storeventory',
    firestore: { host: '127.0.0.1', port: 8180,
      rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env?.cleanup());

test('unauthenticated and unregistered sessions cannot read inventory', async () => {
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'products/p')));
  await assertFails(getDoc(doc(client(now() - 10), 'products/p')));
});
test('fresh password login can create its own bounded immutable deadline', async () => {
  const time = now() - 2;
  const db = client(time);
  const ref = doc(db, sessionPath('admin', time));
  await assertSucceeds(setDoc(ref, { expiresAt: Timestamp.fromMillis((time + 30 * DAY) * 1000) }));
  await assertFails(updateDoc(ref, { expiresAt: Timestamp.fromMillis((time + 31 * DAY) * 1000) }));
  await assertFails(deleteDoc(ref));
  await assertFails(setDoc(doc(db, sessionPath('other', time)), { expiresAt: Timestamp.now() }));
  await assertFails(setDoc(doc(db, sessionPath('admin', time + 1)), { expiresAt: Timestamp.now() }));
});

test('password login can bootstrap controls, session and its own profile', async () => {
  const time = now() - 2;
  const db = client(time);
  // Login reads these documents before either one exists.
  await assertSucceeds(getDoc(doc(db, 'session_controls/admin')));
  const session = doc(db, sessionPath('admin', time));
  await assertSucceeds(getDoc(session));
  await assertSucceeds(setDoc(session, {
    expiresAt: Timestamp.fromMillis((time + 30 * DAY) * 1000),
  }));
  const profile = doc(db, 'admins/admin');
  await assertSucceeds(getDoc(profile));
  await assertSucceeds(setDoc(profile, { name: 'Test admin', email: 'admin@example.com' }));
  await assertSucceeds(getDoc(profile));
  await assertFails(getDoc(doc(db, 'admins/other')));
});
test('session creation rejects oversized expiry and old password authentication', async () => {
  const time = now() - 2;
  await assertFails(setDoc(doc(client(time), sessionPath('admin', time)), {
    expiresAt: Timestamp.fromMillis((time + 31 * DAY) * 1000),
  }));
  const old = time - 301;
  await assertFails(setDoc(doc(client(old), sessionPath('admin', old)), {
    expiresAt: Timestamp.fromMillis((old + 30 * DAY) * 1000),
  }));
});
test('29-day session can read and write ordinary inventory but cannot delete or edit receipts', async () => {
  const time = now() - 29 * DAY;
  await seed(time);
  const db = client(time);
  await assertSucceeds(getDoc(doc(db, 'products/p')));
  await assertSucceeds(updateDoc(doc(db, 'products/p'), { quantity: 9 }));
  await assertFails(deleteDoc(doc(db, 'products/p')));
  await assertFails(updateDoc(doc(db, 'sales/s'), { quantity: 1 }));
  await assertFails(deleteDoc(doc(db, 'sales/s')));
  await assertFails(setDoc(doc(db, 'settings/store'), { name: 'Changed' }));
});
test('exactly 30-day-old authentication is denied even with a forged longer server deadline', async () => {
  const time = now() - 30 * DAY;
  await seed(time, { expires: now() + DAY });
  await assertFails(getDoc(doc(client(time), 'products/p')));
});
test('reauthentication cannot bypass the original stored session deadline', async () => {
  const time = now() - 2;
  await seed(time, { expires: now() - 1 });
  const db = client(time);
  await assertFails(getDoc(doc(db, 'products/p')));
  await assertFails(updateDoc(doc(db, sessionPath('admin', time)), {
    expiresAt: Timestamp.fromMillis((now() + 30 * DAY) * 1000),
  }));
});
test('recent password permits atomic receipt deletion and stock restoration', async () => {
  const time = now() - 2;
  await seed(time);
  const db = client(time);
  const batch = writeBatch(db);
  batch.update(doc(db, 'products/p'), { quantity: 12 });
  batch.delete(doc(db, 'sales/s'));
  batch.set(doc(db, 'stock_history/h'), { reason: 'sale deleted' });
  await assertSucceeds(batch.commit());
});
test('revocation denies issued tokens immediately; a later password login can recover', async () => {
  const cutoff = now() - 20;
  await seed(cutoff, { control: { revokedBefore: cutoff } });
  await assertFails(getDoc(doc(client(cutoff), 'products/p')));
  await seed(cutoff + 10);
  await assertSucceeds(getDoc(doc(client(cutoff + 10), 'products/p')));
});
test('disabled account cannot recover by signing in again or modifying controls', async () => {
  const time = now() - 2;
  await seed(time, { control: { disabled: true } });
  const db = client(time);
  await assertFails(getDoc(doc(db, 'products/p')));
  await assertFails(setDoc(doc(db, 'session_controls/admin'), { disabled: false }));
  await assertSucceeds(getDoc(doc(db, 'session_controls/admin')));
  await assertFails(getDoc(doc(db, 'session_controls/other')));
});
test('refreshing an ID token does not make a six-minute-old login recent', async () => {
  const time = now() - 360;
  await seed(time);
  await assertSucceeds(getDoc(doc(client(time), 'products/p')));
  await assertFails(deleteDoc(doc(client(time), 'products/p')));
});
