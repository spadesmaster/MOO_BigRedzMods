:: ModDev.bat: Find path to Steam and game and then setup environment variables and shortcuts for dev work there
::
:: Tested to run under both basic Windows Cmd and the more advanced Powershell
:: Coding Conventions used:
:: - All caps for script LOCAL variables e.g. %SCRIPTNAME%
:: - Mixed leading upper for Env variables e.g. %Path%
:: - Mixed leading lower for LOCAL functions e.g. exitError
:: - All lower for built-in shell CMDs e.g. echo, if prefaced with _ its a function return value
::
:: 27-Mar-2023 BigRedz Created for MOO Mods Getting Started document and easily editable for other game mod dev
:: 28-Mar-2023 BigRedz Created utility functions for exitError, findFileOrFolder, createShortcut
:: 30-Mar-2023 BigRedz Polished up output gave up on making a more generic iterator since BAT sucks at this
::
:: Summary of what this script does:
::
:: 1)Quickly scans your system to locate where Steamapps, MOO, and other data files are located on your system
::
:: 2)Sets up environment variables for quick access on your system for the following:
::   %MOODocs% to Documents\Master of Orion whereever this user's Documents folder is located
::   %MOODev% to %MOODocs%\Dev
::   %MOOLocalMods% to %MOODocs%\Mods
::   %SteamPath% to C:\Program Files\Steam or wherever you installed your Steam
::   %SteamApps% to %SteamPath%\steamapps 
::   %SteamWork% to %SteamApps%\workshop
::   %MOOSteamMods% to %SteamWork%\298050 (Steam ID for MOO)
::   %MOOGame% to %SteamApps%\common\Master of Orion
::   %MOOData% to %MOOGame%\MasterOfOrion_Data
::
:: 3)Creates a new ModDevs folder (+desktop shortcut) in %MOOLocal% and adds these shortcuts inside:
::   Steam to %MOOSteam% workshop folder where Steam will download/upload mods to
::   Local to %MOOLocal% or .. (parent) your local mod installs, saves, and ModDev work
::   Game to %MOOGame% folder which has the MasterOfOrion.exe and files/data below
::   Data to %MOOData% folder for game’s data files esp. Output_log to debug crashes/mods
::   Modding to %MOOGame%\Modding folder which has most of the YAML files you can tweak
::   Names to %MOOData%\StreamingAssets\Localization\Backend tech/bldg/weap CSVs
::   Thumbs to %MOOData%\StreamingAssets\Assets thumbnail image game assets
::   Plugins to %MOOData%\Plugins for custom Mono Plugin DLL development (advanced)
::   Assembly to %MOOData%\Managed to Assembly-CSharp.dll to decompile (advanced)
::

:: uncomment line below for quieter/release execution, uncomment to DEBUG syntax errors since CMD/BAT sucks
@echo off

:: setlocal = All variables created should be local to prevent interfering with any subscripts we may call
:: EnableExtensions = Use Command extensions such as %CD% %DATE% (defaults True since Vista but just in case...)
:: EnableDelayedExpansion = Expand variables at execution rather than parse (useful for filenames with spaces)
setlocal EnableExtensions EnableDelayedExpansion

:: Change these to setup a different game's environment variables or change the names used by this script
set MODDEV=Dev
set MODFOLDER=Mods
set GAMESHORT=MOO
set GAMELONG=Master of Orion
set GAMEEXE=MasterOfOrion.exe
set GAMEDATA=MasterOfOrion_Data
set GAMESTEAMID=298050

:: Give some newline padding and early feedback as to what script is running and what we are doing
set SCRIPTNAME=%0
echo: & echo: & echo: & echo: & echo: & echo %SCRIPTNAME%: Setting up %GAMESHORT% %MODDEV% for %GAMELONG% with Steam ID %GAMESTEAMID%...
echo: & echo Scanning for important directories for dev work:

:: Find the user's Documents folder (usually UserProfile or OneDrive but registry check is the best way
:: source: https://social.technet.microsoft.com/Forums/windows/en-US/8ffbd83f-66fc-4f99-9698-e772a695941b/
:: Value Personal in HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
:: source: https://superuser.com/questions/995591/how-to-get-a-registry-value-and-set-into-a-variable-in-batch
:: damn this was super hard in figure out, Batch is so primitive!
for /F "tokens=2* skip=2" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal') do (
  set UserDocs=%%b
)
echo    FOUND: User Documents for %USERNAME% at %UserDocs%
set MOODocs=%UserDocs%\%GAMELONG%
echo    FOUND: %GAMELONG% Documents (Saves, Local Mods) at %MOODocs%
if not exist "%MOODocs%" (
   CALL :exitError "No %GAMELONG% found at %MOODocs%"
)

