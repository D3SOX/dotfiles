#!/bin/bash
install="yay -S --needed"

# Font
$install otf-san-francisco-pro ttf-roboto

# Cursors
$install capitaine-cursors

# GTK Theme
$install gtk-engine-murrine gtk-engines mojave-gtk-theme

# Icon Pack
$install la-capitaine-icon-theme

# Zsh
$install zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting

# KWin
$install sierrabreeze-kwin-decoration-git
