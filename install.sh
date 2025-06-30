#!/bin/bash

QUIET=0
OVERRIDE_ALIAS=0
NO_WARN=0

for arg in "$@"; do
    case $arg in
        --quiet)
            QUIET=1
            shift
            ;;
        --override-alias)
            OVERRIDE_ALIAS=1
            shift
            ;;
        --no-warn)
            NO_WARN=1
            shift
            ;;
    esac
done

say() {
    if [ "$QUIET" -eq 0 ]; then
        echo "$@"
    fi
}

yell() {
    echo "ERROR: [ $@ ]" >&2
}

whisper() {
    if [ "$NO_WARN" -eq 0 ]; then
        echo "WARN: [ $@ ], can be disabled with --no-warn"
    fi
}

run() {
    if [ "$QUIET" -eq 1 ]; then
        "$@" >/dev/null
    else
        "$@"
    fi
}

update_system() {
    say "Updating system..."
    run sudo pacman -Syu --noconfirm > /dev/null || { yell "Failed to update system"; exit 1; }
    say ""
}

check_command() {
    local command_name=$1
    command -v "$command_name" &>/dev/null
}

install_yay() {
    say "Installing yay..."
    if ! check_command "yay"; then
        say "    yay not found. Installing yay..."
        run sudo pacman -S --needed git base-devel
        run git clone https://aur.archlinux.org/yay.git
        cd yay || { yell "Failed to change directory to yay"; exit 1; }
        makepkg -si --noconfirm || { yell "Failed to make yay package"; exit 1; }
        cd ..
        run sudo rm -rf yay
    else
        say "    yay is already installed."
    fi
    say ""
}

install_package_if_needed() {
    local package_name=$1
    local command_name=$2
    say "Checking if $package_name is installed..."

    if ! check_command "$command_name"; then
        say "    $package_name not found. Installing..."
        sudo pacman -S --noconfirm "$package_name" || { yell "Failed to install $package_name"; exit 1; }
    else
        say "    $package_name is already installed."
    fi
    say ""
}

install_package_if_needed_confirm() {
    local package_name=$1
    local command_name=$2
    say "Checking if $package_name is installed..."

    if ! check_command "$command_name"; then
        say "    $package_name not found. Installing..."
        sudo pacman -S "$package_name" || { yell "Failed to install $package_name"; exit 1; }
    else
        say "    $package_name is already installed."
    fi
    say ""
}


install_package_if_needed_yay() {
    if ! check_command "yay" "yay"; then
        install_yay
    fi
    local package_name=$1
    local command_name=$2
    say "Checking if $package_name is installed..."

    if ! check_command "$command_name"; then
        say "    $package_name not found. Installing..."
        run yay -S --noconfirm "$package_name" || { yell "Failed to install $package_name"; exit 1; }
    else
        say "    $package_name is already installed."
    fi
    say ""
}

install_nvim_configuration() {
    say "Installing Neovim configuration..."
    cd ~/Dotfiles/nvim || { yell "Failed to change directory to nvim"; exit 1; }
    chmod +x install.sh
    run ./install.sh || { yell "Failed to run Neovim install script"; exit 1; }
    say ""
}

clone_dotfiles() {
    say "Cloning Dotfiles repository..."
    if [ -d ~/Dotfiles ]; then
        say "Dotfiles directory already exists, skipping clone."
    else
        run git clone https://github.com/Steinebeisser/Dotfiles.git ~/Dotfiles || { yell "Failed to clone Dotfiles"; exit 1; }
    fi
    say ""
}

install_dotfiles() {
    say "Running Dotfiles install script..."
    cd ~/Dotfiles || { yell "Failed to change directory to Dotfiles"; exit 1; }
    chmod +x install.sh
    run ./install.sh || { yell "Failed to run Dotfiles install script"; exit 1; }
    say ""
}

