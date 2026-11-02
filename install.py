#!/usr/bin/env python3
"""Install this Neovim configuration and its Windows dependencies."""

from __future__ import annotations

import argparse
import datetime as dt
import os
from pathlib import Path
import shutil
import subprocess
import sys


REPO_DIR = Path(__file__).resolve().parent
CONFIG_ITEMS = ("init.lua", "lazy-lock.json", "lua")
WINGET_PACKAGES = (
    ("Git.Git", "git"),
    ("Neovim.Neovim", "nvim"),
    ("BurntSushi.ripgrep.MSVC", "rg"),
    ("LLVM.LLVM", "clangd"),
    ("OpenJS.NodeJS.LTS", "node"),
    ("MSYS2.MSYS2", None),
)


def run(command: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("+", subprocess.list2cmdline(command))
    return subprocess.run(command, check=check, text=True)


def command_path(name: str, candidates: tuple[str, ...] = ()) -> str | None:
    found = shutil.which(name)
    if found:
        return found
    for candidate in candidates:
        expanded = Path(os.path.expandvars(candidate))
        if expanded.is_file():
            return str(expanded)
    return None


def refresh_windows_path() -> None:
    additions = (
        r"%ProgramFiles%\Neovim\bin",
        r"%ProgramFiles%\Git\cmd",
        r"%ProgramFiles%\nodejs",
        r"%ProgramFiles%\LLVM\bin",
        r"%LOCALAPPDATA%\Microsoft\WinGet\Links",
        r"C:\msys64\ucrt64\bin",
    )
    current = os.environ.get("PATH", "")
    paths = current.split(os.pathsep)
    lowered = {entry.casefold() for entry in paths}
    for entry in additions:
        expanded = os.path.expandvars(entry)
        if Path(expanded).exists() and expanded.casefold() not in lowered:
            paths.insert(0, expanded)
            lowered.add(expanded.casefold())
    os.environ["PATH"] = os.pathsep.join(paths)


def install_windows_packages() -> None:
    winget = command_path("winget")
    if not winget:
        raise RuntimeError(
            "winget is required. Install 'App Installer' from the Microsoft Store, "
            "then run this script again."
        )

    for package_id, executable in WINGET_PACKAGES:
        if executable and command_path(executable):
            print(f"Already installed: {executable}")
            continue
        if package_id == "MSYS2.MSYS2" and Path(r"C:\msys64\usr\bin\pacman.exe").is_file():
            print("Already installed: MSYS2")
            continue
        run(
            [
                winget,
                "install",
                "--id",
                package_id,
                "--exact",
                "--accept-package-agreements",
                "--accept-source-agreements",
                "--disable-interactivity",
            ]
        )
        refresh_windows_path()

    pacman = Path(r"C:\msys64\usr\bin\pacman.exe")
    if pacman.is_file():
        run(
            [
                str(pacman),
                "-S",
                "--needed",
                "--noconfirm",
                "mingw-w64-ucrt-x86_64-gcc",
            ]
        )


def config_directory() -> Path:
    if os.name == "nt":
        local_app_data = os.environ.get("LOCALAPPDATA")
        if not local_app_data:
            raise RuntimeError("LOCALAPPDATA is not set")
        return Path(local_app_data) / "nvim"
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "nvim"


def copy_config(target: Path) -> Path | None:
    source = REPO_DIR.resolve()
    target = target.resolve()
    if source == target:
        print(f"Repository is already the Neovim config directory: {target}")
        return None

    backup = None
    if target.exists():
        stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = target.with_name(f"{target.name}.backup-{stamp}")
        print(f"Backing up existing config to {backup}")
        target.rename(backup)

    target.mkdir(parents=True, exist_ok=True)
    for name in CONFIG_ITEMS:
        src = source / name
        dst = target / name
        if src.is_dir():
            shutil.copytree(src, dst)
        elif src.is_file():
            shutil.copy2(src, dst)
    print(f"Installed config in {target}")
    return backup


def install_typescript_tools() -> None:
    npm = command_path(
        "npm.cmd" if os.name == "nt" else "npm",
        (r"%ProgramFiles%\nodejs\npm.cmd",),
    )
    if not npm:
        raise RuntimeError("npm was not found after installing Node.js")
    run([npm, "install", "--global", "typescript", "typescript-language-server"])


def sync_plugins() -> None:
    nvim = command_path("nvim", (r"%ProgramFiles%\Neovim\bin\nvim.exe",))
    if not nvim:
        raise RuntimeError("Neovim was not found after installation")
    run([nvim, "--headless", "+Lazy! sync", "+qa"])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--skip-packages",
        action="store_true",
        help="do not install system packages or TypeScript language tools",
    )
    parser.add_argument(
        "--skip-plugins",
        action="store_true",
        help="do not run the initial lazy.nvim plugin sync",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if sys.version_info < (3, 9):
        raise RuntimeError("Python 3.9 or newer is required")

    if not args.skip_packages:
        if os.name != "nt":
            raise RuntimeError(
                "Automatic system package installation currently supports Windows only. "
                "Install Neovim, Git, ripgrep, LLVM/clangd, Node.js, and a C compiler, "
                "then rerun with --skip-packages."
            )
        install_windows_packages()
        install_typescript_tools()

    backup = copy_config(config_directory())
    if not args.skip_plugins:
        sync_plugins()

    print("\nNeovim setup complete.")
    if backup:
        print(f"Previous config backup: {backup}")
    print("Open Neovim and run :checkhealth if you want a full environment report.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f"\nInstallation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
