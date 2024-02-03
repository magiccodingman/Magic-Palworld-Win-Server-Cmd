@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Define variables
SET "TargetFolder={Your Folder Location}"
SET "QueryPort=27016"
SET "Port=8211"
SET "Players=32"
SET "AutoUpdate=true"  ; Set to true or false
SET "AutoReplicate=true"  ; Set to true or false

:: Do not change these variables!
SET "PalServerExe=%TargetFolder%\Pal\Binaries\Win64\PalServer-Win64-Test-Cmd.exe"
SET "SavedFolder=%TargetFolder%\Pal\Saved"
SET "SavedGameFolder=%TargetFolder%\Pal\Saved\SaveGames"
SET "EngineIni=%TargetFolder%\Pal\Saved\Config\WindowsServer\Engine.ini"
SET "SettingsIni=%TargetFolder%\DefaultPalWorldSettings.ini"
SET "PalWorldSettingsIni=%TargetFolder%\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini"
set "PalworldSaveToolsURL=https://github.com/magiccodingman/Magic-Palworld-Win-Server-Cmd/releases/download/PreRelease/Cheahjs-PalworldSaveTools.exe"
set "PalworldSaveToolsReadMeURL=https://github.com/magiccodingman/Magic-Palworld-Win-Server-Cmd/releases/download/PreRelease/ReadMe.md"

:: Create the directory structure
set "MagicModdingFolder=!TargetFolder!\Magic-Modding"
set "PalworldSaveToolsFolder=!MagicModdingFolder!\PalworldSaveTools"

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

:: Step 1: Update and Install Server
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
                IF EXIST "%PalWorldSettingsIni%" (
                    echo Base files created.
                    CALL :CheckSavedGameFolder
                )
            )
        )
    )
    IF !ElapsedTime! GEQ !TimeoutLimit! GOTO TimeoutError
    ping localhost -n 2 > nul
    SET /A ElapsedTime+=1
    GOTO WaitForSavedFolder
)

GOTO :EOF

:CheckSavedGameFolder
echo Waiting for world to be generated...
IF NOT EXIST "%SavedGameFolder%\0" (
    echo Please wait while the world is generating. This can take some time...
    ping localhost -n 10 > nul
    GOTO CheckSavedGameFolder
)

