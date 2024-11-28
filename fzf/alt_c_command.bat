@echo off

REM @For /f "delims=" %%a in ('Type "File.txt"') do ( echo command_name argument --option %%a)
REM pause

setlocal EnableDelayedExpansion

REM Exclude arguments
set "fd_exclude="
set "fd_show="

set "fd_exclude_file=%USERPROFILE%\.usr_conf\fzf\fd_exclude"

for /f "tokens=*" %%a in (%fd_exclude_file%) do (
  set "fd_exclude=!fd_exclude! %%a"
)

REM echo Arguments read from fd_exclude_file: %fd_exclude%

set "fd_show_file=%USERPROFILE%\.usr_conf\fzf\fd_show"

for /f "tokens=*" %%a in (%fd_show_file%) do (
  set "fd_show=!fd_show! %%a"
)

REM echo Arguments read from fd_show_file: %fd_show%

call fd --type directory %fd_show% %fd_exclude% --color=always %*

endlocal

