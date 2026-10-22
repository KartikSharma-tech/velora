const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');
const { getAppCheck } = require('firebase-admin/app-check');
const { defineSecret, defineString } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const crypto = require('node:crypto');
const {
  MAX_DEVICES_PER_USER,
  registerNotificationDevice,
  unregisterNotificationDevice,
} = require('./notification_device_store');

initializeApp();

const cloudinaryApiSecret = defineSecret('CLOUDINARY_API_SECRET');
const cloudinaryApiKey = defineString('CLOUDINARY_API_KEY');
const cloudinaryCloudName = defineString('CLOUDINARY_CLOUD_NAME');

async function requireAppCheck(req, res) {
  const appCheckToken = req.get('X-Firebase-AppCheck');
  if (!appCheckToken) {
    res.status(401).send('App verification required');
    return false;
  }
  try {
    await getAppCheck().verifyToken(appCheckToken);
    return true;
  } catch (error) {
    res.status(401).send('Invalid app verification token');
    return false;
  }
}

async function consumeRateLimit(db, uid, bucket, perMinuteLimit, perHourLimit) {
  const now = Date.now();
  const rateRef = db.collection('_server_rate_limits')
    .doc(bucket).collection('users').doc(uid);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(rateRef);
    const data = snapshot.data() || {};
    const minuteStart = typeof data.minuteStart === 'number' ? data.minuteStart : 0;
    const hourStart = typeof data.hourStart === 'number' ? data.hourStart : 0;
    const minuteCount = now - minuteStart < 60_000 ? (data.minuteCount || 0) : 0;
    const hourCount = now - hourStart < 3_600_000 ? (data.hourCount || 0) : 0;
    if (minuteCount >= perMinuteLimit || hourCount >= perHourLimit) return false;
    transaction.set(rateRef, {
      minuteStart: minuteCount === 0 ? now : minuteStart,
      minuteCount: minuteCount + 1,
      hourStart: hourCount === 0 ? now : hourStart,
      hourCount: hourCount + 1,
    });
    return true;
  });
}

exports.notifyChatRecipient = onDocumentCreated(
  {
    document: 'chat_rooms/{roomId}/messages/{messageId}',
    region: 'us-central1',
  },
  async (event) => {
    const message = event.data?.data();
    const { roomId } = event.params;
    if (!message || typeof message.receiverId !== 'string' ||
        typeof message.senderId !== 'string' || message.senderId === message.receiverId) {
      logger.warn('Ignoring malformed chat message notification event', { roomId });
      return;
    }

    const db = getFirestore();
    const roomSnapshot = await db.collection('chat_rooms').doc(roomId).get();
    const participants = roomSnapshot.data()?.participants;
    if (!Array.isArray(participants) ||
        !participants.includes(message.senderId) ||
        !participants.includes(message.receiverId)) {
      logger.warn('Ignoring message whose sender or receiver is not in the chat room', { roomId });
      return;
    }

    const recipientDevices = await db.collection('users')
      .doc(message.receiverId)
      .collection('devices')
      .get();
    const tokens = [...new Set(recipientDevices.docs
      .map((device) => device.data().token)
      .filter((token) => typeof token === 'string' && token.length > 0))];
    if (tokens.length === 0) return;

    const senderSnapshot = await db.collection('users').doc(message.senderId).get();
    const senderName = senderSnapshot.data()?.name || 'New message';
    const body = message.type === 'image' ? 'Sent a photo' : 'You received a message';
    const staleTokenDeletes = [];
    for (let offset = 0; offset < tokens.length; offset += 500) {
      const tokenBatch = tokens.slice(offset, offset + 500);
      const response = await getMessaging().sendEachForMulticast({
        tokens: tokenBatch,
        notification: { title: senderName, body },
        data: {
          roomId,
          senderId: message.senderId,
          senderName: String(senderName),
          receiverId: message.receiverId,
        },
        android: {
          priority: 'high',
          notification: { channelId: 'velora_messages', tag: roomId },
        },
        apns: {
          payload: { aps: { sound: 'default', 'thread-id': roomId } },
        },
      });

      response.responses.forEach((result, index) => {
        if (!result.success && [
          'messaging/registration-token-not-registered',
          'messaging/invalid-registration-token',
        ].includes(result.error?.code)) {
          staleTokenDeletes.push(recipientDevices.docs
            .filter((device) => device.data().token === tokenBatch[index])
            .map((device) => device.ref.delete()));
        } else if (!result.success) {
          logger.warn('FCM delivery failed', { code: result.error?.code });
        }
      });
    }
    await Promise.all(staleTokenDeletes.flat());
  },
);

