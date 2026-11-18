import 'dart:io' show Platform, Process;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb, debugPrint;

/// Whether the "Sign in with Google" button should be offered here.
///
/// * Android: yes (native Google Sign-In; the redirect scheme is declared in
///   AndroidManifest.xml).
/// * Windows: only when the `io.supabase.villahermosa://` scheme is registered
///   in HKCU AND points at THIS exe. The installer writes that key; a
///   `flutter run` build, a zip copied from `build\`, or a moved install is not
///   registered (or registered to a different exe), and the browser would sign
///   the user in and then hand the callback to somewhere else — a button that
///   dead-ends. So it stays hidden there.
/// * Everything else: no (nothing registers the scheme).
Future<bool> googleSignInAvailable() async {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return true;
    case TargetPlatform.windows:
      return _windowsSchemeRegisteredToThisExe();
    default:
      return false;
  }
}

const _schemeCommandKey = r'HKCU\Software\Classes\io.supabase.villahermosa\shell\open\command';

Future<bool> _windowsSchemeRegisteredToThisExe() async {
  try {
    final result = await Process.run('reg', ['query', _schemeCommandKey, '/ve']);
    if (result.exitCode != 0) return false;
    return registryCommandPointsAt(result.stdout.toString(), Platform.resolvedExecutable);
  } catch (e) {
    debugPrint('Could not read the URL scheme registration: $e');
    return false;
  }
}

/// True if `reg query` output for the scheme's open command launches [exePath].
/// Case-insensitive, and tolerant of the `"exe" "%1"` quoting the installer writes.
bool registryCommandPointsAt(String regOutput, String exePath) =>
    regOutput.toLowerCase().contains(exePath.toLowerCase());
