; The Windows installer of Sora: the application, the core and its engines,
; and the core registered as the SoraCore service. Built in CI with Inno Setup 6
; from the repository root:
;   iscc /DAppVersion=0.3.0 packaging\windows\sora.iss
; after the app is built into app\build\windows\x64\runner\Release and the core
; and engines into dist\windows (see README.md).

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{3B2D9C61-7E44-4F0B-9A8E-5D1C4E7F2A90}
AppName=Sora
AppVersion={#AppVersion}
AppPublisher=Sora
AppPublisherURL=https://github.com/levvs-one/sora-client
AppSupportURL=https://github.com/levvs-one/sora-client
DefaultDirName={autopf}\Sora
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Flutter's Windows engine needs Windows 10 1809 or later; Windows 7 gets the
; legacy build.
MinVersion=10.0.17763
OutputDir=..\..\dist
OutputBaseFilename=Sora-Setup-{#AppVersion}-x64
SetupIconFile=..\..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\sora.exe
UninstallDisplayName=Sora
LicenseFile=..\..\LICENSE
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "..\..\dist\windows\sora-core.exe"; DestDir: "{app}\core"; Flags: ignoreversion
Source: "..\..\dist\windows\engines\*"; DestDir: "{app}\core\engines"; Flags: ignoreversion
Source: "..\..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\THIRD-PARTY-NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Sora"; Filename: "{app}\sora.exe"
Name: "{autodesktop}\Sora"; Filename: "{app}\sora.exe"; Tasks: desktopicon

[Run]
; The core registers itself, so the arguments are quoted by the core and not
; by this script; an earlier registration is updated in place.
Filename: "{app}\core\sora-core.exe"; Parameters: "-install-service -data-dir ""{commonappdata}\Sora"" -engines-dir ""{app}\core\engines"""; Flags: runhidden waituntilterminated; StatusMsg: "Sora core…"
Filename: "{app}\sora.exe"; Description: "{cm:LaunchProgram,Sora}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{app}\core\sora-core.exe"; Parameters: "-uninstall-service"; Flags: runhidden waituntilterminated; RunOnceId: "RemoveSoraCore"

[Code]
// An upgrade replaces the core while the service holds it open, so the
// service stops first; with no service installed this does nothing.
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Code: Integer;
begin
  Exec(ExpandConstant('{sys}\sc.exe'), 'stop SoraCore', '', SW_HIDE, ewWaitUntilTerminated, Code);
  Sleep(1500);
  Result := '';
end;
