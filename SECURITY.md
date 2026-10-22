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
   For Web, register the Firebase Web app with reCAPTCHA v3 and build with
   `--dart-define=VELORA_APP_CHECK_WEB_SITE_KEY=<site-key>`.
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

- `firestore.rules` is the single checked-in deploy and emulator-test source.
  Manage production rules in Firebase Console or deploy this reviewed source;
  do not keep a second copy under `lib/`.
- New chat rooms enforce the recipient's messaging preference. Contact matches
  use a server-written UID index that is private to rules and expires after 24
  hours; clients cannot read or edit it. The lookup endpoint includes only
  accounts with a verified Firebase phone number matching the profile number.
- FCM device tokens are no longer client-writable/readable in Firestore.
  `manageNotificationDevice` requires App Check and Firebase Auth, rate-limits
  registration changes, caps accounts at five devices, and stores tokens under
  hashed document IDs. Existing token-ID documents migrate when that device
  next registers or unregisters.
- Cloudinary signature requests are rate-limited before room/profile reads.
- Signup now links a verified phone credential to the email account. Enable
  Firebase Phone Authentication and set SMS region policy before release.
  Firestore access requires a verified email. Signup sends the verification
  email and signs out; first verified login creates the initial user profiles.
  Existing mobile accounts can link and sync a verified number under Settings;
  the user must verify email first. Web signup does not link a phone number, so
  web accounts are not contact-discoverable unless linked in the mobile app.
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
keystore outside source control with the interactive prompt (do not add
passwords to this command):

```powershell
keytool -genkeypair -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias velora
```

Then create `android/key.properties` with:

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
testing and must never be used for distribution. To create that local test APK,
run `cd android; .\gradlew.bat assembleRelease -PallowDebugReleaseSigning=true`;
it is written to `build/app/outputs/apk/release/app-release.apk`.

## Remaining release review

- Replace the template Android application ID `com.example.velora` with the
  final unique ID and register that exact ID with Firebase and App Check.
- Deploy reviewed Firestore rules, indexes, and Functions to the intended
  Firebase project; no deployment is performed by this repository change.
- Confirm the signed preset limits and test upload, contact discovery, account
  recovery, and push notifications on a physical release-signed device.
- Account deletion is not implemented end-to-end. Define whether messages in
  other users' chat history are retained, then delete Auth, profile, contact,
  device-token, and applicable chat data consistently before offering deletion.