FOR /D %%D IN ("%SavedGameFolder%\0\*") DO (
    IF EXIST "%%D\Level.sav" (
        IF EXIST "%%D\LevelMeta.sav" (
            echo World has been successfully generated.
            GOTO KillServerProcess
        )
    )
    echo Please wait while the world is generating. This can take some time...
    ping localhost -n 10 > nul
    GOTO CheckSavedGameFolder
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
    if "%AutoReplicate%"=="true" echo call "%TargetFolder%\Set_Settings_And_Replicate_Default_Everywhere.bat"
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


set "sanitizedAutoUpdate=!AutoUpdate:true=true!"
set "sanitizedAutoUpdate=!AutoUpdate:True=true!"
set "sanitizedAutoUpdate=!AutoUpdate:tRue=true!"
set "sanitizedAutoUpdate=!AutoUpdate:TRue=true!"
set "sanitizedAutoUpdate=!AutoUpdate:trUe=true!"
set "sanitizedAutoUpdate=!AutoUpdate:TrUe=true!"
set "sanitizedAutoUpdate=!AutoUpdate:tRUe=true!"
set "sanitizedAutoUpdate=!AutoUpdate:TRUe=true!"
set "sanitizedAutoUpdate=!AutoUpdate:truE=true!"
set "sanitizedAutoUpdate=!AutoUpdate:TruE=true!"
set "sanitizedAutoUpdate=!AutoUpdate:tRuE=true!"
set "sanitizedAutoUpdate=!AutoUpdate:TRuE=true!"
set "sanitizedAutoUpdate=!AutoUpdate:trUE=true!"
set "sanitizedAutoUpdate=!AutoUpdate:TrUE=true!"
set "sanitizedAutoUpdate=!AutoUpdate:tRUE=true!"
set "sanitizedAutoUpdate=!AutoUpdate:TRUE=true!"
set "sanitizedAutoUpdate=!AutoUpdate:false=false!"
set "sanitizedAutoUpdate=!AutoUpdate:False=false!"
set "sanitizedAutoUpdate=!AutoUpdate:fAlse=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FAlse=false!"
set "sanitizedAutoUpdate=!AutoUpdate:faLse=false!"z
set "sanitizedAutoUpdate=!AutoUpdate:FaLse=false!"
set "sanitizedAutoUpdate=!AutoUpdate:fALse=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FALse=false!"
set "sanitizedAutoUpdate=!AutoUpdate:falSe=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FalSe=false!"
set "sanitizedAutoUpdate=!AutoUpdate:fAlsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FAlsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:faLsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FaLsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:fALsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FALsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:falsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FalsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:fAlsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FAlsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:faLsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FaLsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:fALsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FALsE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:falSE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FalSE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:fAlSE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FAlSE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:faLSE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FaLSE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:fALSE=false!"
set "sanitizedAutoUpdate=!AutoUpdate:FALSE=false!"

set "sanitizedAutoReplicate=!AutoReplicate:true=true!"
set "sanitizedAutoReplicate=!AutoReplicate:True=true!"
set "sanitizedAutoReplicate=!AutoReplicate:tRue=true!"
set "sanitizedAutoReplicate=!AutoReplicate:TRue=true!"
set "sanitizedAutoReplicate=!AutoReplicate:trUe=true!"
set "sanitizedAutoReplicate=!AutoReplicate:TrUe=true!"
set "sanitizedAutoReplicate=!AutoReplicate:tRUe=true!"
set "sanitizedAutoReplicate=!AutoReplicate:TRUe=true!"
set "sanitizedAutoReplicate=!AutoReplicate:truE=true!"
set "sanitizedAutoReplicate=!AutoReplicate:TruE=true!"
set "sanitizedAutoReplicate=!AutoReplicate:tRuE=true!"
set "sanitizedAutoReplicate=!AutoReplicate:TRuE=true!"
set "sanitizedAutoReplicate=!AutoReplicate:trUE=true!"
set "sanitizedAutoReplicate=!AutoReplicate:TrUE=true!"
set "sanitizedAutoReplicate=!AutoReplicate:tRUE=true!"
set "sanitizedAutoReplicate=!AutoReplicate:TRUE=true!"
set "sanitizedAutoReplicate=!AutoReplicate:false=false!"
set "sanitizedAutoReplicate=!AutoReplicate:False=false!"
set "sanitizedAutoReplicate=!AutoReplicate:fAlse=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FAlse=false!"
set "sanitizedAutoReplicate=!AutoReplicate:faLse=false!"z
set "sanitizedAutoReplicate=!AutoReplicate:FaLse=false!"
set "sanitizedAutoReplicate=!AutoReplicate:fALse=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FALse=false!"
set "sanitizedAutoReplicate=!AutoReplicate:falSe=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FalSe=false!"
set "sanitizedAutoReplicate=!AutoReplicate:fAlsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FAlsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:faLsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FaLsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:fALsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FALsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:falsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FalsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:fAlsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FAlsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:faLsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FaLsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:fALsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FALsE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:falSE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FalSE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:fAlSE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FAlSE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:faLSE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FaLSE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:fALSE=false!"
set "sanitizedAutoReplicate=!AutoReplicate:FALSE=false!"



:: Step 5: Create Replicate_Default_Everywhere.bat
(
echo @echo off
echo setlocal EnableDelayedExpansion
echo :: Set Setup Variables
echo SET AutoUpdate=%sanitizedAutoUpdate%
echo SET AutoReplicate=%sanitizedAutoReplicate%
echo set QueryPort=%QueryPort%
echo :: Set initial variables
echo 
echo :: Difficulty
echo set Difficulty=none
echo 
echo :: DayTimeSpeedRate
echo set DayTimeSpeedRate=1.000000
echo 
echo :: NightTimeSpeedRate
echo set NightTimeSpeedRate=1.000000
echo 
echo :: ExpRate
echo set ExpRate=1.000000
echo 
echo :: PalCaptureRate
echo set PalCaptureRate=1.000000
echo 
echo :: PalSpawnNumRate
echo set PalSpawnNumRate=1.000000
echo 
echo :: PalDamageRateAttack
echo set PalDamageRateAttack=1.000000
echo 
echo :: PalDamageRateDefense
echo set PalDamageRateDefense=1.000000
echo 
echo :: PlayerDamageRateAttack
echo set PlayerDamageRateAttack=1.000000
echo 
echo :: PlayerDamageRateDefense
echo set PlayerDamageRateDefense=1.000000
echo 
echo :: PlayerStomachDecreaseRate
echo set PlayerStomachDecreaseRate=1.000000
echo 
echo :: PlayerStaminaDecreaseRate
echo set PlayerStaminaDecreaseRate=1.000000
echo 
echo :: PlayerAutoHPRegenRate
echo set PlayerAutoHPRegenRate=1.000000
echo 
echo :: PlayerAutoHPRegenRateInSleep
echo set PlayerAutoHPRegenRateInSleep=1.000000
echo 
echo :: PalStomachDecreaseRate
echo set PalStomachDecreaseRate=1.000000
echo 
echo :: PalStaminaDecreaseRate
echo set PalStaminaDecreaseRate=1.000000
echo 
echo :: PalAutoHPRegenRate
echo set PalAutoHPRegenRate=1.000000
echo 
echo :: PalAutoHPRegenRateInSleep
echo set PalAutoHPRegenRateInSleep=1.000000
echo 
echo :: BuildObjectDamageRate
echo set BuildObjectDamageRate=1.000000
echo 
echo :: BuildObjectDeteriorationDamageRate
echo set BuildObjectDeteriorationDamageRate=1.000000
echo 
echo :: CollectionDropRate
echo set CollectionDropRate=1.000000
echo 
echo :: CollectionObjectHpRate
echo set CollectionObjectHpRate=1.000000
echo 
echo :: CollectionObjectRespawnSpeedRate
echo set CollectionObjectRespawnSpeedRate=1.000000
echo 
echo :: EnemyDropItemRate
echo set EnemyDropItemRate=1.000000
echo 
echo :: DeathPenalty options:
echo :: All - Drops player items, gear, and pals on death
echo :: 1 - Drop items only on death
echo :: 2 - drops Items and equipped gear
echo :: none - no death penalty
echo set DeathPenalty=none
echo 
echo :: bEnablePlayerToPlayerDamage
echo set bEnablePlayerToPlayerDamage=False
echo 
echo :: bEnableFriendlyFire
echo set bEnableFriendlyFire=False
echo 
echo :: bEnableInvaderEnemy
echo set bEnableInvaderEnemy=True
echo 
echo :: bActiveUNKO
echo set bActiveUNKO=False
echo 
echo :: bEnableAimAssistPad
echo set bEnableAimAssistPad=True
echo 
echo :: bEnableAimAssistKeyboard
echo set bEnableAimAssistKeyboard=False
echo 
echo :: DropItemMaxNum
echo set DropItemMaxNum=3000
echo 
echo :: DropItemMaxNum_UNKO
echo set DropItemMaxNum_UNKO=100
echo 
echo :: BaseCampMaxNum
echo set BaseCampMaxNum=128
echo 
echo :: BaseCampWorkerMaxNum
echo set BaseCampWorkerMaxNum=15
echo 
echo :: DropItemAliveMaxHours
echo set DropItemAliveMaxHours=1.000000
echo 
echo :: bAutoResetGuildNoOnlinePlayers
echo set bAutoResetGuildNoOnlinePlayers=False
echo 
echo :: AutoResetGuildTimeNoOnlinePlayers
echo set AutoResetGuildTimeNoOnlinePlayers=72.000000
echo 
echo :: GuildPlayerMaxNum
echo set GuildPlayerMaxNum=20
echo 
echo :: PalEggDefaultHatchingTime
echo set PalEggDefaultHatchingTime=72.000000
echo 
echo :: WorkSpeedRate
echo set WorkSpeedRate=1.000000
echo 
echo :: bIsMultiplay
echo set bIsMultiplay=False
echo 
echo :: bIsPvP
echo set bIsPvP=False
echo 
echo :: bCanPickupOtherGuildDeathPenaltyDrop
echo set bCanPickupOtherGuildDeathPenaltyDrop=False
echo 
echo :: bEnableNonLoginPenalty
echo set bEnableNonLoginPenalty=True
echo 
echo :: bEnableFastTravel
echo set bEnableFastTravel=True
echo 
echo :: bIsStartLocationSelectByMap
echo set bIsStartLocationSelectByMap=True
echo 
echo :: bExistPlayerAfterLogout
echo set bExistPlayerAfterLogout=False
echo 
echo :: CoopPlayerMaxNum
echo set CoopPlayerMaxNum=4
echo 
echo :: ServerPlayerMaxNum
echo set ServerPlayerMaxNum=%Players%
echo 
echo :: ServerName
echo set ServerName=^"Default Palworld Server^"
echo 
echo :: ServerDescription
echo set ServerDescription=^"^"
echo 
echo :: AdminPassword
echo set AdminPassword=^"^"
echo 
echo :: ServerPassword
echo set ServerPassword=^"^"
echo 
echo :: PublicPort
echo set PublicPort=%Port%
echo 
echo :: PublicIP
echo set PublicIP=^"^"
echo 
echo :: RCONEnabled
echo set RCONEnabled=False
echo 
echo :: RCONPort
echo set RCONPort=25575
echo 
echo :: Region
echo set Region=^"^"
echo 
echo :: bUseAuth
echo set bUseAuth=True
echo 
echo :: BanListURL
echo set BanListURL=^"https://api.palworldgame.com/api/banlist.txt^"
echo 
echo 
echo set bEnableDefenseOtherGuildPlayer=false;
echo 
echo 
echo :: Define destination file paths
echo set ^"DestinationFilePath1=DefaultPalWorldSettings.ini^"
echo set ^"DestinationFilePath2=.\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini^"
echo 
echo set sanitizedServerPassword=^^!ServerPassword:^"^"=^^!
echo set sanitizedPublicIP=^^!PublicIP:^"^"=^^!
echo set sanitizedRegion=^^!Region:^"^"=^^!
echo set sanitizedBanListURL=^^!BanListURL:^"^"=^^!
echo set sanitizedAdminPassword=^^!AdminPassword:^"^"=^^!
echo set sanitizedServerDescription=^^!ServerDescription:^"^"=^^!
echo 
echo :: Construct the new formatted string
echo set ConfigString=[/Script/Pal.PalGameWorldSettings]^^
echo 
echo OptionSettings=^(Difficulty=%%Difficulty%%,DayTimeSpeedRate=%%DayTimeSpeedRate%%,NightTimeSpeedRate=%%NightTimeSpeedRate%%,ExpRate=%%ExpRate%%,PalCaptureRate=%%PalCaptureRate%%,PalSpawnNumRate=%%PalSpawnNumRate%%,PalDamageRateAttack=%%PalDamageRateAttack%%,PalDamageRateDefense=%%PalDamageRateDefense%%,PlayerDamageRateAttack=%%PlayerDamageRateAttack%%,PlayerDamageRateDefense=%%PlayerDamageRateDefense%%,PlayerStomachDecreaceRate=%%PlayerStomachDecreaseRate%%,PlayerStaminaDecreaceRate=%%PlayerStaminaDecreaseRate%%,PlayerAutoHPRegeneRate=%%PlayerAutoHPRegenRate%%,PlayerAutoHPRegeneRateInSleep=%%PlayerAutoHPRegenRateInSleep%%,PalStomachDecreaceRate=%%PalStomachDecreaseRate%%,PalStaminaDecreaceRate=%%PalStaminaDecreaseRate%%,PalAutoHPRegeneRate=%%PalAutoHPRegenRate%%,PalAutoHPRegeneRateInSleep=%%PalAutoHPRegenRateInSleep%%,BuildObjectDamageRate=%%BuildObjectDamageRate%%,BuildObjectDeteriorationDamageRate=%%BuildObjectDeteriorationDamageRate%%,CollectionDropRate=%%CollectionDropRate%%,CollectionObjectHpRate=%%CollectionObjectHpRate%%,CollectionObjectRespawnSpeedRate=%%CollectionObjectRespawnSpeedRate%%,EnemyDropItemRate=%%EnemyDropItemRate%%,DeathPenalty=All,bEnablePlayerToPlayerDamage=%%bEnablePlayerToPlayerDamage%%,bEnableFriendlyFire=%%bEnableFriendlyFire%%,bEnableInvaderEnemy=%%bEnableInvaderEnemy%%,bActiveUNKO=%%bActiveUNKO%%,bEnableAimAssistPad=%%bEnableAimAssistPad%%,bEnableAimAssistKeyboard=%%bEnableAimAssistKeyboard%%,DropItemMaxNum=%%DropItemMaxNum%%,DropItemMaxNum_UNKO=%%DropItemMaxNum_UNKO%%,BaseCampMaxNum=%%BaseCampMaxNum%%,BaseCampWorkerMaxNum=%%BaseCampWorkerMaxNum%%,DropItemAliveMaxHours=%%DropItemAliveMaxHours%%,bAutoResetGuildNoOnlinePlayers=%%bAutoResetGuildNoOnlinePlayers%%,AutoResetGuildTimeNoOnlinePlayers=%%AutoResetGuildTimeNoOnlinePlayers%%,GuildPlayerMaxNum=%%GuildPlayerMaxNum%%,PalEggDefaultHatchingTime=%%PalEggDefaultHatchingTime%%,WorkSpeedRate=%%WorkSpeedRate%%,bIsMultiplay=%%bIsMultiplay%%,bIsPvP=%%bIsPvP%%,bCanPickupOtherGuildDeathPenaltyDrop=%%bCanPickupOtherGuildDeathPenaltyDrop%%,bEnableNonLoginPenalty=%%bEnableNonLoginPenalty%%,bEnableFastTravel=%%bEnableFastTravel%%,bIsStartLocationSelectByMap=%%bIsStartLocationSelectByMap%%,bExistPlayerAfterLogout=%%bExistPlayerAfterLogout%%,CoopPlayerMaxNum=%%CoopPlayerMaxNum%%,ServerPlayerMaxNum=%%ServerPlayerMaxNum%%,ServerName=^"%%ServerName%%^",ServerDescription=^"%%sanitizedServerDescription%%^",AdminPassword=^"%%sanitizedAdminPassword%%^",ServerPassword=^"%%sanitizedServerPassword%%^",PublicPort=%%PublicPort%%,PublicIP=^"%%sanitizedPublicIP%%^",RCONEnabled=%%RCONEnabled%%,RCONPort=%%RCONPort%%,Region=^"%%sanitizedRegion%%^",bUseAuth=%%bUseAuth%%,BanListURL=^"%%sanitizedBanListURL%%^"^)
echo 
echo set ^"OptionSettings=^^!OptionSettings:^"^"^"^"^"^"=^"^"^"^"^^!^"
echo 
echo :: Ensure directories exist before writing
echo if not exist ^".\Pal\Saved\Config\WindowsServer\^" mkdir ^".\Pal\Saved\Config\WindowsServer\^"
echo 
echo :: Save to DestinationFilePath1
echo echo ^^!ConfigString^^! ^> ^"^^!DestinationFilePath1^^!^"
echo 
echo :: Save to DestinationFilePath2
echo echo ^^!ConfigString^^! ^> ^"^^!DestinationFilePath2^^!^"
echo 
echo echo Configuration has been saved to both locations.
echo 
echo echo Creating new WorldOptions.sav
echo 
echo :: Dynamically get the full path of the directory where the batch file is run
echo pushd ^"%%~dp0^"
echo set ^"currentDir=%%CD%%^"
echo 
echo :: Assuming the structure is the same but the base path might change
echo :: Construct the path to GameUserSettings.ini dynamically
echo set ^"iniPath=%%currentDir%%\Pal\Saved\Config\WindowsServer\GameUserSettings.ini^"
echo 
echo :: Debug: Echo the path for verification
echo echo Looking for GameUserSettings.ini at: ^"%%iniPath%%^"
echo 
echo :: Check if GameUserSettings.ini exists
echo if not exist ^"%%iniPath%%^" ^(
echo     echo Error: GameUserSettings.ini not found at ^"%%iniPath%%^".
echo     popd
echo     exit /b 1
echo ^)
echo 
echo :: Extract DedicatedServerName from GameUserSettings.ini
echo for /f ^"tokens=2 delims==^" %%%%a in ^('findstr ^"DedicatedServerName^" ^"%%iniPath%%^"'^) do ^(
echo     set ^"serverName=%%%%a^"
echo ^)
echo 
echo :: Trim the server name if necessary
echo :: set ^"serverName=%%serverName:~1%%^" might be needed to remove quotes or extra characters
echo 
echo :: Construct the save game path using the server name
echo set ^"saveGamePath=%%currentDir%%\Pal\Saved\SaveGames\0\%%serverName%%^"
echo 
echo :: Check if the save game directory exists
echo if not exist ^"%%saveGamePath%%^" ^(
echo     echo Error: Save game folder for server %%serverName%% could not be found.
echo     popd
echo     exit /b 1
echo ^)
echo 
echo :: Specify the file paths
echo :: set ^"worldOptionPath=%%saveGamePath%%\WorldOption.sav^"
echo :: set ^"outputJsonPath=%%worldOptionPath%%.json^"
echo 
echo :: Verify Cheahjs-PalworldSaveTools.exe existence
echo set ^"toolsPath=%%currentDir%%\Magic-Modding\PalworldSaveTools\Cheahjs-PalworldSaveTools.exe^"
echo if not exist ^"%%toolsPath%%^" ^(
echo     echo Error: Cheahjs-PalworldSaveTools.exe not found.
echo     popd
echo     exit /b 1
echo ^)
echo 
echo :: Define the path to the JSON file and the .sav file
echo set ^"worldOptionPath=%%saveGamePath%%\WorldOption.sav^"
echo set ^"outputJsonPath=%%worldOptionPath%%.json^"
echo 
echo :: Check if the WorldOption.sav.json exists, delete if it does
echo if exist ^"%%outputJsonPath%%^" del ^"%%outputJsonPath%%^"
echo 
echo set jsonString={^"header^":{^"magic^":1396790855,^"save_game_version^":3,^"package_file_version_ue4^":522,^"package_file_version_ue5^":1008,^"engine_version_major^":5,^"engine_version_minor^":1,^"engine_version_patch^":1,^"engine_version_changelist^":0,^"engine_version_branch^":^"++UE5+Release-5.1^",^"custom_version_format^":3,^"custom_versions^":[[^"40d2fba7-4b48-4ce5-b038-5a75884e499e^",7],[^"fcf57afa-5076-4283-b9a9-e658ffa02d32^",76],[^"0925477b-763d-4001-9d91-d6730b75b411^",1],[^"4288211b-4548-16c6-1a76-67b2507a2a00^",1],[^"1ab9cecc-0000-6913-0000-4875203d51fb^",100],[^"4cef9221-470e-d43a-7e60-3d8c16995726^",1],[^"e2717c7e-52f5-44d3-950c-5340b315035e^",7],[^"11310aed-2e55-4d61-af67-9aa3c5a1082c^",17],[^"a7820cfb-20a7-4359-8c54-2c149623cf50^",21],[^"f6dfbb78-bb50-a0e4-4018-b84d60cbaf23^",2],[^"24bb7af3-5646-4f83-1f2f-2dc249ad96ff^",5],[^"76a52329-0923-45b5-98ae-d841cf2f6ad8^",5],[^"5fbc6907-55c8-40ae-8e67-f1845efff13f^",1],[^"82e77c4e-3323-43a5-b46b-13c597310df3^",0],[^"0ffcf66c-1190-4899-b160-9cf84a46475e^",1],[^"9c54d522-a826-4fbe-9421-074661b482d0^",44],[^"b0d832e4-1f89-4f0d-accf-7eb736fd4aa2^",10],[^"e1c64328-a22c-4d53-a36c-8e866417bd8c^",0],[^"375ec13c-06e4-48fb-b500-84f0262a717e^",4],[^"e4b068ed-f494-42e9-a231-da0b2e46bb41^",40],[^"cffc743f-43b0-4480-9391-14df171d2073^",37],[^"b02b49b5-bb20-44e9-a304-32b752e40360^",3],[^"a4e4105c-59a1-49b5-a7c5-40c4547edfee^",0],[^"39c831c9-5ae6-47dc-9a44-9c173e1c8e7c^",0],[^"78f01b33-ebea-4f98-b9b4-84eaccb95aa2^",20],[^"6631380f-2d4d-43e0-8009-cf276956a95a^",0],[^"12f88b9f-8875-4afc-a67c-d90c383abd29^",45],[^"7b5ae74c-d270-4c10-a958-57980b212a5a^",13],[^"d7296918-1dd6-4bdd-9de2-64a83cc13884^",3],[^"c2a15278-bfe7-4afe-6c17-90ff531df755^",1],[^"6eaca3d4-40ec-4cc1-b786-8bed09428fc5^",3],[^"29e575dd-e0a3-4627-9d10-d276232cdcea^",17],[^"af43a65d-7fd3-4947-9873-3e8ed9c1bb05^",15],[^"6b266cec-1ec7-4b8f-a30b-e4d90942fc07^",1],[^"0df73d61-a23f-47ea-b727-89e90c41499a^",1],[^"601d1886-ac64-4f84-aa16-d3de0deac7d6^",80],[^"5b4c06b7-2463-4af8-805b-bf70cdf5d0dd^",10],[^"e7086368-6b23-4c58-8439-1b7016265e91^",4],[^"9dffbcd6-494f-0158-e221-12823c92a888^",10],[^"f2aed0ac-9afe-416f-8664-aa7ffa26d6fc^",1],[^"174f1f0b-b4c6-45a5-b13f-2ee8d0fb917d^",10],[^"35f94a83-e258-406c-a318-09f59610247c^",41],[^"b68fc16e-8b1b-42e2-b453-215c058844fe^",1],[^"b2e18506-4273-cfc2-a54e-f4bb758bba07^",1],[^"64f58936-fd1b-42ba-ba96-7289d5d0fa4e^",1],[^"697dd581-e64f-41ab-aa4a-51ecbeb7b628^",88],[^"d89b5e42-24bd-4d46-8412-aca8df641779^",41],[^"59da5d52-1232-4948-b878-597870b8e98b^",8],[^"26075a32-730f-4708-88e9-8c32f1599d05^",0],[^"6f0ed827-a609-4895-9c91-998d90180ea4^",2],[^"30d58be3-95ea-4282-a6e3-b159d8ebb06a^",1],[^"717f9ee7-e9b0-493a-88b3-91321b388107^",16],[^"430c4d19-7154-4970-8769-9b69df90b0e5^",15],[^"aafe32bd-5395-4c14-b66a-5e251032d1dd^",1],[^"23afe18e-4ce1-4e58-8d61-c252b953beb7^",11],[^"a462b7ea-f499-4e3a-99c1-ec1f8224e1b2^",4],[^"2eb5fdbd-01ac-4d10-8136-f38f3393a5da^",5],[^"509d354f-f6e6-492f-a749-85b2073c631c^",0],[^"b6e31b1c-d29f-11ec-857e-9f856f9970e2^",1],[^"4a56eb40-10f5-11dc-92d3-347eb2c96ae7^",2],[^"d78a4a00-e858-4697-baa8-19b5487d46b4^",18],[^"5579f886-933a-4c1f-83ba-087b6361b92f^",2],[^"612fbe52-da53-400b-910d-4f919fb1857c^",1],[^"a4237a36-caea-41c9-8fa2-18f858681bf3^",5],[^"804e3f75-7088-4b49-a4d6-8c063c7eb6dc^",5],[^"1ed048f4-2f2e-4c68-89d0-53a4f18f102d^",1],[^"fb680af2-59ef-4ba3-baa8-19b573c8443d^",2],[^"9950b70e-b41a-4e17-bbcc-fa0d57817fd6^",1],[^"ab965196-45d8-08fc-b7d7-228d78ad569e^",1]],^"save_game_class_name^":^"/Script/Pal.PalWorldOptionSaveGame^"},^"properties^":{^"Version^":{^"id^":null,^"value^":100,^"type^":^"IntProperty^"},^"Timestamp^":{^"struct_type^":^"DateTime^",^"struct_id^":^"00000000-0000-0000-0000-000000000000^",^"id^":null,^"value^":638421225892130000,^"type^":^"StructProperty^"},^"OptionWorldData^":{^"struct_type^":^"PalOptionWorldSaveData^",^"struct_id^":^"00000000-0000-0000-0000-000000000000^",^"id^":null,^"value^":{^"Settings^":{^"struct_type^":^"PalOptionWorldSettings^",^"struct_id^":^"00000000-0000-0000-0000-000000000000^",^"id^":null,^"value^":{^"Difficulty^":{^"id^":null,^"value^":{^"type^":^"EPalOptionWorldDifficulty^",^"value^":^"EPalOptionWorldDifficulty::%%Difficulty%%^"},^"type^":^"EnumProperty^"},^"BuildObjectDeteriorationDamageRate^":{^"id^":null,^"value^":%%BuildObjectDeteriorationDamageRate%%,^"type^":^"FloatProperty^"},^"CollectionDropRate^":{^"id^":null,^"value^":%%CollectionDropRate%%,^"type^":^"FloatProperty^"},^"DeathPenalty^":{^"id^":null,^"value^":{^"type^":^"EPalOptionWorldDeathPenalty^",^"value^":^"EPalOptionWorldDeathPenalty::%%DeathPenalty%%^"},^"type^":^"EnumProperty^"},^"bActiveUNKO^":{^"value^":%%bActiveUNKO%%,^"id^":null,^"type^":^"BoolProperty^"},^"RCONEnabled^":{^"value^":%%RCONEnabled%%,^"id^":null,^"type^":^"BoolProperty^"},^"DropItemMaxNum^":{^"id^":null,^"value^":%%DropItemMaxNum%%,^"type^":^"IntProperty^"},^"BaseCampWorkerMaxNum^":{^"id^":null,^"value^":%%BaseCampWorkerMaxNum%%,^"type^":^"IntProperty^"},^"bAutoResetGuildNoOnlinePlayers^":{^"value^":%%bAutoResetGuildNoOnlinePlayers%%,^"id^":null,^"type^":^"BoolProperty^"},^"GuildPlayerMaxNum^":{^"id^":null,^"value^":%%GuildPlayerMaxNum%%,^"type^":^"IntProperty^"},^"PalEggDefaultHatchingTime^":{^"id^":null,^"value^":%%PalEggDefaultHatchingTime%%,^"type^":^"FloatProperty^"},^"bIsMultiplay^":{^"value^":%%bIsMultiplay%%,^"id^":null,^"type^":^"BoolProperty^"},^"bEnableNonLoginPenalty^":{^"value^":^"%%bEnableNonLoginPenalty%%^",^"id^":null,^"type^":^"BoolProperty^"},^"bIsStartLocationSelectByMap^":{^"value^":%%bIsStartLocationSelectByMap%%,^"id^":null,^"type^":^"BoolProperty^"},^"bEnablePlayerToPlayerDamage^":{^"value^":%%bEnablePlayerToPlayerDamage%%,^"id^":null,^"type^":^"BoolProperty^"},^"bEnableFriendlyFire^":{^"value^":%%bEnableFriendlyFire%%,^"id^":null,^"type^":^"BoolProperty^"},^"bEnableAimAssistKeyboard^":{^"value^":%%bEnableAimAssistKeyboard%%,^"id^":null,^"type^":^"BoolProperty^"},^"bIsPvP^":{^"value^":%%bIsPvP%%,^"id^":null,^"type^":^"BoolProperty^"},^"bCanPickupOtherGuildDeathPenaltyDrop^":{^"value^":%%bCanPickupOtherGuildDeathPenaltyDrop%%,^"id^":null,^"type^":^"BoolProperty^"},^"bExistPlayerAfterLogout^":{^"value^":^"%%bExistPlayerAfterLogout%%^",^"id^":null,^"type^":^"BoolProperty^"},^"bEnableDefenseOtherGuildPlayer^":{^"value^":%%bEnableDefenseOtherGuildPlayer%%,^"id^":null,^"type^":^"BoolProperty^"},^"ServerDescription^":{^"value^":^"%%ServerDescription%%^",^"id^":null,^"type^":^"StrProperty^"},^"AdminPassword^":{^"value^":^"%%sanitizedAdminPassword%%^",^"id^":null,^"type^":^"StrProperty^"},^"ServerPassword^":{^"value^":^"%%sanitizedServerPassword%%^",^"id^":null,^"type^":^"StrProperty^"},^"PublicIP^":{^"value^":^"%%sanitizedPublicIP%%^",^"id^":null,^"type^":^"StrProperty^"},^"Region^":{^"value^":^"%%sanitizedRegion%%^",^"id^":null,^"type^":^"StrProperty^"}},^"type^":^"StructProperty^"}},^"type^":^"StructProperty^"}},^"trailer^":^"AAAAAA==^"}
echo 
echo 
echo :: Replace boolean values directly in the entire JSON string
echo :: Note: This assumes that the JSON string doesn't exceed the maximum command line length for batch files, which is around 8191 characters
echo set ^"jsonString=^^!jsonString:true=true^^!^"
echo set ^"jsonString=^^!jsonString:True=true^^!^"
echo set ^"jsonString=^^!jsonString:tRue=true^^!^"
echo set ^"jsonString=^^!jsonString:TRue=true^^!^"
echo set ^"jsonString=^^!jsonString:trUe=true^^!^"
echo set ^"jsonString=^^!jsonString:TrUe=true^^!^"
echo set ^"jsonString=^^!jsonString:tRUe=true^^!^"
echo set ^"jsonString=^^!jsonString:TRUe=true^^!^"
echo set ^"jsonString=^^!jsonString:truE=true^^!^"
echo set ^"jsonString=^^!jsonString:TruE=true^^!^"
echo set ^"jsonString=^^!jsonString:tRuE=true^^!^"
echo set ^"jsonString=^^!jsonString:TRuE=true^^!^"
echo set ^"jsonString=^^!jsonString:trUE=true^^!^"
echo set ^"jsonString=^^!jsonString:TrUE=true^^!^"
echo set ^"jsonString=^^!jsonString:tRUE=true^^!^"
echo set ^"jsonString=^^!jsonString:TRUE=true^^!^"
echo set ^"jsonString=^^!jsonString:false=false^^!^"
echo set ^"jsonString=^^!jsonString:False=false^^!^"
echo set ^"jsonString=^^!jsonString:fAlse=false^^!^"
echo set ^"jsonString=^^!jsonString:FAlse=false^^!^"
echo set ^"jsonString=^^!jsonString:faLse=false^^!^"
echo set ^"jsonString=^^!jsonString:FaLse=false^^!^"
echo set ^"jsonString=^^!jsonString:fALse=false^^!^"
echo set ^"jsonString=^^!jsonString:FALse=false^^!^"
echo set ^"jsonString=^^!jsonString:falSe=false^^!^"
echo set ^"jsonString=^^!jsonString:FalSe=false^^!^"
echo set ^"jsonString=^^!jsonString:fAlsE=false^^!^"
echo set ^"jsonString=^^!jsonString:FAlsE=false^^!^"
echo set ^"jsonString=^^!jsonString:faLsE=false^^!^"
echo set ^"jsonString=^^!jsonString:FaLsE=false^^!^"
echo set ^"jsonString=^^!jsonString:fALsE=false^^!^"
echo set ^"jsonString=^^!jsonString:FALsE=false^^!^"
echo set ^"jsonString=^^!jsonString:falsE=false^^!^"
echo set ^"jsonString=^^!jsonString:FalsE=false^^!^"
echo set ^"jsonString=^^!jsonString:fAlsE=false^^!^"
echo set ^"jsonString=^^!jsonString:FAlsE=false^^!^"
echo set ^"jsonString=^^!jsonString:faLsE=false^^!^"
echo set ^"jsonString=^^!jsonString:FaLsE=false^^!^"
echo set ^"jsonString=^^!jsonString:fALsE=false^^!^"
echo set ^"jsonString=^^!jsonString:FALsE=false^^!^"
echo set ^"jsonString=^^!jsonString:falSE=false^^!^"
echo set ^"jsonString=^^!jsonString:FalSE=false^^!^"
echo set ^"jsonString=^^!jsonString:fAlSE=false^^!^"
echo set ^"jsonString=^^!jsonString:FAlSE=false^^!^"
echo set ^"jsonString=^^!jsonString:faLSE=false^^!^"
echo set ^"jsonString=^^!jsonString:FaLSE=false^^!^"
echo set ^"jsonString=^^!jsonString:fALSE=false^^!^"
echo set ^"jsonString=^^!jsonString:FALSE=false^^!^"
echo 
echo :: Fix empty strings
echo set ^"jsonString=^^!jsonString:^"^"^"^"=^"^"^^!^"
echo :: Create the new WorldOption.sav.json with user-defined settings
echo ^(
echo echo %%jsonString%%
echo ^) ^> ^"%%outputJsonPath%%^"
echo 
echo echo Configuration JSON has been created: ^"%%outputJsonPath%%^"
echo 
echo :: Check if the WorldOption.sav exists, delete if it does
echo  if exist ^"%%worldOptionPath%%^" del ^"%%worldOptionPath%%^"
echo 
echo :: Execute the tool to convert the JSON back to the WorldOption.sav file
echo  ^"%%toolsPath%%^" ^"%%outputJsonPath%%^" --from-json --output ^"%%worldOptionPath%%^"
echo 
echo echo Conversion to .sav complete.
echo 
echo echo Conversion complete.
echo 
echo :: Step 2: Create Start_Palworld_Server.bat
echo ^(
echo     echo @echo off
echo     if ^"%%AutoUpdate%%^"==^"true^" echo call ^".\Update_Server.bat^"
echo     if ^"%%AutoReplicate%%^"==^"true^" echo call ^".\Set_Settings_And_Replicate_Default_Everywhere.bat^"
echo     echo start PalServer.exe -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS -QueryPort=%%QueryPort%% -port=%%PublicPort%% -players=%%ServerPlayerMaxNum%%
echo ^) ^> ^".\Start_Palworld_Server.bat^"
echo 
echo popd
echo 
echo pause
echo 
echo ENDLOCAL


) > "%TargetFolder%\Set_Settings_And_Replicate_Default_Everywhere.bat"

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




if not exist "!MagicModdingFolder!" mkdir "!MagicModdingFolder!"
if not exist "!PalworldSaveToolsFolder!" mkdir "!PalworldSaveToolsFolder!"

:: Define the destination path for the EXE and ReadMe.md
set "destPathPalworldSaveTools=!PalworldSaveToolsFolder!\Cheahjs-PalworldSaveTools.exe"
set "readMePath=!PalworldSaveToolsFolder!\ReadMe.md"

:: Check if the EXE file exists and delete it if it does
if exist "!destPathPalworldSaveTools!" del /f /q "!destPathPalworldSaveTools!"

:: Check if the ReadMe.md exists and delete it if it does
if exist "!readMePath!" del /f /q "!readMePath!"

:: Download the EXE file using curl
curl -L "%PalworldSaveToolsURL%" -o "%destPathPalworldSaveTools%"

set "destPathReadMe=!PalworldSaveToolsFolder!\ReadMe.md"

:: Create the ReadMe.md
curl -L "%PalworldSaveToolsReadMeURL%" -o "%destPathReadMe%"


echo Folder Process and downloads completed.

GOTO EndScript

:TimeoutError
echo Timeout error: Necessary file or folder not created in time.
:: exit /b
pause

:EndScript
echo Completed
pause
Exit

ENDLOCAL
