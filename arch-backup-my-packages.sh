#!/bin/bash

PKGLIST=pkglist.txt
ENABLED_SERVICES=enabled-services.txt
#TODO: maybe add pacman.conf
#TODO: add this as pacman hook

backup_packages() {
    echo
    echo "Starting backup of installed packages"
    echo
    pacman -Qqe > $PKGLIST
    echo
    echo "Successfully backed up installed packages"
    echo
}

backup_enabled_services() {
    echo
    echo "Starting backup of enabled services"
    echo
    systemctl list-unit-files --state=enabled > $ENABLED_SERVICES
    echo
    echo "Successfully backed up enabled services"
    echo
}

echo "This will backup all installed packages to a $PKGLIST and all enabled services in a $ENABLED_SERVICES file in this directory"
echo

if [ -f "$PKGLIST" ]; then
    echo "There already is a $PKGLIST"
    echo
    read -p "Would you like to overwrite the file? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_packages
    fi
else
    backup_packages
fi

if [ -f "$ENABLED_SERVICES" ]; then
    echo "There already is a $ENABLED_SERVICES"
    echo
    read -p "Would you like to overwrite the file? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_enabled_services
    fi
else
    backup_enabled_services
fi

echo