:: Find the game's Local Mod installation folder
::CALL :findFileOrFolder %GAMELOCAL% "%USERGAMEDIR%\%MODFOLDER%" "%CD%\%MODFOLDER%"
::if exist %GAMELOCAL% (
::    echo FOUND: Local %GAMESHORT% %MODFOLDER% at %GAMELOCAL%...
::) else (
::   //::CALL :exitError "No %MODFOLDER% found at %GAMELOCAL%"
::)
set MOOLocalMods=%MOODocs%\%MODFOLDER%
set MOODev=%MOODocs%\%MODDEV%

:: Find Steam installation folder from the registry
for /F "tokens=2* skip=2" %%a in ('reg query "HKLM\Software\Wow6432Node\Valve\Steam" /v InstallPath') do (
    set SteamPath=%%b
)
set SteamApps=%SteamPath%\steamapps
echo    FOUND: Steam installed at %SteamPath%
echo    FOUND: Steamapps installed at %SteamApps%
if not exist %SteamPath% (
	CALL :exitError "You do not appear to have Steam installed!"
)
set SteamWork=%SteamApps%\workshop
set MOOSteamMods=%SteamWork%\content\%GAMESTEAMID%
if exist %MOOSteamMods% (
	echo    FOUND: MOO SteamMods found at %MOOSteamMods%
)

:: Find game EXE inside steamapps
::%SteamApps%\common\%GAMELONG%
set MOOGame=%SteamApps%\common\%GAMELONG%
set MOOData=%MOOGame%\MasterOfOrion_Data

echo: & echo Creating necessary dev folders:
if not exist "%MOOLocalMods%" (	
	mkdir "%MOOLocalMods%"
	echo    Created %MOOLocalMods% folder
)
if not exist "%MOODev%" (
	mkdir "%MOODev%"
	echo    Created %MOODev% folder
)
	 


:: Setup environment variables turn echo on so they can see the vars being set
echo: & echo Setting up environment vars for future dev work:
CALL :prettySetX UserDocs "%UserDocs%"
CALL :prettySetX SteamPath "%SteamPath%"
CALL :prettySetX SteamWork "%SteamWork%"
CALL :prettySetX SteamApps "%SteamApps%"
CALL :prettySetX MOODocs "%MOODocs%"
CALL :prettySetX MOOLocalMods "%MOOLocalMods%"
CALL :prettySetX MOOSteamMods "%MOOSteamMods%"
CALL :prettySetX MOODev "%MOODev%"
CALL :prettySetX MOOData "%MOOData%"
CALL :prettySetX MOOGame "%MOOGame%"

::   SteamMods to %MOOWork workshop folder where Steam mods will download/upload to/from
::   LocalMods to %MOOLocal% or .. (parent) your local mod installs, saves, and ModDev work
::   Game to %MOOGame% folder which has the MasterOfOrion.exe and files/data below
::   Data to %MOOData% folder for game’s data files esp. Output_log to debug crashes/mods
::   Modding to %MOOGame%\Modding folder which has most of the YAML files you can tweak
::   Names to %MOOData%\StreamingAssets\Localization\Backend tech/bldg/weap CSVs
::   Thumbs to %MOOData%\StreamingAssets\Assets thumbnail image game assets
::   Plugins to %MOOData%\Plugins for custom Mono Plugin DLL development (advanced)
::   Assembly to %MOOData%\Managed to Assembly-CSharp.dll to decompile (advanced)
echo: & echo Creating desktop shortcut for %GAMESHORT% Dev and shortcuts inside to various useful Mod/game locations...
CALL :CreateShortcut "%UserProfile%\Desktop\%GAMESHORT% Dev" "%MOODev%"

CALL :CreateShortcut "%MOODEV%\SteamMods" "%MooSteamMods%"
CALL :CreateShortcut "%MOODEV%\LocalMods" "%MooLocalMods%"

CALL :CreateShortcut "%MOODEV%\Game" "%MOOGame%"
CALL :CreateShortcut "%MOODEV%\Data" "%MOOData%"
CALL :CreateShortcut "%MOODEV%\GameYaml" "%MOOGame%\Modding"
CALL :CreateShortcut "%MOODEV%\UcpYaml" "%MOOLocalMods%\Unofficial Code Patch"
CALL :CreateShortcut "%MOODEV%\Names" "%MOOData%\StreamingAssets\Localization\Backend"
CALL :CreateShortcut "%MOODEV%\Assets" "%MOOData%\StreamingAssets\Assets"
CALL :CreateShortcut "%MOODEV%\Plugins" "%MOOData%\Plugins"
CALL :CreateShortcut "%MOODEV%\Assembly" "%MOOData%\Managed"
CALL :CreateShortcut "%MOODEV%\output_log.txt" "%MOOData%\output_log.txt"
CALL :CreateShortcut "%MOODEV%\config.cfg" "%MOOGAME%\config.cfg"



