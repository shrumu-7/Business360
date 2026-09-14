# Business360 Trial v48 — Stable All Fixes

This package is the **Business360** Android/WebView source for the trial build.

## Fixed in v48
- Top-left ☰ menu uses a direct mobile-safe handler.
- Bottom navigation and side navigation use one delegated handler.
- Dashboard arrange mode shows all 10 dashboard cards.
- Mobile touch drag-and-drop reliably detects the card underneath the finger.
- Drag target is highlighted and saved immediately.
- Arrow controls and drag-and-drop share the same saved dashboard order.
- Existing dashboard card names, including **স্টক মূল্য**, are preserved.
- App initializes the data store before first dashboard render.
- Service-worker cache version bumped to v48.
- Android versionCode is 11 / versionName 1.1.0-trial-stable-all-fixes.
- Persistent `business360-debug.keystore` remains included so future debug builds keep the same signing key.

## GitHub Actions
The active workflow is `.github/workflows/build-apk.yml`. GitHub only discovers workflow YAML files from `.github/workflows` in the repository; the ZIP itself is not a workflow trigger. The workflow therefore builds the repository source directly and verifies the Business360 package/version before Gradle runs.

Artifact name: `Business360-Trial-v48-APK`
