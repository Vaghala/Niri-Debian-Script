#!/bin/bash

set -euo pipefail

######################################       FUNCTIONS        ##########################################

install_ghostty(){
    echo "Installing Ghostty..."

    curl -LO "https://download.opensuse.org/repositories/home:/clayrisser:/sid/Debian_Unstable/${ARCH}/ghostty_1.1.3-4_${ARCH}.deb"
    sudo apt install -y "./ghostty_1.1.3-4_${ARCH}.deb"
    rm "ghostty_1.1.3-4_${ARCH}.deb"
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

    systemctl --user daemon-reload
}

intall_niri(){

    echo "Installing Niri..."
    sudo install -Dm755 Niri/niri /usr/local/bin/niri
    sudo install -Dm755 Niri/resources/niri-session /usr/local/bin/niri-session
    sudo install -Dm644 Niri/resources/niri.desktop /usr/local/share/wayland-sessions/niri.desktop
    sudo install -Dm644 Niri/resources/niri-portals.conf /usr/local/share/xdg-desktop-portal/niri-portals.conf
    sudo install -Dm644 Niri/resources/niri.service /etc/systemd/user/niri.service
    sudo install -Dm644 Niri/resources/niri-shutdown.target /etc/systemd/user/niri-shutdown.target

}

#####################################   START SCRIPT     #################################################



echo "Starting installation..."

ARCH="$(dpkg --print-architecture)"
BASE_DIR="$(pwd)"

# Dependencies check
for cmd in curl dpkg sudo; do
    command -v $cmd >/dev/null 2>&1 || { echo "$cmd is required but not installed."; exit 1; }
done

install_ghostty

# Install dependencies
CORE_PACKAGES=(
    libcairo2
    libxcb-cursor0
    libseat1
    libdisplay-info2
    xwayland
    # xdg-desktop-portal-gtk
    # xdg-desktop-portal-gnome
    gnome-keyring
    adwaita-icon-theme-legacy
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
    mate-polkit-bin
    #nwg-bar
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
)

echo "Installing core packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install --no-install-recommends "${CORE_PACKAGES[@]}" -y

mkdir -p $HOME/Pictures
cp -rf ./Pictures/*.jpg $HOME/Pictures/
mkdir -p $HOME/.config/systemd/user/

intall_niri

echo "Installing waybar service"
systemctl --user add-wants niri.service waybar.service
cp -r waybar $HOME/.config/waybar


# TODO: Install as a service
#       dunst

#create_swaybg_service

create_swayidle_service

echo "Installing xwayland-satellite..."
sudo install -Dm755 xwayland-satellite/xwayland-satellite /usr/local/bin/xwayland-satellite


#echo "Installing polkit"


echo "Setting up greetd, gtkgreet"

# /etc/greetd/environments --- //niri \n bash
# sed -i "s|\$USER|$USER|g" greetd.config.toml
# sudo cp -rf greetd.config.toml /etc/greetd/config.toml


read -p "Install Optional packages? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing optional packages..."
    sudo apt-get install -y "${OTHER_PACKAGES[@]}"

    # dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"'
else
    echo "Skipping system install"
fi

mkdir $HOME/.config/niri
cp -rf ./Niri/resources/default-config.kdl $HOME/.config/niri/config.kdl



FONTS=(
    JetBrainsMono
    AdwaitaMono
    UbuntuSans
    Iosevka
)

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

###   base=$(basename $PWD) && cd .. && tar -czf $base.tar.gz $base && mv -f $base.tar.gz $base/$base.tar.gz && cd $base
###   curl -LO http://192.168.122.1:3923/niri_setup.tar.gz && tar xf niri_setup.tar.gz && rm niri_setup.tar.gz && cd niri_setup && chmod +x install.sh