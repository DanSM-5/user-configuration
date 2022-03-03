
Custom Configuration
====================

Repository to backup general configurations, aliases and functions in a windows environment + wsl

## Usage
The custom configuration provide general configurations and aliases that are common for both `pwsh` and `bash` (e.g. `gs` alias for `git status`).

The general files are:
* .ualiasgrc (wsl)
* .uconfgrc (wsl)
* .ualiasgrc.ps1 (windows)
* .uconfgrc.ps1 (windows)

It will also add support for 4 device specific configurations:
* .ualiasrc (wsl)
* .uconfrc (wsl)
* .ualiasrc.ps1 (windows)
* .uconfrc.ps1 (windows)

Files are only sourced if they are found. It will be ignored otherwise.

## Instalation
Clon the repository and rename the folder as `.usr_conf` in the `$HOME` of the windows user.
Symlink the folder `.usr_conf` to the wls `$HOME` instance.
```
$ ln -s /mnt/c/Users/[user_name]/.usr_conf ~
```
Run the install script on for each system

pwsh
```
> ./install.ps1
```
bash
```
$ ./install.sh
```