// Matches on-device contacts without allowing clients to read every user's
// private profile (which contains email addresses and phone numbers).
exports.lookupVeloraContacts = onRequest(
  { region: 'us-central1', cors: false },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.set('Allow', 'POST').status(405).send('Method not allowed');
      return;
    }
    if (!await requireAppCheck(req, res)) return;

    const authorization = req.get('authorization') || '';
    const token = authorization.match(/^Bearer (.+)$/)?.[1];
    if (!token) {
      res.status(401).send('Authentication required');
      return;
    }

    let uid;
    try {
      const decoded = await getAuth().verifyIdToken(token);
      if (decoded.email_verified !== true) {
        res.status(403).send('Verified email required');
        return;
      }
      uid = decoded.uid;
    } catch (error) {
      res.status(401).send('Invalid authentication token');
      return;
    }

    const phones = req.body?.phones;
    if (!Array.isArray(phones) || phones.length > 1000 ||
        phones.some((phone) => typeof phone !== 'string' ||
          !/^\+[1-9]\d{7,14}$/.test(phone))) {
      res.status(400).send('Invalid contact list');
      return;
    }

    const db = getFirestore();
    try {
      const allowed = await consumeRateLimit(db, uid, 'contact_lookup', 4, 20);
      if (!allowed) {
        res.status(429).send('Too many contact lookup requests');
        return;
      }

      const candidates = new Map();
      const uniquePhones = [...new Set(phones)];
      const uniquePhoneSet = new Set(uniquePhones);
      for (let offset = 0; offset < uniquePhones.length; offset += 25) {
        const batch = uniquePhones.slice(offset, offset + 25);
        if (batch.length === 0) continue;
        const users = await db.collection('users')
          .where('phoneNumber', 'in', batch)
          .get();
        for (const userDoc of users.docs) {
          const user = userDoc.data();
          if (userDoc.id === uid) continue;
          if (user.discoverability && user.discoverability !== 'phone_number') continue;
          if (typeof user.phoneNumber !== 'string' ||
              !uniquePhoneSet.has(user.phoneNumber)) continue;
          candidates.set(userDoc.id, user);
          if (candidates.size > 1000) {
            res.status(413).send('Too many matching accounts');
            return;
          }
        }
      }

      const authUsers = candidates.size === 0
        ? { users: [] }
        : await getAuth().getUsers(
          [...candidates.keys()].map((candidateUid) => ({ uid: candidateUid })),
        );
      const contactUids = [];
      const matches = [];
      for (const authUser of authUsers.users) {
        const user = candidates.get(authUser.uid);
        if (!user || authUser.emailVerified !== true ||
            !authUser.phoneNumber || authUser.phoneNumber !== user.phoneNumber) {
          continue;
        }
        contactUids.push(authUser.uid);
        matches.push({
          uid: authUser.uid,
          phoneNumber: authUser.phoneNumber,
          name: typeof user.name === 'string' ? user.name : 'Velora User',
          photoUrl: typeof user.photoUrl === 'string' ? user.photoUrl : '',
          username: typeof user.username === 'string' ? user.username : null,
        });
      }
      await db.collection('message_contacts').doc(uid).set({
        contactUids,
        syncedAt: FieldValue.serverTimestamp(),
      });
      res.status(200).json(matches);
    } catch (error) {
      logger.error('Contact lookup failed', { uid, error: error.message });
      res.status(500).send('Contact lookup failed');
    }
  },
);

