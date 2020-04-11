#!/bin/bash

PKGLIST=pkglist.txt
ENABLED_SERVICES=enabled-services.txt
#TODO: maybe add pacman.conf

restore_packages() {
    echo
    echo "Starting restore of installed packages"
    echo
    yay -S --needed - < $PKGLIST
    echo
    echo "Successfully restored installed packages"
    echo
}

restore_enabled_services() {
    echo
    echo "Starting restore of enabled services"
    echo
    echo "TODO"
    echo
    echo "Successfully restored enabled services"
    echo
}

echo "This will install the packages from the $PKGLIST file in this directory and enable all the services in the $ENABLED_SERVICES"
echo

if [ -f "$PKGLIST" ]; then
    echo "Found $PKGLIST"
    echo
    read -p "Would you like to restore the packages from the file (This will not uninstall installed packages which are not in the list)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restore_packages
    fi
else
    echo "There already is no $PKGLIST"
fi

if [ -f "$ENABLED_SERVICES" ]; then
    echo "Found $ENABLED_SERVICES"
    echo
    read -p "Would you like to re-enable the services from the file (This will not disable enabled services which are not in the list)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restore_enabled_services
    fi
else
    echo "There already no a $ENABLED_SERVICES"
fi

echo
