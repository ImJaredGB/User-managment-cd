; --- Instalador de Castelldans (proyecto Flutter) ---

[Setup]
AppName=Castelldans
AppVersion=1.0
DefaultDirName={pf}\Castelldans
DefaultGroupName=Castelldans
OutputBaseFilename=CastelldansSetup
Compression=lzma
SolidCompression=yes
SetupIconFile=windows\runner\resources\Castelldans.ico
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"; Flags: unchecked

[Files]
; Archivos de tu aplicación Flutter (release)
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

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
