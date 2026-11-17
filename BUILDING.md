# Build and Installation Guide

This guide covers installing build dependencies and building ScriptExecutorApp
on Windows and in WSL. For application usage and project
development details, see the main [README](README.md).

## Prerequisites

All builds require CMake 3.21.1 or newer, a C++17-capable compiler, Qt 6.2 or
newer with Core, Gui, Qml, and Quick, and libssh. WSL and MinGW builds also
require `pkg-config`.

## Which workflow should I use?

| What you want to do | Where to run it | Command | Helper needed |
| --- | --- | --- | --- |
| Build and launch the Linux app | WSL | `cmake --preset linux-dev`, then `cmake --build --preset linux-dev --parallel` and `./build/linux-dev/ScriptExecutorApp` | No script; use the `linux-dev` preset |
| Package the Windows app from WSL | WSL | `bash scripts/windows-build-from-wsl.sh package` | [windows-build-from-wsl.sh](scripts/windows-build-from-wsl.sh) |
| Package and launch the Windows app from WSL | WSL | `bash scripts/windows-build-from-wsl.sh launch` | [windows-build-from-wsl.sh](scripts/windows-build-from-wsl.sh) |
| Package the Windows app from a Windows checkout | PowerShell | `.\scripts\windows-build.ps1 package` | [windows-build.ps1](scripts/windows-build.ps1) |
| Package and launch the Windows app from a Windows checkout | PowerShell | `.\scripts\windows-build.ps1 launch` | [windows-build.ps1](scripts/windows-build.ps1) |

Use the WSL shell script only from WSL; it calls Windows CMake and copies the
WSL checkout to the Windows filesystem for packaging. Use the PowerShell
script only from Windows. The Linux app itself is built and launched inside
WSL with the `linux-dev` preset.

## Build and run in WSL

These instructions are for building and running the Linux application inside
WSL. Keep the checkout in the WSL filesystem, for example
`~/projects/ScriptExecutorApp`, rather than under a mounted Windows directory
such as `/mnt/c`.
Building Qt projects on the mounted Windows filesystem can be substantially
slower because the build creates many files.

Install the required development packages using your distribution's package
manager. For apt-based distributions, for example:

```bash
sudo apt update
sudo apt install -y \
  cmake \
  build-essential \
  ninja-build \
  qt6-base-dev \
  qt6-base-dev-tools \
  qt6-declarative-dev \
  libxkbcommon-dev \
  qml6-module-qtquick \
  qml6-module-qtquick-window \
  qml6-module-qtquick-controls \
  qml6-module-qtquick-layouts \
  qml6-module-qtquick-templates \
  qml6-module-qtqml \
  qml6-module-qtqml-workerscript \
  libssh-dev \
  pkg-config
```

From the project directory in the WSL filesystem, configure, build, and run
the app:

```bash
cd ~/projects/ScriptExecutorApp
cmake --preset linux-dev
cmake --build --preset linux-dev --parallel
./build/linux-dev/ScriptExecutorApp
```

The repository's `scripts/dependencyInstaller.sh` can also install these
packages on apt-based distributions, but it additionally runs `apt upgrade
-y`. Review the script before using it.

### Package and launch the Windows app from WSL

The Linux app runs inside WSL using the commands above. To build a Windows
package from that WSL checkout, the script copies the source to the Windows
filesystem and invokes Windows CMake and the MSYS2 toolchain there. This keeps
Windows build tools from being run against a WSL filesystem path.

