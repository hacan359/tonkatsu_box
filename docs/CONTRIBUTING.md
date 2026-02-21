[← Back to README](../README.md)

# 🤝 Contributing

Thanks for your interest in contributing to Tonkatsu Box!

## Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest features
- 📖 Improve documentation
- 🔧 Submit pull requests

---

## Reporting Issues

Before creating an issue:
1. Check if it already exists
2. Include steps to reproduce
3. Include your OS version and app version

---

## Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Development Setup

> [!IMPORTANT]
> **Flutter SDK is installed on Windows only, not in WSL.** All Flutter commands must be executed through PowerShell:
>
> ```bash
> powershell.exe -Command "cd D:\CODE\xerabora; flutter pub get"
> powershell.exe -Command "cd D:\CODE\xerabora; flutter run -d windows"
> ```

```bash
git clone https://github.com/your-username/xerabora.git
cd xerabora  # repository name unchanged
```

Then in PowerShell (or via `powershell.exe`):

```powershell
cd D:\CODE\xerabora
flutter pub get
flutter run -d windows
```

---

## Android Release Builds

Debug builds (`flutter run` or `flutter build apk --debug`) work out of the box — no extra setup needed.

To build a **release** APK (`flutter build apk --release`), you need a signing keystore. Without it, the release build will fail. This is expected — only the maintainer's keystore produces APKs that can update existing installations.

### Creating your own keystore (for testing release builds)

1. **Generate a keystore** using `keytool` (bundled with Android Studio's JBR):

   ```bash
   keytool -genkey -v \
     -keystore my-debug-release.jks \
     -keyalg RSA \
     -keysize 2048 \
     -validity 10000 \
     -alias my-key \
     -storepass YOUR_PASSWORD \
     -keypass YOUR_PASSWORD \
     -dname "CN=Developer, O=Dev, C=US"
   ```

   > If `keytool` is not in your PATH, find it at:
   > `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`

2. **Create `android/key.properties`** (this file is git-ignored):

   ```properties
   storePassword=YOUR_PASSWORD
   keyPassword=YOUR_PASSWORD
   keyAlias=my-key
   storeFile=../../my-debug-release.jks
   ```

3. **Build:**

   ```bash
   flutter build apk --release
   ```

> [!NOTE]
> APKs signed with your personal keystore **cannot** be installed over the official release. Users will need to uninstall first. This is an Android security restriction — each signing key is treated as a different publisher.

---

## Code Style

> [!IMPORTANT]
> **Before every commit, ensure the following checks pass:**
>
> ```bash
> powershell.exe -Command "cd D:\CODE\xerabora; flutter analyze"
> powershell.exe -Command "cd D:\CODE\xerabora; flutter test"
> ```
>
> - `flutter analyze` must report **no issues** (warnings from third-party packages like `file_picker` are ignored)
> - `flutter test` must pass **all tests**

Key rules:

- Follow Flutter/Dart conventions
- **Strict typing** — no `dynamic`, no `var` for public API, always explicit types
- **Immutability** — use `final` and `const` wherever possible
- **Riverpod** for state management — no `setState` in complex widgets
- Keep commits focused and atomic
- Run `flutter analyze` before committing

---

## Questions?

Open a discussion or issue — happy to help!
