#define MyAppName "Sora"
#define MyAppVersion "0.1.0"
#define MyAppExeName "Sora.exe"

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
AppPublisher=Sora Contributors
AppPublisherURL=https://github.com/levvs-one/sora-client
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany=Sora Contributors
VersionInfoDescription=Неофициальный клиент для Windows 7 x86
DefaultDirName={localappdata}\Programs\Sora
DefaultGroupName=Sora
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
MinVersion=6.1sp1
ArchitecturesAllowed=x86compatible
OutputDir={#BuildOutputDir}
OutputBaseFilename=Sora-{#MyAppVersion}-Win7-x86-Setup
SetupIconFile={#StageDir}\sora.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
SetupLogging=yes
LicenseFile={#StageDir}\LICENSE

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Ярлыки:"; Flags: unchecked
Name: "autorun"; Description: "Запускать в фоне при входе в Windows"; GroupDescription: "Автозапуск:"; Flags: unchecked

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#NdpInstaller}"; DestName: "NDP48-x86-x64-AllOS-ENU.exe"; Flags: dontcopy
Source: "{#KbInstaller}"; DestName: "Windows6.1-KB3033929-x86.msu"; Flags: dontcopy

[Icons]
Name: "{group}\Sora"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\Sora"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{userstartup}\Sora"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--silent"; WorkingDir: "{app}"; Tasks: autorun

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Запустить Sora"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent; Check: not WizardNoIcons

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
