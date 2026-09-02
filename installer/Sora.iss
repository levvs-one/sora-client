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
#ifndef AppIdValue
  #define AppIdValue "{{8D33A351-982B-4E71-8216-4B7E4B75EBA8}"
#endif

[Setup]
AppId={#AppIdValue}
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
WizardSizePercent=108,120
WizardImageFile=
WizardSmallImageFile=
WizardBackColor=#111113
WizardBackColorDynamicDark=#111113
ShowLanguageDialog=auto
UsePreviousLanguage=yes
UsePreviousAppDir=yes
UsePreviousTasks=yes
DisableStartupPrompt=yes
DisableWelcomePage=yes
DisableDirPage=yes
DisableReadyPage=yes
DisableReadyMemo=yes
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
CloseApplicationsFilter={#MyAppExeName}
RestartApplications=no
SetupLogging=yes
UninstallDisplayName=Sora
#ifdef SignToolName
SignTool={#SignToolName}
SignedUninstaller=yes
#endif

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
russian.WizardInstalling=Установка Sora
russian.InstallingLabel=Устанавливаем Sora
russian.FinishedHeadingLabel=Sora готова
russian.FinishedLabelNoIcons=Добавьте подписку, выберите сервер и подключитесь.
russian.FinishedLabel=Добавьте подписку, выберите сервер и подключитесь.
russian.ClickFinish=Можно начинать.
russian.ButtonInstall=&Установить
russian.ButtonFinish=&Готово
english.WizardInstalling=Installing Sora
english.InstallingLabel=Installing Sora
english.FinishedHeadingLabel=Sora is ready
english.FinishedLabelNoIcons=Add a subscription, choose a server, and connect.
english.FinishedLabel=Add a subscription, choose a server, and connect.
english.ClickFinish=You can get started.
english.ButtonInstall=&Install
english.ButtonFinish=&Done

[CustomMessages]
russian.SoraInstallTitle=Установить Sora
russian.SoraInstallSubtitle=VPN и proxy-клиент без лишних экранов и сложной настройки.
russian.SoraUpdateTitle=Обновить Sora
russian.SoraUpdateSubtitle=Настройки и подписки останутся на месте. Обновятся только файлы приложения.
russian.SoraRepairTitle=Восстановить Sora
russian.SoraRepairSubtitle=Переустановим файлы приложения, не затрагивая настройки и подписки.
russian.SoraInstallAction=Установить
russian.SoraUpdateAction=Обновить
russian.SoraRepairAction=Восстановить
russian.SoraFreshMode=НОВАЯ УСТАНОВКА
russian.SoraUpdateMode=БЕЗОПАСНОЕ ОБНОВЛЕНИЕ
russian.SoraRepairMode=ВОССТАНОВЛЕНИЕ
russian.SoraQuickSetup=НАСТРОЙКИ ЗАПУСКА
russian.SoraDesktopTask=Создать ярлык на рабочем столе
russian.SoraStartupTask=Запускать Sora при входе в Windows
russian.SoraPackageLabel=В комплекте
russian.SoraPackageValue=Sora и сетевые компоненты
russian.SoraDataLabel=Личные данные
russian.SoraDataFresh=Будут храниться только на этом компьютере
russian.SoraDataSafe=Подписки и настройки будут сохранены
russian.SoraCancel=Отмена
russian.SoraProgressPrepare=Проверяем систему
russian.SoraProgressApp=Устанавливаем Sora
russian.SoraProgressNetwork=Добавляем сетевые компоненты
russian.SoraProgressFinish=Завершаем установку
russian.SoraBackupFailed=Не удалось создать резервную копию настроек. Установка остановлена, чтобы не рисковать вашими данными.
russian.SoraNewerVersion=На компьютере установлена более новая версия Sora. Удалите её вручную, если действительно хотите вернуться к версии {#MyAppVersion}.
russian.SoraIntegrityError=Встроенный системный компонент повреждён. Скачайте установщик Sora заново с официальной страницы GitHub.
russian.SoraPrerequisiteError=Windows не смогла установить необходимый компонент (код %1). Перезагрузите компьютер и повторите установку.
russian.SoraUninstallTitle=Удаление Sora
russian.SoraUninstallSubtitle=Приложение будет удалено с этого компьютера.
russian.SoraKeepData=Сохранить подписки и настройки
russian.SoraKeepDataHint=При следующей установке Sora всё останется на месте.
russian.SoraPurgeData=Удалить также локальные данные
russian.SoraPurgeDataHint=Подписки, настройки, журналы и резервные копии будут удалены безвозвратно.
russian.SoraRemove=Удалить Sora
russian.SoraUninstallCancel=Оставить Sora
russian.SoraLaunch=Запустить Sora
english.SoraInstallTitle=Install Sora
english.SoraInstallSubtitle=A VPN and proxy client without unnecessary screens or complicated setup.
english.SoraUpdateTitle=Update Sora
english.SoraUpdateSubtitle=Settings and subscriptions stay in place. Only application files will be updated.
english.SoraRepairTitle=Repair Sora
english.SoraRepairSubtitle=Application files will be reinstalled without changing settings or subscriptions.
english.SoraInstallAction=Install
english.SoraUpdateAction=Update
english.SoraRepairAction=Repair
english.SoraFreshMode=NEW INSTALLATION
english.SoraUpdateMode=SAFE UPDATE
english.SoraRepairMode=REPAIR
english.SoraQuickSetup=STARTUP OPTIONS
english.SoraDesktopTask=Create a desktop shortcut
english.SoraStartupTask=Start Sora when Windows starts
english.SoraPackageLabel=Included
english.SoraPackageValue=Sora and network components
english.SoraDataLabel=Personal data
english.SoraDataFresh=Stored only on this computer
english.SoraDataSafe=Subscriptions and settings will be preserved
english.SoraCancel=Cancel
english.SoraProgressPrepare=Checking the system
english.SoraProgressApp=Installing Sora
english.SoraProgressNetwork=Adding network components
english.SoraProgressFinish=Finishing installation
english.SoraBackupFailed=Setup could not back up your settings. Installation was stopped to keep your data safe.
english.SoraNewerVersion=A newer version of Sora is already installed. Uninstall it manually if you really want to return to version {#MyAppVersion}.
english.SoraIntegrityError=An embedded system component is damaged. Download Sora Setup again from the official GitHub page.
english.SoraPrerequisiteError=Windows could not install a required component (code %1). Restart the computer and try again.
english.SoraUninstallTitle=Uninstall Sora
english.SoraUninstallSubtitle=The application will be removed from this computer.
english.SoraKeepData=Keep subscriptions and settings
english.SoraKeepDataHint=Everything will be restored the next time you install Sora.
english.SoraPurgeData=Also remove local data
english.SoraPurgeDataHint=Subscriptions, settings, logs, and backups will be permanently deleted.
english.SoraRemove=Uninstall Sora
english.SoraUninstallCancel=Keep Sora
english.SoraLaunch=Launch Sora

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#NdpInstaller}"; DestName: "NDP48-x86-x64-AllOS-ENU.exe"; Flags: dontcopy
Source: "{#KbInstaller}"; DestName: "Windows6.1-KB3033929-x86.msu"; Flags: dontcopy

[Icons]
Name: "{group}\Sora"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\Sora"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Check: DesktopShortcutEnabled
Name: "{userstartup}\Sora"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--silent"; WorkingDir: "{app}"; Check: StartupEnabled

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:SoraLaunch}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent; Check: not WizardNoIcons

[UninstallRun]
Filename: "{app}\{#MyAppExeName}"; Parameters: "--restore-proxy"; WorkingDir: "{app}"; Flags: runhidden waituntilterminated skipifdoesntexist; RunOnceId: "RestoreSystemProxy"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\guiTemps"

[Code]
const
  SoraCanvas = $00131111;
  SoraSurface = $001B1818;
  SoraRaised = $00232121;
  SoraBorder = $00353232;
  SoraMuted = $00C2BEBE;
  SoraText = $00F5F4F4;
  InstallModeFresh = 0;
  InstallModeUpdate = 1;
  InstallModeRepair = 2;
  InstallModeDowngrade = 3;
  SoraKeySpace = $20;
  SoraKeyLeft = $25;
  SoraKeyUp = $26;
  SoraKeyRight = $27;
  SoraKeyDown = $28;

var
  SoraPage: TWizardPage;
  SoraInstallMode: Integer;
  SoraPageTitle: TNewStaticText;
  SoraPageSubtitle: TNewStaticText;
  SoraModeLabel: TNewStaticText;
  SoraDataValue: TNewStaticText;
  DesktopShortcutCheck: TNewCheckBox;
  StartupCheck: TNewCheckBox;
  InstallProgressTrack: TPanel;
  InstallProgressFill: TPanel;
  InstallProgressPercent: TNewStaticText;
  InstallProgressStatus: TNewStaticText;
  PurgeUserData: Boolean;
  SettingsBackupCreated: Boolean;
  UninstallKeepRow: TPanel;
  UninstallPurgeRow: TPanel;
  UninstallKeepMarker: TNewStaticText;
  UninstallPurgeMarker: TNewStaticText;
  UninstallKeepTitle: TNewStaticText;
  UninstallPurgeTitle: TNewStaticText;

function DetectInstallMode: Integer;
var
  InstalledExecutable: String;
  InstalledVersion: Int64;
  PackageVersion: Int64;
  Comparison: Integer;
begin
  Result := InstallModeFresh;
  InstalledExecutable := AddBackslash(WizardDirValue) + '{#MyAppExeName}';
  if not FileExists(InstalledExecutable) then
    Exit;

  if not GetPackedVersion(InstalledExecutable, InstalledVersion) then
  begin
    Result := InstallModeRepair;
    Exit;
  end;
  if not StrToVersion('{#MyAppVersion}.0', PackageVersion) then
  begin
    Result := InstallModeRepair;
    Exit;
  end;

  Comparison := ComparePackedVersion(InstalledVersion, PackageVersion);
  if Comparison < 0 then
    Result := InstallModeUpdate
  else if Comparison = 0 then
    Result := InstallModeRepair
  else
    Result := InstallModeDowngrade;
end;

procedure ApplyInstallMode;
begin
  if SoraInstallMode = InstallModeUpdate then
  begin
    SoraPageTitle.Caption := CustomMessage('SoraUpdateTitle');
    SoraPageSubtitle.Caption := CustomMessage('SoraUpdateSubtitle');
    SoraModeLabel.Caption := CustomMessage('SoraUpdateMode');
    SoraDataValue.Caption := CustomMessage('SoraDataSafe');
    WizardForm.NextButton.Caption := CustomMessage('SoraUpdateAction');
  end
  else if SoraInstallMode = InstallModeRepair then
  begin
    SoraPageTitle.Caption := CustomMessage('SoraRepairTitle');
    SoraPageSubtitle.Caption := CustomMessage('SoraRepairSubtitle');
    SoraModeLabel.Caption := CustomMessage('SoraRepairMode');
    SoraDataValue.Caption := CustomMessage('SoraDataSafe');
    WizardForm.NextButton.Caption := CustomMessage('SoraRepairAction');
  end
  else if SoraInstallMode = InstallModeDowngrade then
  begin
    SoraPageTitle.Caption := CustomMessage('SoraRepairTitle');
    SoraPageSubtitle.Caption := CustomMessage('SoraNewerVersion');
    SoraModeLabel.Caption := CustomMessage('SoraRepairMode');
    SoraDataValue.Caption := CustomMessage('SoraDataSafe');
    WizardForm.NextButton.Enabled := False;
  end
  else
  begin
    SoraPageTitle.Caption := CustomMessage('SoraInstallTitle');
    SoraPageSubtitle.Caption := CustomMessage('SoraInstallSubtitle');
    SoraModeLabel.Caption := CustomMessage('SoraFreshMode');
    SoraDataValue.Caption := CustomMessage('SoraDataFresh');
    WizardForm.NextButton.Caption := CustomMessage('SoraInstallAction');
  end;
end;

procedure InitializeWizard;
var
  ButtonBottom: Integer;
  HeaderBrand: TNewStaticText;
  HeaderMeta: TNewStaticText;
  HeaderDivider: TPanel;
  PageDivider: TPanel;
  OptionsTitle: TNewStaticText;
  PackageLabel: TNewStaticText;
  PackageValue: TNewStaticText;
  DataLabel: TNewStaticText;
  InstallingTitle: TNewStaticText;
begin
  SoraInstallMode := DetectInstallMode;
  WizardForm.Color := SoraCanvas;
  WizardForm.MainPanel.Color := SoraCanvas;
  WizardForm.MainPanel.ParentBackground := False;
  WizardForm.PageNameLabel.Visible := False;
  WizardForm.PageDescriptionLabel.Visible := False;
  WizardForm.WizardSmallBitmapImage.Visible := False;
  WizardForm.Bevel.Visible := False;

  HeaderBrand := TNewStaticText.Create(WizardForm);
  HeaderBrand.Parent := WizardForm.MainPanel;
  HeaderBrand.Left := ScaleX(36);
  HeaderBrand.Top := ScaleY(21);
  HeaderBrand.Width := ScaleX(160);
  HeaderBrand.Height := ScaleY(22);
  HeaderBrand.Caption := 'SORA';
  HeaderBrand.Font.Name := 'Segoe UI';
  HeaderBrand.Font.Size := 12;
  HeaderBrand.Font.Style := [fsBold];
  HeaderBrand.Font.Color := SoraText;

  HeaderMeta := TNewStaticText.Create(WizardForm);
  HeaderMeta.Parent := WizardForm.MainPanel;
  HeaderMeta.Left := WizardForm.MainPanel.Width - ScaleX(236);
  HeaderMeta.Top := ScaleY(23);
  HeaderMeta.Width := ScaleX(200);
  HeaderMeta.Height := ScaleY(18);
  HeaderMeta.Alignment := taRightJustify;
  HeaderMeta.Caption := '{#MyAppVersion}  /  {#WindowsDisplayName}';
  HeaderMeta.Font.Name := 'Segoe UI';
  HeaderMeta.Font.Size := 9;
  HeaderMeta.Font.Color := SoraMuted;

  HeaderDivider := TPanel.Create(WizardForm);
  HeaderDivider.Parent := WizardForm.MainPanel;
  HeaderDivider.Left := ScaleX(36);
  HeaderDivider.Top := WizardForm.MainPanel.Height - ScaleY(1);
  HeaderDivider.Width := WizardForm.MainPanel.Width - ScaleX(72);
  HeaderDivider.Height := ScaleY(1);
  HeaderDivider.BevelOuter := bvNone;
  HeaderDivider.Color := SoraBorder;
  HeaderDivider.ParentBackground := False;

  SoraPage := CreateCustomPage(wpWelcome, '', '');
  SoraPage.Surface.Color := SoraSurface;

  SoraModeLabel := TNewStaticText.Create(SoraPage);
  SoraModeLabel.Parent := SoraPage.Surface;
  SoraModeLabel.Left := ScaleX(36);
  SoraModeLabel.Top := ScaleY(22);
  SoraModeLabel.Width := SoraPage.SurfaceWidth - ScaleX(72);
  SoraModeLabel.Height := ScaleY(16);
  SoraModeLabel.Font.Name := 'Segoe UI';
  SoraModeLabel.Font.Size := 8;
  SoraModeLabel.Font.Style := [fsBold];
  SoraModeLabel.Font.Color := SoraMuted;

  SoraPageTitle := TNewStaticText.Create(SoraPage);
  SoraPageTitle.Parent := SoraPage.Surface;
  SoraPageTitle.Left := ScaleX(36);
  SoraPageTitle.Top := ScaleY(45);
  SoraPageTitle.Width := SoraPage.SurfaceWidth - ScaleX(72);
  SoraPageTitle.Height := ScaleY(31);
  SoraPageTitle.Font.Name := 'Segoe UI';
  SoraPageTitle.Font.Size := 20;
  SoraPageTitle.Font.Style := [fsBold];
  SoraPageTitle.Font.Color := SoraText;

  SoraPageSubtitle := TNewStaticText.Create(SoraPage);
  SoraPageSubtitle.Parent := SoraPage.Surface;
  SoraPageSubtitle.Left := ScaleX(36);
  SoraPageSubtitle.Top := ScaleY(81);
  SoraPageSubtitle.Width := SoraPage.SurfaceWidth - ScaleX(72);
  SoraPageSubtitle.Height := ScaleY(34);
  SoraPageSubtitle.AutoSize := False;
  SoraPageSubtitle.WordWrap := True;
  SoraPageSubtitle.Font.Name := 'Segoe UI';
  SoraPageSubtitle.Font.Size := 10;
  SoraPageSubtitle.Font.Color := SoraMuted;

  PageDivider := TPanel.Create(SoraPage);
  PageDivider.Parent := SoraPage.Surface;
  PageDivider.Left := ScaleX(36);
  PageDivider.Top := ScaleY(122);
  PageDivider.Width := SoraPage.SurfaceWidth - ScaleX(72);
  PageDivider.Height := ScaleY(1);
  PageDivider.BevelOuter := bvNone;
  PageDivider.Color := SoraBorder;
  PageDivider.ParentBackground := False;

  PackageLabel := TNewStaticText.Create(SoraPage);
  PackageLabel.Parent := SoraPage.Surface;
  PackageLabel.Left := ScaleX(36);
  PackageLabel.Top := ScaleY(140);
  PackageLabel.Width := ScaleX(128);
  PackageLabel.Height := ScaleY(18);
  PackageLabel.Caption := CustomMessage('SoraPackageLabel');
  PackageLabel.Font.Name := 'Segoe UI';
  PackageLabel.Font.Size := 9;
  PackageLabel.Font.Color := SoraMuted;

  PackageValue := TNewStaticText.Create(SoraPage);
  PackageValue.Parent := SoraPage.Surface;
  PackageValue.Left := ScaleX(172);
  PackageValue.Top := ScaleY(140);
  PackageValue.Width := SoraPage.SurfaceWidth - ScaleX(208);
  PackageValue.Height := ScaleY(18);
  PackageValue.Alignment := taRightJustify;
  PackageValue.Caption := CustomMessage('SoraPackageValue');
  PackageValue.Font.Name := 'Segoe UI';
  PackageValue.Font.Size := 9;
  PackageValue.Font.Color := SoraText;

  DataLabel := TNewStaticText.Create(SoraPage);
  DataLabel.Parent := SoraPage.Surface;
  DataLabel.Left := ScaleX(36);
  DataLabel.Top := ScaleY(168);
  DataLabel.Width := ScaleX(128);
  DataLabel.Height := ScaleY(18);
  DataLabel.Caption := CustomMessage('SoraDataLabel');
  DataLabel.Font.Name := 'Segoe UI';
  DataLabel.Font.Size := 9;
  DataLabel.Font.Color := SoraMuted;

  SoraDataValue := TNewStaticText.Create(SoraPage);
  SoraDataValue.Parent := SoraPage.Surface;
  SoraDataValue.Left := ScaleX(172);
  SoraDataValue.Top := ScaleY(168);
  SoraDataValue.Width := SoraPage.SurfaceWidth - ScaleX(208);
  SoraDataValue.Height := ScaleY(18);
  SoraDataValue.Alignment := taRightJustify;
  SoraDataValue.Font.Name := 'Segoe UI';
  SoraDataValue.Font.Size := 9;
  SoraDataValue.Font.Color := SoraText;

  PageDivider := TPanel.Create(SoraPage);
  PageDivider.Parent := SoraPage.Surface;
  PageDivider.Left := ScaleX(36);
  PageDivider.Top := ScaleY(198);
  PageDivider.Width := SoraPage.SurfaceWidth - ScaleX(72);
  PageDivider.Height := ScaleY(1);
  PageDivider.BevelOuter := bvNone;
  PageDivider.Color := SoraBorder;
  PageDivider.ParentBackground := False;

  OptionsTitle := TNewStaticText.Create(SoraPage);
  OptionsTitle.Parent := SoraPage.Surface;
  OptionsTitle.Left := ScaleX(36);
  OptionsTitle.Top := ScaleY(216);
  OptionsTitle.Width := ScaleX(220);
  OptionsTitle.Height := ScaleY(16);
  OptionsTitle.Caption := CustomMessage('SoraQuickSetup');
  OptionsTitle.Font.Name := 'Segoe UI';
  OptionsTitle.Font.Size := 8;
  OptionsTitle.Font.Style := [fsBold];
  OptionsTitle.Font.Color := SoraMuted;

  DesktopShortcutCheck := TNewCheckBox.Create(SoraPage);
  DesktopShortcutCheck.Parent := SoraPage.Surface;
  DesktopShortcutCheck.Left := ScaleX(36);
  DesktopShortcutCheck.Top := ScaleY(243);
  DesktopShortcutCheck.Width := SoraPage.SurfaceWidth - ScaleX(72);
  DesktopShortcutCheck.Height := ScaleY(24);
  DesktopShortcutCheck.Caption := CustomMessage('SoraDesktopTask');
  DesktopShortcutCheck.Checked := GetPreviousData('DesktopShortcut', '0') = '1';
  DesktopShortcutCheck.Font.Name := 'Segoe UI';
  DesktopShortcutCheck.Font.Size := 10;
  DesktopShortcutCheck.Font.Color := SoraText;

  StartupCheck := TNewCheckBox.Create(SoraPage);
  StartupCheck.Parent := SoraPage.Surface;
  StartupCheck.Left := ScaleX(36);
  StartupCheck.Top := ScaleY(277);
  StartupCheck.Width := SoraPage.SurfaceWidth - ScaleX(72);
  StartupCheck.Height := ScaleY(24);
  StartupCheck.Caption := CustomMessage('SoraStartupTask');
  StartupCheck.Checked := GetPreviousData('Startup', '0') = '1';
  StartupCheck.Font.Name := 'Segoe UI';
  StartupCheck.Font.Size := 10;
  StartupCheck.Font.Color := SoraText;

  ButtonBottom := WizardForm.NextButton.Top + WizardForm.NextButton.Height;
  WizardForm.NextButton.Width := ScaleX(116);
  WizardForm.NextButton.Height := ScaleY(34);
  WizardForm.NextButton.Top := ButtonBottom - WizardForm.NextButton.Height;
  WizardForm.NextButton.Font.Name := 'Segoe UI';
  WizardForm.NextButton.Font.Style := [fsBold];
  WizardForm.NextButton.Default := False;
  WizardForm.BackButton.Visible := False;
  WizardForm.CancelButton.Caption := CustomMessage('SoraCancel');
  WizardForm.CancelButton.Cancel := True;
  WizardForm.CancelButton.Width := ScaleX(88);
  WizardForm.CancelButton.Height := WizardForm.NextButton.Height;
  WizardForm.CancelButton.Top := WizardForm.NextButton.Top;
  WizardForm.CancelButton.Left := WizardForm.ClientWidth - ScaleX(24) - WizardForm.CancelButton.Width;
  WizardForm.NextButton.Left := WizardForm.CancelButton.Left - ScaleX(12) - WizardForm.NextButton.Width;

  ApplyInstallMode;

  WizardForm.InstallingPage.Color := SoraSurface;
  InstallingTitle := TNewStaticText.Create(WizardForm);
  InstallingTitle.Parent := WizardForm.InstallingPage;
  InstallingTitle.Left := ScaleX(36);
  InstallingTitle.Top := ScaleY(42);
  InstallingTitle.Width := WizardForm.InstallingPage.Width - ScaleX(72);
  InstallingTitle.Height := ScaleY(30);
  InstallingTitle.Caption := SetupMessage(msgWizardInstalling);
  InstallingTitle.Font.Name := 'Segoe UI';
  InstallingTitle.Font.Size := 18;
  InstallingTitle.Font.Style := [fsBold];
  InstallingTitle.Font.Color := SoraText;
  WizardForm.StatusLabel.Visible := False;
  WizardForm.FilenameLabel.Visible := False;
  WizardForm.ProgressGauge.Visible := False;

  InstallProgressStatus := TNewStaticText.Create(WizardForm);
  InstallProgressStatus.Parent := WizardForm.InstallingPage;
  InstallProgressStatus.Left := ScaleX(36);
  InstallProgressStatus.Top := ScaleY(82);
  InstallProgressStatus.Width := WizardForm.InstallingPage.Width - ScaleX(72);
  InstallProgressStatus.Height := ScaleY(18);
  InstallProgressStatus.Caption := CustomMessage('SoraProgressPrepare');
  InstallProgressStatus.Font.Name := 'Segoe UI';
  InstallProgressStatus.Font.Size := 10;
  InstallProgressStatus.Font.Color := SoraMuted;

  InstallProgressTrack := TPanel.Create(WizardForm);
  InstallProgressTrack.Parent := WizardForm.InstallingPage;
  InstallProgressTrack.Left := ScaleX(36);
  InstallProgressTrack.Top := ScaleY(120);
  InstallProgressTrack.Width := WizardForm.InstallingPage.Width - ScaleX(72);
  InstallProgressTrack.Height := ScaleY(4);
  InstallProgressTrack.BevelOuter := bvNone;
  InstallProgressTrack.Color := SoraBorder;
  InstallProgressTrack.ParentBackground := False;

  InstallProgressFill := TPanel.Create(WizardForm);
  InstallProgressFill.Parent := InstallProgressTrack;
  InstallProgressFill.Left := 0;
  InstallProgressFill.Top := 0;
  InstallProgressFill.Width := 0;
  InstallProgressFill.Height := InstallProgressTrack.Height;
  InstallProgressFill.BevelOuter := bvNone;
  InstallProgressFill.Color := SoraText;
  InstallProgressFill.ParentBackground := False;

  InstallProgressPercent := TNewStaticText.Create(WizardForm);
  InstallProgressPercent.Parent := WizardForm.InstallingPage;
  InstallProgressPercent.Left := ScaleX(36);
  InstallProgressPercent.Top := ScaleY(136);
  InstallProgressPercent.Width := WizardForm.InstallingPage.Width - ScaleX(72);
  InstallProgressPercent.Height := ScaleY(18);
  InstallProgressPercent.Alignment := taRightJustify;
  InstallProgressPercent.Caption := '0%';
  InstallProgressPercent.Font.Name := 'Segoe UI';
  InstallProgressPercent.Font.Size := 9;
  InstallProgressPercent.Font.Color := SoraMuted;

  WizardForm.WizardBitmapImage2.Visible := False;
  WizardForm.FinishedPage.Color := SoraSurface;
  WizardForm.FinishedHeadingLabel.Left := ScaleX(36);
  WizardForm.FinishedHeadingLabel.Top := ScaleY(42);
  WizardForm.FinishedHeadingLabel.Width := WizardForm.FinishedPage.Width - ScaleX(72);
  WizardForm.FinishedHeadingLabel.Font.Name := 'Segoe UI';
  WizardForm.FinishedHeadingLabel.Font.Size := 20;
  WizardForm.FinishedHeadingLabel.Font.Style := [fsBold];
  WizardForm.FinishedHeadingLabel.Font.Color := SoraText;
  WizardForm.FinishedLabel.Left := ScaleX(36);
  WizardForm.FinishedLabel.Top := ScaleY(82);
  WizardForm.FinishedLabel.Width := WizardForm.FinishedPage.Width - ScaleX(72);
  WizardForm.FinishedLabel.Font.Name := 'Segoe UI';
  WizardForm.FinishedLabel.Font.Size := 10;
  WizardForm.FinishedLabel.Font.Color := SoraMuted;
  WizardForm.RunList.Left := ScaleX(36);
  WizardForm.RunList.Top := ScaleY(142);
  WizardForm.RunList.Width := WizardForm.FinishedPage.Width - ScaleX(72);
  WizardForm.RunList.Color := SoraSurface;
  WizardForm.RunList.BorderStyle := bsNone;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = SoraPage.ID then
    ApplyInstallMode
  else if CurPageID = wpFinished then
    WizardForm.NextButton.Caption := SetupMessage(msgButtonFinish)
end;

procedure CurInstallProgressChanged(CurProgress, MaxProgress: Integer);
var
  Percent: Integer;
begin
  if MaxProgress > 0 then
    Percent := (CurProgress * 100) div MaxProgress
  else
    Percent := 0;
  InstallProgressFill.Width := (InstallProgressTrack.Width * Percent) div 100;
  InstallProgressPercent.Caption := Format('%d%%', [Percent]);
  if Percent < 12 then
    InstallProgressStatus.Caption := CustomMessage('SoraProgressPrepare')
  else if Percent < 42 then
    InstallProgressStatus.Caption := CustomMessage('SoraProgressApp')
  else if Percent < 90 then
    InstallProgressStatus.Caption := CustomMessage('SoraProgressNetwork')
  else
    InstallProgressStatus.Caption := CustomMessage('SoraProgressFinish');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = SoraPage.ID) and (SoraInstallMode = InstallModeDowngrade) then
    Result := False;
end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  if CurPageID = SoraPage.ID then
    Confirm := False;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  if DesktopShortcutCheck.Checked then
    SetPreviousData(PreviousDataKey, 'DesktopShortcut', '1')
  else
    SetPreviousData(PreviousDataKey, 'DesktopShortcut', '0');
  if StartupCheck.Checked then
    SetPreviousData(PreviousDataKey, 'Startup', '1')
  else
    SetPreviousData(PreviousDataKey, 'Startup', '0');
end;

function BackUpFileIfPresent(const FileName, BackupDirectory, Stamp: String): Boolean;
var
  SourcePath: String;
  BackupPath: String;
  Suffix: Integer;
begin
  SourcePath := ExpandConstant('{app}\') + FileName;
  Result := True;
  if not FileExists(SourcePath) then
    Exit;

  BackupPath := BackupDirectory + '\' + FileName + '.' + Stamp + '.bak';
  Suffix := 0;
  while FileExists(BackupPath) do
  begin
    Suffix := Suffix + 1;
    BackupPath := BackupDirectory + '\' + FileName + '.' + Stamp + '.' + IntToStr(Suffix) + '.bak';
  end;
  Result := CopyFile(SourcePath, BackupPath, True);
  if Result then
    Log('Created settings backup: ' + BackupPath)
  else
    Log('Could not create settings backup: ' + BackupPath);
end;

function BackUpUserSettings: Boolean;
var
  BackupDirectory: String;
  Stamp: String;
begin
  Result := True;
  if SettingsBackupCreated or (SoraInstallMode = InstallModeFresh) then
    Exit;

  BackupDirectory := ExpandConstant('{app}\guiBackups\installer');
  if not ForceDirectories(BackupDirectory) then
  begin
    Result := False;
    Exit;
  end;

  Stamp := GetDateTimeString('yyyymmdd-hhnnss', '-', '-');
  Result := BackUpFileIfPresent('guiNConfig.json', BackupDirectory, Stamp) and
    BackUpFileIfPresent('statistics.json', BackupDirectory, Stamp) and
    BackUpFileIfPresent('user-wininet.json', BackupDirectory, Stamp);
  SettingsBackupCreated := Result;
end;

function HasCommandLineSwitch(const SwitchName: String): Boolean;
var
  Index: Integer;
begin
  Result := False;
  for Index := 1 to ParamCount do
    if CompareText(ParamStr(Index), SwitchName) = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

procedure UpdateUninstallChoice;
begin
  if PurgeUserData then
  begin
    UninstallKeepRow.Color := SoraSurface;
    UninstallPurgeRow.Color := SoraRaised;
    UninstallKeepMarker.Caption := '○';
    UninstallPurgeMarker.Caption := '●';
    UninstallKeepTitle.Font.Color := SoraMuted;
    UninstallPurgeTitle.Font.Color := SoraText;
  end
  else
  begin
    UninstallKeepRow.Color := SoraRaised;
    UninstallPurgeRow.Color := SoraSurface;
    UninstallKeepMarker.Caption := '●';
    UninstallPurgeMarker.Caption := '○';
    UninstallKeepTitle.Font.Color := SoraText;
    UninstallPurgeTitle.Font.Color := SoraMuted;
  end;
end;

procedure SelectKeepData(Sender: TObject);
begin
  PurgeUserData := False;
  UpdateUninstallChoice;
end;

procedure SelectPurgeData(Sender: TObject);
begin
  PurgeUserData := True;
  UpdateUninstallChoice;
end;

procedure UninstallChoiceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = SoraKeyUp) or (Key = SoraKeyLeft) then
  begin
    PurgeUserData := False;
    UpdateUninstallChoice;
    Key := 0;
  end
  else if (Key = SoraKeyDown) or (Key = SoraKeyRight) then
  begin
    PurgeUserData := True;
    UpdateUninstallChoice;
    Key := 0;
  end
  else if Key = SoraKeySpace then
  begin
    PurgeUserData := not PurgeUserData;
    UpdateUninstallChoice;
    Key := 0;
  end;
end;

function ShowUninstallDataChoice: Boolean;
var
  ChoiceForm: TSetupForm;
  BrandLabel: TNewStaticText;
  VersionLabel: TNewStaticText;
  Divider: TPanel;
  TitleLabel: TNewStaticText;
  SubtitleLabel: TNewStaticText;
  KeepHint: TNewStaticText;
  PurgeHint: TNewStaticText;
  RemoveButton: TNewButton;
  CancelButton: TNewButton;
begin
  Result := False;
  ChoiceForm := CreateCustomForm(560, 356, False, False);
  try
    ChoiceForm.Caption := CustomMessage('SoraUninstallTitle');
    ChoiceForm.Color := SoraCanvas;
    ChoiceForm.BorderStyle := bsDialog;
    ChoiceForm.Position := poScreenCenter;
    ChoiceForm.KeyPreview := True;
    ChoiceForm.OnKeyDown := @UninstallChoiceKeyDown;
    PurgeUserData := False;

    BrandLabel := TNewStaticText.Create(ChoiceForm);
    BrandLabel.Parent := ChoiceForm;
    BrandLabel.Left := ScaleX(32);
    BrandLabel.Top := ScaleY(20);
    BrandLabel.Width := ScaleX(180);
    BrandLabel.Height := ScaleY(22);
    BrandLabel.Caption := 'SORA';
    BrandLabel.Font.Name := 'Segoe UI';
    BrandLabel.Font.Size := 12;
    BrandLabel.Font.Style := [fsBold];
    BrandLabel.Font.Color := SoraText;

    VersionLabel := TNewStaticText.Create(ChoiceForm);
    VersionLabel.Parent := ChoiceForm;
    VersionLabel.Left := ChoiceForm.ClientWidth - ScaleX(216);
    VersionLabel.Top := ScaleY(22);
    VersionLabel.Width := ScaleX(184);
    VersionLabel.Height := ScaleY(18);
    VersionLabel.Alignment := taRightJustify;
    VersionLabel.Caption := '{#MyAppVersion}  /  {#WindowsDisplayName}';
    VersionLabel.Font.Name := 'Segoe UI';
    VersionLabel.Font.Size := 9;
    VersionLabel.Font.Color := SoraMuted;

    Divider := TPanel.Create(ChoiceForm);
    Divider.Parent := ChoiceForm;
    Divider.Left := ScaleX(32);
    Divider.Top := ScaleY(56);
    Divider.Width := ChoiceForm.ClientWidth - ScaleX(64);
    Divider.Height := ScaleY(1);
    Divider.BevelOuter := bvNone;
    Divider.Color := SoraBorder;
    Divider.ParentBackground := False;

    TitleLabel := TNewStaticText.Create(ChoiceForm);
    TitleLabel.Parent := ChoiceForm;
    TitleLabel.Left := ScaleX(32);
    TitleLabel.Top := ScaleY(82);
    TitleLabel.Width := ChoiceForm.ClientWidth - ScaleX(64);
    TitleLabel.Height := ScaleY(30);
    TitleLabel.Caption := CustomMessage('SoraUninstallTitle');
    TitleLabel.Font.Name := 'Segoe UI';
    TitleLabel.Font.Size := 19;
    TitleLabel.Font.Style := [fsBold];
    TitleLabel.Font.Color := SoraText;

    SubtitleLabel := TNewStaticText.Create(ChoiceForm);
    SubtitleLabel.Parent := ChoiceForm;
    SubtitleLabel.Left := ScaleX(32);
    SubtitleLabel.Top := ScaleY(118);
    SubtitleLabel.Width := ChoiceForm.ClientWidth - ScaleX(64);
    SubtitleLabel.Height := ScaleY(22);
    SubtitleLabel.Caption := CustomMessage('SoraUninstallSubtitle');
    SubtitleLabel.Font.Name := 'Segoe UI';
    SubtitleLabel.Font.Size := 10;
    SubtitleLabel.Font.Color := SoraMuted;

    UninstallKeepRow := TPanel.Create(ChoiceForm);
    UninstallKeepRow.Parent := ChoiceForm;
    UninstallKeepRow.Left := ScaleX(32);
    UninstallKeepRow.Top := ScaleY(156);
    UninstallKeepRow.Width := ChoiceForm.ClientWidth - ScaleX(64);
    UninstallKeepRow.Height := ScaleY(64);
    UninstallKeepRow.BevelOuter := bvNone;
    UninstallKeepRow.ParentBackground := False;
    UninstallKeepRow.Cursor := crHand;
    UninstallKeepRow.OnClick := @SelectKeepData;

    UninstallKeepMarker := TNewStaticText.Create(ChoiceForm);
    UninstallKeepMarker.Parent := UninstallKeepRow;
    UninstallKeepMarker.Left := ScaleX(14);
    UninstallKeepMarker.Top := ScaleY(13);
    UninstallKeepMarker.Width := ScaleX(22);
    UninstallKeepMarker.Height := ScaleY(22);
    UninstallKeepMarker.Font.Name := 'Segoe UI Symbol';
    UninstallKeepMarker.Font.Size := 12;
    UninstallKeepMarker.Font.Color := SoraText;
    UninstallKeepMarker.Cursor := crHand;
    UninstallKeepMarker.OnClick := @SelectKeepData;

    UninstallKeepTitle := TNewStaticText.Create(ChoiceForm);
    UninstallKeepTitle.Parent := UninstallKeepRow;
    UninstallKeepTitle.Left := ScaleX(44);
    UninstallKeepTitle.Top := ScaleY(10);
    UninstallKeepTitle.Width := UninstallKeepRow.Width - ScaleX(58);
    UninstallKeepTitle.Height := ScaleY(20);
    UninstallKeepTitle.Caption := CustomMessage('SoraKeepData');
    UninstallKeepTitle.Font.Name := 'Segoe UI';
    UninstallKeepTitle.Font.Size := 10;
    UninstallKeepTitle.Font.Style := [fsBold];
    UninstallKeepTitle.Cursor := crHand;
    UninstallKeepTitle.OnClick := @SelectKeepData;

    KeepHint := TNewStaticText.Create(ChoiceForm);
    KeepHint.Parent := UninstallKeepRow;
    KeepHint.Left := ScaleX(44);
    KeepHint.Top := ScaleY(32);
    KeepHint.Width := UninstallKeepRow.Width - ScaleX(58);
    KeepHint.Height := ScaleY(20);
    KeepHint.Caption := CustomMessage('SoraKeepDataHint');
    KeepHint.Font.Name := 'Segoe UI';
    KeepHint.Font.Size := 9;
    KeepHint.Font.Color := SoraMuted;
    KeepHint.Cursor := crHand;
    KeepHint.OnClick := @SelectKeepData;

    UninstallPurgeRow := TPanel.Create(ChoiceForm);
    UninstallPurgeRow.Parent := ChoiceForm;
    UninstallPurgeRow.Left := ScaleX(32);
    UninstallPurgeRow.Top := ScaleY(228);
    UninstallPurgeRow.Width := ChoiceForm.ClientWidth - ScaleX(64);
    UninstallPurgeRow.Height := ScaleY(72);
    UninstallPurgeRow.BevelOuter := bvNone;
    UninstallPurgeRow.ParentBackground := False;
    UninstallPurgeRow.Cursor := crHand;
    UninstallPurgeRow.OnClick := @SelectPurgeData;

    UninstallPurgeMarker := TNewStaticText.Create(ChoiceForm);
    UninstallPurgeMarker.Parent := UninstallPurgeRow;
    UninstallPurgeMarker.Left := ScaleX(14);
    UninstallPurgeMarker.Top := ScaleY(13);
    UninstallPurgeMarker.Width := ScaleX(22);
    UninstallPurgeMarker.Height := ScaleY(22);
    UninstallPurgeMarker.Font.Name := 'Segoe UI Symbol';
    UninstallPurgeMarker.Font.Size := 12;
    UninstallPurgeMarker.Font.Color := SoraText;
    UninstallPurgeMarker.Cursor := crHand;
    UninstallPurgeMarker.OnClick := @SelectPurgeData;

    UninstallPurgeTitle := TNewStaticText.Create(ChoiceForm);
    UninstallPurgeTitle.Parent := UninstallPurgeRow;
    UninstallPurgeTitle.Left := ScaleX(44);
    UninstallPurgeTitle.Top := ScaleY(10);
    UninstallPurgeTitle.Width := UninstallPurgeRow.Width - ScaleX(58);
    UninstallPurgeTitle.Height := ScaleY(20);
    UninstallPurgeTitle.Caption := CustomMessage('SoraPurgeData');
    UninstallPurgeTitle.Font.Name := 'Segoe UI';
    UninstallPurgeTitle.Font.Size := 10;
    UninstallPurgeTitle.Font.Style := [fsBold];
    UninstallPurgeTitle.Cursor := crHand;
    UninstallPurgeTitle.OnClick := @SelectPurgeData;

    PurgeHint := TNewStaticText.Create(ChoiceForm);
    PurgeHint.Parent := UninstallPurgeRow;
    PurgeHint.Left := ScaleX(44);
    PurgeHint.Top := ScaleY(32);
    PurgeHint.Width := UninstallPurgeRow.Width - ScaleX(58);
    PurgeHint.Height := ScaleY(34);
    PurgeHint.AutoSize := False;
    PurgeHint.WordWrap := True;
    PurgeHint.Caption := CustomMessage('SoraPurgeDataHint');
    PurgeHint.Font.Name := 'Segoe UI';
    PurgeHint.Font.Size := 9;
    PurgeHint.Font.Color := SoraMuted;
    PurgeHint.Cursor := crHand;
    PurgeHint.OnClick := @SelectPurgeData;

    UpdateUninstallChoice;

    CancelButton := TNewButton.Create(ChoiceForm);
    CancelButton.Parent := ChoiceForm;
    CancelButton.Left := ChoiceForm.ClientWidth - ScaleX(240);
    CancelButton.Top := ChoiceForm.ClientHeight - ScaleY(50);
    CancelButton.Width := ScaleX(104);
    CancelButton.Height := ScaleY(32);
    CancelButton.Caption := CustomMessage('SoraUninstallCancel');
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;

    RemoveButton := TNewButton.Create(ChoiceForm);
    RemoveButton.Parent := ChoiceForm;
    RemoveButton.Left := ChoiceForm.ClientWidth - ScaleX(128);
    RemoveButton.Top := ChoiceForm.ClientHeight - ScaleY(50);
    RemoveButton.Width := ScaleX(96);
    RemoveButton.Height := ScaleY(32);
    RemoveButton.Caption := CustomMessage('SoraRemove');
    RemoveButton.Default := False;
    RemoveButton.ModalResult := mrOk;

    if ChoiceForm.ShowModal = mrOk then
    begin
      Result := True;
    end;
  finally
    ChoiceForm.Free;
  end;
end;

function InitializeUninstall: Boolean;
begin
  PurgeUserData := HasCommandLineSwitch('/PURGEUSERDATA');
  if UninstallSilent then
    Result := True
  else
    Result := ShowUninstallDataChoice;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and PurgeUserData then
  begin
    DeleteFile(ExpandConstant('{app}\guiNConfig.json'));
    DeleteFile(ExpandConstant('{app}\statistics.json'));
    DeleteFile(ExpandConstant('{app}\user-wininet.json'));
    DelTree(ExpandConstant('{app}\guiLogs'), True, True, True);
    DelTree(ExpandConstant('{app}\guiBackups'), True, True, True);
    DelTree(ExpandConstant('{app}\guiConfigs'), True, True, True);
    DelTree(ExpandConstant('{app}\guiTemps'), True, True, True);
  end;
end;

function DesktopShortcutEnabled: Boolean;
begin
  Result := DesktopShortcutCheck.Checked;
end;

function StartupEnabled: Boolean;
begin
  Result := StartupCheck.Checked;
end;

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

  if SoraInstallMode = InstallModeDowngrade then
  begin
    Result := CustomMessage('SoraNewerVersion');
    Exit;
  end;

  if IsWindows7 and not IsWin64 and not IsKb3033929Installed then
  begin
    ExtractTemporaryFile('Windows6.1-KB3033929-x86.msu');
    InstallerPath := ExpandConstant('{tmp}\Windows6.1-KB3033929-x86.msu');
    if CompareText(GetSHA256OfFile(InstallerPath), '246C300A6AE6DCA99453F6839745AC0015953528A7065BED1B015F91B80CF64D') <> 0 then
    begin
      Result := CustomMessage('SoraIntegrityError');
      Exit;
    end;
    if ShellExec('runas', ExpandConstant('{sys}\wusa.exe'), '"' + InstallerPath + '" /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      Log(Format('KB3033929 завершился с кодом %d', [ResultCode]));
      if (ResultCode = 3010) or (ResultCode = 1641) then
        NeedsRestart := True;
      if (ResultCode <> 0) and (ResultCode <> 3010) and (ResultCode <> 1641) and (ResultCode <> 2359302) then
      begin
        Result := FmtMessage(CustomMessage('SoraPrerequisiteError'), [IntToStr(ResultCode)]);
        Exit;
      end;
    end
    else
    begin
      Result := FmtMessage(CustomMessage('SoraPrerequisiteError'), [IntToStr(ResultCode)]);
      Exit;
    end;
  end;

  if not IsDotNet48Installed then
  begin
    ExtractTemporaryFile('NDP48-x86-x64-AllOS-ENU.exe');
    InstallerPath := ExpandConstant('{tmp}\NDP48-x86-x64-AllOS-ENU.exe');
    if CompareText(GetSHA256OfFile(InstallerPath), '0A3A390C47E639D0F7FC65B21195FEE6B7F65B066F80F70C60FAB191D14B7E40') <> 0 then
    begin
      Result := CustomMessage('SoraIntegrityError');
      Exit;
    end;
    if not ShellExec('runas', InstallerPath, '/q /norestart', '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
    begin
      Result := FmtMessage(CustomMessage('SoraPrerequisiteError'), [IntToStr(ResultCode)]);
      Exit;
    end;
    if (ResultCode <> 0) and (ResultCode <> 3010) and (ResultCode <> 1641) then
    begin
      Result := FmtMessage(CustomMessage('SoraPrerequisiteError'), [IntToStr(ResultCode)]);
      Exit;
    end;
    if (ResultCode = 3010) or (ResultCode = 1641) then
      NeedsRestart := True;
  end;

  if not BackUpUserSettings then
    Result := CustomMessage('SoraBackupFailed');
end;
