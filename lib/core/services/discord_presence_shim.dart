// Conditional facade over dart_discord_presence: the package pulls dart:ffi
// (win32 pipes), which the web compile cannot even import.
export 'discord_presence_shim_io.dart'
    if (dart.library.js_interop) 'discord_presence_shim_web.dart';
