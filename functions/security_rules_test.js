const assert = require('node:assert/strict');

const projectId = process.env.GCLOUD_PROJECT || 'demo-velora';
const authBase = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const firestoreBase = `http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents`;

function toValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') return Number.isInteger(value)
    ? { integerValue: String(value) }
    : { doubleValue: value };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(toValue) } };
  if (typeof value === 'object') {
    return { mapValue: { fields: toFields(value) } };
  }
  throw new TypeError(`Unsupported Firestore test value: ${typeof value}`);
}

function toFields(value) {
  return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, toValue(item)]));
}

async function signUp(email) {
  const response = await fetch(`${authBase}/accounts:signUp?key=fake-api-key`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'test-password-123', returnSecureToken: true }),
  });
  assert.equal(response.status, 200, `Auth emulator signup failed: ${await response.text()}`);
  return response.json();
}

async function request(path, { token, method = 'GET', body, updateFields = [] } = {}) {
  const url = new URL(`${firestoreBase}/${path}`);
  for (const field of updateFields) url.searchParams.append('updateMask.fieldPaths', field);
  const response = await fetch(url, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify({ fields: toFields(body) }) } : {}),
  });
  return response;
}

async function create(path, token, data) {
  const [collection, ...rest] = path.split('/');
  const documentId = rest.pop();
  assert.equal(rest.length, 0, 'Test create only supports top-level collection docs');
  const url = new URL(`${firestoreBase}/${collection}`);
  url.searchParams.set('documentId', documentId);
  return fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: toFields(data) }),
  });
}

async function expectStatus(response, expected, label) {
  const details = response.status === expected ? '' : `: ${await response.text()}`;
  assert.equal(response.status, expected, `${label} returned ${response.status}${details}`);
}

(async () => {
  const suffix = Date.now();
  const alice = await signUp(`alice-${suffix}@example.test`);
  const bob = await signUp(`bob-${suffix}@example.test`);
  const hidden = await signUp(`hidden-${suffix}@example.test`);
  const now = new Date();`r`n  const nowIso = now.toISOString();

  const publicProfile = (uid, discoverability = 'phone_number') => ({
    uid,
    name: 'Test User',
    photoUrl: '',
    about: 'Test profile',
    isOnline: false,
    lastSeen: null,
    createdAt: now,
    updatedAt: now,
    username: null,
    bio: null,
    discoverability,
    whoCanMessage: 'contacts_and_requests',
  });
  const privateProfile = (authUser, name) => ({
    uid: authUser.localId,
    name,
    email: authUser.email,
    photoUrl: '',
    about: 'Test profile',
    isOnline: false,
    lastSeen: now,
    createdAt: now,
    updatedAt: now,
    blockedUsers: [],
    phoneNumber: '+14155550123',
    discoverability: 'phone_number',
    whoCanMessage: 'contacts_and_requests',
  });

  for (const [account, name] of [[alice, 'Alice'], [bob, 'Bob'], [hidden, 'Hidden']]) {
    await expectStatus(
      await create(`users/${account.localId}`, account.idToken, privateProfile(account, name)),
      200,
      `owner creates private profile (${name})`,
    );
  }
  await expectStatus(
    await create(`public_profiles/${alice.localId}`, alice.idToken, publicProfile(alice.localId)),
    200,
    'owner creates public profile',
  );
  await expectStatus(
    await create(`public_profiles/${bob.localId}`, bob.idToken, publicProfile(bob.localId)),
    200,
    'owner creates public profile',
  );
  await expectStatus(
    await create(`public_profiles/${hidden.localId}`, hidden.idToken, publicProfile(hidden.localId, 'hidden')),
    200,
    'owner creates hidden public profile',
  );

  await expectStatus(
    await request(`users/${bob.localId}`, { token: alice.idToken }),
    403,
    'another user cannot read private email or phone',
  );
  await expectStatus(
    await request(`public_profiles/${bob.localId}`, { token: alice.idToken }),
    200,
    'discoverable public profile is readable',
  );
  await expectStatus(
    await request(`public_profiles/${hidden.localId}`, { token: alice.idToken }),
    403,
    'hidden profile is not readable outside an existing chat',
  );

  const participants = [alice.localId, bob.localId].sort();
  const roomId = participants.join('_');
  await expectStatus(
    await create(`chat_rooms/${roomId}`, alice.idToken, {
      id: roomId,
      participants,
      lastMessage: '',
      lastMessageSenderId: '',
      lastMessageTime: now,
      lastMessageSeen: true,
      createdAt: now,
      pinnedBy: [],
      typingUsers: [],
      deletedBy: [],
    }),
    200,
    'room participant creates chat room',
  );

  const messageId = `message-${suffix}`;
  const messagePath = `chat_rooms/${roomId}/messages`;
  const message = {
    id: messageId,
    chatRoomId: roomId,
    senderId: alice.localId,
    receiverId: bob.localId,
    text: 'hello',
    type: 'text',
    timestamp: nowIso,
    isSeen: false,
    isDelivered: false,
    deliveredAt: null,
    seenAt: null,
    imageUrl: null,
    replyToId: null,
    replyToText: null,
    replyToSenderName: null,
    deletedFor: [],
    isDeletedForEveryone: false,
    reactions: {},
  };
  const messageCreateUrl = new URL(`${firestoreBase}/${messagePath}`);
  messageCreateUrl.searchParams.set('documentId', messageId);
  await expectStatus(await fetch(messageCreateUrl, {
    method: 'POST',
    headers: { Authorization: `Bearer ${alice.idToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: toFields(message) }),
  }), 200, 'room participant creates a valid message');

  await expectStatus(
    await request(`${messagePath}/${messageId}`, {
      token: bob.idToken,
      method: 'PATCH',
      body: { text: 'tampered' },
      updateFields: ['text'],
    }),
    403,
    'recipient cannot edit sender message content',
  );
  await expectStatus(
    await request(`${messagePath}/${messageId}`, {
      token: bob.idToken,
      method: 'PATCH',
      body: { isDelivered: true, deliveredAt: nowIso },
      updateFields: ['isDelivered', 'deliveredAt'],
    }),
    200,
    'recipient can update delivery receipt',
  );
  await expectStatus(
    await request(`${messagePath}/${messageId}`, {
      token: bob.idToken,
      method: 'PATCH',
      body: { reactions: { [bob.localId]: '??' } },
      updateFields: ['reactions'],
    }),
    200,
    'participant can set their own reaction',
  );
  await expectStatus(
    await request(`${messagePath}/${messageId}`, {
      token: alice.idToken,
      method: 'PATCH',
      body: {
        isDeletedForEveryone: true,
        text: '',
        imageUrl: null,
        reactions: {},
      },
      updateFields: ['isDeletedForEveryone', 'text', 'imageUrl', 'reactions'],
    }),
    200,
    'original sender can delete message for everyone',
  );

  console.log('Firestore security rules checks passed.');
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});