; Inno Setup script for the VM Distribution System (Windows / admin role)
;
; BUILD FIRST, then compile this:
;   flutter build windows --release --dart-define-from-file=secrets.json
;   (Inno Setup) File > Open this script > Build > Compile
;
; Output: installer\VMDistributionSetup-1.0.0.exe — one file to hand the client.
;
; OPEN THIS FILE FROM installer\, NOT a copy in Downloads. BuildDir below is
; relative to this script, so a copy elsewhere silently packages nothing and
; produces an installer that installs only an uninstaller.
;
; AppId is fixed. Windows uses it to tell an upgrade from a separate app, so
; never regenerate it — a new GUID makes the next release install alongside
; the old one instead of replacing it.
;
; PrivilegesRequired=lowest installs per-user under %LOCALAPPDATA%\Programs, so
; staff without administrator rights can install it and Windows never shows a
; UAC prompt. Change to "admin" with DefaultDirName={autopf}\... only if the
; client wants one shared install for every account on a machine.
;
; The local SQLite database lives in the user's Documents folder, NOT in the
; install directory, so uninstalling or reinstalling to upgrade does not touch
; local data or unsynced orders.

#define AppName        "VM Distribution System"
#define AppVersion     "1.0.0"
#define AppPublisher   "Villahermosa Marketing"
#define AppExeName     "villahermosa_inventory_system.exe"
#define BuildDir       "..\build\windows\x64\runner\Release"

[Setup]
AppId={{690807F2-B875-4E02-9DCF-35DBF4EDB1A7}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\Programs\VMDistribution
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=.
OutputBaseFilename=VMDistributionSetup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Points Add/Remove Programs at the right icon
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
; recursesubdirs + createallsubdirs is what carries data\ and flutter_assets\.
; Without it you ship the exe and DLLs only, and the app dies on launch.
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Registry]
; Registers io.supabase.villahermosa:// with Windows so the Google OAuth
; callback can come back INTO the app. Without this the browser signs the user
; in, redirects to a scheme Windows does not recognise, and the app never
; receives a session — which is why Google sign-in worked on Android (the
; scheme is declared in AndroidManifest.xml) but not here.
;
; HKCU, not HKCR: this is a per-user install, so the keys go under the current
; user and need no administrator rights. They are removed on uninstall.
;
; The redirect URL must ALSO be listed in the Supabase dashboard under
; Authentication > URL Configuration > Redirect URLs, or Supabase refuses the
; callback before Windows ever sees it.
Root: HKCU; Subkey: "Software\Classes\io.supabase.villahermosa"; ValueType: string; ValueName: ""; ValueData: "URL:VM Distribution System"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\io.supabase.villahermosa"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\io.supabase.villahermosa\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExeName},0"
Root: HKCU; Subkey: "Software\Classes\io.supabase.villahermosa\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Open {#AppName}"; Flags: nowait postinstall skipifsilent
