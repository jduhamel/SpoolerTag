# SpoolerTag

SpoolerTag is a Flutter app for reading and writing OpenSpool NFC 215 tags used on 3D printer filament spools. It integrates with Spoolman, supports QR-code fallback flows, and is structured to support additional spool database providers later.

The project targets iOS, Android, Web, and macOS. It was ported from the Kotlin-based `SpoolPainter` app in `../SpoolPainter/`.

## Acknowledgements

This project is based on [`ni4223/SpoolPainter`](https://github.com/ni4223/SpoolPainter).

## Features

- Read OpenSpool data from NFC tags
- Write OpenSpool-compatible JSON to NFC 215 tags
- Preview the exact JSON payload before writing
- Generate and scan QR codes as a fallback where NFC is unavailable
- Load spool data from Spoolman and map it into the app's form model
- Persist local settings such as provider type, server URL, and spool sort order

## Platform Support

| Platform | Support |
| --- | --- |
| Android | NFC + QR |
| iOS | NFC + QR |
| Web | Web NFC on supported browsers, otherwise QR fallback |
| macOS | QR fallback only |

Notes:

- iOS uses modal NFC sessions. The 5-second recent-tag cache behavior only applies on Android.
- Android allows cleartext HTTP for local Spoolman servers.
- Web NFC currently depends on browser support and is mainly relevant on Chrome for Android.

## Getting Started

### Requirements

- Flutter SDK compatible with Dart `^3.11.4`
- Xcode for iOS/macOS builds
- Android Studio or Android SDK tools for Android builds

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Configure Spoolman

Open the Settings screen in the app and set:

- `Spool Provider Type`: currently `Spoolman`
- `Server URL`: your Spoolman instance URL
- `Sort Order`: optional spool ordering

The default Spoolman URL seed is `http://192.168.1.` for local-network setups.

## Development Commands

```bash
flutter analyze
flutter test
flutter test test/models/
flutter test test/models/open_spool_data_test.dart
dart run build_runner build
flutter build apk --debug
flutter build ipa --release --export-method development
flutter build web
flutter build macos
```

## Architecture

### State Management

The app uses Riverpod with `Notifier`, `StateProvider`, and `FutureProvider`. Providers live under `lib/providers/`.

### Main abstractions

- `SpoolProvider`: pluggable interface for spool database backends
- `SpoolmanProvider`: current provider implementation
- `NfcService`: platform-agnostic NFC interface

### NFC platform resolution

Conditional imports keep mobile NFC dependencies out of unsupported targets:

```text
nfc_service_factory.dart
  -> nfc_service_factory_io.dart
  -> nfc_service_factory_web.dart
  -> nfc_service_factory_stub.dart
```

### Data flow

```text
Spoolman API
  -> SpoolmanSpool
  -> FilamentSpool
  -> SpoolFormState
  -> OpenSpoolData
  -> NFC / QR payload
```

## OpenSpool Compatibility

OpenSpool compatibility is strict. `OpenSpoolData.toJson()` must remain byte-identical to the Kotlin `SpoolPainter` output.

Important rules:

- `color_hex` must always be present and must be `""` when no value exists
- `bed_min_temp`, `bed_max_temp`, `spool_id`, and `lot_nr` must be omitted entirely when null
- `subtype` is included only when it is non-empty
- the `type` field must use `FilamentSpool.displayName`
- NFC writes use an NDEF MIME media record with type `application/json` and UTF-8 payload

If you change the OpenSpool models or JSON serialization, verify compatibility carefully before shipping.

## Temperature Mapping

`FilamentSpool.fromSpoolman()` preserves the temperature behavior from `SpoolPainter`:

- if Spoolman extruder temperature falls within the material default range, the material defaults win
- otherwise the Spoolman extruder temperature becomes min and max is `min + 20`
- bed temperature follows the same rule, with `max = min + 10`

## Testing Notes

- Dio API tests use a custom `MockHttpAdapter`
- NFC tests mock the `NfcService` interface
- timer-based behavior uses `fakeAsync`
- Riverpod tests use `ProviderContainer()` overrides
- SharedPreferences tests initialize mock values in setup

## Code Generation

Spoolman DTOs use `json_serializable`. After editing annotated model classes, regenerate committed outputs with:

```bash
dart run build_runner build
```

## Repository Layout

```text
lib/
  core/                  App constants and theme
  data/                  Local persistence and spool-provider integrations
  models/                Domain and protocol models
  providers/             Riverpod state
  services/              NFC and QR services
  ui/                    Screens and widgets
test/
  core/
  data/
  integration/
  models/
  providers/
  services/
  ui/
```

## License

See [LICENSE](LICENSE).
