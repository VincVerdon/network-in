; Network-In! simulator installation on Windows
; VVerdon Corp.! 
; Version 20251011

Function .oninit
  Var /GLOBAL networkin_version
  StrCpy $networkin_version "2.0"
FunctionEnd


;Include Modern UI
;--------------------------------

  !include "MUI2.nsh"


;Généralités
;--------------------------------

; The name of the installer
Name "Network-In! Simulateur $networkin_version"

; The file to write
OutFile "Network-In-install-2.0.exe"

; Request application privileges for Windows Vista and higher
RequestExecutionLevel user
;RequestExecutionLevel admin

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir $LOCALAPPDATA\network-in

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\network-in" "Install_Dir"


;Interface Settings
;--------------------------------

  !define MUI_ABORTWARNING

  ;Show all languages, despite user's codepage
  !define MUI_LANGDLL_ALLLANGUAGES

;--------------------------------
;Language Selection Dialog Settings

  ;Remember the installer language
  !define MUI_LANGDLL_REGISTRY_ROOT "HKCU" 
  !define MUI_LANGDLL_REGISTRY_KEY "Software\Modern UI Test" 
  !define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"


;Pages
;--------------------------------

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "doc\license.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  

;Languages
;--------------------------------
 
  !insertmacro MUI_LANGUAGE "English"
  !insertmacro MUI_LANGUAGE "French"


;Installer Sections
;--------------------------------

Section "WSL" SecWSL

  SectionIn RO

  !include x64.nsh
  ${DisableX64FSRedirection}
  nsExec::execToStack '"$SYSDIR\wsl.exe" --status'
  pop $0
  pop $1
  ${If} $0 == 0
    DetailPrint "WSL version : $1"
  ${Else}
    MessageBox MB_TOPMOST $(MES_INST_WSL_1)
    ;SetOutPath "$INSTDIR"
    ;File "install_WSL.cmd"
    ;ExecShell "runas" '"install_WSL.cmd"'
    ;Delete "install_WSL.cmd"
    ;MessageBox MB_TOPMOST $(MES_INST_WSL_2)
    Abort
  ${EndIf}

SectionEnd


Section "Simulateur" SecSimu

  SectionIn RO

  !include x64.nsh
  ${DisableX64FSRedirection}

  SetOutPath "$INSTDIR"
  File /r doc
  File network-in.ico

  SetOutPath "$LOCALAPPDATA\Microsoft\WSL"
  File ".wslgconfig"
  
  SetOutPath "$INSTDIR\VM"
  File networkin.tgz
  File install_VM.cmd

  ExecWait '"install_VM.cmd" "$INSTDIR\VM"'
  Delete networkin.tgz
  Delete install_VM.cmd
  
  ;SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\Network-In-Simulator"
  CreateShortcut "$SMPROGRAMS\Network-In-Simulator\Network-In-Simulator.lnk" \
    "c:\Program Files\WSL\wslg.exe" "-d NetworkIn --cd ~ -- /usr/bin/network-in" "$INSTDIR\network-in.ico"
  CreateShortcut "$DESKTOP\Network-In-Simulator.lnk" \
    "c:\Program Files\WSL\wslg.exe" "-d NetworkIn --cd ~ -- /usr/bin/network-in" "$INSTDIR\network-in.ico"
  
  ;Language and other configuration in VM
  Var /GLOBAL lang
  StrCpy $lang "auto"
  ${If} $LANGUAGE == 1036
    StrCpy $lang "fr"
  ${EndIf}
  Exec "$SYSDIR\wsl.exe -d NetworkIn -u root -- /root/init.sh $lang '$DOCUMENTS'"

  ;Store installation folder
  WriteRegStr HKCU "Software\network-in" "Install_Dir" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateShortcut "$SMPROGRAMS\Network-In-Simulator\Uninstall-Network-In-Simulator.lnk" "$INSTDIR\Uninstall.exe"

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

  !include x64.nsh
  ${DisableX64FSRedirection}
  Exec "$SYSDIR\wsl.exe --unregister NetworkIn"

  ;SetShellVarContext all
  RMdir /r "$SMPROGRAMS\Network-In-Simulator"
  Delete "$DESKTOP\Network-In-Simulator.lnk"

  RMdir /r "$LOCALAPPDATA\Microsoft\WSL"
  RMDir /r "$INSTDIR"

  DeleteRegKey /ifempty HKCU "Software\network-in"

SectionEnd


;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecSimu ${LANG_ENGLISH} "The simulator"
  LangString DESC_SecSimu ${LANG_FRENCH} "Le simulateur"
  LangString DESC_SecWSL ${LANG_ENGLISH} "WSL installation"
  LangString DESC_SecWSL ${LANG_FRENCH} "Installation de WSL"
  ;LangString MES_INST_WSL_1 ${LANG_ENGLISH} "WSL is not installed but necessary. \nInstallation stage will start, the screen can feel empty for a moment, be patient"
  ;LangString MES_INST_WSL_1 ${LANG_FRENCH} "WSL n'est pas installe mais est necessaire. \nL'installation va demarrer, l'ecran peut rester vide un moment, soyez patient"

  LangString MES_INST_WSL_1 ${LANG_ENGLISH} "WSL is not installed but necessary. Open a cmd.exe terminal and enter command :$\r$\nwsl.exe --install --no-distribution. $\r$\nReboot the computer. Run again installation program after reboot"
  LangString MES_INST_WSL_1 ${LANG_FRENCH} "WSL n'est pas installe mais est necessaire. Ouvrez un terminal cmd.exe and entrez la commands :$\r$\nwsl.exe --install --no-distribution. $\r$\nRedemarrez l'ordinateur. Relancez le programme d'installation apres redemarrage"

  ;LangString MES_INST_WSL_2 ${LANG_ENGLISH} "The computer is going to reboot before to continue. Run again installation program after reboot"
  ;LangString MES_INST_WSL_2 ${LANG_FRENCH} "L'ordinateur va redemarrer avant de poursuite. Relancez le programme d'installation apres redemarrage"


  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSimu} $(DESC_SecSimu)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
