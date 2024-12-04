@echo off
REM Script to filter net user output for specific fields for multiple users
setlocal enabledelayedexpansion

REM Input file with usernames (one username per line)
set "USERFILE=users.txt"

REM Output file for filtered results
set "OUTPUTFILE=filtered_users.txt"

REM Clear the output file before appending
> "%OUTPUTFILE%" echo Filtered User Information

REM Loop through each username in the file
for /f "usebackq delims=" %%U in ("%USERFILE%") do (
    set "USERNAME=%%U"
    >> "%OUTPUTFILE%" echo ============================================
    >> "%OUTPUTFILE%" echo User: !USERNAME!
    >> "%OUTPUTFILE%" echo --------------------------------------------
    
    REM Get user details
    for /f "delims=" %%A in ('net user !USERNAME! /domain 2^>nul') do (
        set "line=%%A"
        
        REM Check and filter for specific fields
        echo !line! | findstr /i "User name Last logon Password expires Comment" >nul && >> "%OUTPUTFILE%" echo !line!
    )
    
    REM Add a newline after processing each user
    >> "%OUTPUTFILE%" echo.
)

echo Processing complete. Results saved in "%OUTPUTFILE%".
pause