echo: & echo FINISHED: DevEnv Setup complete for %GAMELONG% at %MOODev%
cd "%MOODev%"
pause
goto:eof


::---------------------------------------------------------------------------------
::prettySetX - Set user environment variable and surpress output but show values
::---------------------------------------------------------------------------------
:prettySetX [envVar] [value]
	setlocal EnableDelayedExpansion
	echo     %~1 set to %~2
    setx %~1 "%~2" > nul
	exit /B


::---------------------------------------------------------------------------------
::strLen - Subroutine to return the length of a string
::Parameter 1 - string to test
::Parameter 2 - number variable to return the length into
::---------------------------------------------------------------------------------
:strLen [strToCheck] [varReturnLen]
	setlocal EnableDelayedExpansion
    
    set "s=#!%~1!"
    set "len=0"

    ::haven't deciphered how this works (btree?) but it does
    for %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
    	if "!s:~%%N,1!" neq "" (
      	   set /a "len+=%%N"
      	   set "s=!s:~%%N!"
	)
    )

    ::Return the length in the second variable provided, else just output it instead
    endlocal & if "%~2" neq "" (set %~2=%len%) else echo %len%
    exit /b



::---------------------------------------------------------------------------------
::findFileOrFolder - Subroutine finds a file or folder in a priority order list
::Parameter 1 (req) - variable to return FIRST file or folder found from list (nul if none)
::Optional Parameter 2-255: <additional file/folder paths to test for in check order
::---------------------------------------------------------------------------------
:findFileOrFolder [varFirstFoundFile] [Paths...]
    setlocal EnableDelayedExpansion
	
    ::Count and create a vector/pseudoarray _path with the passed in parameters for easy reference
    ::Source: https://stackoverflow.com/questions/19835849/batch-script-iterate-through-arguments
    set _count=0
    for %%x in (%*) do (
    	set /A _count+=1
		set _path[!_count!]=%%~x
    )
    ::like this better but not sure it works
	::set ARGC=0
    REM for %%x in (%*) do (
    	REM set /A ARGC+=1
    	REM set "ARGV[!ARGC!]=%%~x"
    REM )

    ::Loop through _path[i] provided starting at 2 (to skip return) and test for existence
    ::Source: https://ss64.com/nt/syntax-arrays.html
    set FOUND=""
    echo Scanning for %~1 in:
    for /L %%G in (2,1,%_count%) do (
        echo    !_path[%%G]!
    	if exist "_path[%%G]" set FOUND=!_path[%%G]!
    )
    echo Found %FOUND%
    
    ::Return the found path in the first variable provided, else just output it instead
    endlocal & if "%~1" neq "" (set %~1=%FOUND%) else echo %FOUND%

    exit /b




::---------------------------------------------------------------------------------
::createShortcuts - subroutine to create shortcut (only solution I could find used VBS)
::mklink would work but it requires to be Run as Administrator and we dont want that
:createShortcut [shortcutNameAndPath] [targetNameAndPath]
	setlocal EnableDelayedExpansion

    echo     Created %~1 shortcut to %~2
	set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.vbs"
    echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
    echo sLinkFile = "%~1.lnk" >> %SCRIPT%
    echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
    echo oLink.TargetPath = "%~2" >> %SCRIPT%
    echo oLink.Save >> %SCRIPT%
    cscript /nologo %SCRIPT%
    del %SCRIPT%

    exit /b



::---------------------------------------------------------------------------------
::exitError: Subroutine to report errors to STDOUT and STDERR and exit the script
::If global ERRORLEVEL not already set by caller, it will set it to 1 before exiting
::
::Optional Parameter 1: <text for error message>
::Optional Parameter 2-255: <additional lines to show in error message>
::---------------------------------------------------------------------------------
:exitError [content for error message]
    setlocal EnableDelayedExpansion

    ::Play system beep (if set) add an ERROR: prefix and then
    ::output each additional parameter provided on its own line ~ removes quotes
    ::BUG: 2>&1 should output to both STDOUT and STDERR but gives errors?
    echo 
    echo "[%0]: ERROR! %~1"
	
    ::If global ERRORLEVEL not already set before this call, this sets it to 1 before exiting
    ::Never directly set ERRORLEVEL, use (CALL)  Source: https://ss64.com/nt/errorlevel.html
    if %ERRORLEVEL% equ 0 (CALL)

	::Stop execution and exit the script now
    goto :eof 
