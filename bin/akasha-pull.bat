@echo off
REM Wrapper for Windows Task Scheduler — runs akasha-pull.sh via Git Bash
"C:\Program Files\Git\bin\bash.exe" -l -c "cd '/c/Users/gbacu/Documents/Gio Files/AKASHA/akasha-PKM-ref' && bash bin/akasha-pull.sh" >> "%USERPROFILE%\akasha-pull.log" 2>&1
