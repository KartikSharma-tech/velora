# Velora security setup

This file records the settings required before distributing a production build.
Firebase and Cloudinary changes are not deployed automatically from this repo.

## Firebase App Check

The mobile app initializes App Check with debug providers in debug builds and
Play Integrity / App Attest in release builds. The contact lookup and Cloudinary
signature HTTP functions reject requests without a valid App Check token.

1. In Firebase Console, register the Android app using the final Android
   application ID and configure Play Integrity. Register Apple apps before
   shipping iOS/macOS builds.
2. Run a debug build once, copy its App Check debug token from the device logs,
   and register that token under Firebase Console → App Check → Manage debug
   tokens. Never ship a debug token in the app.
3. Review App Check metrics before enabling enforcement for Firebase products.

## Cloudinary signed uploads

The Cloudinary API secret is read only by the `createCloudinaryUploadSignature`
Cloud Function. The app receives a signature for its own profile image or a
chat room where its authenticated account is a participant.

1. In Cloudinary, create a **signed** upload preset named
   `velora_mobile_signed`. Restrict it to image formats `jpg`, `jpeg`, `png`,
   and `webp`, with a maximum file size of 10 MB.
2. Set `CLOUDINARY_API_KEY` and `CLOUDINARY_CLOUD_NAME` in the project-specific
   Functions environment file (`functions/.env.<firebase-project-id>`).
   These values identify the Cloudinary account; do not put the API secret there.
3. Add the API secret to Firebase Secret Manager with
   `firebase functions:secrets:set CLOUDINARY_API_SECRET`.
4. Deploy the Functions only after verifying the Firebase project and the
   Cloudinary preset. Disable or delete the old unsigned `velora_chat` preset
   after the new client version is active.

Do not place the Cloudinary API secret in Dart code, Firebase client config,
`.env` files committed to Git, or screenshots/logs.

## Firestore and account protections

- `firestore.rules` is the deploy source; `lib/firestore.rules` is a checked-in
  duplicate and must remain byte-for-byte synchronized.
- Run `firebase emulators:exec --only auth,firestore --project demo-velora
  "npm --prefix functions run test:security"` before deploying rules.
- In Firebase Authentication settings, enable email enumeration protection,
  configure an appropriate password policy, and require verified email where
  account recovery or contact discovery depends on it.
- Restrict the Firebase/Google API key by application and API in Google Cloud.
  Firebase client API keys identify the project; they are not Admin SDK secrets.
- Keep Admin SDK service account keys out of the repository. Deployed Functions
  should use their attached service identity.

## Android release signing

Release builds no longer use the Android debug key by default. Create an upload
keystore outside source control, then create `android/key.properties` with:

```properties
storeFile=upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=velora
keyPassword=YOUR_KEY_PASSWORD
```

`android/key.properties` and `*.jks` are ignored by Git. Back up the keystore
and passwords securely; losing them can prevent updates to an already published
app. Without this file, Gradle produces an unsigned release artifact. The
`allowDebugReleaseSigning=true` Gradle property is only for local sideload
testing and must never be used for distribution.

## Remaining release review

- Replace the template Android application ID `com.example.velora` with the
  final unique ID and register that exact ID with Firebase and App Check.
- Deploy reviewed Firestore rules, indexes, and Functions to the intended
  Firebase project; no deployment is performed by this repository change.
- Confirm the signed preset limits and test upload, contact discovery, account
  recovery, and push notifications on a physical release-signed device.
