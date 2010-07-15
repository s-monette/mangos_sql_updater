@ECHO OFF
::----- Configuration section begin ----
::----- Read the README for more info about the different configuration option.
SET sql_user=root
SET sql_pass=PASSWORD
SET mangos_db=mangos
SET char_db=characters
SET realmd_db=realmd
SET sd2_db=scriptdev2
SET mangos_dir=mangos
SET sd2dir=%mangos_dir%\src\bindings\ScriptDev2
SET acid_dir=ACID
set acid_branch=wotlk
SET server_dir=server
SET bin=win32
SET vsversion=vc100
::If you got error about git or msbuil.exe not recognized adjust the fallowing, otherwise default should work.
SET gitdir=%ProgramFiles(x86)%\Git\cmd
 IF EXIST "%ProgramFiles%" SET gitdir=%ProgramFiles%\Git\cmd
SET msbuild=%WinDir%\Microsoft.NET\Framework\v2.0.50727
 IF EXIST %WinDir%\Microsoft.NET\Framework\v4.0.30319 SET msbuild=%WinDir%\Microsoft.NET\Framework\v4.0.30319
::----- Configuration section end ------
::----- Main begin --------------
CALL :git_update
CALL :svn_update
CALL :create_sql_file
CALL :show_version Current
CALL :update_db
CALL :show_version Updated
CALL :start_compiling
CALL :copy_bin
CALL :deco_frame "All done !"
PAUSE
GOTO :EOF
::----- Main end ----------------
::----- Functions begin ----------
:git_update
 CALL :deco_frame "Updating Git repository."
 PATH=%PATH%;%gitdir%
 CD mangos
 git pull | MORE
 CD ..
 GOTO :EOF

:svn_update
 CALL :deco_frame "Updating SVN repository."
 ECHO ACID is
 svn update %acid_dir%
 ECHO ScriptDev2 is
 svn update %sd2dir%
 GOTO :EOF

:create_sql_file
 IF exist sql_update.sql DEL sql_update.sql
 ECHO SHOW COLUMNS FROM character_db_version FROM %char_db%; >> sql_update.sql
 ECHO SHOW COLUMNS FROM db_version FROM %mangos_db%; >> sql_update.sql
 ECHO SHOW COLUMNS FROM realmd_db_version FROM %realmd_db%; >> sql_update.sql
 GOTO :EOF

:show_version
 CALL :deco_frame "%1 DB version are:"
 SET count=1
 FOR /F "tokens=2,3 delims=_" %%A IN ('mysql -u %sql_user% -p%sql_pass% -s ^< sql_update.sql ^| FIND "required_"') DO (CALL :get_db_version %%A_%%B)
 ECHO -%char_db%    = %charv%
 ECHO -%mangos_db%        = %mangosv%
 ECHO -%realmd_db%        = %realmdv%
 IF %1==Updated DEL sql_update.sql
 GOTO :EOF

:get_db_version
 IF %count%==1 SET charv=%1
 IF %count%==2 SET mangosv=%1
 IF %count%==3 SET realmdv=%1
 SET /a count+=1
 GOTO :EOF

:update_db
 CALL :deco_frame "Updating database"
 FOR /F %%A IN ('DIR /B %mangos_dir%\sql\updates\*characters*') DO IF /i %%A GTR %charv%   mysql -u %sql_user% -p%sql_pass% %char_db%   < %mangos_dir%\sql\updates\%%A 2>NUL
 FOR /F %%A IN ('DIR /B %mangos_dir%\sql\updates\*mangos*')     DO IF /i %%A GTR %mangosv% mysql -u %sql_user% -p%sql_pass% %mangos_db% < %mangos_dir%\sql\updates\%%A 2>NUL
 FOR /F %%A IN ('DIR /B %mangos_dir%\sql\updates\*realmd*')     DO IF /i %%A GTR %realmdv% mysql -u %sql_user% -p%sql_pass% %realmd_db% < %mangos_dir%\sql\updates\%%A 2>NUL
 FOR /F "tokens=1 delims=" %%A IN ('DIR /B/s %acid_dir%\*.sql ^| FIND "%acid_branch%"') DO SET acid_sql="%%A"
 mysql -u %sql_user% -p%sql_pass% %mangos_db% < %sd2dir%\sql\mangos_scriptname_full.sql
 mysql -u %sql_user% -p%sql_pass% %sd2_db%    < %sd2dir%\sql\scriptdev2_script_full.sql
 mysql -u %sql_user% -p%sql_pass% %mangos_db% < %acid_sql%
 GOTO :EOF

:start_compiling
 CALL :deco_frame "Starting Mangos compilation."
 PATH=%PATH%;%msbuild%
 msbuild /t:build /p:Configuration=Release /V:q /p:Platform=%bin% %mangos_dir%\win\mangosd%vsversion%.sln
 CALL :deco_frame "Starting SD2 compilation."
 msbuild /t:build /p:Configuration=Release /V:q /p:Platform=%bin% %sd2dir%\script%vsversion%.sln
 GOTO :EOF

:copy_bin
 CALL :deco_frame "Copying .exe and .dll to server."
 COPY %mangos_dir%\bin\%bin%_Release\*.exe %server_dir% > NUL
 COPY %mangos_dir%\bin\%bin%_Release\*.dll %server_dir% > NUL
 GOTO :EOF

:deco_frame
 ECHO -----------
 ECHO -%~1
 ECHO -----------
 GOTO :EOF
::----- Functions end -----------