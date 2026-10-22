const crypto = require('node:crypto');
const { FieldValue } = require('firebase-admin/firestore');

const MAX_DEVICES_PER_USER = 5;

function notificationDeviceId(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

async function registerNotificationDevice(db, uid, token, platform) {
  const devices = db.collection('users').doc(uid).collection('devices');
  const deviceRef = devices.doc(notificationDeviceId(token));
  const legacyRef = Buffer.byteLength(token, 'utf8') <= 1400
    ? devices.doc(token)
    : null;

  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(deviceRef);
    const existingLegacy = legacyRef && legacyRef.path !== deviceRef.path
      ? await transaction.get(legacyRef)
      : null;
    if (!existing.exists) {
      const registeredDevices = await transaction.get(devices.limit(
        MAX_DEVICES_PER_USER + 1,
      ));
      const retainedCount = registeredDevices.docs.filter((device) =>
        device.ref.path !== deviceRef.path &&
        device.ref.path !== legacyRef?.path
      ).length;
      if (retainedCount >= MAX_DEVICES_PER_USER) {
        const error = new Error('Device limit reached');
        error.code = 'device-limit';
        throw error;
      }
    }
    if (existingLegacy?.exists) transaction.delete(legacyRef);
    transaction.set(deviceRef, {
      token,
      platform,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

async function unregisterNotificationDevice(db, uid, token) {
  const devices = db.collection('users').doc(uid).collection('devices');
  const deviceRef = devices.doc(notificationDeviceId(token));
  const legacyRef = Buffer.byteLength(token, 'utf8') <= 1400
    ? devices.doc(token)
    : null;
  await Promise.all([
    deviceRef.delete(),
    legacyRef && legacyRef.path !== deviceRef.path
      ? legacyRef.delete()
      : Promise.resolve(),
  ]);
}

module.exports = {
  MAX_DEVICES_PER_USER,
  notificationDeviceId,
  registerNotificationDevice,
  unregisterNotificationDevice,
};
