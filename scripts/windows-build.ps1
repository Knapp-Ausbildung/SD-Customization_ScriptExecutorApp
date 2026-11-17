param(
    [Parameter(Position = 0)]
    [ValidateSet("configure", "build", "package", "launch")]
    [string]$Action = "package"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$mingwRoot = if ($env:MINGW_ROOT) {
    $env:MINGW_ROOT
} else {
    "C:\msys64\mingw64"
}
$cmakePath = Join-Path $mingwRoot "bin\cmake.exe"

if (-not (Test-Path $cmakePath)) {
    $cmakeCommand = Get-Command cmake.exe -ErrorAction SilentlyContinue
    if ($cmakeCommand) {
        $cmakePath = $cmakeCommand.Source
    } else {
        throw "CMake was not found. Install MSYS2 MinGW64 or set MINGW_ROOT to its root directory."
    }
}

$env:MINGW_ROOT = $mingwRoot
$env:Path = "$(Join-Path $mingwRoot 'bin');$env:Path"

function Invoke-CMake {
    param([string[]]$Arguments)

    & $cmakePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "CMake failed with exit code $LASTEXITCODE."
    }
}

Push-Location $repositoryRoot
try {
    if ($Action -eq "configure") {
        Invoke-CMake @("--preset", "windows-mingw64")
        return
    }

    Invoke-CMake @("--preset", "windows-mingw64")

    if ($Action -eq "build") {
        Invoke-CMake @("--build", "--preset", "windows-mingw64", "--parallel")
        return
    }

    Invoke-CMake @("--build", "--preset", "windows-mingw64-package", "--parallel")

    if ($Action -eq "launch") {
        $packageDirectory = Join-Path $repositoryRoot "build\windows-mingw64\windows-package"
        $executable = Join-Path $packageDirectory "ScriptExecutorApp.exe"
        if (-not (Test-Path $executable)) {
            throw "Packaged executable was not created: $executable"
        }

        Start-Process -FilePath $executable -WorkingDirectory $packageDirectory
    }
} finally {
    Pop-Location
}
