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
WizardSizePercent=108,100
WizardResizable=no
WizardImageFile=
WizardSmallImageFile=
WizardBackColor=#111113
WizardBackColorDynamicDark=#111113
ShowLanguageDialog=auto
UsePreviousLanguage=yes
DisableStartupPrompt=yes
DisableWelcomePage=yes
DisableDirPage=yes
DisableReadyPage=yes
DisableReadyMemo=yes
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
SetupLogging=yes

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
russian.SoraQuickSetup=БЫСТРЫЕ НАСТРОЙКИ
russian.SoraDesktopTask=Создать ярлык на рабочем столе
russian.SoraStartupTask=Запускать Sora при входе в Windows
russian.SoraInstallMeta={#WindowsDisplayName}  —  автономный комплект
russian.SoraCancel=Отмена
russian.SoraProgress=Подготавливаем файлы и сетевые компоненты
russian.SoraLaunch=Запустить Sora
english.SoraInstallTitle=Install Sora
english.SoraInstallSubtitle=A VPN and proxy client without unnecessary screens or complicated setup.
english.SoraQuickSetup=QUICK SETUP
english.SoraDesktopTask=Create a desktop shortcut
english.SoraStartupTask=Start Sora when Windows starts
english.SoraInstallMeta={#WindowsDisplayName}  —  offline bundle
english.SoraCancel=Cancel
english.SoraProgress=Preparing files and network components
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
Type: files; Name: "{app}\guiNConfig.json"
Type: files; Name: "{app}\statistics.json"
Type: filesandordirs; Name: "{app}\guiLogs"
Type: filesandordirs; Name: "{app}\guiTemps"
Type: filesandordirs; Name: "{app}\guiBackups"
Type: filesandordirs; Name: "{app}\guiConfigs"

[Code]
const
  SoraCanvas = $00131111;
  SoraSurface = $001B1818;
  SoraBorder = $002F2A2A;
  SoraMuted = $00B0A9A9;
  SoraText = $00F5F4F4;

var
  SoraPage: TWizardPage;
  DesktopShortcutCheck: TNewCheckBox;
  StartupCheck: TNewCheckBox;
  InstallProgressTrack: TPanel;
  InstallProgressFill: TPanel;
  InstallProgressPercent: TNewStaticText;

procedure InitializeWizard;
var
  ButtonBottom: Integer;
  HeaderBrand: TNewStaticText;
  HeaderMeta: TNewStaticText;
  HeaderDivider: TPanel;
  PageAccent: TPanel;
  PageTitle: TNewStaticText;
  PageSubtitle: TNewStaticText;
  PageDivider: TPanel;
  OptionsTitle: TNewStaticText;
  PageMeta: TNewStaticText;
  InstallingTitle: TNewStaticText;
  FinishAccent: TPanel;
begin
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

  PageAccent := TPanel.Create(SoraPage);
  PageAccent.Parent := SoraPage.Surface;
  PageAccent.Left := ScaleX(36);
  PageAccent.Top := ScaleY(28);
  PageAccent.Width := ScaleX(3);
  PageAccent.Height := ScaleY(62);
  PageAccent.BevelOuter := bvNone;
  PageAccent.Color := SoraText;
  PageAccent.ParentBackground := False;

  PageTitle := TNewStaticText.Create(SoraPage);
  PageTitle.Parent := SoraPage.Surface;
  PageTitle.Left := ScaleX(56);
  PageTitle.Top := ScaleY(24);
  PageTitle.Width := SoraPage.SurfaceWidth - ScaleX(92);
  PageTitle.Height := ScaleY(30);
  PageTitle.Caption := CustomMessage('SoraInstallTitle');
  PageTitle.Font.Name := 'Segoe UI';
  PageTitle.Font.Size := 20;
  PageTitle.Font.Style := [fsBold];
  PageTitle.Font.Color := SoraText;

  PageSubtitle := TNewStaticText.Create(SoraPage);
  PageSubtitle.Parent := SoraPage.Surface;
  PageSubtitle.Left := ScaleX(56);
  PageSubtitle.Top := ScaleY(62);
  PageSubtitle.Width := SoraPage.SurfaceWidth - ScaleX(92);
  PageSubtitle.Height := ScaleY(34);
  PageSubtitle.AutoSize := False;
  PageSubtitle.WordWrap := True;
  PageSubtitle.Caption := CustomMessage('SoraInstallSubtitle');
  PageSubtitle.Font.Name := 'Segoe UI';
  PageSubtitle.Font.Size := 10;
  PageSubtitle.Font.Color := SoraMuted;

  PageDivider := TPanel.Create(SoraPage);
  PageDivider.Parent := SoraPage.Surface;
  PageDivider.Left := ScaleX(36);
  PageDivider.Top := ScaleY(108);
  PageDivider.Width := SoraPage.SurfaceWidth - ScaleX(72);
  PageDivider.Height := ScaleY(1);
  PageDivider.BevelOuter := bvNone;
  PageDivider.Color := SoraBorder;
  PageDivider.ParentBackground := False;

  OptionsTitle := TNewStaticText.Create(SoraPage);
  OptionsTitle.Parent := SoraPage.Surface;
  OptionsTitle.Left := ScaleX(36);
  OptionsTitle.Top := ScaleY(126);
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
  DesktopShortcutCheck.Top := ScaleY(153);
  DesktopShortcutCheck.Width := SoraPage.SurfaceWidth - ScaleX(72);
  DesktopShortcutCheck.Height := ScaleY(24);
  DesktopShortcutCheck.Caption := CustomMessage('SoraDesktopTask');
  DesktopShortcutCheck.Checked := False;
  DesktopShortcutCheck.Font.Name := 'Segoe UI';
  DesktopShortcutCheck.Font.Size := 10;
  DesktopShortcutCheck.Font.Color := SoraText;

  StartupCheck := TNewCheckBox.Create(SoraPage);
  StartupCheck.Parent := SoraPage.Surface;
  StartupCheck.Left := ScaleX(36);
  StartupCheck.Top := ScaleY(187);
  StartupCheck.Width := SoraPage.SurfaceWidth - ScaleX(72);
  StartupCheck.Height := ScaleY(24);
  StartupCheck.Caption := CustomMessage('SoraStartupTask');
  StartupCheck.Checked := False;
  StartupCheck.Font.Name := 'Segoe UI';
  StartupCheck.Font.Size := 10;
  StartupCheck.Font.Color := SoraText;

  PageMeta := TNewStaticText.Create(SoraPage);
  PageMeta.Parent := SoraPage.Surface;
  PageMeta.Left := ScaleX(36);
  PageMeta.Top := SoraPage.SurfaceHeight - ScaleY(26);
  PageMeta.Width := SoraPage.SurfaceWidth - ScaleX(72);
  PageMeta.Height := ScaleY(16);
  PageMeta.Caption := CustomMessage('SoraInstallMeta');
  PageMeta.Font.Name := 'Segoe UI';
  PageMeta.Font.Size := 8;
  PageMeta.Font.Color := SoraMuted;

  ButtonBottom := WizardForm.NextButton.Top + WizardForm.NextButton.Height;
  WizardForm.NextButton.Width := ScaleX(116);
  WizardForm.NextButton.Height := ScaleY(34);
  WizardForm.NextButton.Top := ButtonBottom - WizardForm.NextButton.Height;
  WizardForm.NextButton.Font.Name := 'Segoe UI';
  WizardForm.NextButton.Font.Style := [fsBold];
  WizardForm.NextButton.Default := False;
  WizardForm.BackButton.Visible := False;
  WizardForm.CancelButton.Caption := CustomMessage('SoraCancel');
  WizardForm.CancelButton.Width := ScaleX(88);
  WizardForm.CancelButton.Height := WizardForm.NextButton.Height;
  WizardForm.CancelButton.Top := WizardForm.NextButton.Top;
  WizardForm.CancelButton.Left := WizardForm.ClientWidth - ScaleX(24) - WizardForm.CancelButton.Width;
  WizardForm.NextButton.Left := WizardForm.CancelButton.Left - ScaleX(12) - WizardForm.NextButton.Width;

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
  WizardForm.StatusLabel.Left := ScaleX(36);
  WizardForm.StatusLabel.Top := ScaleY(82);
  WizardForm.StatusLabel.Width := WizardForm.InstallingPage.Width - ScaleX(72);
  WizardForm.StatusLabel.Font.Name := 'Segoe UI';
  WizardForm.StatusLabel.Font.Size := 9;
  WizardForm.StatusLabel.Font.Color := SoraMuted;
  WizardForm.StatusLabel.Caption := CustomMessage('SoraProgress');
  WizardForm.FilenameLabel.Visible := False;
  WizardForm.ProgressGauge.Visible := False;

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
  FinishAccent := TPanel.Create(WizardForm);
  FinishAccent.Parent := WizardForm.FinishedPage;
  FinishAccent.Left := ScaleX(36);
  FinishAccent.Top := ScaleY(46);
  FinishAccent.Width := ScaleX(3);
  FinishAccent.Height := ScaleY(68);
  FinishAccent.BevelOuter := bvNone;
  FinishAccent.Color := SoraText;
  FinishAccent.ParentBackground := False;
  WizardForm.FinishedHeadingLabel.Left := ScaleX(56);
  WizardForm.FinishedHeadingLabel.Top := ScaleY(42);
  WizardForm.FinishedHeadingLabel.Width := WizardForm.FinishedPage.Width - ScaleX(92);
  WizardForm.FinishedHeadingLabel.Font.Name := 'Segoe UI';
  WizardForm.FinishedHeadingLabel.Font.Size := 20;
  WizardForm.FinishedHeadingLabel.Font.Style := [fsBold];
  WizardForm.FinishedHeadingLabel.Font.Color := SoraText;
  WizardForm.FinishedLabel.Left := ScaleX(56);
  WizardForm.FinishedLabel.Top := ScaleY(82);
  WizardForm.FinishedLabel.Width := WizardForm.FinishedPage.Width - ScaleX(92);
  WizardForm.FinishedLabel.Font.Name := 'Segoe UI';
  WizardForm.FinishedLabel.Font.Size := 10;
  WizardForm.FinishedLabel.Font.Color := SoraMuted;
  WizardForm.RunList.Left := ScaleX(56);
  WizardForm.RunList.Top := ScaleY(142);
  WizardForm.RunList.Width := WizardForm.FinishedPage.Width - ScaleX(92);
  WizardForm.RunList.Color := SoraSurface;
  WizardForm.RunList.BorderStyle := bsNone;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = SoraPage.ID then
    WizardForm.NextButton.Caption := SetupMessage(msgButtonInstall)
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
