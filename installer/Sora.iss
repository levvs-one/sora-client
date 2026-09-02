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
WizardSmallImageFile=..\v2rayN\v2rayN\Assets\Sora\sora-logo-white.png
WizardSmallImageBackColor=#111113
ShowLanguageDialog=auto
UsePreviousLanguage=yes
DisableStartupPrompt=yes
DisableWelcomePage=yes
DisableDirPage=auto
DisableReadyPage=yes
DisableReadyMemo=yes
ShowTasksTreeLines=no
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
SetupLogging=yes

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
russian.WizardSelectDir=Папка установки
russian.SelectDirDesc=Куда установить Sora
russian.SelectDirLabel3=Файлы приложения и сетевые компоненты будут сохранены здесь.
russian.SelectDirBrowseLabel=Можно оставить путь по умолчанию.
russian.WizardSelectTasks=Быстрые настройки
russian.SelectTasksDesc=Ярлык и автозапуск
russian.SelectTasksLabel2=Выберите, что включить сразу. Всё можно изменить позже.
russian.WizardInstalling=Установка Sora
russian.InstallingLabel=Устанавливаем приложение и необходимые компоненты.
russian.FinishedHeadingLabel=Sora готова
russian.FinishedLabelNoIcons=Добавьте подписку, выберите сервер и подключитесь.
russian.FinishedLabel=Добавьте подписку, выберите сервер и подключитесь.
russian.ClickFinish=Можно начинать.
russian.ButtonNext=&Продолжить
russian.ButtonInstall=&Установить
russian.ButtonFinish=&Готово
english.WizardSelectDir=Installation folder
english.SelectDirDesc=Where to install Sora
english.SelectDirLabel3=The application and its network components will be stored here.
english.SelectDirBrowseLabel=You can keep the default path.
english.WizardSelectTasks=Quick setup
english.SelectTasksDesc=Shortcut and startup
english.SelectTasksLabel2=Choose what to enable now. You can change everything later.
english.WizardInstalling=Installing Sora
english.InstallingLabel=Installing the application and required components.
english.FinishedHeadingLabel=Sora is ready
english.FinishedLabelNoIcons=Add a subscription, choose a server, and connect.
english.FinishedLabel=Add a subscription, choose a server, and connect.
english.ClickFinish=You can get started.
english.ButtonNext=&Continue
english.ButtonInstall=&Install
english.ButtonFinish=&Done

[CustomMessages]
russian.SoraShortcutGroup=Ярлыки
russian.SoraDesktopTask=Создать ярлык на рабочем столе
russian.SoraStartupGroup=Автозапуск
russian.SoraStartupTask=Запускать Sora при входе в Windows
russian.SoraLaunch=Запустить Sora
english.SoraShortcutGroup=Shortcuts
english.SoraDesktopTask=Create a desktop shortcut
english.SoraStartupGroup=Startup
english.SoraStartupTask=Start Sora when Windows starts
english.SoraLaunch=Launch Sora

[Tasks]
Name: "desktopicon"; Description: "{cm:SoraDesktopTask}"; Flags: unchecked
Name: "autorun"; Description: "{cm:SoraStartupTask}"; Flags: unchecked

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
procedure InitializeWizard;
var
  ButtonBottom: Integer;
begin
  WizardForm.PageNameLabel.Font.Name := 'Segoe UI';
  WizardForm.PageNameLabel.Font.Size := 14;
  WizardForm.PageNameLabel.Font.Style := [fsBold];
  WizardForm.PageNameLabel.Top := ScaleY(10);
  WizardForm.PageNameLabel.Height := ScaleY(24);
  WizardForm.PageDescriptionLabel.Font.Name := 'Segoe UI';
  WizardForm.PageDescriptionLabel.Font.Size := 9;
  WizardForm.PageDescriptionLabel.Top := ScaleY(36);
  WizardForm.PageDescriptionLabel.Height := ScaleY(18);
  WizardForm.WizardSmallBitmapImage.Visible := False;

  WizardForm.SelectDirBitmapImage.Visible := False;
  WizardForm.SelectDirLabel.Left := 0;
  WizardForm.SelectDirLabel.Width := WizardForm.SelectDirPage.Width;
  WizardForm.SelectDirBrowseLabel.Left := 0;
  WizardForm.SelectDirBrowseLabel.Width := WizardForm.SelectDirPage.Width;
  WizardForm.DirEdit.Font.Name := 'Segoe UI';
  WizardForm.DirEdit.Font.Size := 10;

  WizardForm.TasksList.BorderStyle := bsNone;
  WizardForm.TasksList.Flat := True;
  WizardForm.TasksList.ShowLines := False;
  WizardForm.TasksList.MinItemHeight := ScaleY(34);
  WizardForm.TasksList.Offset := ScaleX(8);

  ButtonBottom := WizardForm.NextButton.Top + WizardForm.NextButton.Height;
  WizardForm.NextButton.Width := ScaleX(116);
  WizardForm.NextButton.Height := ScaleY(34);
  WizardForm.NextButton.Top := ButtonBottom - WizardForm.NextButton.Height;
  WizardForm.NextButton.Font.Name := 'Segoe UI';
  WizardForm.NextButton.Font.Style := [fsBold];
  WizardForm.NextButton.Default := False;
  WizardForm.BackButton.Height := WizardForm.NextButton.Height;
  WizardForm.BackButton.Top := WizardForm.NextButton.Top;
  WizardForm.CancelButton.Height := WizardForm.NextButton.Height;
  WizardForm.CancelButton.Top := WizardForm.NextButton.Top;

  WizardForm.WizardBitmapImage2.Visible := False;
  WizardForm.FinishedHeadingLabel.Left := ScaleX(36);
  WizardForm.FinishedHeadingLabel.Top := ScaleY(48);
  WizardForm.FinishedHeadingLabel.Width := WizardForm.FinishedPage.Width - ScaleX(72);
  WizardForm.FinishedHeadingLabel.Font.Name := 'Segoe UI';
  WizardForm.FinishedHeadingLabel.Font.Size := 17;
  WizardForm.FinishedHeadingLabel.Font.Style := [fsBold];
  WizardForm.FinishedLabel.Left := ScaleX(36);
  WizardForm.FinishedLabel.Top := ScaleY(86);
  WizardForm.FinishedLabel.Width := WizardForm.FinishedPage.Width - ScaleX(72);
  WizardForm.RunList.Left := ScaleX(36);
  WizardForm.RunList.Width := WizardForm.FinishedPage.Width - ScaleX(72);
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpSelectTasks then
    WizardForm.NextButton.Caption := SetupMessage(msgButtonInstall)
  else if CurPageID = wpFinished then
    WizardForm.NextButton.Caption := SetupMessage(msgButtonFinish)
  else
    WizardForm.NextButton.Caption := SetupMessage(msgButtonNext);
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