create_alias() {
    local name="$1"
    local target="$2"
    local shellrc="$HOME/.bashrc"

    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        shellrc="$HOME/.zshrc"
    fi

    if grep -q "alias $name=" "$shellrc"; then
        if [ "$OVERRIDE_ALIAS" -eq 1 ]; then
            sed -i "/alias $name=/d" "$shellrc"
            echo "alias $name='$target'" >> "$shellrc"
            say "Overwrote alias: $name → $target in $shellrc"
        else
            whisper "Alias for $name exists, use --override-alias to replace"
        fi
    else
        echo "alias $name='$target'" >> "$shellrc"
        say "Added alias: $name → $target to $shellrc"
    fi
}

reload_shell_config() {
    echo "Run 'source ~/.zshrc' to apply alias changes"
}

install_discord() {
    say "Installing Discord"
    if ! flatpak list | grep -q com.discordapp.Discord; then
        if [ "$QUIET" -eq 1 ]; then
            echo "installing discord takes forever so still printing, even with --quiet"
        fi
        flatpak install -y flathub com.discordapp.Discord
        say "    Discord installed"
        say "    restart session to view discord or run 'flatpak run com.discordapp.Discord'"
    else
        say "    Discord already installed"
    fi
}

install_evolution() {
    install_package_if_needed "evolution" "evolution"

    say "Installing evolution-ews"
    if pacman -Qq | grep -q "^evolution-ews$"; then
        say "    evolution-ews is already installed."
    else
        say "    Installing evolution-ews..."
        sudo pacman -S --noconfirm "evolution-ews" || { yell "Failed to install evolution-ews"; exit 1; }
    fi
    say ""
}

install_font() {
    local name=$1
    local grep_pattern=$2

    say "Installing \"$name\" Font"
    if ! pacman -Qs "$grep_pattern" > /dev/null; then
        sudo pacman -S --noconfirm "$name"
        fc-cache -f -v
    else
        say "$name is already installed."
    fi
    say ""

}

install_zsh() {
    install_package_if_needed "zsh" "zsh"

    say "Setting Zsh as default shell"
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        say "    Default shell changed to Zsh. Please log out and log back in for the changes to take effect."
    else
        say "    Zsh is already set as the default shell."
    fi
    say ""
}

enable_multilib_if_needed() {
    say "Checking if multilib is enabled"
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        say "    Enabling multilib repository"

        sudo sed -i '/^#\s*\[multilib\]/,/^#\s*Include/ s/^#\s*//' /etc/pacman.conf
        
        sudo pacman -Sy
    else
        say "    Multilib already enabled"
    fi
    say ""
}

install_steam() {
    enable_multilib_if_needed

    # sudo pacman -S --noconfirm \
    #     lsb-release lsof xorg-xrandr zenity lib32-alsa-plugins || { 
    #         yell "Failed to install Steam dependencies"
    #         exit 1
    #     }

    install_package_if_needed "steam" "steam"
}

install_minecraft_grub_theme() {
    say "Installing Minecraft Grub Theme"
    if [ ! -d /boot/grub/themes/minegrub ]; then
        say "    Cloning repo"
        git clone https://github.com/Lxtharia/minegrub-theme.git
        cd ./minegrub-theme
        sudo cp -ruv ./minegrub /boot/grub/themes/
        
        cd ..
        sudo rm -rf minegrub-theme

        say "    Adding backup file"
        sudo cp /etc/default/grub /etc/default/grub.bak

        say "    Adding theme to file"
        sudo sed -i -r '
            s|^#?GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/minegrub/theme.txt|
        ' /etc/default/grub

        sudo grub-mkconfig -o /boot/grub/grub.cfg
    else
        say "    Already Installed"
    fi
    say ""
}


install_starship_rs() {
    install_package_if_needed "starship" "starship"

    say "Setting up catppuccin-powerline"
    if [ ! -f ~/.config/starship.toml ]; then
        say "    Added Catppuccin preset"
        starship preset catppuccin-powerline -o ~/.config/starship.toml
    else
        say "    Already installed"
    fi
}