// Returns only the caller's current messaging decision, without exposing the
// recipient's phone numbers or complete contact index.
exports.resolveMessagingPermission = onRequest(
  { region: 'us-central1', cors: false },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.set('Allow', 'POST').status(405).send('Method not allowed');
      return;
    }
    if (!await requireAppCheck(req, res)) return;

    const token = (req.get('authorization') || '').match(/^Bearer (.+)$/)?.[1];
    if (!token) {
      res.status(401).send('Authentication required');
      return;
    }

    let uid;
    try {
      const decoded = await getAuth().verifyIdToken(token);
      if (decoded.email_verified !== true) {
        res.status(403).send('Verified email required');
        return;
      }
      uid = decoded.uid;
    } catch (error) {
      res.status(401).send('Invalid authentication token');
      return;
    }

    const targetUid = req.body?.targetUid;
    if (typeof targetUid !== 'string' || targetUid === uid ||
        !/^[A-Za-z0-9_-]{1,128}$/.test(targetUid)) {
      res.status(400).send('Invalid target account');
      return;
    }

    const db = getFirestore();
    try {
      const allowed = await consumeRateLimit(
        db,
        uid,
        'messaging_permission',
        60,
        300,
      );
      if (!allowed) {
        res.status(429).send('Too many permission checks');
        return;
      }

      const [callerSnapshot, recipientSnapshot] = await Promise.all([
        db.collection('users').doc(uid).get(),
        db.collection('users').doc(targetUid).get(),
      ]);
      if (!callerSnapshot.exists || !recipientSnapshot.exists) {
        res.status(200).json({ permission: 'blocked' });
        return;
      }
      const caller = callerSnapshot.data();
      const recipient = recipientSnapshot.data();
      if (caller.blockedUsers?.includes(targetUid) ||
          recipient.blockedUsers?.includes(uid)) {
        res.status(200).json({ permission: 'blocked' });
        return;
      }

      const roomId = [uid, targetUid].sort().join('_');
      const roomSnapshot = await db.collection('chat_rooms').doc(roomId).get();
      if (roomSnapshot.exists &&
          roomSnapshot.data()?.participants?.includes(uid) &&
          roomSnapshot.data()?.participants?.includes(targetUid)) {
        res.status(200).json({ permission: 'allowed' });
        return;
      }

      const messagePrivacy = recipient.whoCanMessage || 'contacts_and_requests';
      if (messagePrivacy === 'anyone') {
        res.status(200).json({ permission: 'allowed' });
        return;
      }
      if (messagePrivacy === 'nobody') {
        res.status(200).json({ permission: 'blocked' });
        return;
      }

      const contactsSnapshot = await db.collection('message_contacts')
        .doc(targetUid)
        .get();
      const contacts = contactsSnapshot.data();
      const hasFreshContactIndex = contactsSnapshot.exists &&
        typeof contacts?.syncedAt?.toMillis === 'function' &&
        Date.now() - contacts.syncedAt.toMillis() >= 0 &&
        Date.now() - contacts.syncedAt.toMillis() < 24 * 60 * 60 * 1000;
      const senderIsRecipientContact = hasFreshContactIndex &&
        Array.isArray(contacts.contactUids) && contacts.contactUids.includes(uid);
      if (senderIsRecipientContact) {
        res.status(200).json({ permission: 'allowed' });
        return;
      }
      if (messagePrivacy === 'contacts') {
        res.status(200).json({ permission: 'blocked' });
        return;
      }

      const requestSnapshot = await db.collection('chat_requests')
        .doc(`${uid}_${targetUid}`)
        .get();
      const request = requestSnapshot.data();
      if (request?.fromUserId === uid && request?.toUserId === targetUid &&
          request?.status === 'accepted') {
        res.status(200).json({ permission: 'allowed' });
        return;
      }
      res.status(200).json({ permission: 'request_required' });
    } catch (error) {
      logger.error('Messaging permission check failed', { uid, error: error.message });
      res.status(500).send('Permission check failed');
    }
  },
);

// Device tokens grant the ability to send push notifications. Keep them out
// of client-writable Firestore paths; only this authenticated, App Check
// protected endpoint can register or remove a token for the caller.
exports.manageNotificationDevice = onRequest(
  { region: 'us-central1', cors: false },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.set('Allow', 'POST').status(405).send('Method not allowed');
      return;
    }
    if (!await requireAppCheck(req, res)) return;

    const token = (req.get('authorization') || '').match(/^Bearer (.+)$/)?.[1];
    if (!token) {
      res.status(401).send('Authentication required');
      return;
    }

    let uid;
    try {
      const decoded = await getAuth().verifyIdToken(token);
      if (decoded.email_verified !== true) {
        res.status(403).send('Verified email required');
        return;
      }
      uid = decoded.uid;
    } catch (error) {
      res.status(401).send('Invalid authentication token');
      return;
    }

    const { action, deviceToken, platform } = req.body || {};
    if (!['register', 'unregister'].includes(action) ||
        typeof deviceToken !== 'string' ||
        Buffer.byteLength(deviceToken, 'utf8') < 100 ||
        Buffer.byteLength(deviceToken, 'utf8') > 4096 ||
        !/^[A-Za-z0-9:_-]+$/.test(deviceToken) ||
        (action === 'register' &&
          !['android', 'ios', 'macOS'].includes(platform))) {
      res.status(400).send('Invalid device registration');
      return;
    }

    const db = getFirestore();
    try {
      const allowed = await consumeRateLimit(
        db,
        uid,
        'notification_device',
        10,
        50,
      );
      if (!allowed) {
        res.status(429).send('Too many device changes');
        return;
      }

      if (action === 'unregister') {
        await unregisterNotificationDevice(db, uid, deviceToken);
        res.status(204).end();
        return;
      }

      await registerNotificationDevice(db, uid, deviceToken, platform);
      res.status(204).end();
    } catch (error) {
      if (error.code === 'device-limit') {
        res.status(429).send(`Device limit reached (${MAX_DEVICES_PER_USER})`);
        return;
      }
      logger.error('Notification device update failed', { uid, error: error.message });
      res.status(500).send('Notification device update failed');
    }
  },
);

