@echo off

if not exist "%~dp0X17-59465.iso" echo please put X17-59465.iso side by side with this batch file
if not exist "%~dp0X17-59465.iso" start "iexplore" "https://drive.google.com/uc?export=download&id=0ByXszuHgPs8ubkpHRFhqY3ZGZnc"
if not exist "%~dp0X17-59465.iso" goto exit

rem set working directory
set w=%temp%

rem set install.wim index to work with
set i=4

if not exist "%w%\iso" md "%w%\iso"

echo extracting iso
"%~dp07z.exe" x "%~dp0X17-59465.iso" -o"%w%\iso" > nul 2>&1
echo.

rem I want to use latest dism utility instead of default
cd "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"

echo This media contains following versions of Windows:
dism /get-wiminfo /wimfile:"%w%\iso\sources\install.wim" | find "Name"

rem Create mounting directory
if not exist "%w%\mount" md "%w%\mount"

echo Mounting index %i% which stands for
dism /get-wiminfo /wimfile:"%w%\iso\sources\install.wim" /index:%i% | find "Name"
dism /mount-wim /wimfile:"%w%\iso\sources\install.wim" /index:%i% /mountdir:"%w%\mount" > nul 2>&1

rem integrating Internet Explorer 11 prerequisites
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0Windows6.1-KB2533623-x64.msu"
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0Windows6.1-KB2670838-x64.msu"
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0Windows6.1-KB2729094-v2-x64.msu"
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0Windows6.1-KB2731771-x64.msu"
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0Windows6.1-KB2786081-x64.msu"
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0Windows6.1-KB2834140-v2-x64.msu"

rem integrating Internet Explorer 11
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0IE11-Windows6.1-KB2841134-x64.cab"

rem kb3020369 and kb3172605 must be installed to succesfully detect future updates
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0windows6.1-kb3020369-x64_5393066469758e619f21731fc31ff2d109595445.msu"

echo.
rem kb3172605 can not be slipstream before remounting wim
echo Unmounting index %i% from install.wim
dism /unmount-wim /mountdir:"%w%\mount" /commit > nul 2>&1
dism /mount-wim /wimfile:"%w%\iso\sources\install.wim" /index:%i% /mountdir:"%w%\mount" > nul 2>&1

rem slipstreaming kb3172605
dism /image:"%w%\mount" /add-package /packagepath:"%~dp0windows6.1-kb3172605-x64_2bb9bc55f347eee34b1454b50c436eb6fd9301fc.msu"
echo.

rem final unmount
echo Unmounting index %i% from install.wim
dism /unmount-wim /mountdir:"%w%\mount" /commit > nul 2>&1

rem Remove working dir
if exist "%w%\mount" rd "%w%\mount" /Q /S

echo Exporting only index %i% from install.wim
dism /Export-Image /SourceImageFile:"%w%\iso\sources\install.wim" /SourceIndex:%i% /DestinationImageFile:"%w%\install.wim" /Compress:max > nul 2>&1
echo.

echo Overwriting install.wim..
move /y "%w%\install.wim" "%w%\iso\sources\install.wim" > nul 2>&1
echo.

echo creating zero touch scenario
xcopy "%~dp0autounattend.xml" "%w%\iso" /Y
echo.

echo.
echo Creating win7ie11x64ultimate.iso
"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" -b"%w%\iso\boot\etfsboot.com" -h -u2 -m -l"Win7ie11x64" "%w%\iso" "%~dp0win7ie11x64ultimate.iso"  > nul 2>&1
echo.

rem Remove iso dir
if exist "%w%\iso" rd "%w%\iso" /Q /S

:exit

pause