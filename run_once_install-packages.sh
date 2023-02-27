#! /usr/bin/env bash
# Installs frequently used packages. Must be manually editted!

read -rep "Would you like to install some things? (yes) " confirmation
if [[ -z "$confirmation" || "${confirmation,,}" =~ ^\s*y(es)?\s*$ ]]; then
    # Get user password
    sudo -v
    sudo apt install age apt-clone autopoint bat curl dconf-editor \
        debian-archive-keyring duf flatpak fwts gh git \
        gnome-shell-extension-manager grub-editor gucharmap ifupdown \
        inotify-tools libsnmp-dev libtool-bin make meson neofetch neovim \
        net-tools npm pdfsam python3-neovim python3-pip tlp tree vim-scripts \
        xclip xsane zeal zoxide nodejs command-not-found
    # Maintain sudo after long install
    sudo -v
    # Install some snaps, if snap is installed
    if command -v snap &>/dev/null; then
        sudo snap install bitwarden
        sudo snap install code
        sudo snap install firefox
        sudo snap install fx
        sudo snap install httpie
        sudo snap install spotify
    else
        printf '%s\n' "Snap is not installed, not installing snaps."
    fi

    # Install flatpaks, if flatpak is installed
    if command -v flatpak &>/dev/null; then
        sudo flatpak install com.github.alainm23.planner \
            com.github.tchx84.Flatseal \
            io.mrarm.mcpelauncher \
            org.gnome.Cheese \
            org.libretro.RetroArch
    else
        printf '%s\n' "Flatpak is not installed, not installing Flatpaks."
    fi
fi