main() {
    update_system

    say "==> Installing core CLI tools..."
    install_package_if_needed "git" "git" # source control | Command: git
    install_package_if_needed "neovim" "nvim" # my text editor | Command: nvim
    install_package_if_needed "unzip" "unzip" # extract zip archives | Command: unzip
    install_package_if_needed "jq" "jq" # JSON processor, kinda uselss | Command: jq
    install_package_if_needed "fzf" "fzf" # fuzzy finder | Command: fzf
    install_package_if_needed "tmux" "tmux" # terminal multiplexer, sessions | Command: tmux
    install_package_if_needed "flatpak" "flatpak" # app installer (used for discord) | Command: flatpak
    install_package_if_needed "vi" "vi" # vi text editor, default for git | Command: vi

    install_zsh # installs Zsh and sets it as default | Command: zsh 

    say "==> Installing enhanced terminal utilities..."
    install_package_if_needed_yay "exa" "exa" # modern ls with icons | aliased as: ls
    install_package_if_needed "fd" "fd" # better find | Command: fd
    install_package_if_needed "ripgrep" "rg" # better grep | aliased as: grep
    install_package_if_needed "bat" "bat" # better cat | aliased as: cat
    install_package_if_needed "btop" "btop" # better htop, which is better top | Command: btop
    install_package_if_needed "yazi" "yazi" # file explorer in terminal, supports images | Command: yazi
    install_package_if_needed "less" "less" # used for git diff | Command: less
    install_package_if_needed "mpv" "mpv" # media player for terminal | Command: mpv 
    install_package_if_needed "yt-dlp" "yt-dlp" # used to download videos (yt, twitch, soundcloud) | Command: yt-dlp


    say "==> Installing aesthetic and fun terminal tools..."
    install_package_if_needed_yay "neofetch" "neofetch" # to flex that i use arch | Command: neofetch
    install_package_if_needed_yay "lolcat" "lolcat" # to make rainbow text | echo "test" | lolcat
    install_package_if_needed_yay "pipes.sh" "pipes.sh" # fancy animated pipes | Command: pipes.sh
    install_package_if_needed_yay "asciiquarium" "asciiquarium" # fancy anommated aquarium | Command: asciiquarium
    install_package_if_needed_yay "ponysay" "ponysay" # cowsay but with ponys | Command: ponysay
    install_package_if_needed_yay "cbonsai" "cbonsai" # let bonsai grow | Command: cbonsai -li 
    install_package_if_needed "figlet" "figlet" # fancy text banner | Command: figlet Hello
    install_package_if_needed "cowsay" "cowsay" # cowsay | Comand: cowsay Hello
    install_package_if_needed "fortune-mod" "fortune" # random text | Comand: fortune
    install_package_if_needed "toilet" "toilet" # fancy text banner | Command: toilet
    install_package_if_needed "cmatrix" "cmatrix" # fancy matrix | Command: matrix
    install_package_if_needed "sl" "sl" # train if missspell ls | Command: sl
    install_starship_rs
    install_package_if_needed "starship" "starship"

    say "==> Installing assets"
    install_font "ttf-jetbrains-mono-nerd" "ttf-jetbrains-mono-nerd" # fancy font
    install_font "noto-fonts-cjk" "noto-fonts-cjk" # chinese, japanese, korean font

    install_minecraft_grub_theme # minecraft grub theme


    # Comment this as the aliases get added through dotfiles, still keep cause why not
    # say "==> Creating useful command aliases..."

    # create_alias "ls" "exa --icons --group-directories-first" 
    # create_alias "ll" "exa -lh"
    # create_alias "la" "exa -la"
    # create_alias "grep" "rg"
    # create_alias "cat" "bat"
    # create_alias "top" "btop"
    # create_alias ".." "cd .."
    # create_alias "..." "cd ../.."


    say "==> Setting up dotfiles..."
    clone_dotfiles # clones my dotfiles
    install_dotfiles # installs all my dotfiles (nvim, zshrc, kitty...), symlinks and installs needed dependencies

    say "==> Installing useful applications"
    install_discord #discord over flatpak
    install_package_if_needed_yay "spotify" "spotify" # spotify
    install_evolution # email client
    install_steam # installs steam and enables multilib

    say "Setup complete!"

    reload_shell_config # notify user to reload shell config
}

main

