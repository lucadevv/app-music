# App Music

Production-grade music streaming app for **iOS & Android**, built with **Flutter**. Clean Architecture, BLoC state management, OAuth sign-in (Google & Apple), background audio playback and full offline mode.

## Features

- 🎵 Music streaming with background audio (`just_audio` + `audio_service`)
- 🔐 Sign-in with Google & Apple (JWT)
- 📴 Offline mode with Hive local database
- 🌐 Multi-language support (`flutter_localizations`)
- 🧭 Type-safe navigation with `auto_route`
- 🧪 Unit, bloc and integration tests (`mocktail`, `bloc_test`)

## Tech Stack

- **Flutter / Dart** — cross-platform mobile app
- **flutter_bloc** + `equatable`, `dartz`, `get_it` — Clean Architecture
- **Dio** — networking
- **Hive** — offline storage
- **just_audio / audio_service / audio_session** — audio playback
- **flutter_secure_storage** — token storage
- **cached_network_image**, `shimmer` — UI polish

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```
