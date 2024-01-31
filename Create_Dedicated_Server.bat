@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Define variables
SET "TargetFolder={CHOOSE YOUR DIRECTORY}"
SET "QueryPort=27040" :: Steam CMD port
SET "Port=8223" :: Server port
SET "Players=32"
SET "AutoUpdate=true"  ; Set to true or false
SET "AutoReplicate=true"  ; Set to true or false

:: Do not change these variables!
SET "PalServerExe=%TargetFolder%\Pal\Binaries\Win64\PalServer-Win64-Test-Cmd.exe"
SET "SavedFolder=%TargetFolder%\Pal\Saved"
SET "EngineIni=%TargetFolder%\Pal\Saved\Config\WindowsServer\Engine.ini"
SET "SettingsIni=%TargetFolder%\DefaultPalWorldSettings.ini"
SET "PalWorldSettingsIni=%TargetFolder%\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini"

:: Generate a "safe" name from TargetFolder by removing special characters and adding 'Magic' prefix
SET "SafeFolderName=%TargetFolder:C=%"
SET "SafeFolderName=!SafeFolderName::=!"
SET "SafeFolderName=!SafeFolderName:\=!"
SET "SafeFolderName=!SafeFolderName:/=!"
SET "SafeFolderName=!SafeFolderName:.=!"
SET "RuleName=Magic_!SafeFolderName!"

:: Timeout settings
SET /A TimeoutLimit=600  ; 10 minutes in seconds
SET /A ElapsedTime=0

:: Unique title for the new window
SET "PalServerTitle=PalWorld Server Process sdfj2nnv001mn4"

:: Check for administrative privileges
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo You must run this script as an administrator.
    echo Please right-click and select "Run as administrator".
    pause
    exit
)

:: Verify SteamCMD exists
IF NOT EXIST "C:\steamcmd\steamcmd.exe" (
    echo Error: "C:\steamcmd\steamcmd.exe" not found. Please install SteamCMD and ensure it is available at this path.
    exit /b
)

 Step 1: Update and Install Server
 if "%AutoUpdate%"=="true" (
     "C:\steamcmd\steamcmd.exe" +login anonymous +force_install_dir "%TargetFolder%" +app_update 2394010 validate +quit
 )

:LaunchAndWaitForSaved
IF EXIST "%PalServerExe%" (
    start "%PalServerTitle%" "%PalServerExe%"
    SET /A ElapsedTime=0

    :WaitForSavedFolder
    IF EXIST "%SavedFolder%" (
        IF EXIST "%EngineIni%" (
            IF EXIST "%SettingsIni%" (
                IF EXIST "%PalWorldSettingsIni%" GOTO KillServerProcess
            )
        )
    )
    IF %ElapsedTime% GEQ %TimeoutLimit% GOTO TimeoutError
    ping localhost -n 2 > nul
    SET /A ElapsedTime+=1
    GOTO WaitForSavedFolder
) ELSE (
    echo PalServer executable not found.
    exit /b
)

:KillServerProcess
taskkill /FI "WINDOWTITLE eq %PalServerTitle%" /F
GOTO ContinueWithScript

:ContinueWithScript
:: Check if the Firewall Rule for PalServer Application already exists
netsh advfirewall firewall show rule name="%RuleName%" >nul

IF %ERRORLEVEL% NEQ 0 (
    echo The Windows Firewall rule "%RuleName%" does not exist. Adding it now...
) ELSE (
    echo Windows Firewall rule "%RuleName%" already exists. Deleting and re-adding it...
    netsh advfirewall firewall delete rule name="%RuleName%"
)

:: Add (or re-add) the firewall rule
netsh advfirewall firewall add rule name="%RuleName%" dir=in action=allow program="%PalServerPath%" enable=yes profile=any
echo Windows Firewall rule "%RuleName%" has been added or updated.


:: Step 2: Create Start_Palworld_Server.bat
(
    echo @echo off
    if "%AutoUpdate%"=="true" echo call "%TargetFolder%\Update_Server.bat"
    if "%AutoReplicate%"=="true" echo call "%TargetFolder%\Replicate_Default_Everywhere.bat"
    echo start PalServer.exe -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -QueryPort=%QueryPort% -port=%Port% -players=%Players%
) > "%TargetFolder%\Start_Palworld_Server.bat"

:: Step 3: Create Update_Server.bat
(
    echo @echo off
    echo "C:\steamcmd\steamcmd.exe" +login anonymous +force_install_dir "%TargetFolder%" +app_update 2394010 validate +quit
) > "%TargetFolder%\Update_Server.bat"

:: Step 4: Modify DefaultPalWorldSettings.ini
SET "IniFile=%TargetFolder%\DefaultPalWorldSettings.ini"
IF EXIST "%IniFile%" (
    powershell -Command "(Get-Content '%IniFile%').replace('PublicPort=8214,PublicIP', 'PublicPort=%Port%,PublicIP').replace('ServerPlayerMaxNum=32', 'ServerPlayerMaxNum=%Players%') | Set-Content '%IniFile%'"
)

