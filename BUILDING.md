# Build and Installation Guide

This guide covers installing build dependencies and building ScriptExecutorApp
on Windows and in WSL. For application usage and project
development details, see the main [README](README.md).

## Prerequisites

All builds require CMake 3.21.1 or newer, a C++17-capable compiler, Qt 6.2 or
newer with Core, Gui, Qml, and Quick, and libssh. WSL and MinGW builds also
require `pkg-config`.

## Build with VS Code and CMake Tools

This is the recommended workflow for configuring and building the app. It does
not require a separate build script.

1. Open the repository folder in VS Code and install the **CMake Tools**
   extension. For WSL, install or enable the extension in the WSL context too.
2. Install the dependencies for your platform:
   - Native Windows: follow [Native Windows: MSYS2 MinGW64](#native-windows-msys2-mingw64).
   - Linux in WSL: follow [Build and run in WSL](#build-and-run-in-wsl).
3. Select the configure preset:
   - `windows-mingw64` for native Windows with MSYS2
   - `linux-dev` for the Linux app inside WSL
4. Run **CMake: Configure**, then **CMake: Build**.
5. To package on native Windows, use the **Windows: Package (MSYS2)** task.
   To package and launch, use **Windows: Package and launch (MSYS2)**. These
   tasks call CMake directly. They are provided in
   [`examples/vscode/tasks.json`](examples/vscode/tasks.json) and are not
   installed automatically. Copy `examples/vscode/tasks.json` into the
   workspace's `.vscode` folder, then reload the window.
6. In WSL, the example tasks **Linux (WSL): Build and launch** and
   **Windows (WSL): Package** / **Windows (WSL): Package and launch** are
   available after copying the example task file. Run the Windows (WSL) tasks
   from a WSL window.

If a preset does not appear, check that VS Code has the repository folder open,
CMake Tools is installed in the active context, and the required tools are
available. The first native Windows configure needs internet access to
download the Qt Design Studio components.

## Native Windows: MSYS2 MinGW64

This is the recommended native Windows toolchain. The `windows-mingw64` preset
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

3. Follow [Build with VS Code and CMake Tools](#build-with-vs-code-and-cmake-tools)
   to configure and build. Use **Windows: Package (MSYS2)** to create the
   distributable package.

The package is created in
`build\windows-mingw64\windows-package\`. Distribute the complete folder or a
ZIP of it, not just the executable. If the first Qt Design Studio component
download is interrupted, remove `build\windows-mingw64` in the VS Code
Explorer and run the package task again.

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

If you are not using the VS Code workflow, configure, build, and run from the
project directory in the WSL filesystem:

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

## Optional VS Code configuration

The repository provides example `settings.json`, `launch.json`, and
`tasks.json` files in [`examples/vscode/`](examples/vscode/). They are not
installed automatically. Copy the files you need into the workspace's
`.vscode/` folder. To enable the build tasks, copy
`examples/vscode/tasks.json` there.

Copying overwrites files with the same names in `.vscode/`. The local
`.vscode/` folder is ignored by Git. Install the **C/C++** extension
(`ms-vscode.cpptools`) as well as CMake Tools to use the launch configurations.
If MSYS2 or GDB is installed in a different location, adjust the corresponding
paths in `launch.json`.
