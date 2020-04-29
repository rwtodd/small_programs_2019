@echo off

setlocal
set project=gen-dsed
set version=1.0.0

echo Building uberjar...
call lein.bat uberjar
if %ERRORLEVEL% NEQ 0 (
   echo lein failed 1>&2
   exit /b 1
)

set tgtdir=h:\bin\_%project%
set tgtjar=%tgtdir%\%project%-%version%.jar
set prjjar=target\uberjar\%project%-%version%-standalone.jar
set tgtscript=h:\bin\%project%

REM remove anything that was already there
echo Removing any existing installs...
rmdir /s "%tgtdir%"
del %tgtscript%.ps1
del %tgtscript%.bat

REM now copy the jar(s) over...
echo Copying %prjjar%...
mkdir "%tgtdir%
copy "%prjjar%" "%tgtjar%"

echo Writing %tgtscript%.ps1...
> "%tgtscript%.ps1" echo ^
& java -jar "%tgtjar%" @args

echo Writing %tgtscript%.bat...
> "%tgtscript%.bat" echo ^
@echo off ^

java -jar "%tgtjar%" %%*

echo Done!
endlocal
