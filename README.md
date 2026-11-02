# ScriptExecutorApp

## Overview

ScriptExecutorApp is a desktop application developed for the SD Customization department.

The goal of this application is to provide customers with an intuitive user interface that allows them to connect to KNAPP warehouse servers and execute testing scripts remotely. Since customers do not have direct access to these servers by default, the application acts as a secure bridge for script execution and test automation.

## Features

- Connect to KNAPP warehouse servers
- Execute predefined testing scripts
- Execute commands and aliases configured in the remote user's shell settings
- Intuitive and user-friendly interface
- Built with Qt Quick (QML) and C++
- Cross-platform architecture

Commands entered in the application run in an interactive, non-login Bash
shell on the remote server. In addition to the user's `~/.bashrc`, the app
loads `~/.common.alias` when present so aliases configured through the user's
`~/.profile` are available. It does not execute the entire `~/.profile`, which
may contain login-only commands. The entered command is evaluated after the
alias file is loaded so aliases such as `lh` can expand.

## Design Language

- Member Variables
  Make sure to mark them with "m_name".
  This makes it easier to be distinguished from local variables.
  Example:
  ```cpp
  class Player
  {
  private:
  string m_name;
  int m_score;
  };
  ```
  
- Memory Management
  In general, try to prefer stack allocation.
  It is up to the developer if he wants to use references or pointers, but it is recommended to use Smart Pointers to prevent memory leaks.
  Also make sure to use "ptr" in the name of pointers.
  Example:
  ```cpp
  int *ptr = new int(10);
  std::unique_ptr<Player> ptrPlayer = std::make_unique<Player>("Name", "100");
  ```

- Naming conventions
  Classes and Structs use PascalCase: z.B. LoginService 
  Method Names and local variables use camelCase: z.B. currentValue, sshKey
  Constants are all caps: z.B. SSH_PORT

- Use const when appropriate
  Mark parameters or the return values of methods as constants to make it obvious they are not meant to be modified in any way.
  Example:
    ```cpp
  void printSession(const Session& session):
  std::string& getSesssionName() const;
  ```

## Dependencies

### Build Dependencies

- CMake >= 3.21
- C++17 compatible compiler
- Qt 6.2 or newer
- libssh

Required Qt modules:

- Qt6 Core
- Qt6 Gui
- Qt6 Qml
- Qt6 Quick
- Qt6 Quick Controls 2

### Linux development build

Install Qt 6, libssh development files, pkg-config, and the C++ build tools
for your distribution. Then configure and build with:

```bash
cmake --preset linux-dev
cmake --build --preset linux-dev --parallel
```

In VS Code on Linux, select `linux-dev` as the configure and build preset in
CMake Tools. Use its **Build** button to compile and **Launch** to run
`ScriptExecutorApp`.

### Windows x64 build (MSYS2 MinGW64)

The project uses one supported Windows toolchain: MSYS2 MinGW64 with GCC and
Ninja. Qt and libssh must both come from that same MinGW64 environment; do not
mix them with MSVC packages. Visual Studio is not required.

Install the MINGW64 packages for GCC, CMake, Ninja, pkgconf, libssh, and the
Qt 6 modules used by the app (Core, Gui, Qml, Quick, and Quick Controls 2).
The Windows preset uses the standard `C:\msys64\mingw64` installation path.
For a standard installation, configure and build with:

```powershell
cmake --preset windows-mingw64
cmake --build --preset windows-mingw64
```

<<<<<<< Updated upstream
If MSYS2 is installed elsewhere, update the four toolchain paths in the
`windows-mingw64` preset in `CMakePresets.json` and `MINGW_ROOT`/`PATH` in
`.vscode/settings.json`.

### Build and run with VS Code

Install the **CMake Tools** extension (`ms-vscode.cmake-tools`) and open the
repository folder in VS Code. The workspace selects `windows-mingw64` on
Windows and `linux-dev` on Linux. On Windows, it configures the standard MSYS2
location (`C:\msys64\mingw64`) and adds its MinGW/MSYS2 tools to `PATH`. If
MSYS2 is installed elsewhere, update the paths in `.vscode/settings.json` and
`CMakePresets.json`. CMake Tools configures the project when the folder opens; use the
**Build** button in the status bar to compile, then select
`ScriptExecutorApp` as the launch target and click **Launch** (play button) to
run it. The same actions are available from the Command Palette as **CMake:
Build** and **CMake: Launch Target**.

To package the app with its Qt/QML plugins and runtime dependencies, run:
=======
For a WSL workspace that has MSYS2 installed at `C:\msys64\mingw64`, the
workspace CMake Tools setting uses `scripts/cmake-dispatch.sh`. It selects the
Linux CMake executable for Linux build directories and MSYS2 CMake for Windows
presets, so the CMake executable does not need to be changed manually. Select
`windows-mingw64-wsl` in CMake Tools to build a Windows executable while the
workspace remains under WSL. Its build directory is on the Windows filesystem
at `/mnt/c/Users/Public/ScriptExecutorApp-build/windows-mingw64`, where Windows
Ninja can run its compiler checks and builds. The native Windows preset remains
`windows-mingw64`. In WSL, package the app with the
`windows-mingw64-wsl-package` build preset.

In VS Code, select `windows-mingw64` as the configure preset. CMake Tools can
then build and launch `ScriptExecutorApp.exe` using its normal Build and Launch
Target commands. The packaged app is built with:
>>>>>>> Stashed changes

```powershell
cmake --build --preset windows-mingw64-package
```

The package target deploys Qt/QML plugins and runtime DLL dependencies into
`build\windows-mingw64\windows-package\`. Distribute the whole folder (or zip
it), not just the executable.

The app runs locally on Windows while SSH commands execute on the connected
remote Linux server.

## Contact

In case of any further questions, feel free to contact: Alexander Auer
