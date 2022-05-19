
Custom Configuration
====================

Repository to fot general  configurations, aliases and functions. It attempts consistency on Windows, Linux and Macos.

## Usage
The custom configuration provide general configurations and aliases that are common for both `pwsh`, `bash`, and `zsh` (e.g. `gs` alias for `git status`).

The general files are:
* .ualiasgrc (unix)
* .uconfgrc (unix)
* .ualiasgrc.ps1 (windows)
* .uconfgrc.ps1 (windows)

It will also add support for 4 device specific configurations (ignored by git):
* .ualiasrc (unix)
* .uconfrc (unix)
* .ualiasrc.ps1 (windows)
* .uconfrc.ps1 (windows)

Files are only sourced if they are found. It will be ignored otherwise.

The files laod_conf.sh and load_conf.ps1 will be copied to one of the following locations
* .bashrc (bash)
* .profile (bash)
* .bash_profile (bash)
* .zshrc (zsh)
* profile.ps1 (pwsh or powershell using $PROFILE variable)

## Instalation
Clon the repository in your home directory
```
git clone https://github.com/DanSM-5/user-configuration .usr_conf
```
The repository will be cloned into `.usr_conf`.

If using wsl this folder can be symlinked and shared between windows and wsl.
```
$ ln -s /mnt/c/Users/[user_name]/.usr_conf ~
```

Run the install script for your system

pwsh
```
> ./install.ps1
```
bash
```
$ ./install.sh bash
```
zsh
```
$ ./install.sh zsh
```

## Dependencies
This repository uses external tools. The configuration won't load specific configs if the dependencies are not present.
* ripgrep (rg)
* fd
* fzf
* PSFzf (windows)
* bat
* coreutils (mac only)
* homebrew (linux and mac)
* scoop (windows)
* gsudo
* nvm
* python
* pipx
* git
* oh-my-posh (optional)
* starship (optional)