Install MSYS2 MinGW64 at `C:\msys64\mingw64` on Windows and install the
packages listed in [Native Windows: MSYS2 MinGW64](#native-windows-msys2-mingw64).
WSL interoperability and `rsync` are also required. From the project directory
in WSL:

```bash
bash scripts/windows-build-from-wsl.sh configure
bash scripts/windows-build-from-wsl.sh build
bash scripts/windows-build-from-wsl.sh package
bash scripts/windows-build-from-wsl.sh launch
```

`launch` packages the app and starts the Windows executable. The helper also
supports the separate `configure`, `build`, and `package` actions. The source
copy is placed in `C:\Users\Public\ScriptExecutorApp-src-wsl`; the Windows
package is placed in
`C:\Users\Public\ScriptExecutorApp-build\windows-mingw64-wsl\windows-package`.
The original WSL checkout remains the source of truth. If Windows CMake is
installed somewhere other than `C:\msys64\mingw64\bin\cmake.exe`, set
`WINDOWS_CMAKE_EXE` in WSL to its mounted path.

## Native Windows: MSYS2 MinGW64

This is the recommended native Windows build. The `windows-mingw64` preset
expects MSYS2 in `C:\msys64\mingw64`. Qt, libssh, the compiler, and build tools
must all come from the same MINGW64 environment; do not mix these with MSVC
packages.

1. Install MSYS2 from [msys2.org](https://www.msys2.org/) at `C:\msys64`.
2. Open **MSYS2 MINGW64** from the Start menu and update the package database:

   ```bash
   pacman -Syu
   ```

   If the update closes the terminal, open **MSYS2 MINGW64** again and install
   the project packages:

   ```bash
   pacman -S --needed \
     mingw-w64-x86_64-gcc \
     mingw-w64-x86_64-cmake \
     mingw-w64-x86_64-ninja \
     mingw-w64-x86_64-pkgconf \
     mingw-w64-x86_64-libssh \
     mingw-w64-x86_64-qt6-base \
     mingw-w64-x86_64-qt6-declarative \
     mingw-w64-x86_64-qt6-tools
   ```

3. In PowerShell, navigate to the project folder. If MSYS2 is installed in its
   standard location, the build script finds it automatically. Otherwise, set
   `MINGW_ROOT` to the MSYS2 `mingw64` directory:

   ```powershell
   cd "$HOME\development\ScriptExecutorApp"
   $env:MINGW_ROOT = 'C:\msys64\mingw64'
   ```

4. Configure and build, or build and package:

   ```powershell
   .\scripts\windows-build.ps1 configure
   .\scripts\windows-build.ps1 build
   .\scripts\windows-build.ps1 package
   ```

   To package and launch the application in one step:

   ```powershell
   .\scripts\windows-build.ps1 launch
   ```

The package is created in
`build\windows-mingw64\windows-package\`. Launch `ScriptExecutorApp.exe` from
that folder to test it. Distribute the complete folder or a ZIP of it, not
just the executable.

## Build with VS Code and CMake Tools

The **CMake Tools** extension (`ms-vscode.cmake-tools`) detects the configure
and build presets in `CMakePresets.json` and provides build and launch actions.
It does not install CMake, Qt, or a compiler; install the required tools using
the instructions above.

1. Open the project folder in VS Code and install **CMake Tools**. For WSL,
   install or enable the extension in the WSL context as well.
2. Select the configure preset:
   - `linux-dev` for building and running the Linux app in WSL
   - `windows-mingw64` for a native Windows build with MSYS2
3. Run **CMake: Configure**, then **CMake: Build**.
4. In a WSL window, use the **Linux (WSL): Build and launch** task to run the
   Linux app, or **Windows (WSL): Package** / **Windows (WSL): Package and
   launch** to create and optionally start the Windows app.
5. On native Windows with MSYS2, use the **Windows: Package (MSYS2)** or
   **Windows: Package and launch (MSYS2)** task.

If a preset does not appear, check that VS Code has the repository folder open,
CMake Tools is installed, and the required tools and environment variables are
available to VS Code. After changing Windows environment variables, restart
VS Code.

### Optional project-specific VS Code configuration

The repository provides example `settings.json`, `launch.json`, and
`tasks.json` files in [`examples/vscode/`](examples/vscode/). They are not
installed automatically. To use them, copy them into a local `.vscode/` folder
from the repository root.

In WSL:

```sh
mkdir -p .vscode
cp examples/vscode/*.json .vscode/
```

In PowerShell:

```powershell
New-Item -ItemType Directory -Force .vscode
Copy-Item examples/vscode/*.json .vscode/
```

Copying overwrites files with the same names in `.vscode/`. The local
`.vscode/` folder is ignored by Git. Install the **C/C++** extension
(`ms-vscode.cpptools`) as well as CMake Tools to use the launch configurations.
If MSYS2 or GDB is installed in a different location, adjust the corresponding
paths in `launch.json`.
