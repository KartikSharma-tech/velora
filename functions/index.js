const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
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
