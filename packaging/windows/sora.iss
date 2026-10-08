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
Compression=lzma2/ultra64
SolidCompression=yes
CloseApplications=yes
; One page and a button: the choices, Install, the progress, Open Sora. The
; place is Program Files, and an upgrade keeps where an earlier Sora went. The
; GPL asks for no acceptance, so there is no licence page; the text is
; installed next to the program.
DisableWelcomePage=yes
DisableDirPage=yes
DisableReadyPage=yes
; The language of Windows, without asking, where Sora speaks it.
ShowLanguageDialog=auto
; Windows 11 controls, light or dark as Windows is, on Sora's own ground: the
; Apple Intelligence glow along the top edge and nothing at the side.
WizardStyle=modern dynamic windows11 includetitlebar
WizardBackImageFile=art\back-light.png,art\back-light@2x.png
WizardBackImageFileDynamicDark=art\back-dark.png,art\back-dark@2x.png
WizardImageFile=
WizardSmallImageFile=
WizardImageFileDynamicDark=
WizardSmallImageFileDynamicDark=

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Messages]
ru.WizardSelectTasks=Sora
en.WizardSelectTasks=Sora
ru.SelectTasksDesc=Всё готово к установке
en.SelectTasksDesc=Ready to install
ru.SelectTasksLabel2=Sora встанет службой и будет жить в трее рядом с часами.
en.SelectTasksLabel2=Sora installs as a service and lives in the tray by the clock.
ru.FinishedHeadingLabel=Sora установлена
en.FinishedHeadingLabel=Sora is installed
ru.FinishedLabelNoIcons=Значок Sora в трее рядом с часами.
en.FinishedLabelNoIcons=Sora's icon is in the tray by the clock.
ru.FinishedLabel=Значок Sora в трее рядом с часами.
en.FinishedLabel=Sora's icon is in the tray by the clock.

[CustomMessages]
ru.HappLinks=Открывать в Sora ссылки happ:// от провайдеров
en.HappLinks=Open happ:// links from providers in Sora
ru.Links=Ссылки:
en.Links=Links:
ru.WebViewMissing=Для встроенной проверки скорости нужен Microsoft Edge WebView2 Runtime. Скачайте Evergreen Standalone Installer (x64) с https://developer.microsoft.com/microsoft-edge/webview2/ и установите его. До этого используйте кнопку "Открыть в браузере".
en.WebViewMissing=Embedded speed tests require Microsoft Edge WebView2 Runtime. Download and install the Evergreen Standalone Installer (x64) from https://developer.microsoft.com/microsoft-edge/webview2/. Until then, use "Open in browser".

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
; Only where nothing opens happ:// yet: Sora does not take the links of an
; installed Happ, and removing Sora then leaves Happ's registration alone.
Name: "happlinks"; Description: "{cm:HappLinks}"; GroupDescription: "{cm:Links}"; Check: HappLinksFree

[Registry]
; sora:// opens the import of a subscription in the running Sora.
Root: HKA; Subkey: "Software\Classes\sora"; ValueType: string; ValueData: "URL:Sora"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\sora"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\sora\DefaultIcon"; ValueType: string; ValueData: """{app}\sora.exe"",0"
Root: HKA; Subkey: "Software\Classes\sora\shell\open\command"; ValueType: string; ValueData: """{app}\sora.exe"" ""%1"""
Root: HKA; Subkey: "Software\Classes\happ"; ValueType: string; ValueData: "URL:Happ link"; Tasks: happlinks
Root: HKA; Subkey: "Software\Classes\happ"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: happlinks
Root: HKA; Subkey: "Software\Classes\happ\shell\open\command"; ValueType: string; ValueData: """{app}\sora.exe"" ""%1"""; Tasks: happlinks
; The app adds itself to the start with the system; removing Sora removes that
; entry rather than leave one pointing at nothing.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "io.github.levvs_one.sora"; Flags: uninsdeletevalue dontcreatekey

[Files]
Source: "..\..\app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "..\..\dist\windows\sora-core.exe"; DestDir: "{app}\core"; Flags: ignoreversion
Source: "..\..\dist\windows\engines\*"; DestDir: "{app}\core\engines"; Flags: ignoreversion
Source: "..\..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\THIRD-PARTY-NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\app\assets\fonts\Inter-LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion

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
// Evergreen can be installed for the machine or for the current user.
function WebViewRuntimePresent: Boolean;
var
  Version: String;
  Key: String;
begin
  Key := 'Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
  Result := RegQueryStringValue(HKLM32, Key, 'pv', Version) and
    (Version <> '') and (Version <> '0.0.0.0');
  if not Result then
    Result := RegQueryStringValue(HKCU, Key, 'pv', Version) and
      (Version <> '') and (Version <> '0.0.0.0');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and not WebViewRuntimePresent then
    if WizardSilent then
      Log(CustomMessage('WebViewMissing'))
    else
      MsgBox(CustomMessage('WebViewMissing'), mbInformation, MB_OK);
end;

// happ:// is free when nothing opens it, or when it is Sora's own from an
// earlier install.
function HappLinksFree: Boolean;
var
  Command: String;
begin
  Result := not RegKeyExists(HKEY_CLASSES_ROOT, 'happ');
  if not Result and RegQueryStringValue(HKEY_CLASSES_ROOT, 'happ\shell\open\command', '', Command) then
    Result := Pos(Lowercase(ExpandConstant('{app}\sora.exe')), Lowercase(Command)) > 0;
end;

// The page of choices is the last before the copying starts, so its button
// says what it does.
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpSelectTasks then
    WizardForm.NextButton.Caption := SetupMessage(msgButtonInstall);
end;

// Removing Sora removes happ:// only while it is still Sora's: if Happ took
// the links back since, its registration stays.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Command: String;
begin
  if (CurUninstallStep = usUninstall) and
     RegQueryStringValue(HKLM, 'Software\Classes\happ\shell\open\command', '', Command) and
     (Pos(Lowercase(ExpandConstant('{app}\sora.exe')), Lowercase(Command)) > 0) then
    RegDeleteKeyIncludingSubkeys(HKLM, 'Software\Classes\happ');
end;

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
