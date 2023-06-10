#!/usr/bin/env bash
# ████████╗ █████╗  ██████╗██╗
# ╚══██╔══╝██╔══██╗██╔════╝██║
#    ██║   ███████║╚█████╗ ██║
#    ██║   ██╔══██║ ╚═══██╗██║
#    ██║   ██║  ██║██████╔╝██║
#    ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝
# TransGirl Arch System Installer
#
# Loosely based upon the script by SolDoesTech
# https://github.com/SolDoesTech/HyprV4/blob/main/set-hypr

# Define the software to be installed
prep_stage=(
    gtk3
    jq
    pacman-contrib
    pipewire
    polkit-gnome
    python-requests
    terminus-font-nerd
    wireplumber
    xclip
    )

nvidia_stage=(
    linux-headers
    nvidia-dkms
    nvidia-settings
    libva
    libva-nvidia-driver-git
    )

zsh_stage=(
    zsh
    zsh-completions
    zsh-theme-powerlevel10k
    zsh-syntax-highlighting
)

xserver_stage=(
    xorg-server
    xorg-apps
    xorg-xinit
    xf86-input-elographics
    xf86-input-libinput
    xf86-input-vmmouse
    xf86-video-vmware
    mesa
    )

install_stage=(
    arc-gtk-theme
    blueman
    bluez
    bluez-utils
    bspwm
    btop
    dmenu
    dunst
    file-roller
    firefox
    github-cli
    gvfs
    kitty
    lxappearance
    mpv
    network-manager-applet
    neovim
    noto-fonts-emoji
    pamixer
    papirus-icon-theme
    pavucontrol
    picom-ibhagwan-git
    polybar
    ranger
    redshift
    rofi
    sddm
    starship
    sxhkd
    ttf-jetbrains-mono-nerd
    ttf-unifont
    thunar
    thunar-archive-plugin
    vim
    xdg-user-dirs
    xdg-user-dirs-gtk
    xfce4-settings
    )

for str in ${myArray[@]}; do
    echo $str
done

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"

######
# Functions

# function that would show a progress bar
show_progress() {
    while ps | grep $1 &> /dev/null;
    do
        echo -en "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 2
}

# test for package, if not found install it.
install_software() {
    # first lets see if the package is there
    if yay -Q $1 &>> /dev/null ; then
        echo -e "$COK - $1 is already installed."
    else
        # no package found so installing
        echo -en "$CNT - Now installing $1 ."
        yay -S --noconfirm $1 &>> $INSTLOG &
        show_progress $!
        # test to make sure it's installed
        if yay -Q $1 &>> /dev/null; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            # it's still missing, exit to review log
            echo -e "\e[1A\e[K$CER - $1 install failed, check the logs please."
            exit
        fi
    fi
}

# clear the screen
clear

# set some expectations
echo -e "$CNT - You are about to install clean system"
sleep 1

# attempt to discover if this is a VM or not
echo -e "$CNT - Checking if this is a Virtual Machine"
ISVM=$(hostnamectl | grep Chassis)
# echo -e "Using $ISVM"
if [[ $ISVM == *"vm"* ]]; then
    echo -e "$CWR - Please note that VMs are not fuly supported and if you try to run this on a VM there is a high change this will fail."
    sleep 1
else
    echo -e "$CNT - Using Physical Machine"
fi

# let the user know that we will use sudo
echo -e "$CNT - This script will run some commands that require sudo privileges."
sleep 1