// The Cloudinary API secret stays in Secret Manager. The client receives a
// short-lived signature for a narrowly scoped, authenticated image upload.
exports.createCloudinaryUploadSignature = onRequest(
  {
    region: 'us-central1',
    cors: false,
    secrets: [cloudinaryApiSecret],
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.set('Allow', 'POST').status(405).send('Method not allowed');
      return;
    }
    if (!await requireAppCheck(req, res)) return;

    const token = (req.get('authorization') || '').match(/^Bearer (.+)$/)?.[1];
    if (!token) {
      res.status(401).send('Authentication required');
      return;
    }

    let uid;
    try {
      const decoded = await getAuth().verifyIdToken(token);
      if (decoded.email_verified !== true) {
        res.status(403).send('Verified email required');
        return;
      }
      uid = decoded.uid;
    } catch (error) {
      res.status(401).send('Invalid authentication token');
      return;
    }

    const db = getFirestore();
    try {
      const allowed = await consumeRateLimit(
        db,
        uid,
        'cloudinary_upload_signature',
        6,
        50,
      );
      if (!allowed) {
        res.status(429).send('Too many upload requests');
        return;
      }
    } catch (error) {
      logger.error('Cloudinary upload rate-limit check failed', {
        uid,
        error: error.message,
      });
      res.status(500).send('Upload authorization failed');
      return;
    }

    const { roomId, messageId, profile } = req.body || {};
    let folder;
    let publicId;
    if (profile === true && roomId == null && messageId == null) {
      folder = 'profile_images';
      publicId = `profile_${uid}_${crypto.randomUUID()}`;
    } else if (profile !== true && typeof roomId === 'string' &&
        /^[A-Za-z0-9_-]{1,256}$/.test(roomId) &&
        typeof messageId === 'string' && /^[A-Za-z0-9_-]{1,100}$/.test(messageId)) {
      const room = await getFirestore().collection('chat_rooms').doc(roomId).get();
      const participants = room.data()?.participants;
      if (!room.exists || !Array.isArray(participants) ||
          !participants.includes(uid) || participants.length !== 2) {
        res.status(403).send('Chat room access denied');
        return;
      }
      const otherUserId = participants.find((participant) => participant !== uid);
      if (typeof otherUserId !== 'string') {
        res.status(403).send('Chat room access denied');
        return;
      }
      const [callerProfile, otherProfile] = await Promise.all([
        getFirestore().collection('users').doc(uid).get(),
        getFirestore().collection('users').doc(otherUserId).get(),
      ]);
      if (!callerProfile.exists || !otherProfile.exists ||
          callerProfile.data().blockedUsers?.includes(otherUserId) ||
          otherProfile.data().blockedUsers?.includes(uid)) {
        res.status(403).send('Chat room access denied');
        return;
      }
      folder = `chat_images/${roomId}`;
      publicId = messageId;
    } else {
      res.status(400).send('Invalid upload request');
      return;
    }

    try {
      const timestamp = Math.floor(Date.now() / 1000);
      const params = {
        folder,
        public_id: publicId,
        timestamp,
        upload_preset: 'velora_mobile_signed',
        overwrite: false,
      };
      const signatureBase = Object.keys(params).sort()
        .map((key) => `${key}=${params[key]}`).join('&');
      const signature = crypto.createHash('sha256')
        .update(signatureBase + cloudinaryApiSecret.value())
        .digest('hex');
      res.status(200).json({
        apiKey: cloudinaryApiKey.value(),
        cloudName: cloudinaryCloudName.value(),
        folder,
        publicId,
        timestamp,
        signature,
      });
    } catch (error) {
      logger.error('Cloudinary upload signature failed', { uid, error: error.message });
      res.status(500).send('Upload authorization failed');
    }
  },
);
