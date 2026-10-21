const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');
const { getAppCheck } = require('firebase-admin/app-check');
const { defineSecret, defineString } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const crypto = require('node:crypto');

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
    if (!Array.isArray(phones) || phones.length > 250 ||
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

      const matches = [];
      const uniquePhones = [...new Set(phones)];
      for (let offset = 0; offset < uniquePhones.length; offset += 25) {
        const batch = uniquePhones.slice(offset, offset + 25);
        if (batch.length === 0) continue;
        const users = await db.collection('users')
          .where('phoneNumber', 'in', batch)
          .get();
        for (const userDoc of users.docs) {
          const user = userDoc.data();
          if (user.discoverability && user.discoverability !== 'phone_number') continue;
          const profile = {
            uid: userDoc.id,
            name: typeof user.name === 'string' ? user.name : 'Velora User',
            photoUrl: typeof user.photoUrl === 'string' ? user.photoUrl : '',
            about: typeof user.about === 'string' ? user.about : '',
            isOnline: user.isOnline === true,
            lastSeen: user.lastSeen || null,
            createdAt: user.createdAt || new Date(),
            updatedAt: user.updatedAt || new Date(),
            username: typeof user.username === 'string' ? user.username : null,
            bio: typeof user.bio === 'string' ? user.bio : null,
            discoverability: user.discoverability || 'phone_number',
            whoCanMessage: user.whoCanMessage || 'contacts_and_requests',
          };
          await db.collection('public_profiles').doc(userDoc.id).set(profile, { merge: true });
          matches.push({
            uid: userDoc.id,
            phoneNumber: user.phoneNumber,
            name: profile.name,
            photoUrl: profile.photoUrl,
            username: profile.username,
          });
        }
      }
      res.status(200).json(matches);
    } catch (error) {
      logger.error('Contact lookup failed', { uid, error: error.message });
      res.status(500).send('Contact lookup failed');
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
      uid = (await getAuth().verifyIdToken(token)).uid;
    } catch (error) {
      res.status(401).send('Invalid authentication token');
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
      if (!room.exists || !Array.isArray(room.data()?.participants) ||
          !room.data().participants.includes(uid)) {
        res.status(403).send('Chat room access denied');
        return;
      }
      folder = `chat_images/${roomId}`;
      publicId = messageId;
    } else {
      res.status(400).send('Invalid upload request');
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
