# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

SpoolerTag is a Flutter app (iOS, Android, Web, macOS) for reading/writing OpenSpool NFC 215 tags on 3D printer filament spools. It integrates with Spoolman and is designed for additional spool database providers.

Ported from the SpoolPainter Android/Kotlin app in `../SpoolPainter/`.

## Build & Test Commands

```bash
flutter pub get                          # Install dependencies
flutter analyze                          # Lint (must pass clean)
flutter test                             # Run all tests
flutter test test/models/                # Run a test directory
flutter test test/models/open_spool_data_test.dart  # Run a single test file
dart run build_runner build              # Regenerate json_serializable .g.dart files
flutter build apk --debug               # Android debug build
flutter build ipa --release --export-method development  # iOS IPA
flutter build web                        # Web build
flutter build macos                      # macOS build
```

## Architecture

**State management**: Riverpod (Notifier + StateProvider + FutureProvider). All providers in `lib/providers/`.

**Key abstractions**:
- `SpoolProvider` (`lib/data/spool_provider/spool_provider.dart`) — pluggable spool database interface. Only `SpoolmanProvider` exists today; designed for OctoPrint/Klipper additions.
- `NfcService` (`lib/services/nfc/nfc_service.dart`) — platform-agnostic NFC interface with platform-specific implementations resolved at compile time via conditional imports in `nfc_service_factory.dart`.

**NFC conditional import chain** (avoids importing `nfc_manager` on web):
```
nfc_service_factory.dart (export hub)
  → nfc_service_factory_io.dart    (dart.library.io → MobileNfcService)
  → nfc_service_factory_web.dart   (dart.library.js_interop → WebNfcService)
  → nfc_service_factory_stub.dart  (fallback → unsupported)
```

**Data flow**: Spoolman API → `SpoolmanSpool` (DTO) → `FilamentSpool` (domain) → `SpoolFormState` (UI) → `OpenSpoolData` (NFC/QR JSON).

## OpenSpool Protocol (Critical for NFC Compatibility)

The `OpenSpoolData.toJson()` output MUST produce byte-identical JSON to the Kotlin SpoolPainter app. Key rules:
- `color_hex`: always present, empty string `""` when null (not omitted)
- `bed_min_temp`, `bed_max_temp`, `spool_id`, `lot_nr`: completely **omitted** from JSON when null (not present as `null`)
- `subtype`: included when non-empty string, omitted when empty. Default `"Basic"` only applies when *reading* tags that lack the field
- `type` field uses `FilamentSpool.displayName` (e.g., `"PLA Silk"` not `"PLA"`)
- NDEF record format: TNF_MIME_MEDIA with type `application/json`, UTF-8 payload

## Temperature Mapping Logic

`FilamentSpool.fromSpoolman()` in `lib/models/filament_spool.dart` — if Spoolman's extruder temp falls within the material's default range (inclusive), use material defaults. If outside range, use Spoolman temp as min, +20 as max. Same for bed temps with +10 offset. This is ported exactly from SpoolPainter.

## Platform Notes

- **iOS**: Deployment target 15.5 (required by `mobile_scanner`). NFC sessions are modal (system dialog) — the 5-second "recent tag" cache only applies on Android.
- **Android**: `usesCleartextTraffic=true` for local HTTP Spoolman servers. NFC feature `required=false` (app works via QR fallback).
- **macOS**: No NFC. QR code fallback is primary. Network + camera entitlements configured.
- **Web**: Web NFC API via `dart:js_interop` (Chrome Android only). Falls back to QR on unsupported browsers.

## Testing Patterns

- Dio mocking: `MockHttpAdapter` implementing Dio's `HttpClientAdapter` (see `test/data/spoolman/`)
- NFC mocking: `MockNfcService` implementing `NfcService` interface
- Timer testing: `fakeAsync` for the 5-second `RecentTagNotifier` auto-clear
- Riverpod testing: `ProviderContainer()` with overrides
- SharedPreferences: `SharedPreferences.setMockInitialValues({})` in setUp

## Code Generation

Spoolman models (`lib/data/spool_provider/spoolman/spoolman_models.dart`) use `json_serializable`. After modifying `@JsonSerializable` classes, regenerate with `dart run build_runner build`. The `.g.dart` files are committed.
