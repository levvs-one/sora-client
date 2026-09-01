#define MyAppName "Sora"
#define MyAppVersion "0.2.3"
#ifndef WindowsTarget
  #define WindowsTarget "win7"
#endif
#ifndef WindowsDisplayName
  #define WindowsDisplayName "Windows 7 SP1"
#endif
#ifndef MinimumWindowsVersion
  #define MinimumWindowsVersion "6.1sp1"
#endif
#define MyAppExeName "sora_" + WindowsTarget + ".exe"

#ifndef StageDir
  #define StageDir "stage"
#endif
#ifndef NdpInstaller
  #define NdpInstaller "NDP48-x86-x64-AllOS-ENU.exe"
#endif
#ifndef KbInstaller
  #define KbInstaller "Windows6.1-KB3033929-x86.msu"
#endif
#ifndef BuildOutputDir
  #define BuildOutputDir "."
#endif

[Setup]
AppId={{8D33A351-982B-4E71-8216-4B7E4B75EBA8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher=levvs-one
AppCopyright=Copyright (C) 2026 levvs-one
AppPublisherURL=https://github.com/levvs-one/sora-client
AppSupportURL=https://github.com/levvs-one/sora-client/issues
AppUpdatesURL=https://github.com/levvs-one/sora-client/releases/latest
AppComments=Sora — клиент VPN и proxy с открытым исходным кодом
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany=levvs-one
VersionInfoDescription=Sora — клиент подключений для {#WindowsDisplayName}
DefaultDirName={localappdata}\Programs\Sora
DefaultGroupName=Sora
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
MinVersion={#MinimumWindowsVersion}
ArchitecturesAllowed=x86compatible
OutputDir={#BuildOutputDir}
OutputBaseFilename=Sora-{#MyAppVersion}-{#WindowsTarget}-Setup
SetupIconFile={#StageDir}\sora.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
DefaultDialogFontName=Segoe UI
WizardStyle=modern dark includetitlebar hidebevels
WizardSizePercent=110,108
WizardImageFile=assets\sora-wizard.png
WizardImageBackColor=#111113
WizardSmallImageFile=..\v2rayN\v2rayN\Assets\Sora\sora-logo-white.png
WizardSmallImageBackColor=#111113
DisableWelcomePage=no
DisableReadyPage=no
DisableReadyMemo=no
ShowTasksTreeLines=no
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
SetupLogging=yes
LicenseFile={#StageDir}\LICENSE

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
russian.WelcomeLabel1=Установить Sora
russian.WelcomeLabel2=Версия {#MyAppVersion} для {#WindowsDisplayName}.%n%nОдин клиент для VPN и proxy: добавьте подписку, выберите сервер и подключитесь.
russian.WizardLicense=Лицензия GPL-3.0
russian.LicenseLabel=Открытый исходный код и прозрачные условия использования.
russian.LicenseLabel3=Для продолжения примите условия GNU GPL-3.0.
russian.WizardSelectDir=Папка Sora
russian.SelectDirDesc=Куда установить Sora?
russian.SelectDirLabel3=Sora хранит программу и её компоненты в одной папке. Данные пользователя остаются локально.
russian.WizardSelectTasks=Быстрые настройки
russian.SelectTasksDesc=Что включить сразу?
russian.SelectTasksLabel2=Выберите только нужные ярлыки и автозапуск. Позже это можно изменить в настройках Sora.
russian.WizardReady=Всё готово
russian.ReadyLabel1=Sora готова к установке.
russian.ReadyLabel2a=Проверьте выбранные параметры и нажмите «Установить».
russian.ReadyLabel2b=Нажмите «Установить», чтобы продолжить.
russian.WizardInstalling=Установка Sora
russian.InstallingLabel=Sora устанавливается. Не закрывайте это окно.
russian.FinishedHeadingLabel=Sora установлена
russian.FinishedLabelNoIcons=Установка завершена. Откройте Sora и добавьте подписку.
russian.FinishedLabel=Установка завершена. Sora доступна через созданные ярлыки.
russian.ClickFinish=Нажмите «Готово», чтобы закрыть установщик.
russian.ButtonFinish=&Готово
english.WelcomeLabel1=Install Sora
english.WelcomeLabel2=Version {#MyAppVersion} for {#WindowsDisplayName}.%n%nOne client for VPN and proxy: add a subscription, choose a server, and connect.
english.WizardLicense=GPL-3.0 License
english.LicenseLabel=Open source with transparent terms of use.
english.LicenseLabel3=Accept the GNU GPL-3.0 terms to continue.
english.WizardSelectDir=Sora folder
english.SelectDirDesc=Where should Sora be installed?
english.SelectDirLabel3=Sora keeps the application and its components in one folder. User data stays local.
english.WizardSelectTasks=Quick setup
english.SelectTasksDesc=What should be enabled now?
english.SelectTasksLabel2=Choose only the shortcuts and startup option you need. You can change them later in Sora.
english.WizardReady=Ready
english.ReadyLabel1=Sora is ready to install.
english.ReadyLabel2a=Review the selected options and click Install.
english.ReadyLabel2b=Click Install to continue.
english.WizardInstalling=Installing Sora
english.InstallingLabel=Sora is being installed. Keep this window open.
english.FinishedHeadingLabel=Sora is installed
english.FinishedLabelNoIcons=Installation is complete. Open Sora and add a subscription.
english.FinishedLabel=Installation is complete. Sora is available from the shortcuts you selected.
english.ClickFinish=Click Done to close Setup.
english.ButtonFinish=&Done

[CustomMessages]
russian.SoraShortcutGroup=Ярлыки
russian.SoraDesktopTask=Создать ярлык на рабочем столе
russian.SoraStartupGroup=Автозапуск
russian.SoraStartupTask=Запускать Sora в фоне при входе в Windows
russian.SoraLaunch=Запустить Sora
english.SoraShortcutGroup=Shortcuts
english.SoraDesktopTask=Create a desktop shortcut
english.SoraStartupGroup=Startup
english.SoraStartupTask=Start Sora in the background when Windows starts
english.SoraLaunch=Launch Sora

[Tasks]
Name: "desktopicon"; Description: "{cm:SoraDesktopTask}"; GroupDescription: "{cm:SoraShortcutGroup}:"; Flags: unchecked
Name: "autorun"; Description: "{cm:SoraStartupTask}"; GroupDescription: "{cm:SoraStartupGroup}:"; Flags: unchecked

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#NdpInstaller}"; DestName: "NDP48-x86-x64-AllOS-ENU.exe"; Flags: dontcopy
Source: "{#KbInstaller}"; DestName: "Windows6.1-KB3033929-x86.msu"; Flags: dontcopy

[Icons]
Name: "{group}\Sora"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\Sora"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{userstartup}\Sora"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--silent"; WorkingDir: "{app}"; Tasks: autorun

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:SoraLaunch}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent; Check: not WizardNoIcons

[UninstallRun]
Filename: "{app}\{#MyAppExeName}"; Parameters: "--restore-proxy"; WorkingDir: "{app}"; Flags: runhidden waituntilterminated skipifdoesntexist; RunOnceId: "RestoreSystemProxy"

[UninstallDelete]
Type: files; Name: "{app}\guiNConfig.json"
Type: files; Name: "{app}\statistics.json"
Type: filesandordirs; Name: "{app}\guiLogs"
Type: filesandordirs; Name: "{app}\guiTemps"
Type: filesandordirs; Name: "{app}\guiBackups"
Type: filesandordirs; Name: "{app}\guiConfigs"

[Code]
function IsWindows7: Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  Result := (Version.Major = 6) and (Version.Minor = 1);
end;

function IsDotNet48Installed: Boolean;
var
  Release: Cardinal;
begin
  Result := False;
  if RegQueryDWordValue(HKLM32, 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full', 'Release', Release) then
    Result := Release >= 528040;
  if IsWin64 and RegQueryDWordValue(HKLM64, 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full', 'Release', Release) then
    Result := Result or (Release >= 528040);
end;

function IsKb3033929Installed: Boolean;
var
  PackageNames: TArrayOfString;
  PackagePath: String;
  CurrentState: Cardinal;
  Index: Integer;
begin
  Result := False;
  PackagePath := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages';
  if not RegGetSubkeyNames(HKLM32, PackagePath, PackageNames) then
    Exit;
  for Index := 0 to GetArrayLength(PackageNames) - 1 do
  begin
    if Pos('Package_for_KB3033929~', PackageNames[Index]) = 1 then
    begin
      if RegQueryDWordValue(HKLM32, PackagePath + '\' + PackageNames[Index], 'CurrentState', CurrentState) and (CurrentState = 112) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
  InstallerPath: String;
begin
  Result := '';

  if IsWindows7 and not IsWin64 and not IsKb3033929Installed then
  begin
    ExtractTemporaryFile('Windows6.1-KB3033929-x86.msu');
    InstallerPath := ExpandConstant('{tmp}\Windows6.1-KB3033929-x86.msu');
    if CompareText(GetSHA256OfFile(InstallerPath), '246C300A6AE6DCA99453F6839745AC0015953528A7065BED1B015F91B80CF64D') <> 0 then
    begin
      Result := 'Проверка целостности KB3033929 не пройдена.';
      Exit;
    end;
    if ShellExec('runas', ExpandConstant('{sys}\wusa.exe'), '"' + InstallerPath + '" /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      Log(Format('KB3033929 завершился с кодом %d', [ResultCode]));
      if (ResultCode = 3010) or (ResultCode = 1641) then
        NeedsRestart := True;
      if (ResultCode <> 0) and (ResultCode <> 3010) and (ResultCode <> 1641) and (ResultCode <> 2359302) then
      begin
        Result := Format('Проверка или установка KB3033929 завершилась с кодом %d.', [ResultCode]);
        Exit;
      end;
    end
    else
    begin
      Result := Format('Не удалось запустить проверку или установку KB3033929. Код: %d', [ResultCode]);
      Exit;
    end;
  end;

  if not IsDotNet48Installed then
  begin
    ExtractTemporaryFile('NDP48-x86-x64-AllOS-ENU.exe');
    InstallerPath := ExpandConstant('{tmp}\NDP48-x86-x64-AllOS-ENU.exe');
    if CompareText(GetSHA256OfFile(InstallerPath), '0A3A390C47E639D0F7FC65B21195FEE6B7F65B066F80F70C60FAB191D14B7E40') <> 0 then
    begin
      Result := 'Проверка целостности .NET Framework 4.8 не пройдена.';
      Exit;
    end;
    if not ShellExec('runas', InstallerPath, '/q /norestart', '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
    begin
      Result := Format('Не удалось запустить установку .NET Framework 4.8. Код: %d', [ResultCode]);
      Exit;
    end;
    if (ResultCode <> 0) and (ResultCode <> 3010) and (ResultCode <> 1641) then
    begin
      Result := Format('Установка .NET Framework 4.8 завершилась с кодом %d.', [ResultCode]);
      Exit;
    end;
    if (ResultCode = 3010) or (ResultCode = 1641) then
      NeedsRestart := True;
  end;
end;
