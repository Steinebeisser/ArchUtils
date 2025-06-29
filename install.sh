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
    echo "ERROR: [ $@ ]"
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
            say "Overwrote alias: $name → $target"
        else
            whisper "Alias for $name exists, use --override-alias to replace"
        fi
    else
        echo "alias $name='$target'" >> "$shellrc"
        say "Added alias: $name → $target"
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

        sudo sed -i '/^[[:space:]]*# \[multilib\]/,/^[[:space:]]*# Include/ s/^[[:space:]]*# //' /etc/pacman.conf
        
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

main() {
    update_system

    say "==> Installing core CLI tools..."
    install_package_if_needed "git" "git"
    install_package_if_needed "neovim" "nvim"
    install_package_if_needed "unzip" "unzip"
    install_package_if_needed "jq" "jq"
    install_package_if_needed "fzf" "fzf"
    install_package_if_needed "tmux" "tmux"
    install_package_if_needed "flatpak" "flatpak"
    install_package_if_needed "vi" "vi"

    install_zsh

    say "==> Installing enhanced terminal utilities..."
    install_package_if_needed_yay "exa" "exa"
    install_package_if_needed "fd" "fd"
    install_package_if_needed "ripgrep" "rg"
    install_package_if_needed "bat" "bat"
    install_package_if_needed "btop" "btop"
    install_package_if_needed "yazi" "yazi"
    install_package_if_needed "less" "less"

    say "==> Installing aesthetic and fun terminal tools..."
    install_package_if_needed_yay "neofetch" "neofetch"
    install_package_if_needed_yay "lolcat" "lolcat"
    install_package_if_needed_yay "pipes.sh" "pipes.sh"
    install_package_if_needed_yay "asciiquarium" "asciiquarium"
    install_package_if_needed_yay "ponysay" "ponysay"
    install_package_if_needed_yay "cbonsai" "cbonsai"
    install_package_if_needed "figlet" "figlet"
    install_package_if_needed "cowsay" "cowsay"
    install_package_if_needed "fortune-mod" "fortune"
    install_package_if_needed "toilet" "toilet"
    install_package_if_needed "cmatrix" "cmatrix"
    install_package_if_needed "sl" "sl"

    say "==> Installing assets"
    install_font "ttf-jetbrains-mono-nerd" "ttf-jetbrains-mono-nerd"
    install_font "noto-fonts-cjk" "noto-fonts-cjk"


    say "==> Creating useful command aliases..."

    create_alias "ls" "exa --icons --group-directories-first"
    create_alias "ll" "exa -lh"
    create_alias "la" "exa -la"
    create_alias "grep" "rg"
    create_alias "cat" "bat"
    create_alias "top" "btop"

    reload_shell_config

    say "==> Setting up dotfiles..."
    clone_dotfiles
    install_dotfiles

    say "==> Installing useful applications"
    install_discord
    install_package_if_needed_yay "spotify" "spotify"
    install_evolution
    install_steam

    say "Setup complete!"
}

main

