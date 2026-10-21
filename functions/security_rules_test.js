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
  const payload = await response.json();
  assert.equal(response.status, 200, 'Auth emulator signup failed: ' + JSON.stringify(payload));
  return payload;
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

async function commit(token, writes) {
  return fetch(`${firestoreBase}:commit`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ writes }),
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
  const now = new Date();
  const nowIso = now.toISOString();

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

  const requestId = `${alice.localId}_${bob.localId}`;
  const chatRequest = {
    id: requestId,
    fromUserId: alice.localId,
    fromUserName: 'Test User',
    fromUserPhoto: '',
    toUserId: bob.localId,
    toUserName: 'Test User',
    toUserPhoto: '',
    message: 'Hi Bob',
    status: 'pending',
    createdAt: now,
    respondedAt: null,
  };
  await expectStatus(
    await create(`chat_requests/${requestId}`, alice.idToken, chatRequest),
    200,
    'sender creates a valid chat request',
  );
  await expectStatus(
    await request(`chat_requests/${requestId}`, {
      token: alice.idToken,
      method: 'PATCH',
      body: { status: 'accepted', respondedAt: now },
      updateFields: ['status', 'respondedAt'],
    }),
    403,
    'sender cannot accept their own chat request',
  );
  await expectStatus(
    await request(`chat_requests/${requestId}`, {
      token: bob.idToken,
      method: 'PATCH',
      body: { status: 'accepted', respondedAt: now },
      updateFields: ['status', 'respondedAt'],
    }),
    200,
    'recipient can accept a pending chat request',
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
      lastMessageId: '',
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
  const standaloneMessageUrl = new URL(`${firestoreBase}/${messagePath}`);
  standaloneMessageUrl.searchParams.set('documentId', `standalone-${messageId}`);
  await expectStatus(await fetch(standaloneMessageUrl, {
    method: 'POST',
    headers: { Authorization: `Bearer ${alice.idToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: toFields({
      ...message,
      id: `standalone-${messageId}`,
      timestamp: now,
    }) }),
  }), 403, 'message cannot be created without its room preview update');

  const messageFields = { ...message };
  delete messageFields.timestamp;
  const documentName = (path) =>
    `projects/${projectId}/databases/(default)/documents/${path}`;
  const messageDocument = documentName(`${messagePath}/${messageId}`);
  const roomDocument = documentName(`chat_rooms/${roomId}`);
  await expectStatus(await commit(alice.idToken, [
    {
      update: { name: messageDocument, fields: toFields(messageFields) },
      updateMask: { fieldPaths: Object.keys(messageFields) },
      updateTransforms: [{ fieldPath: 'timestamp', setToServerValue: 'REQUEST_TIME' }],
    },
    {
      update: {
        name: roomDocument,
        fields: toFields({
          lastMessage: message.text,
          lastMessageId: messageId,
          lastMessageSenderId: alice.localId,
          lastMessageSeen: false,
        }),
      },
      updateMask: {
        fieldPaths: ['lastMessage', 'lastMessageId', 'lastMessageSenderId', 'lastMessageSeen'],
      },
      updateTransforms: [{ fieldPath: 'lastMessageTime', setToServerValue: 'REQUEST_TIME' }],
    },
  ]), 200, 'sender creates a message with its matching room preview atomically');

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
      body: { isDelivered: true, deliveredAt: now },
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

  await expectStatus(
    await request(`users/${bob.localId}`, {
      token: bob.idToken,
      method: 'PATCH',
      body: { blockedUsers: [alice.localId] },
      updateFields: ['blockedUsers'],
    }),
    200,
    'owner can update their block list',
  );
  const blockedMessageId = `blocked-${suffix}`;
  const blockedMessageUrl = new URL(`${firestoreBase}/${messagePath}`);
  blockedMessageUrl.searchParams.set('documentId', blockedMessageId);
  await expectStatus(await fetch(blockedMessageUrl, {
    method: 'POST',
    headers: { Authorization: `Bearer ${alice.idToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: toFields({ ...message, id: blockedMessageId }) }),
  }), 403, 'blocked sender cannot create a new message');

  console.log('Firestore security rules checks passed.');
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
