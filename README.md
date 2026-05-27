# Smart Siddur

An **offline-first Orthodox Halachic siddur** built with Flutter. Prayer texts are bundled as versioned JSON assets; no network connection is required at runtime. The app automatically selects the correct prayer, text variants, and halachic additions for the current date, time of day, and user profile.

---

## Table of Contents

1. [Features](#features)
2. [Architecture Overview](#architecture-overview)
3. [Core State Pipeline](#core-state-pipeline)
4. [JSON Data Model](#json-data-model)
5. [Project Structure](#project-structure)
6. [Getting Started](#getting-started)
7. [Code Generation](#code-generation)
8. [Running Tests](#running-tests)
9. [Halachic Standard](#halachic-standard)
10. [App Store Deployment](#app-store-deployment)
11. [Adding New Content](#adding-new-prayers--content)

---

## Features

- **Three nusachim**: Ashkenaz, Sfard, Edot HaMizrach
- **Three daily services**: Shacharit, Mincha, Maariv — auto-selected by halachic zmanim
- **Full halachic calendar**: Shabbat, Yom Tov, Chol HaMoed, Rosh Chodesh, Chanukah, Purim, fast days, Sefirat HaOmer, Sukkot (hoshanot, daily korban), Kriat HaTorah (Mon/Thu, RC, CHM, Chanukah, Purim, fast days)
- **User settings** (persisted across sessions): nusach, gender, Israel/diaspora, minyan/individual, Purim date
- **In-prayer navigation panel**: jump-to-section within each service
- **Adjustable font size** with one-tap FAB controls

---

## Architecture Overview

The codebase follows **Clean Architecture** with strict three-layer separation. No layer may import from a higher layer.

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│  Flutter widgets · Riverpod providers        │
│  lib/presentation/                           │
│  • No business logic                         │
│  • Reads assembled segments via providers    │
├─────────────────────────────────────────────┤
│               Domain Layer                   │
│  Entities · Repository interfaces            │
│  Services · Post-processors                  │
│  lib/domain/                                 │
│  • Pure Dart — no Flutter, no JSON parsing   │
│  • All halachic logic lives here             │
├─────────────────────────────────────────────┤
│                Data Layer                    │
│  Datasources · Repository implementations   │
│  lib/data/                                   │
│  • JSON parsing, SharedPreferences I/O       │
│  • Asset bundle access only                  │
└─────────────────────────────────────────────┘
               ↑ assets/prayers/ ↑
     572 JSON files, fully bundled offline
```

### Key Design Decisions

| Decision | Rationale |
|---|---|
| Offline-first JSON assets | Guarantees correct text in shuls worldwide without connectivity |
| Riverpod for state | Compile-safe, composable, testable without `BuildContext` |
| `freezed` + `json_serializable` | Immutable domain entities; eliminates mutation bugs |
| `kosher_dart` for zmanim | Battle-tested Hebrew calendar and zmanim engine |
| Per-nusach manifest lookup | A single segment ID resolves to the correct file for the active nusach |

---

## Core State Pipeline

This is the central data flow that drives every prayer screen:

```
DateTime.now()  +  UserSettings (nusach, gender, Israel, …)
        │
        ▼
┌────────────────────────────┐
│  HalachicCalendarService   │  lib/domain/services/halachic_calendar_service.dart
│  .flagsFor(date, context)  │
└───────────┬────────────────┘
            │  DayFlags
            │  (Set<String> flag tokens + int? omerDay / sukkotDay / chanukahDay / …)
            ▼
┌────────────────────────────┐
│       UserContext          │  lib/domain/entities/user_context.dart
│  (nusach + activeFlags     │  Assembled in prayer_providers.dart → userContextProvider
│   + day-specific ints)     │
└───────────┬────────────────┘
            │
            ▼
┌────────────────────────────┐
│      PrayerAssembler       │  lib/domain/services/prayer_assembler.dart
│  .assemble(templateId,     │
│            userContext)    │
└───────────┬────────────────┘
            │  List<AssembledSegment>
            │  (resolved Hebrew text · optional · groupId)
            ▼
┌────────────────────────────┐
│     PrayerScreen widget    │  lib/presentation/pages/prayers/prayer_screen.dart
│  (renders segments,        │
│   accordion groups,        │
│   navigation panel)        │
└────────────────────────────┘
```

### Flag System

`HalachicCalendarService` emits string flag tokens (e.g. `"skip_tachanun"`, `"rosh_chodesh"`, `"omer_period"`) into `DayFlags.flags`. These merge into `UserContext.activeFlags` and serve as a **condition/exclude gate** in two places:

- **Template entries** — `condition_flags` / `exclude_flags` determine which segments appear
- **Segment sections** — the same fields control which text variant renders within a segment

Every flag constant lives in `DayFlag` (`lib/domain/entities/day_flags.dart`) — the single source of truth referenced by both Dart code and JSON assets.

### Post-Processors

After assembly, specialized post-processors inject dynamic content:

| Post-Processor | Trigger | What it injects |
|---|---|---|
| `OmerPostProcessor` | `omerDay != null` | Fills `{{omer_day_count}}` and `{{omer_sefira}}`; bolds the day's word in Lamenatzeach and Ana BeKoach |
| `SukkotKorbanotPostProcessor` | `sukkotDay != null` | Fills `{{daily_korban}}` with the correct Numbers 29 pasuk |
| Kriah resolver | `upcomingParshah != null` | Loads Mon/Thu Torah reading text |
| RC Tevet composite | `rc_tevet` flag | Merges RC olim 1–3 + Chanukah day-N as oleh 4 |
| GraSsy resolver | `chagYt1Weekday != null` | Loads the Gr"a Shir Shel Yom chapter for CHM Pesach/Sukkot |

---

## JSON Data Model

### Asset Manifest — `assets/prayers/_manifest.json`

Three top-level keys: `common` (nusach-agnostic segments), `nusach` (per-nusach overrides), and `templates`.

```json
{
  "common": {
    "hallel": "assets/prayers/shacharit/acharei_amidah/common/hallel.json"
  },
  "nusach": {
    "ashkenaz":     { "kedushah": "…/ashkenaz/kedushah.json" },
    "sfard":        { "kedushah": "…/sfard/kedushah.json"    },
    "edot_mizrach": { "kedushah": "…/edot_mizrach/kedushah.json" }
  }
}
```

Lookup order: nusach-specific entry → `common` fallback.

### Prayer Template

```json
{
  "id": "shacharit_ashkenaz",
  "name": "shacharit_ashkenaz",
  "segments": [
    {
      "segment_id": "baruch_sheamar",
      "condition_flags": [],
      "exclude_flags": [],
      "optional": false,
      "allowed_nusach": []
    },
    {
      "sub_template_id": "tachanun_ashkenaz",
      "condition_flags": [],
      "exclude_flags": ["skip_tachanun"]
    }
  ]
}
```

| Field | Type | Meaning |
|---|---|---|
| `segment_id` | string | Leaf segment — load from manifest and render |
| `sub_template_id` | string | Expand a nested template recursively |
| `condition_flags` | string[] | ALL must be in `activeFlags` for this entry to appear |
| `exclude_flags` | string[] | ANY match causes the entry to be skipped |
| `allowed_nusach` | string[] | If non-empty, restricts to listed nusachim |
| `optional` | bool | Renders as a collapsed accordion the user can expand |

### Prayer Segment

```json
{
  "id": "amidah_avot",
  "sections": [
    {
      "text": [
        "בָּרוּךְ אַתָּה יְהֹוָה אֱלֹהֵינוּ",
        "וֵאלֹהֵי אֲבוֹתֵינוּ"
      ],
      "condition_flags": [],
      "exclude_flags": ["hamelech_hakadosh"]
    },
    {
      "text": "הַמֶּלֶךְ הַקָּדוֹשׁ",
      "condition_flags": ["hamelech_hakadosh"],
      "exclude_flags": []
    }
  ]
}
```

- **`text`**: `String` or `List<String>`. Arrays are joined with `" "` at runtime. **Texts longer than ~80 characters must use the array form**, split at natural phrase boundaries (CLAUDE.md rule).
- **Sections** are filtered by `condition_flags`/`exclude_flags` and concatenated with `\n`.
- **Bold syntax**: `<b>word</b>` — used by post-processors; rendered by `RichPrayerText`.

---

## Project Structure

```
smart_siddur/
├── assets/prayers/               # 572 JSON prayer asset files
│   ├── _manifest.json            # Central segment-ID → path registry
│   ├── templates/                # 42 prayer templates (nested)
│   │   ├── shacharit/            # One template per service-section per nusach
│   │   ├── maariv_ashkenaz.json
│   │   └── …
│   ├── shared_global/            # Amidah blessings, Kaddish, shared segments
│   ├── shacharit/                # Shacharit-specific segments by section
│   ├── mincha/
│   ├── maariv/
│   └── musaf/
│
├── lib/
│   ├── core/
│   │   ├── calendar/             # HebrewDate value object
│   │   └── utils/                # HebrewFormatter (display strings)
│   ├── data/
│   │   ├── datasources/local/    # Asset bundle + SharedPreferences datasources
│   │   └── repositories/         # Concrete repository implementations
│   ├── domain/
│   │   ├── entities/             # Freezed immutable models (+ generated .freezed.dart/.g.dart)
│   │   ├── repositories/         # Abstract interfaces (I*.dart)
│   │   └── services/             # HalachicCalendarService · PrayerAssembler · post-processors
│   └── presentation/
│       ├── constants/            # segment_labels.dart — Hebrew UI labels per segment ID
│       ├── pages/                # PrayerScreen (shared) · Shacharit/Mincha/Maariv · Settings
│       ├── providers/            # prayer_providers.dart — all Riverpod providers
│       ├── theme/                # AppColors · AppDimens — design token constants
│       └── widgets/              # PrayerTextWidget · HalachicHeader · FontSizeFab · …
│
├── test/
│   ├── domain/                   # HalachicCalendarService · assembler · post-processors
│   └── presentation/             # Provider reactivity · widget rendering
│
├── pubspec.yaml
├── CLAUDE.md                     # Development rules for AI-assisted and human contributors
└── README.md                     # This file
```

---

## Getting Started

### Prerequisites

| Tool | Required Version |
|---|---|
| Flutter | 3.41.9 (stable) |
| Dart | 3.11.5 |
| Xcode | 16+ (for iOS builds) |
| Android SDK | API 21+ (minSdkVersion) |

### Install

```bash
git clone <repo-url>
cd smart-siddur
flutter pub get
```

### Run (development)

```bash
flutter run
```

A debug overlay (🛠 button) is available in debug builds with presets for every testable halachic scenario: Chanukah, Sukkot, Purim, Rosh Chodesh, fast days, Sefirat HaOmer, etc.

---

## Code Generation

The project uses `freezed` (immutable models) and `json_serializable` (JSON deserialization). **Run this command whenever you modify any entity in `lib/domain/entities/`:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode for active development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

Generated files (`*.freezed.dart`, `*.g.dart`) are committed to source control and must always be in sync with their source files before submitting a PR.

---

## Running Tests

```bash
# Full suite — 200 tests across 11 files
flutter test

# Verbose output showing each test name
flutter test --reporter=expanded

# Single file
flutter test test/domain/halachic_calendar_service_test.dart

# Static analysis — target: 0 errors, 0 warnings
flutter analyze
```

### Test matrix

| File | Coverage |
|---|---|
| `halachic_calendar_service_test.dart` | Flag emission for every halachic scenario (RC, YT, CHM, Chanukah, Purim, fasts, Omer, BaHaB, seasons) |
| `prayer_assembler_test.dart` | Template assembly, condition/exclude gates, sub-template recursion |
| `prayer_assembler_mincha_test.dart` | Mincha-specific flow (Tisha B'Av, Nachem) |
| `omer_post_processor_test.dart` | `{{omer_day_count}}` substitution, Lamenatzeach/Ana BeKoach bold highlighting |
| `sukkot_korbanot_post_processor_test.dart` | `{{daily_korban}}` injection per day |
| `service_time_resolver_test.dart` | Zmanim-based service auto-selection |
| `prayer_providers_test.dart` | Riverpod provider reactivity, persistence round-trips |
| `settings_repository_test.dart` | SharedPreferences read/write |
| `rich_prayer_text_test.dart` | `<b>…</b>` span parsing |
| `hebrew_formatter_test.dart` | Hebrew date/nusach display strings |

---

## Halachic Standard

This application is a **strictly Orthodox Halachic siddur**. See `CLAUDE.md` for the complete halachic constraints. Key points for all contributors:

- Only mainstream Orthodox Halachic practice is represented. Reform, Conservative, Egalitarian, or Liberal variants are forbidden in any part of the codebase (source, JSON, comments, tests, docs).
- Every flag constant in `DayFlag` is documented with its Halachic basis and source.
- Gender-specific variants require a cited posek from mainstream Orthodox halacha before implementation.
- The only supported prayer services are Shacharit, Mincha, and Maariv. Kabbalat Shabbat and Musaf Yom Tov/Shabbat are out of scope for the current version.

---

## App Store Deployment

### Pre-submission checklist

```bash
# 1. Regenerate all code-gen artifacts from source
dart run build_runner build --delete-conflicting-outputs

# 2. Full test suite must pass with zero failures
flutter test

# 3. Analyzer must report zero errors and zero warnings
flutter analyze

# 4. Bump version in pubspec.yaml (format: major.minor.patch+buildNumber)
#    Example: version: 1.0.1+2
```

### iOS — Apple App Store

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode → Product → Archive → Distribute App → App Store Connect.

**Notes for first submission:**
- Confirm Bundle ID in `ios/Runner.xcodeproj` matches the App Store Connect entry.
- The app requires **no special entitlements**: no push notifications, no background modes, no camera, no microphone, no location.
- The app does **not** collect or transmit any user data. The privacy manifest (`PrivacyInfo.xcprivacy`) should reflect zero data collection.
- Hebrew RTL is configured via `flutter_localizations` with `Locale('he')`. No additional localisation work is needed.

### Android — Google Play

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to the Play Console.

---

## Adding New Prayers / Content

1. **Create segment JSON** in the appropriate `assets/prayers/…/nusach/<nusach>/` folder.
2. **Register the segment** in `assets/prayers/_manifest.json` under the correct nusach key.
3. **Add to a template** (`assets/prayers/templates/…`) with appropriate `condition_flags` / `exclude_flags`.
4. **Declare the asset directory** in `pubspec.yaml` under `flutter.assets` if it is a new folder.
5. **Add a label** in `lib/presentation/constants/segment_labels.dart` (empty string = no visible section header).
6. Run `flutter test` to verify no regressions.

Refer to `CLAUDE.md` for the mandatory JSON text formatting rules (texts over ~80 characters must use array form, split at natural phrase/cantillation-pause boundaries).
