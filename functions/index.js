const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');
const { logger } = require('firebase-functions');

initializeApp();

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
    const now = Date.now();
    const rateRef = db.collection('_server_rate_limits')
      .doc('contact_lookup').collection('users').doc(uid);
    try {
      const allowed = await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(rateRef);
        const data = snapshot.data() || {};
        const startedAt = typeof data.startedAt === 'number' ? data.startedAt : 0;
        const count = now - startedAt < 60_000 ? (data.count || 0) : 0;
        if (count >= 20) return false;
        transaction.set(rateRef, {
          startedAt: count === 0 ? now : startedAt,
          count: count + 1,
        });
        return true;
      });
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