# give the user an option to exit out
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue with the install (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting..."
    sudo touch /tmp/tasi.tmp
else
    echo -e "$CNT - This script will now exit, no changes were made to your system."
    exit
fi

# find the Nvidia GPU
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    ISNVIDIA=true
else
    ISNVIDIA=false
fi

### Disable wifi powersave mode ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to disable WiFi powersave? (y,n) ' WIFI
if [[ $WIFI == "Y" || $WIFI == "y" ]]; then
    LOC="/etc/NetworkManager/conf.d/wifi-powersave.conf"
    echo -e "$CNT - The following file has been created $LOC.\n"
    echo -e "[connection]\nwifi.powersave = 2" | sudo tee -a $LOC &>> $INSTLOG
    echo -en "$CNT - Restarting NetworkManager service, Please wait."
    sleep 2
    sudo systemctl restart NetworkManager &>> $INSTLOG
    
    #wait for services to restore (looking at you DNS)
    for i in {1..6} 
    do
        echo -n "."
        sleep 1
    done
    echo -en "Done!\n"
    sleep 2
    echo -e "\e[1A\e[K$COK - NetworkManager restart completed."
fi

#### Check for package manager ####
if [ ! -f /sbin/yay ]; then  
    echo -en "$CNT - Configuering yay."
    git clone https://aur.archlinux.org/yay.git &>> $INSTLOG
    cd yay
    makepkg -si --noconfirm &>> ../$INSTLOG &
    show_progress $!
    if [ -f /sbin/yay ]; then
        echo -e "\e[1A\e[K$COK - yay configured"
        cd ..
        
        # update the yay database
        echo -en "$CNT - Updating yay."
        yay -Suy --noconfirm &>> $INSTLOG &
        show_progress $!
        echo -e "\e[1A\e[K$COK - yay updated."
    else
        # if this is hit then a package is missing, exit to review log
        echo -e "\e[1A\e[K$CER - yay install failed, please check the install.log"
        exit
    fi
fi
### Install all of the above pacakges ####
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    
    # Prep Stage - Bunch of needed items
    echo -e "$CNT - Prep Stage - Installing needed components, this may take a while..."
    for SOFTWR in ${prep_stage[@]}; do
        install_software $SOFTWR 
    done

    # Setup Nvidia if it was found
    if [[ "$ISNVIDIA" == true ]]; then
        echo -e "$CNT - Nvidia GPU support setup stage, this may take a while..."
        for SOFTWR in ${nvidia_stage[@]}; do
            install_software $SOFTWR
        done
    
        # update config
        sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        # sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
        sudo mkinitcpio -P
        echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf &>> $INSTLOG
    fi

    # Stage 1 - xserver stage
    echo -e "$CNT - Installing Xserver, this may take a while..."
    for ITEM in ${xserver_stage[@]}; do
        install_software $ITEM
    done

    # Stage 2 - main components
    echo -e "$CNT - Installing main components, this may take a while..."
    for SOFTWR in ${install_stage[@]}; do
        install_software $SOFTWR 
    done
    
    # Stage 3 - ZSH stage
    echo -e "$CNT - Installing ZSH..."
    for ITEM in ${zsh_stage[@]}; do
        install_software $ITEM
    done

    # Start the bluetooth service
    # echo -e "$CNT - Starting the Bluetooth Service..."
    # sudo systemctl enable --now bluetooth.service &>> $INSTLOG
    # sleep 2

    # Set ZSH as default shell
    # -- autoload -Uz zsh-newuser-install
    # -- zsh-newuser-install -f
    ZSHRC="~/.zshrc"
    echo -e "$CNT - Setting up ZSH..."
    # chsh -s /usr/bin/zsh &>> $INSTLOG
    echo -e "$CNT - Don't forget to change the shell with: chsh -s /usr/bin/zsh!"

    # creating a simple zshrc
    echo -e "autoload -Uz compinit promptinit\ncompinit\npromptinit\n\nprompt walters" >>! $ZSHRC &>> $INSTLOG
    echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >>! $ZSHRC &>> $INSTLOG

    # Enable the sddm login manager service
    echo -e "$CNT - Enabling the SDDM Service..."
    sudo systemctl enable sddm &>> $INSTLOG
    sleep 2

    # Clean out other portals
    echo -e "$CNT - Cleaning out conflicting xdg portals..."
    yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk &>> $INSTLOG
fi

### Copy Config Files ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to copy config files? (y,n) ' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "$CNT - Copying config files..."

fi
