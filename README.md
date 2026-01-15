# Arch Linux maintenance and cleanup tool

A Bash script designed to automate routine system maintenance and cleanup tasks for Arch Linux. It handles package caches, system logs, orphan packages, and user thumbnails safely and interactively.

<img style="width: 100%;" alt="screenshot" src="https://github.com/user-attachments/assets/d8c1c9ed-fea4-48b4-babf-080a95c911ef" />

## Features

* **Smart privilege detection**: Automatically detects the real user (`SUDO_USER`) when run as root to safely handle user-specific directories (like AUR caches).
* **Safety first**: Performs a "Dry Run" analysis first. It shows you exactly how much space will be freed and lists orphan packages *before* deleting anything.
* **Dependency handling**: Automatically checks for and installs `pacman-contrib` if missing (required for `paccache`).
* **AUR support**: Auto-detects `yay` or `paru` to clean AUR build caches.

## What it cleans

* **Pacman cache**: Keeps only the 3 latest versions of installed packages (using `paccache`).
* **AUR cache**: Removes uninstalled AUR package sources (supports `yay` and `paru`).
* **Orphan packages**: Identifies and removes unused dependencies (`pacman -Qtdq`).
* **System logs**: Vacuums `systemd` journal logs to a limit of 50MB.
* **Thumbnails**: Clears the user's thumbnail cache (`~/.cache/thumbnails`).

## Instruction

1.  **Download and make the script executable:**
    ```bash
    chmod +x arch-maintenance-tool.sh
    ```

2.  **Run with sudo:**
    ```bash
    sudo ./arch-maintenance-tool.sh
    ```

## Disclaimer

This script performs file deletion operations. While it includes safety prompts and utilizes standard Arch Linux tools (`paccache`, `pacman`), **always review the proposed changes** (especially the list of orphan packages) before confirming the cleanup.
