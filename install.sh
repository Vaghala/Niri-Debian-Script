#!/bin/bash

set -euo pipefail

######################################       FUNCTIONS        ##########################################

install_ghostty_pkg(){
    echo "Installing Ghostty..."

    curl -LO "https://download.opensuse.org/repositories/home:/clayrisser:/sid/Debian_Unstable/${ARCH}/ghostty_1.1.3-4_${ARCH}.deb"
    sudo apt install -y "./ghostty_1.1.3-4_${ARCH}.deb"
    rm "ghostty_1.1.3-4_${ARCH}.deb"
}

install_ghostty_compiled(){
    sudo install -Dm755 ghostty/ghostty /usr/bin/ghostty

    #install dependencies...
}

create_swaybg_service(){
    echo "Installing swaybg"

    sed -i "s|\$USER|$USER|g" swaybg.service

    install -Dm644 swaybg.service $HOME/.config/systemd/user/swaybg.service

    systemctl --user add-wants niri.service swaybg.service
}

create_swayidle_service(){
    echo "Installing swayidle"

    install -Dm644 swayidle.service $HOME/.config/systemd/user/swayidle.service

    systemctl --user add-wants niri.service swayidle.service
}

create_waybar_service(){
    echo "Installing waybar service"
    systemctl --user add-wants niri.service waybar.service
    cp -r waybar $HOME/.config/waybar
}

create_polkit_servie(){
    echo "Installing polkit"

    install -Dm644 mate-polkit.service $HOME/.config/systemd/user/mate-polkit.service

    systemctl --user add-wants niri.service mate-polkit.service
}

intall_niri(){

    echo "Installing Niri..."
    sudo install -Dm755 Niri/niri /usr/local/bin/niri
    sudo install -Dm755 Niri/resources/niri-session /usr/local/bin/niri-session
    sudo install -Dm644 Niri/resources/niri.desktop /usr/local/share/wayland-sessions/niri.desktop
    sudo install -Dm644 Niri/resources/niri-portals.conf /usr/local/share/xdg-desktop-portal/niri-portals.conf
    sudo install -Dm644 Niri/resources/niri.service /etc/systemd/user/niri.service
    sudo install -Dm644 Niri/resources/niri-shutdown.target /etc/systemd/user/niri-shutdown.target

    sudo sed -i "s|/usr/bin/niri|/usr/local/bin/niri|g" /etc/systemd/user/niri.service

    mkdir -p $HOME/.config/niri
    cp -rf ./Niri/resources/config.kdl $HOME/.config/niri/config.kdl
}

setup_greeter(){
    echo "lol"
    # sudo useradd -M -G video greeter
    # #sudo chmod -R go+r /etc/greetd/
    # echo "Setting up greetd, gtkgreet"
    # sudo useradd greetd
    # # /etc/greetd/environments --- //niri \n bash
    # sudo sed -i "s|\$USER|$USER|g" greetd.config.toml
    # sudo cp -rf greetd.config.toml /etc/greetd/config.toml

}

#####################################   START SCRIPT     #################################################



echo "Starting installation..."

ARCH="$(dpkg --print-architecture)"
BASE_DIR="$(pwd)"

# Dependencies check
for cmd in curl dpkg sudo; do
    command -v $cmd >/dev/null 2>&1 || { echo "$cmd is required but not installed."; exit 1; }
done

install_ghostty_pkg
# install_ghostty_compiled

# Install dependencies
CORE_PACKAGES=(
    libcairo2
    libxcb-cursor0
    libseat1
    libdisplay-info2
    xwayland
    xdg-desktop-portal-gtk
    gnome-keyring
    mate-polkit-bin
    waybar
    swaybg
    fuzzel
    cliphist
    swaylock
    wlogout
    swayidle
    greetd
    # gtkgreet
    dunst
    libnotify-bin
    adwaita-icon-theme-legacy
)

OTHER_PACKAGES=(
    stow
    ffmpeg
    zsh
    tealdeer
    fd-find
    ripgrep
    neovim
    tmux
    fontconfig
    unzip
    dconf-cli
    nwg-look
    #brightnessctl
)

FONTS=(
    JetBrainsMono
    AdwaitaMono
    UbuntuSans
    Iosevka
)

echo "Installing core packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install --no-install-recommends "${CORE_PACKAGES[@]}" -y

mkdir -p $HOME/Pictures
cp -rf ./Pictures/*.jpg $HOME/Pictures/
mkdir -p $HOME/.config/systemd/user/

echo "Installing xwayland-satellite..."
sudo install -Dm755 xwayland-satellite/xwayland-satellite /usr/local/bin/xwayland-satellite

intall_niri

create_waybar_service

create_swaybg_service

create_swayidle_service

setup_greeter

systemctl --user daemon-reload
#################               OPTIONAL            ####################

read -p "Install Optional packages? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing optional packages..."
    sudo apt-get install -y "${OTHER_PACKAGES[@]}"

    # dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"'
else
    echo "Skipping system install"
fi


FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

for font in "${FONTS[@]}"; do
    echo "Installing $font..."

    curl -fL --create-dirs -o "$FONT_DIR/$font.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.tar.xz"

    tar -xf "$FONT_DIR/$font.tar.xz" -C "$FONT_DIR" --one-top-level="$font"
    rm "$FONT_DIR/$font.tar.xz"
done

fc-cache -fv

echo "Fonts installed: ${FONTS[*]}"

echo "Instllation completed"



###   rm /home/vagelis/Documents/niri_setup/niri_setup.tar.gz && cd /home/$USER/Documents/ && tar -czf niri_setup.tar.gz -C /home/$USER/Documents --exclude='niri_setup/temp' --exclude='niri_setup/.git' niri_setup && mv niri_setup.tar.gz /home/$USER/Documents/niri_setup/ && cd /home/$USER/Documents/niri_setup/
###   curl -LO http://192.168.122.1:3923/niri_setup.tar.gz && tar xf niri_setup.tar.gz && rm niri_setup.tar.gz && cd niri_setup && chmod +x install.sh