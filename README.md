# Arch Linux maintenance and cleanup tool

A Bash script designed to automate routine system maintenance and cleanup tasks for Arch Linux. It handles package caches, system logs, orphan packages, and user thumbnails safely and interactively.

<img style="width: 100%;" alt="screenshot" src="https://github.com/user-attachments/assets/ee079834-b81c-4c3a-bdf9-730caf53930c" />

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

## Usage

1.  **Download the script:**
    You can clone the repository or download the script directly:
    ```shell
    curl -O https://raw.githubusercontent.com/jakubd-m/arch-maintenance-tool/main/arch-maintenance-tool.sh
    ```

2.  **Make it executable:**
    ```shell
    chmod +x arch-maintenance-tool.sh
    ```

3.  **Run it:**
    ```shell
    sudo ./arch-maintenance-tool.sh
    ```
    Or add it to your Bash or Zsh shell as, for instance, "clean":
    ```shell
    echo "alias clean='sudo $PWD/arch-maintenance-tool.sh'" >> ~/.bashrc && source ~/.bashrc
    ```
    ```shell
    echo "alias clean='sudo $PWD/arch-maintenance-tool.sh'" >> ~/.zshrc && source ~/.zshrc
    ```
    
## Disclaimer

This script performs file deletion operations. While it includes safety prompts and utilizes standard Arch Linux tools (`paccache`, `pacman`), **always review the proposed changes** (especially the list of orphan packages) before confirming the cleanup.
