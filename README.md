# ScriptExecutorApp – Developer and User Documentation

This guide describes how ScriptExecutorApp is structured, how an action is
executed from the click to the SSH server, and how to add another action button.

## Table of Contents

- [Overview](#overview)
- [Visual Design](#visual-design)
- [Prerequisites](#prerequisites)
- [C++ Conventions](#c-conventions)
- [Project Structure](#project-structure)
- [Login and Server Favorites](#login-and-server-favorites)
- [Multiple Servers](#multiple-servers)
- [How an Action Flows Through the Application](#how-an-action-flows-through-the-application)
- [Adding an Action Button](#adding-an-action-button)
- [Dashboard Buttons](#dashboard-buttons)
- [Caching Passwords and Credentials](#caching-passwords-and-credentials)
- [Build and Installation](BUILDING.md)
- [Notes for Changes](#notes-for-changes)
- [Feedback](#feedback)

## Overview

ScriptExecutorApp is a Qt desktop application for working with KNAPP servers
for KiSoft One. The user interface is rendered with QML. C++ manages the
application state and uses libssh to perform actions on the connected servers.
The application supports, among other things:

- SSH login and confirmation of an unknown or changed host key
- multiple simultaneous server connections with independent state per tab
- shared server favorites and pre-filled login details
- arbitrary shell commands and predefined actions
- display of command output while it is running and interactive input
- management of installed Git repositories and branches
- Oracle Data Pump export and restore
- cancellation of running commands, tab notifications, and server-specific logs

Remote commands run in an interactive, non-login Bash shell. In addition to
`~/.bashrc`, `~/.common.alias` is loaded. `~/.profile` is not executed.

## Visual Design

The interface uses the **Material Dark style of Qt Quick Controls** as its
foundation. Colors and components are customized with QML styles; the
unmodified default theme is not used.

| Design element | Implementation |
| --- | --- |
| Background | Dark navy tones (`#101f2c`, `#0b1520`) |
| Accent and focus | Turquoise/cyan (`#35c7e4`) |
| Text | Light text (`#e3edf5`) and subdued secondary text (`#9bb0c0`) |
| Surfaces and borders | Subtle contrast and rounded elements |
| Status and actions | Custom colors for running, successful, and destructive actions |

The design is intended for technical workflows: status, feedback, and the live
console output should be easy to recognize.

## Prerequisites

### For Use

- A supported desktop build of the application. On Windows, use the complete
  provided x64 package.
- A network connection to the target server over SSH. The application uses
  port `22` by default and currently supports login with a username and password.
- A valid user account on a reachable KNAPP Linux server (usually the klassx
  user). The host key must be confirmed on the first connection.
- The required tools and permissions for arbitrary commands and actions must
  already be available on the target server. They are not installed by the
  desktop application.
- Testing was performed on Platform 13.1.2 with KiSoft version 2.10. There are
  known issues with KiSoft 2.10 starting with Platform 14, so different
  commands may be required due to a major changes at Platform 14.

### Target Server and Action Prerequisites

Remote commands require a Bash shell. The additional programs and permissions
needed depend on the selected action:

- Git/repository actions require `git` and access to the selected remote
  repository.
- Database actions require the appropriate Oracle environment and its
  programs, for example `sqlplus`, `expdp`, and `impdp`.
- **Setup Repository** and other reinstallation actions require the configured
  KiSoft environment (including `WCS_ROOT`, `KX_SRC_ROOT`, and
  `KLASSX_DB_CONNECT`), the build tools used for each step, and the required
  `sudo` permissions. The relevant system services must also exist for service
  actions.

Check the permissions and installation paths that apply to the server before
running an action. Installation and restore actions can change the server state.

### Build and Installation

See the [Build and Installation Guide](BUILDING.md) for installing dependencies
and building on Windows, Linux, and WSL. For native Windows, see the
[Quick install](BUILDING.md#quick-install-native-windows).

## C++ Conventions

- **Naming:** Classes and structures use `PascalCase`, methods and local
  variables use `camelCase`, and constants use `UPPER_SNAKE_CASE`.

  - **Member variables**
    Mark them with the prefix `m_`. This makes them easier to distinguish from
    local variables. Example:

    ```cpp
    class Player
    {
    private:
      string m_name;
      int m_score;
    };
    ```

- **Lifetime and memory management:**
  - Use local variables for objects that are needed only within a function or
    a limited block. Their memory is released automatically when they leave
    scope.
  - Use Qt parent-child ownership for `QObject` objects when the child's
    lifetime is tied to the parent's. Pass the parent when creating the child;
    Qt deletes its child objects when the parent is destroyed. Do not also
    delete such a child manually.
    - **Memory management**
      In general, try to prefer stack allocation. It is up to the developer
      whether to use references or pointers, but smart pointers are recommended
      to prevent memory leaks. Also make sure to use `ptr` in pointer names.
      Example:

      ```cpp
      int *ptr = new int(10);
      std::unique_ptr<Player> ptrPlayer = std::make_unique<Player>("Name", "100");
      ```
  - Use raw pointers only for non-owning references when it is ensured that the
    referenced object outlives them. For owning pointers, it must be clear who
    releases the object.
- **Use const when appropriate**
  
    Mark parameters or method return values as constants to make it clear that
    they are not intended to be modified. Example:

    ```cpp
    void printSession(const Session& session):
    std::string& getSesssionName() const;
    ```

## Project Structure

| File or folder | Purpose |
| --- | --- |
| `main.qml` | Creates the tab bar and session views, shares favorites, and manages the active tab. |
| `content/App.qml` | User interfaces: login, dashboard, buttons, dialogs, and output. |
| `src/main.cpp` | Starts Qt/QML, creates the `SessionManager`, and exposes the manager and settings-file path to QML. |
| `src/App/SessionManager.hpp/.cpp` | Creates, activates, and removes the `AppController` instances used per server. |
| `src/App/AppController.hpp/.cpp` | Session state, UI actions, checks, log management, and result processing. |
| `src/LoginService/LoginService.hpp/.cpp` | Mediates between the controller and SSH worker and manages its thread. |
| `src/LoginService/SshWorker.hpp/.cpp` | SSH connection and remote commands, presets, Git, and Oracle actions. |
| `imports/ScriptExecutor/` | Shared QML helper components. |
| `CMakeLists.txt` and `CMakePresets.json` | Dependencies, build configuration, and build presets. |
| `scripts/dependencyInstaller.sh` | Installs build dependencies on Ubuntu/Debian; also runs `apt upgrade`. |

## Login and Server Favorites

The login screen accepts an IP address, username, and password for SSH login.
A name for the server favorite is optional. After a successful login:

- the IP address and username are pre-filled the next time the login screen is
  opened;
- the server is automatically saved as a favorite. If no name was entered, the
  name field remains empty; the IP address is used only as the visible fallback
  name for the favorite and tab;
- an existing favorite with the same IP address is updated instead of adding
  another entry.

Saved servers can be selected from the list: the IP address, username, and
favorite name are entered into the fields. The most recently selected favorite
IP is saved and selected again the next time the login screen is opened, if the
favorite still exists. If no selection is saved, the field shows “Select
favorite”. An entry can be removed using the red **x** next to it. If you log
in to that server successfully again, it is added as a favorite again.

The favorites list and its settings are shared by all server tabs. Changes such
as adding, updating, or removing a favorite are therefore immediately available
on the login screens in the other tabs as well.

The data is stored locally in `ScriptExecutorApp/settings.ini` in the
user-specific configuration directory:

- **Linux:** usually `~/.config/ScriptExecutorApp/settings.ini`
- **Windows:** usually
  `C:\Users\<username>\AppData\Local\ScriptExecutorApp\settings.ini`.
  The folder can be opened in Explorer using `%LOCALAPPDATA%\ScriptExecutorApp`.

The actual path depends on the system configuration. The file contains
favorites, the most recently selected favorite, IP addresses, usernames, and
favorite names, but no SSH passwords. This information is not stored encrypted;
handle the file accordingly.

If the favorites cannot be loaded, the application displays an error and
prevents changes to the favorites list so that existing data is not
overwritten. The `settings.ini` file should then be checked.

## Multiple Servers

Use the **+** entry in the tab bar to open another session. Each session has
its own `AppController`, `LoginService`, and `SshWorker`; therefore the SSH
connection, login status, active repository, command output, and running action
each have their own state. Switching tabs only changes the displayed session
and does not disconnect it.

The tab name is the favorite name, if one exists, or otherwise the server IP.
Long tab bars can be navigated with the arrows or by scrolling over the bar
with the mouse wheel. A connected tab can be closed after confirmation; a
running action prevents it from being closed. The last session cannot be closed.

If a command finishes, fails, or is canceled in an inactive tab, a notification
dot appears on that tab. The notification is cleared when you switch to that
tab. While a command is running, the tab shows an animated loading indicator.
Dialogs also show the name or address of the server whose session opened them.

### Responsibilities of the C++ Layers

- **`SessionManager`** owns the session controllers and manages their order and
  the active tab.
- **`AppController`** is the interface between the user interface and the
  application. There is one instance per server. It exposes QML properties and
  slots, checks the active repository type, among other things, and processes
  worker results.
- **`LoginService`** keeps the `SshWorker` in its own `QThread`. Calls and
  results are forwarded through Qt signals and slots.
- **`SshWorker`** performs the SSH and shell work. Its own thread keeps
  blocking network and process calls from blocking the user interface.

## How an Action Flows Through the Application

```mermaid
flowchart LR
    UI["QML interface<br/>Tabs and session views"]
    SM["SessionManager<br/>Sessions and active tab"]
    FAVORITES["Shared favorites<br/>ListModel + settings.ini"]

    subgraph SESSION["Per-server session (separate instances)"]
        AC["AppController<br/>Session state and checks"]
        LS["LoginService<br/>Dedicated QThread"]
        SW["SshWorker<br/>Dedicated SSH connection"]
        SERVER[("KNAPP server")]
    end

    UI -->|"Add / switch / close tab"| SM
    SM -->|"Creates and manages controller"| AC
    UI -->|"Action in active tab"| AC
    UI <-->|"Read and change favorites"| FAVORITES
    AC -->|"Action"| LS
    LS -->|"Queued signal"| SW
    SW -->|"SSH command"| SERVER
    SERVER -->|"Output and exit code"| SW
    SW -->|"Qt signals"| LS
    LS -->|"Result / live output"| AC
    AC -->|"Display status and result"| UI

    classDef ui fill:#e7f5ff,stroke:#1677a8,color:#102a43
    classDef logic fill:#eef7e8,stroke:#4d7c0f,color:#243b0b
    classDef worker fill:#fff4df,stroke:#c27803,color:#4a2d00
    classDef server fill:#f4eaff,stroke:#7e22ce,color:#32104f
    class UI ui
    class SM,AC,LS,FAVORITES logic
    class SW worker
    class SERVER server
```

The `SessionManager` manages multiple sessions. Each session has its own
`AppController`/`LoginService`/`SshWorker` chain, its own SSH connection, and
its own command state. Sessions can connect to different servers or to the
same server. Favorites, on the other hand, are intentionally shared. Each
`SshWorker` runs in its own thread. This keeps SSH calls from blocking the user
interface. Command output can be returned in chunks through signals while the
command is running; after it finishes, the exit code and any error message are
also returned.

For a predefined button, the flow is typically:

1. QML calls `dashboardRoot.runPreset(...)`.
2. This function sets the running state and calls
   `appController.executePresetCommand(commandId)`.
3. `AppController` checks whether the action is allowed in the current state
   and forwards it to `LoginService`.
4. `LoginService` sends the action to the worker thread.
5. `SshWorker::executePresetCommand()` maps the ID to a shell command and runs
   it over SSH.
6. Output, errors, and the exit status are returned to the controller and the
   user interface.

The user interface prevents other actions while a command is running.
`AppController` also checks that a KiSoft-One repository is active for commands
and presets. `installRepository` is handled separately by the controller.

## Adding an Action Button

A simple preset consists of two connected parts:

1. a button in `content/App.qml`
2. a command mapping for the same ID in
   `SshWorker::executePresetCommand()` in `src/LoginService/SshWorker.cpp`

The ID connects the UI and C++. Use the same unique ID in both places.

### 1. Add a Button to the Dashboard

Place the button in the appropriate `ActionCard` and use the existing
`AnimatedCommandButton` pattern. Example:

```qml
AnimatedCommandButton {
    Layout.fillWidth: true
    text: "My action"
    iconText: "▶"
    Accessible.name: text
    enabled: !dashboardRoot.commandRunning &&
             dashboardRoot.kiSoftOneActive
    running: dashboardRoot.activeCommandButton === "myAction"
    clickHandler: function() {
        dashboardRoot.runPreset(
            "myAction",
            "My action is running ...",
            "myAction")
    }
}
```

Important details:

- `text` is the button label.
- `enabled` should match the action's state logic. For a regular KiSoft-One
  preset, the conditions above are a good example.
- `running` marks the button that is currently active.
- The first parameter of `runPreset` is the preset ID. The second text is used
  as a description in the command output. The third parameter is the button ID
  used for the running indicator.
- `runPreset` ignores clicks if a command is already running, sets the UI
  state, and calls the controller. Use this helper instead of reimplementing
  the flow in the button.

### 2. Map the Preset ID to a Command

Add a branch for the same ID to `SshWorker::executePresetCommand()`:

```cpp
} else if (commandId == "myAction") {
    command = "echo 'My action was executed'";
}
```

The branch belongs in the existing `if`/`else if` mapping, before its final
`else` rejects unknown IDs. The worker then calls
`executeCommandInternal(command, requestPty)`. For a non-interactive command
without `sudo`, `requestPty` can remain `false`.

A command that requires `sudo` or interactive terminal input must be handled
separately: check the existing presets and dialogs for
`runPresetWithSudoPassword`, `requestPty`, and input prompts. Do not simply add
a `sudo` command to the basic example.

### 3. Check and Test

1. Check that the QML call and C++ mapping use exactly the same ID.
2. Build and start the application using the
   [Linux/WSL build guide](BUILDING.md#linux-and-wsl).
3. Log in to a suitable test system and check the button in the appropriate
   repository state.
4. Check both successful execution and error output and exit status.

A new signal, slot, or dedicated controller handler is normally not required
for a simple preset. If the action needs additional input, its own dialog, a
multi-step flow, or special result handling, the relevant properties, slots,
signals, and controller logic must also be added. First look for a similar
existing action and follow its pattern.

## Dashboard Buttons

The buttons are arranged in the dashboard in `content/App.qml`. The following
overview describes what the current actions do according to the implementation.

### Repository Actions

| Button | Effect |
| --- | --- |
| **Open Repository** | Opens the origin URL of the currently selected repository with the system's default application. |
| **Setup Repository** | Requests a repository URL, loads the available branches, and lets you select a branch. Before replacement, a warning is shown: the target repository is completely replaced, including local changes. After confirmation, the `klassx` sudo password is requested and automatically provided if the process prompts for it. After a successful replacement, the application immediately asks whether to start the installation. |
| **Switch Branch** | Loads branches from the installed repository. The selected branch is not just switched locally: the UI confirms complete replacement of the repository directory. Local changes and files may be lost. |
| **Fetch Branch** | Fetches the currently selected branch from the remote. It does not switch to the branch or update the working tree by merging. |
| **Pull Branch** | First checks that there are no local or untracked changes, fetches the branch, and updates it with a fast-forward. It aborts if there are local changes or divergent history. |

### Database Actions

| Button | Effect |
| --- | --- |
| **Dump DB** | Requests the `klassx` sudo password and the `BACKUPTOOL_USER` password. Oracle Data Pump then creates the `kisoft_schemas.dmp` dump file for `LU`, `AFCONFIG`, `ARCHIVE`, `KLASSX`, `KXGUI`, `KXREPORT`, and `USER_MANAGEMENT`. If `BACKUPTOOL_USER` is missing, the application checks for it and starts creating it. |
| **Load dumped DB** | First asks for confirmation and then requests the Oracle credentials. The restore resets the same seven target schemas and reimports them from the dump. Existing data in these schemas is deleted or overwritten. Use only with the appropriate dump and on a system intended for this operation. |
| **Rebuild Database** | Runs `make reinstall` in the WMW directory and automatically confirms the prepared updates requested there with `y`. |

The dump is stored on the connected Oracle environment in the Oracle
`DATA_PUMP_DIR` directory as `kisoft_schemas.dmp`; it is not downloaded to the
computer running the application. Subsequent exports use the same filename
(`REUSE_DUMPFILES=YES`) and overwrite an existing dump; no version history is
created. The restore also reads this file from `DATA_PUMP_DIR`. Sessions using
the same Oracle environment therefore share the file. Concurrent export and
restore actions there can interfere with each other.

### Reinstallation and Services

| Button | Effect |
| --- | --- |
| **Repository** | Requests the `klassx` sudo password and starts the complete installation: `setupBuildTarget.sh`, then `KXrelease.sh` or `KXrelease.sh -f` depending on the detected database state, followed by the Navigator build and restarts/starts of the associated services. |
| **Database** | Requests the sudo password, runs `make uninstall` and `make install` in the WMW directory, and then updates the KiSoft parameter tables. |
| **Navigator** | Requests the sudo password, rebuilds Navigator in the `afgui` directory with `xmkmf` and `make release`, and restarts the associated services. |
| **KiSoft** | Requests the sudo password, runs `make release` in the WCS directory, and then updates the KiSoft parameter tables. |
| **Refresh Dummy-Station Hosts** | Reads TCP host names from `station_parameter.xml` and adds missing entries to `/etc/hosts` using free addresses from the designated local address range. |
| **Status** | Runs the KiSoft-One `qking` status program and displays its output in the live console. |
| **Restart** | Restarts `kisoft-one.service` with `systemctl`. |
| **Stop** | Stops `kisoft-one.service` with `systemctl`. |

Installation, database, and service actions can significantly change the
server state. In particular, **Load dumped DB**, **Reinstall Database**,
**Rebuild Database**, **Repository**, and **Switch Branch** should only be
performed during an appropriate maintenance window, with the necessary
permissions, and on a verified target system. An exit code of `0` is not a
substitute for a functional check of the resulting server or database state.

### Other Controls

- **Log out** ends the SSH session.
- **Cancel command** requests cancellation of the running remote command.
- **Clear output** clears only the live console display.
- **Open logs** opens the current server's log folder.
- The search field filters the displayed console output; it does not change
  the remote command or delete a log file.

### Server-Specific Logs

Logs are stored next to the application executable under `logs/`, independent
of the working directory used to launch the app. A separate subfolder is
created for each server based on its favorite name; if there is no name, the IP
address is used. Invalid filename characters are replaced:

```text
logs/
└── <server-name-or-IP>/
    ├── latest.log
    └── archive/
        └── <timestamp>_exit_<exit-code>.log
```

`latest.log` contains the most recently written command log. Commands with a
non-zero exit code are also archived in `archive/`. When the installed
repository is changed, only the archive for the currently active server is
cleared. Existing logs from the former global structure `logs/latest.log` and
`logs/archive/` are not moved automatically.

## Caching Passwords and Credentials

Passwords and Personal Access Tokens are not permanently stored in a file or
system keychain. IP addresses and usernames are stored permanently as
described in [Login and Server Favorites](#login-and-server-favorites). To
reuse them during a workflow, the QML interface temporarily keeps them as
`string` properties on the `dashboardRoot` object (in `content/App.qml`). This
is a simple in-memory buffer, not an encrypted vault or one protected against
memory access. The values are no longer available after the application closes.

### Existing Buffers

| Property | Contents and use | Lifetime according to the current code |
| --- | --- | --- |
| `oracleSudoPasswordCache` | `klassx` sudo password; used for Oracle, Database, Navigator, and KiSoft actions when matching password prompts appear. | Cleared after command completion, failure, or cancellation. |
| `oracleBackupPasswordCache` | `BACKUPTOOL_USER` password; reused for Oracle dump/restore prompts. | Cleared after command completion, failure, or cancellation. |
| `setupRepositorySudoPasswordCache` | `klassx` sudo password; automatically provided only for matching sudo prompts during the Setup Repository workflow. | Remains available during repository replacement and the subsequent installation while the installation is pending. Cleared after completion, failure, or cancellation. |
| `gitUsernameCache` and `gitPatCache` | Git username and Personal Access Token; after entry in the Git credentials dialog, further matching Git prompts are answered automatically. | Cleared when the Git credentials dialog is canceled and after command completion, failure, or cancellation. |
| `SshWorker::m_pendingPassword` | SSH login password; temporarily needed if the host key must be confirmed before login. | Cleared after the authentication attempt and discarded when the SSH session is cleaned up. |

For **Dump DB** and **Load dumped DB**, both Oracle passwords are entered in
`oracleCredentialsDialog`. When confirmed, the dialog copies the values to
`oracleSudoPasswordCache` and `oracleBackupPasswordCache`, clears the input
fields, and starts the action. When the worker reports a matching password
prompt, `onCommandInputRequested` looks up the value in the buffer and passes
it through `appController.submitCommandInput(...)`. If `BACKUPTOOL_USER` is
missing, it is created; the application answers both the new-password prompt
and its confirmation with the `oracleBackupPasswordCache` entered in the dialog.

For **Database**, **Navigator**, and **KiSoft**, the sudo password is first
entered in `reinstallSudoCredentialsDialog` and copied to
`oracleSudoPasswordCache`. For **Setup Repository**, it is requested after
branch selection and confirmation of the complete repository replacement, and
copied to the separate `setupRepositorySudoPasswordCache`. The password field
is then cleared; matching sudo prompts during repository replacement or the
subsequent installation are answered automatically. After a successful
download, the installation prompt appears immediately. The cache is cleared
if installation is declined, or if there is an error, cancellation, or
completion of the installation.

### Adding a Buffer for a New Credential Prompt

For a new action, extend the existing dialog/prompt flow instead of embedding
a password in a shell command:

1. Add an empty property under the `dashboardRoot` properties, for example
   `property string myPasswordCache: ""`.
2. On dialog confirmation, copy the value from the password field into this
   property and then call `passwordField.clear()`.
3. Answer only the expected prompt for the associated action with
   `appController.submitCommandInput(dashboardRoot.myPasswordCache)`.
4. Clear the property and input field when the dialog is canceled and when the
   command succeeds, fails, or is canceled. Do not rely on the user closing
   the application immediately.

The basic pattern of the existing Oracle buffers looks like this:

```qml
property string myPasswordCache: ""

function clearMyPasswordCache() {
    myPasswordCache = ""
    myPasswordField.clear()
}

// In the dialog's confirmation handler:
dashboardRoot.myPasswordCache = myPasswordField.text
myPasswordField.clear()

// In the appropriate onCommandInputRequested branch:
if (dashboardRoot.myPasswordCache.length > 0) {
    appController.submitCommandInput(dashboardRoot.myPasswordCache)
    return
}
```

Also connect `clearMyPasswordCache()` to the existing `onCommandCompleted`,
`onCommandFailed`, `onCommandCancelled`, and dialog-cancellation paths. Use
`echoMode: TextInput.Password` for password input. The Git buffers are cleared
through `clearGitCredentialsCache()` when a command ends (regardless of exit
code), fails, or is canceled. New buffers should follow the same pattern.

## Notes for Changes

- UI and presentation state generally belong in QML; application logic and
  state checks belong in the `AppController`.
- SSH and shell work belongs in the `SshWorker`; UI threads must not be blocked.
- New controller functions that QML calls must be declared as `public slots`
  or otherwise made explicitly available to QML.
- Do not suppress error messages: errors and exit statuses should remain
  visible to the UI through the existing signal path.
- Changes to existing presets can have server-side effects. Test them on a
  suitable system and pay particular attention to restart, stop, reinstallation,
  and restore actions.

## Feedback

If you have questions or suggestions, feel free to contact Thomas Milowiz.
