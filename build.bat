@echo off

set msbuild="C:\Program Files (x86)\MSBuild\14.0\bin\msbuild"
if not exist %msbuild% (
	set msbuild="C:\Program Files (x86)\MSBuild\12.0\bin\msbuild"
	if not exist %msbuild% (
		echo "Error trying to find MSBuild executable"
		exit 1
	)
)
set SolutionDir=%~dp0

%msbuild% TeamCity.targets /t:RemoveProjectJson /v:minimal

echo building all projects in the solution (Release)

rmdir /s/q "%SolutionDir%Release"
mkdir "%SolutionDir%Release"

CALL :Build GeoAPI v2.0 "" v2.0 "TRACE;NET20"
CALL :Build GeoAPI v3.5 "" v3.5 "TRACE;NET20;NET35"
CALL :Build GeoAPI v4.0 "" v4.0 "TRACE;NET20;NET35;NET40"
CALL :Build GeoAPI v4.0.3 "" v4.0.3 "TRACE;NET20;NET35;NET40"
CALL :Build GeoAPI v4.5 "" v4.5 "TRACE;NET20;NET35;NET40"
CALL :Build GeoAPI_PCL v4.0 Profile328 PCL40 "TRACE;PCL"
CALL :Build GeoAPI_PCL v4.5 Profile259 PCL "TRACE;PCL;NET45"

echo building for Windows CE
REM check this: https://gist.github.com/skarllot/4953ddb6e23d8a6f0816029c4155997a
set msbuild35="C:\Windows\Microsoft.NET\Framework\v3.5\MSBuild"
if not exist %msbuild% (
	echo "Error trying to find MSBuild 3.5 executable, cannot build for Windows CF"
	goto SKIP_CF
)

if not exist "C:\Windows\Microsoft.NET\Framework\v3.5\Microsoft.CompactFramework.CSharp.targets" (
	echo "Error trying to find MSBuild 3.5 CF targets, cannot build for Windows CF"
	goto SKIP_CF
)

%msbuild35% GeoAPI.vs2008.sln /target:GeoAPI_CF /p:Configuration=Release /v:minimal

:SKIP_CF

%msbuild% TeamCity.targets /t:RestoreProjectJson /v:minimal
echo building .NET Core
rmdir /s /q "%SolutionDir%GeoAPI\bin\Release\netstandard1.0"
rmdir /s /q "%SolutionDir%GeoAPI\bin\Release\netstandard1.1"
dotnet --version
dotnet restore
dotnet build -c Release %SolutionDir%GeoAPI
if %errorlevel%==0 (
mkdir "%SolutionDir%Release\netstandard1.0"
mkdir "%SolutionDir%Release\netstandard1.1"
copy "%SolutionDir%GeoAPI\bin\Release\netstandard1.0\GeoAPI.deps.json" "%SolutionDir%Release\netstandard1.0\GeoAPI.deps.json"
copy "%SolutionDir%GeoAPI\bin\Release\netstandard1.0\GeoAPI.dll" "%SolutionDir%Release\netstandard1.0\GeoAPI.dll"
copy "%SolutionDir%GeoAPI\bin\Release\netstandard1.0\GeoAPI.pdb" "%SolutionDir%Release\netstandard1.0\GeoAPI.pdb"
copy "%SolutionDir%GeoAPI\bin\Release\netstandard1.1\GeoAPI.deps.json" "%SolutionDir%Release\netstandard1.1\GeoAPI.deps.json"
copy "%SolutionDir%GeoAPI\bin\Release\netstandard1.1\GeoAPI.dll" "%SolutionDir%Release\netstandard1.1\GeoAPI.dll"
copy "%SolutionDir%GeoAPI\bin\Release\netstandard1.1\GeoAPI.pdb" "%SolutionDir%Release\netstandard1.1\GeoAPI.pdb"
) else (
ECHO Build using dotnet.exe failed.
)

echo build complete.

ENDLOCAL
ECHO ON
@EXIT /B %ERRORLEVEL%

:Build
set Project=%~1
set TargetFX=%~2
set Profile=%~3
set TargetDir=%~4
set Constants=%~5

set OutputPath=%SolutionDir%Release\%TargetDir%\AnyCPU\
set ObjOutputPath=%SolutionDir%GeoAPI\obj\%TargetDir%\
echo building for .NET Framework %Target% %Profile%
rmdir /s/q "%OutputPath%" 2> nul
%msbuild% %SolutionDir%GeoAPI.sln /target:%Project% /verbosity:minimal /property:Configuration=Release;TargetFrameworkVersion=%TargetFX%;TargetFrameworkProfile=%Profile%;BaseIntermediateOutputPath=%ObjOutputPath%;OutputPath=%OutputPath%\;DefineConstants="%Constants%"

REM Clean variables
set Project=
set TargetFX=
set Profile=
set TargetDir=
set Constants=
set OutputPath=
set ObjOutputPath=
EXIT /B 0
