[Setup]
AppId={{97806af7-6482-4256-903e-ac9443f4841e}}
AppName=Castelldans
AppVerName=Castelldans (Actualización 1.1)
AppVersion=1.1
DefaultDirName={pf}\Castelldans
DefaultGroupName=Castelldans
OutputBaseFilename=CastelldansUpdate
Compression=lzma
SolidCompression=yes
SetupIconFile=windows\runner\resources\Castelldans.ico
WizardStyle=modern
UninstallDisplayIcon={app}\Castelldans.exe

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:";

[Files]
; Archivos de la aplicación (se actualizan si existen)
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

; Instalador de Visual C++ Redistributable
Source: "installer\VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
; Instalar dependencias de Microsoft (modo silencioso)
Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Instalando dependencias de Microsoft..."; Flags: waituntilterminated

; Ejecutar la app al finalizar (opcional)
Filename: "{app}\Castelldans.exe"; Description: "{cm:LaunchProgram,Castelldans}"; Flags: nowait postinstall skipifsilent

[Icons]
; Acceso directo en el menú Inicio
Name: "{group}\Castelldans"; Filename: "{app}\Castelldans.exe"

; Acceso directo en el escritorio
Name: "{commondesktop}\Castelldans"; Filename: "{app}\Castelldans.exe"; Tasks: desktopicon

[Code]
function CheckOldInstallation(): Boolean;
var
  InstallPath: String;
begin
  Result := True;
  InstallPath := ExpandConstant('{pf}\Castelldans');

  if DirExists(InstallPath) then begin
    if not RegKeyExists(HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{{A1B2C3D4-E5F6-47AB-90CD-1234567890AB}_is1') then begin
      MsgBox('Se ha detectado una versión anterior de Castelldans instalada sin AppId. ' +
             'Por favor, desinstala la versión anterior manualmente antes de continuar con la instalación de la versión 1.1.',
             mbInformation, MB_OK);
      Result := False;
    end;
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := CheckOldInstallation();
end;
