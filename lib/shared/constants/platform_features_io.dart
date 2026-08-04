// Platform detection for every target that has dart:io (native, and tests).
import 'dart:io' show Platform;

const bool isWeb = false;

bool get isWindows => Platform.isWindows;

bool get isLinux => Platform.isLinux;

bool get isMacOS => Platform.isMacOS;

bool get isAndroid => Platform.isAndroid;

bool get isIOS => Platform.isIOS;
