#!/bin/bash
set -euo pipefail

echo "Starting installation..."

ARCH="$(dpkg --print-architecture)"
BASE_DIR="$(pwd)"

# Dependencies check
for cmd in curl dpkg sudo; do
    command -v $cmd >/dev/null 2>&1 || { echo "$cmd is required but not installed."; exit 1; }
done

# Install Ghostty terminal
echo "Installing Ghostty..."
curl -LO "https://download.opensuse.org/repositories/home:/clayrisser:/sid/Debian_Unstable/${ARCH}/ghostty_1.1.3-4_${ARCH}.deb"
sudo apt install -y "./ghostty_1.1.3-4_${ARCH}.deb"
rm "ghostty_1.1.3-4_${ARCH}.deb"

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
    dunst
    mate-polkit-bin
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
sudo apt update
sudo apt install --no-install-recommends "${CORE_PACKAGES[@]}" -y


# Install Niri
echo "Installing Niri..."
sudo install -Dm755 Niri/niri /usr/local/bin/niri
sudo install -Dm755 Niri/resources/niri-session /usr/local/bin/niri-session
sudo install -Dm644 Niri/resources/niri.desktop /usr/local/share/wayland-sessions/niri.desktop
sudo install -Dm644 Niri/resources/niri-portals.conf /usr/local/share/xdg-desktop-portal/niri-portals.conf
sudo install -Dm644 Niri/resources/niri.service /etc/systemd/user/niri.service
sudo install -Dm644 Niri/resources/niri-shutdown.target /etc/systemd/user/niri-shutdown.target

echo "Installing waybar service"
systemctl --user add-wants niri.service waybar.service

# TODO: Install as a service
#       dunst

echo "Installing swaybg"

mkdir -p $HOME/Pictures
cp -rf ./Pictures/*.jpg $HOME/Pictures/ ;
mkdir -p $HOME/.config/systemd/user/
sed -i "s|\$USER|$USER|g" swaybg.service
install -Dm644 swaybg.service $HOME/.config/systemd/user/swaybg.service
systemctl --user add-wants niri.service swaybg.service

echo "Installing swayidle"

install -Dm644 swayidle.service $HOME/.config/systemd/user/swayidle.service
systemctl --user add-wants niri.service swayidle.service

systemctl --user daemon-reload

# Install Xwayland-satellite
echo "Installing xwayland-satellite..."
sudo install -Dm755 xwayland-satellite/xwayland-satellite /usr/local/bin/xwayland-satellite

#echo "Installing polkit"


echo "Setting up greetd, gtkgreet"

# /etc/greetd/environments --- //niri \n bash
sed -i "s|\$USER|$USER|g" greetd.config.toml
sudo cp -rf greetd.config.toml /etc/greetd/config.toml



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


###   base=$(basename $PWD) && cd .. && tar -czf $base.tar.gz $base && mv -f $base.tar.gz $base/$base.tar.gz && cd $base
