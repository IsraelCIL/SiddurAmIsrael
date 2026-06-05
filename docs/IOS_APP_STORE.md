# Publishing Siddur Am Israel to the Apple App Store (from Windows)

You are on Windows, and Apple's build/upload toolchain (Xcode) runs only on macOS.
This project therefore ships through **Codemagic**, a cloud CI that builds on macOS
machines, signs the app, and uploads it to App Store Connect — no Mac required.

The pipeline is defined in [`codemagic.yaml`](../codemagic.yaml).

---

## Prerequisites

- [x] Apple Developer Program membership (paid, $99/yr) — you have this.
- [x] Code hosted on GitHub (`github.com/IsraelCIL/SiddurAmIsrael`).
- [x] App icon at `assets/icon/app_icon.png` (1024×1024, opaque PNG) — generated from `smart-siddur.svg`.
- [ ] Screenshots (generated later from the running app — see the final section).

---

## One-time setup

### 1. Decide & lock the Bundle ID

The bundle identifier is **permanent** once registered and must be identical in three places:
- `codemagic.yaml` → `BUNDLE_ID` and `ios_signing.bundle_identifier`
- the App ID you register in the Apple Developer portal
- the app record in App Store Connect

Default in this repo: **`com.sidduramisrael.app`**. Change it everywhere if you prefer
another (e.g. `com.igintech.smartsiddur`). It does not need to match a domain you own.

### 2. Register the App ID

Apple Developer portal → <https://developer.apple.com/account> → **Certificates, IDs & Profiles**
→ **Identifiers** → **+** → **App IDs** → **App** →
- Description: `Siddur Am Israel`
- Bundle ID: **Explicit** → `com.sidduramisrael.app`
- Capabilities: leave all **off** (the app needs none).

> Codemagic can also auto-create this for you (`--create` flag in the signing step),
> but creating it manually first is clearer.

### 3. Create an App Store Connect API key

App Store Connect → <https://appstoreconnect.apple.com> → **Users and Access** →
**Integrations** tab → **App Store Connect API** → **+** →
- Access: **App Manager** (or Admin)
- **Generate**, then **Download** the `.p8` file (you can only download it once).
- Note the **Issuer ID** (top of the page) and the **Key ID** (next to your key).

### 4. Create the app record

App Store Connect → **Apps** → **+** → **New App** →
- Platform: **iOS**
- Name: `Siddur Am Israel` (must be unique across the whole App Store — adjust if taken)
- Primary language: **Hebrew**
- Bundle ID: select `com.sidduramisrael.app`
- SKU: any internal string, e.g. `smart-siddur-001`
- User access: Full Access

### 5. Connect Codemagic

1. Sign up at <https://codemagic.io> with your GitHub account.
2. **Add application** → pick `IsraelCIL/SiddurAmIsrael` → framework **Flutter**.
   Codemagic detects `codemagic.yaml` automatically.
3. Codemagic → **Teams/User settings → Integrations → App Store Connect → Connect**:
   - Name the integration **exactly** `SmartSiddur_ASC` (the YAML references this name).
   - Paste the **Issuer ID** and **Key ID**, upload the **`.p8`** file.

### 6. Push the deployment config

The icon (`assets/icon/app_icon.png`) and all CI config are already in the repo on the
`feature/ios-app-store-deployment` branch. Merge it to `main` (or your release branch)
and push so Codemagic can build it:

```powershell
git push -u origin feature/ios-app-store-deployment
# then open a PR and merge to main, or merge locally
```

---

## Build & upload

1. Codemagic → your app → **Start new build** → workflow **iOS — App Store** → **Start**.
2. The pipeline generates the iOS project, sets the bundle ID / Hebrew localization,
   adds the privacy manifest, generates icons & code, runs analyze + tests, signs,
   builds the `.ipa`, and uploads it to **TestFlight**.
3. First upload reaches App Store Connect → **TestFlight** after ~10–30 min of processing.

---

## Finish the store listing & submit for review

In App Store Connect → your app → **App Store** tab:

1. **Screenshots** — required sizes (use the iOS Simulator on Codemagic or a service,
   or capture from a friend's device):
   - 6.9" iPhone (1320×2868) **and** 6.5" iPhone (1242×2688) — at least one each.
   - 13" iPad (2064×2752) only if you mark the app iPad-compatible.
2. **Description, keywords, support URL, marketing info** (Hebrew + optionally English).
3. **App Privacy** → answer the questionnaire: **"Data Not Collected"** (matches the
   privacy manifest). No tracking.
4. **Age rating** questionnaire.
5. **Pricing** → Free (or your choice).
6. Under **Build**, select the build that came from TestFlight.
7. **Add for Review** → **Submit**.

Apple review typically takes 24–48 hours.

---

## Updating the app later

1. Bump the version in `pubspec.yaml` (e.g. `version: 1.0.1+2`).
2. `git commit` + `git push`.
3. Start a new Codemagic build. The build number auto-increments (`$BUILD_NUMBER`).
4. In App Store Connect, create a new version, select the new build, submit.

---

## Notes / troubleshooting

- **`flutter: 3.41.9` not found** → change it to `stable` in `codemagic.yaml`.
- **Bundle ID mismatch errors** → ensure `BUNDLE_ID`, `ios_signing.bundle_identifier`,
  the App ID, and the App Store Connect record all match.
- **`ITMS-91053` (missing API declaration) email** → the privacy manifest
  (`ci/PrivacyInfo.xcprivacy`) already covers UserDefaults; add any new required-reason
  API there if a new plugin needs one.
- **Build minutes** → the `Static analysis & tests` step is the slowest; remove it from
  `codemagic.yaml` once you trust the pipeline, to conserve free-tier minutes.
- The iOS project is generated fresh on every build, so there is **no `ios/` folder to
  commit** — all iOS config lives in `codemagic.yaml` + `ci/`.
