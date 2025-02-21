@echo off

REM @For /f "delims=" %%a in ('Type "File.txt"') do ( echo command_name argument --option %%a)
REM pause

setlocal EnableDelayedExpansion

REM Exclude arguments
REM set "fd_exclude="
set "fd_options="

set "fd_exclude_file=%USERPROFILE%\.usr_conf\fzf\fd_exclude"

REM for /f "tokens=*" %%a in (%fd_exclude_file%) do (
REM   set "fd_exclude=!fd_exclude! %%a"
REM )

REM echo Arguments read from fd_exclude_file: %fd_exclude%

set "fd_options_file=%USERPROFILE%\.usr_conf\fzf\fd_options"

for /f "tokens=*" %%a in (%fd_options_file%) do (
  set "fd_options=!fd_options! %%a"
)

REM echo Arguments read from fd_options_file: %fd_options%

call fd %fd_options% --ignore-file %fd_exclude_file% --color=always %*

endlocal

