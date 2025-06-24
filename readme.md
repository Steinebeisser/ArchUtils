# ArchUtils

# Overview

This is a repo that i use for my arch setup so i can easily reproduce my config

## Features

- **Easy Installation**: Quickly install essential CLI tools, utilities, and applications.
- **Easy Dotfile config**: Sets up my dotfiles automatically for good environment (at least for me)
- **Command Aliases**: Create useful command aliases for a more efficient workflow. (e.g., `cat` becomes `bat`, `grub` becomes `rg`, etc.)

## Installation

To get started with ArchUtils, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/Steinebeisser/ArchUtils.git
   cd ArchUtils
   ```

2. Make installation script executable
    ```bash
    chmod +x install.sh
    ```

3. Run it 
    ```bash
    ./install.sh --quiet --override-alias
    ```

### Installation Script Flags

- `--quiet`: Supresses normal output, shows errors and long intalls
- `--override-alias`: allows script to override existing command aliases with the ones defined in script
- `--no-warn`: disables warnings

## Tools and Applications Installed


- **Core CLI Tools**: `git`, `neovim`, `unzip`, `jq`, `fzf`, `tmux`, `flatpak`, `vi`
- **Enhanced Terminal Utilities**: `exa`, `fd`, `ripgrep`, `bat`, `btop`
- **Aesthetic and Fun Tools**: `neofetch`, `lolcat`, `pipes.sh`, `asciiquarium`, `ponysay`, `cbonsai`, `figlet`, `cowsay`, `fortune-mod`, `toilet`, `cmatrix`, `sl`
- **Applications**: `Discord`, `Spotify`

And more tools that are needed for my dotfiles. For more information, visit my [Dotfiles repository](https://github.com/Steinebeisser/Dotfiles) (e.g. Dotnet for Neovim C# development)
