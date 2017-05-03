@echo off

set scriptpath=%~dp0

where /q ruby 

if errorlevel 1 (
  echo eec2 requires Ruby -- please go to http://rubyinstaller.org/downloads
  exit /b
)

ruby "%scriptpath%\eec2" %*
