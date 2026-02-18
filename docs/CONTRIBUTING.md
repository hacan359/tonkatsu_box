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
