# EvoChat 🔐

**A Secure, Offline P2P Messenger built with Flutter**

No internet. No servers. No accounts. Just encrypted messaging over local WiFi.

---

## Features

- ✅ **Fully Offline** — works on local WiFi only, no internet needed
- ✅ **End-to-End Encrypted** — AES-256-CBC with random IV per message
- ✅ **P2P Discovery** — auto-discovers peers using mDNS (Bonsoir)
- ✅ **Persistent Storage** — messages saved locally with SQLite
- ✅ **Beautiful Dark UI** — modern, polished interface
- ✅ **Message Status** — sending / sent / failed indicators
- ✅ **No Registration** — just enter a name and start chatting

---

## Build Instructions

### Requirements
- Flutter SDK 3.x ([install here](https://flutter.dev/docs/get-started/install))
- Android Studio + Android SDK
- Java 11+

### Steps

```bash
# 1. Navigate to project folder
cd evochat

# 2. Install dependencies
flutter pub get

# 3. Build debug APK (for testing)
flutter build apk --debug

# 4. Build release APK (for distribution)
flutter build apk --release

# APK output location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Run on device directly
```bash
flutter run
```

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme.dart                   # Colors & theme
├── models/
│   └── models.dart              # User, Message, Peer models
├── services/
│   ├── mesh_service.dart        # P2P networking (mDNS + TCP)
│   ├── database_service.dart    # SQLite persistence
│   └── encryption_service.dart # AES-256 encryption
└── screens/
    ├── setup_screen.dart        # First-launch name setup
    ├── home_screen.dart         # Peer discovery list
    └── chat_screen.dart         # Chat interface
```

---

## How It Works

1. On launch, user sets a display name (saved locally)
2. App starts broadcasting its presence over mDNS on port 4545
3. When scanning, app discovers other EvoChat users on the same WiFi
4. Messages are AES-256-CBC encrypted before sending over TCP
5. All messages stored in local SQLite database

---

## Security Notes

- The AES key is currently hardcoded — for production, generate a unique key per device pair
- Uses random IV per message (fixed from original)
- Consider adding key exchange (Diffie-Hellman) for production use

---

## Using Codemagic (Online Build — No Setup Needed)

Your project includes `codemagic.yaml`. Just:
1. Go to [codemagic.io](https://codemagic.io)
2. Upload this project or connect your GitHub repo
3. Trigger a build → download your APK
