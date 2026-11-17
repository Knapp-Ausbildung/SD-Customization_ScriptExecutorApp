#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
windows_source="${WINDOWS_SOURCE_DIR:-/mnt/c/Users/Public/ScriptExecutorApp-src-wsl}"
package_dir="/mnt/c/Users/Public/ScriptExecutorApp-build/windows-mingw64-wsl/windows-package"
cmake_exe="${WINDOWS_CMAKE_EXE:-/mnt/c/msys64/mingw64/bin/cmake.exe}"

case "$action" in
    configure|build|package|launch)
        ;;
    *)
        printf 'Usage: bash %s {configure|build|package|launch}\n' "$0" >&2
        exit 2
        ;;
esac

if [[ ! -x "$cmake_exe" ]]; then
    printf 'Windows CMake not found at %s. Set WINDOWS_CMAKE_EXE if it is installed elsewhere.\n' "$cmake_exe" >&2
    exit 1
fi

for tool in rsync wslpath powershell.exe; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Required WSL tool not found: %s\n' "$tool" >&2
        exit 1
    fi
done

mkdir -p "$windows_source"
rsync -a \
    --exclude='/.git/' \
    --exclude='/build/' \
    --exclude='/CMakeLists.txt.user' \
    "$repo_root/" "$windows_source/"

cd "$windows_source"
"$cmake_exe" --preset windows-mingw64-wsl

case "$action" in
    configure)
        ;;
    build)
        "$cmake_exe" --build --preset windows-mingw64-wsl --parallel
        ;;
    package|launch)
        "$cmake_exe" --build --preset windows-mingw64-wsl-package --parallel
        if [[ "$action" == "launch" ]]; then
            app_path="$(wslpath -w "$package_dir/ScriptExecutorApp.exe")"
            app_directory="$(wslpath -w "$package_dir")"
            powershell.exe -NoProfile -Command \
                "Start-Process -FilePath '$app_path' -WorkingDirectory '$app_directory'"
        fi
        ;;
esac
