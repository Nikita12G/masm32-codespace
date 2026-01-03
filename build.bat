@echo off
rem Build script for Windows with MASM32
if not exist C:\masm32\bin\ml.exe (
  echo MASM (ml.exe) not found in C:\masm32\bin
  echo Please install MASM32 and ensure C:\masm32\bin is available.
  exit /b 1
)

set SRC=main.asm
if not exist %SRC% (
  echo Source file %SRC% not found.
  exit /b 1
)

echo Assembling %SRC% ...
ml /c /coff %SRC%
if errorlevel 1 (
  echo Assembler failed.
  exit /b 1
)

echo Linking ...
link /subsystem:windows main.obj C:\masm32\lib\masm32.lib C:\masm32\lib\user32.lib C:\masm32\lib\kernel32.lib C:\masm32\lib\gdi32.lib /OUT:main.exe
if errorlevel 1 (
  echo Linker failed.
  exit /b 1
)

echo Build succeeded: main.exe
exit /b 0
