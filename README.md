User config
============

Set of config files that provides the same developer experience in multiple platforms.

## Quick Install

Powershell:

```powershell
irm -Uri https://raw.githubusercontent.com/DanSM-5/user-configuration/master/setup.ps1 | iex
```

Bash/zsh:

```bash
curl -sSLf https://raw.githubusercontent.com/DanSM-5/user-configuration/master/setup.sh | bash
```

## Supported shells

- pwsh (do not confuse with windows powershell)
- bash (linux, mac, WSL1, WSL2, git bash)
- zsh (linux, mac, WSL1, WSL2, git bash)

## Usage

### Entry point

The load files are the entry point to the configuration. You need to source this file inside your `.bashrc`, `.zshrc` or `$PROFILE` file.

- load_conf.sh: For POSIX shells (bash/zsh)
  - It is a sh compatible script.
  - In charge of setup environment variables for platform detection.
- load_conf.ps1: For crossplatform pwsh
  - In charge of setup environment variables for platform detection.

Example:

```bash
# .bashrc/.zshrc (bash/zsh)
[ -f "$HOME/.usr_conf/load_conf.sh" ] && \. "$HOME/.usr_conf/load_conf.sh"
```

```powershell
# $PROFILE (pwsh)
if (Test-Path -Path "$HOME/.usr_conf/load_conf.ps1" -PathType Leaf -ErrorAction SilentlyContinue) {
  . "$HOME/.usr_conf/load_conf.ps1"
}
```

### General files

General files are meant to be sourced in any platform. They handle the required configurations and add curstom alias and functions

* .ualiasgrc (posix)
* .uconfgrc (posix)
* .ualiasgrc.ps1 (pwsh)
* .uconfgrc.ps1 (pwsh)

A set of custom configs per platform is also provided (non g files).

* .ualiasrc (posix)
* .uconfrc (posix)
* .ualiasrc.ps1 (pwsh)
* .uconfrc.ps1 (pwsh)

Files are only sourced if they are found. They will be ignored otherwise.

The order in which files are sourced is as follows

- .uconfgrc
- .ualiasgrc
- .uconfrc (if found)
- .ualiasrc (if found)

Same order happens with the equivalent ps1 scripts

## Setup

Clone the repository in your home directory as `.usr_conf` (could be other location and just symlink this file)

```bash
git clone https://github.com/DanSM-5/user-configuration "$HOME/.usr_conf"
```

If using wsl this folder can be symlinked and shared between windows and wsl.
Be aware that there are performance downsides if you are using wsl2.

```
$ ln -s /mnt/c/Users/[user_name]/.usr_conf ~
```

Source the respective `load_conf` file in your startup files.
Optionally, you can run the provided install scripts.

For powershell

```pwsh
> ./install.ps1
```

For zsh and bash

```
$ ./install.sh
```

**NOTICE**: Install script for bash and zsh will create a backup of current .zshrc and .bashrc if found.

## Environment variables

To keep the environment consistent, some environment variables are polyfilled when missing to values that make sense to the respective platform.

## Dependencies

This repository uses external tools to improve the user experience.
The configuration won't load specific settings if the dependencies are not present.

* git
* ripgrep
* fd
* fzf
* PSFzf (pwsh)
* bat
* eza
* erdtree
* dua
* coreutils (mac)
* nix (linux, mac, wsl)
* homebrew (linux and mac)
* scoop (pwsh, bash, zsh in windows and gitbash)
* gsudo (pwsh, bash, zsh in windows and gitbash)
* nvm (nvm shell script or NVM4W)
* python
* pipx
* git
* oh-my-posh
* starship
* lf
* poppler
* chafa
* ghostscript
* p7zip / 7zz
* zip
* unzip
* unrar

## Recommended terminals

- Windows Terminal
- Kitty
- Konsole
- Alacritty