:: Step 5: Create Replicate_Default_Everywhere.bat
(
    echo @echo off
    echo SET "SourceIni=%TargetFolder%\DefaultPalWorldSettings.ini"
    echo SET "DestinationIni=%TargetFolder%\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini"
    echo IF EXIST "!SourceIni!" ^(
    echo    IF EXIST "!DestinationIni!" ^(
    echo        copy /Y "!SourceIni!" "!DestinationIni!"
    echo    ^)
    echo ^)
) > "%TargetFolder%\Replicate_Default_Everywhere.bat"

echo "Modding Engine.ini"

:: Step 6: Modify Engine.ini
SET "EngineIni=%TargetFolder%\Pal\Saved\Config\WindowsServer\Engine.ini"

IF EXIST "%EngineIni%" (
    :: Append sections if they do not exist
    FINDSTR /C:"[/script/onlinesubsystemutils.ipnetdriver]" "%EngineIni%" > nul || (
        echo [/script/onlinesubsystemutils.ipnetdriver] >> "%EngineIni%"
        echo "LanServerMaxTickRate=120  ; Sets maximum ticks per second for LAN servers, higher rates result in smoother gameplay." >> "%EngineIni%"
        echo "NetServerMaxTickRate=120  ; Sets maximum ticks per second for Internet servers, similarly ensuring smoother online gameplay." >> "%EngineIni%"
        echo. >> "%EngineIni%"
    )

    FINDSTR /C:"[/script/engine.player]" "%EngineIni%" > nul || (
        echo [/script/engine.player] >> "%EngineIni%"
        echo "ConfiguredInternetSpeed=104857600  ; Sets the assumed player internet speed in bytes per second. High value reduces chances of bandwidth throttling." >> "%EngineIni%"
        echo "ConfiguredLanSpeed=104857600       ; Sets the LAN speed, ensuring LAN players can utilize maximum network capacity." >> "%EngineIni%"
        echo. >> "%EngineIni%"
    )

    FINDSTR /C:"[/script/socketsubsystemepic.epicnetdriver]" "%EngineIni%" > nul || (
        echo [/script/socketsubsystemepic.epicnetdriver] >> "%EngineIni%"
        echo "MaxClientRate=104857600          ; Maximum data transfer rate per client for all connections, set to a high value to prevent data capping." >> "%EngineIni%"
        echo "MaxInternetClientRate=104857600  ; Specifically targets internet clients, allowing for high-volume data transfer without restrictions." >> "%EngineIni%"
        echo. >> "%EngineIni%"
    )

    FINDSTR /C:"[/script/engine.engine]" "%EngineIni%" > nul || (
        echo [/script/engine.engine] >> "%EngineIni%"
        echo "bSmoothFrameRate=true    ; Enables the game engine to smooth out frame rate fluctuations for a more consistent visual experience." >> "%EngineIni%"
        echo "bUseFixedFrameRate=false ; Disables the use of a fixed frame rate, allowing the game to dynamically adjust frame rate for optimal performance." >> "%EngineIni%"
        echo "SmoothedFrameRateRange=(LowerBound=(Type=Inclusive,Value=30.000000^),UpperBound=(Type=Exclusive,Value=120.000000^)) ; Sets a target frame rate range for smoothing." >> "%EngineIni%"
        echo "MinDesiredFrameRate=60.000000 ; Specifies a minimum acceptable frame rate, ensuring the game runs smoothly at least at this frame rate." >> "%EngineIni%"
        echo "FixedFrameRate=120.000000     ; (Not active due to bUseFixedFrameRate set to false) Placeholder for a fixed frame rate if needed." >> "%EngineIni%"
        echo "NetClientTicksPerSecond=120   ; Increases the update frequency for clients, enhancing responsiveness and reducing lag." >> "%EngineIni%"
        echo. >> "%EngineIni%"
    )
)

:: Step 7: Configure Firewall Rules
echo Configuring Firewall Rules...

:: Check and update the "SteamCMD" rule for TCP
echo Configuring Firewall Rules...

:: Rule names include port numbers to make them unique
SET "SteamCMDRuleName=Magic_SteamCMD_TCP_%QueryPort%"
SET "PalworldRuleName=Magic_Palworld_Dedicated_Server_UDP_%Port%"

:: Check and add the "SteamCMD" rule for TCP
netsh advfirewall firewall show rule name="%SteamCMDRuleName%" > nul
IF %ERRORLEVEL% NEQ 0 (
    echo Adding "%SteamCMDRuleName%" rule for TCP...
    netsh advfirewall firewall add rule name="%SteamCMDRuleName%" dir=in action=allow protocol=TCP localport=%QueryPort% enable=yes profile=any
) ELSE (
    echo Rule "%SteamCMDRuleName%" already exists. No action needed.
)

:: Check and add the "Palworld Dedicated Server" rule for UDP
netsh advfirewall firewall show rule name="%PalworldRuleName%" > nul
IF %ERRORLEVEL% NEQ 0 (
    echo Adding "%PalworldRuleName%" rule for UDP...
    netsh advfirewall firewall add rule name="%PalworldRuleName%" dir=in action=allow protocol=UDP localport=%Port% enable=yes profile=any
) ELSE (
    echo Rule "%PalworldRuleName%" already exists. No action needed.
)

echo Firewall configuration completed.



GOTO EndScript

:TimeoutError
echo Timeout error: Necessary file or folder not created in time.
:: exit /b
pause

:EndScript
echo Completed
pause

ENDLOCAL
