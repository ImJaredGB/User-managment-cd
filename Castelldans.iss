[Setup]
AppId={{97806af7-6482-4256-903e-ac9443f4841e}}
AppName=Castelldans
AppVerName=Castelldans (Actualización 1.2)
AppVersion=1.2
DefaultDirName={pf}\Castelldans
DefaultGroupName=Castelldans
OutputBaseFilename=CastelldansUpdateV2
Compression=lzma
SolidCompression=yes
SetupIconFile=windows\runner\resources\Castelldans.ico
WizardStyle=modern
UninstallDisplayIcon={app}\Castelldans.exe
PrivilegesRequired=admin

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
Source: "installer\VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Instalando dependencias de Microsoft..."; Flags: waituntilterminated
Filename: "{app}\Castelldans.exe"; Description: "{cm:LaunchProgram,Castelldans}"; Flags: nowait postinstall skipifsilent

[Icons]
Name: "{group}\Castelldans"; Filename: "{app}\Castelldans.exe"
Name: "{commondesktop}\Castelldans"; Filename: "{app}\Castelldans.exe"; Tasks: desktopicon

[Code]
function CheckOldInstallation(): Boolean;
var
  UninstallString: String;
  Response: Integer;
  ExecResult: Integer; // <- Nueva variable para capturar el resultado del Exec
begin
  Result := True;

  // Busca el desinstalador anterior en el registro
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, 
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{{97806af7-6482-4256-903e-ac9443f4841e}_is1', 
    'UninstallString', UninstallString) then
  begin
    // Pregunta al usuario si quiere desinstalar la versión anterior
    Response := MsgBox('Se ha detectado una versión anterior de Castelldans.'#13#13 +
      '¿Deseas desinstalarla antes de continuar?', mbConfirmation, MB_YESNO);

    if Response = IDYES then
    begin
      // Ejecuta el desinstalador en modo silencioso
      if Exec(RemoveQuotes(UninstallString), '/SILENT', '', SW_SHOW, ewWaitUntilTerminated, ExecResult) then
      begin
        MsgBox('La versión anterior se ha desinstalado correctamente.', mbInformation, MB_OK);
      end
      else
      begin
        MsgBox('Ocurrió un error al intentar desinstalar la versión anterior.', mbError, MB_OK);
        Result := False;
      end;
    end
    else
    begin
      // Si el usuario no quiere desinstalar, cancela la instalación
      MsgBox('Debes desinstalar la versión anterior antes de continuar.', mbInformation, MB_OK);
      Result := False;
    end;
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := CheckOldInstallation();
end;
