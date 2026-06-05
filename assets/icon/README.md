# App Icon

Place your app icon here as:

```
assets/icon/app_icon.png
```

## Requirements (Apple)

| Requirement | Value |
|---|---|
| File name | `app_icon.png` |
| Size | **1024 × 1024 px** (square) |
| Format | PNG |
| Transparency | **None** — must be fully opaque. The build flattens alpha (`remove_alpha_ios: true`), but provide an opaque PNG to be safe. |
| Corners | Square (do **not** pre-round; iOS rounds them automatically) |

The CI pipeline runs `dart run flutter_launcher_icons` (configured in `pubspec.yaml`)
to generate every required iOS icon size from this single source image.

> Commit `app_icon.png` to the repo — the cloud build reads it from here.
