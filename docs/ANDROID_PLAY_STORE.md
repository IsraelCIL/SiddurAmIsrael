# Android — Google Play deployment

Companion to [IOS_APP_STORE.md](IOS_APP_STORE.md). The app builds for Android from
the committed `android/` project. Package id: **`com.sidduramisrael.app`** (matches iOS).

## Signing — the upload keystore

A release build must be signed with an **upload keystore** (Play App Signing then
re-signs with Google's managed app key). The keystore was generated at:

```
android/app/upload-keystore.jks      ← NEVER commit this (gitignored)
android/key.properties               ← NEVER commit this (gitignored) — holds the passwords
```

- Alias: `upload`
- The store/key password is in your local `android/key.properties`.
- **Back up both files + the password in a password manager.** If you lose the
  upload key you must request a reset from Google (possible with Play App Signing,
  but slow); without Play App Signing it would mean you can never update the app.

`android/app/build.gradle.kts` reads `key.properties` for **local** release builds,
and falls back to Codemagic's `CM_KEYSTORE_*` environment variables for **CI** builds.
If neither is present, it signs with the debug key so `flutter run --release` still works.

## Building

### Local (needs Android SDK + JDK 17)
```bash
flutter build appbundle --release      # → build/app/outputs/bundle/release/app-release.aab
```

### Codemagic (recommended — same as iOS, builds from Windows)
1. Codemagic → **Code signing identities → Android keystores** → upload
   `android/app/upload-keystore.jks`. Reference name **must** be
   `siddur_upload_keystore` (the `codemagic.yaml` Android workflow expects it).
   Enter the store password, key alias `upload`, and key password.
2. Run the **"Android — Google Play"** workflow on `main`.
3. Download the `.aab` artifact from the build.

## Google Play Console (one-time)

1. Create a Play Developer account — **$25 one-time** (play.google.com/console).
2. Create the app → package name `com.sidduramisrael.app`.
3. Store listing:
   - App icon 512×512, **feature graphic 1024×500**, phone screenshots (reuse the
     ones in `screenshot/appstore/` — Android accepts a range of sizes).
   - Title / short / full description — copy in [app-store-listing.md](app-store-listing.md).
4. **Data safety** form → declare *no data collected* (same as Apple).
5. **Privacy policy URL** → host [privacy-policy.html](privacy-policy.html) (GitHub Pages works).
6. **Content rating** questionnaire → rates "Everyone".
7. First release: upload the `.aab` **manually** to the Internal testing or
   Production track. After that, you can optionally enable auto-publishing via a
   service-account JSON (see the commented `google_play:` block in `codemagic.yaml`).

## Notes
- The app requests `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` **only** for
  on-device zmanim (sunrise/sunset/candle-lighting). Nothing is stored or transmitted —
  reflect this in the Data safety form (location used, not collected/shared).
- No other runtime permissions; fully offline.
