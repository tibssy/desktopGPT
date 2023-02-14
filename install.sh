#!/bin/bash

src_folder="./src"
dst_folder="$(echo $HOME)/.example"
if [ -d "$dst_folder" ]; then
  read -p "Destination directory already exists. Do you want to continue? (y/n) " choice
  case "$choice" in
    y|Y) cp -r $src_folder/* $dst_folder;;
    n|N) exit;;
    *) echo "Invalid choice."; exit;;
  esac
else
  mkdir $dst_folder
  cp -r $src_folder/* $dst_folder
fi
echo "Directory copied from $src_folder to $dst_folder"


echo -n "Enter the API key: "
read api_key
if [ -z "$api_key" ]; then
  echo "No API key has been provided. You can add it later in the config.ini file."
fi


# Replace the API key in the ini file
if grep -q "API_KEY" "$dst_folder/config.ini"; then
  sed -i "/API_KEY/c API_KEY = $api_key" "$dst_folder/config.ini"
else
  if grep -q "\[OPENAI\]" "$dst_folder/config.ini"; then
    sed -i "/\[OPENAI\]/a API_KEY = $api_key" "$dst_folder/config.ini"
  else
    echo -e "\n[OPENAI]\nAPI_KEY = $api_key" >> "$dst_folder/config.ini"
  fi
fi
echo "API key added/replaced in config.ini successfully."


read -p "Do you want to install dependencies (y/n)? " choice
if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
  # Check for Debian-based systems
  if which apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y tesseract-ocr
    if dpkg-query -W -f='${Status}' "plasma-desktop" | grep -q "ok installed" &&
      dpkg-query -W -f='${Status}' "gnome-desktop-environment" | grep -q "ok installed"; then
      echo "KDE Plasma and GNOME are installed on this Debian-based system."
      sudo apt-get install -y spectacle gnome-screenshot
    elif dpkg-query -W -f='${Status}' "plasma-desktop" | grep -q "ok installed"; then
      echo "KDE Plasma is installed on this Debian-based system."
      sudo apt-get install -y spectacle
    elif dpkg-query -W -f='${Status}' "gnome-desktop-environment" | grep -q "ok installed"; then
      echo "GNOME is installed on this Debian-based system."
      sudo apt-get install -y gnome-screenshot
    else
      echo "Neither KDE Plasma nor GNOME is installed on this Debian-based system."
    fi
  # Check for Arch-based systems
  elif which pacman &> /dev/null; then
    sudo pacman -Sy && sudo pacman -S tesseract tesseract-data-eng
    if pacman -Q plasma-desktop &> /dev/null &&
      pacman -Q gnome-desktop &> /dev/null; then
      echo "KDE Plasma and GNOME are installed on this Arch-based system."
      sudo pacman -S spectacle gnome-screenshot
    elif pacman -Q plasma-desktop &> /dev/null; then
      echo "KDE Plasma is installed on this Arch-based system."
      sudo pacman -S spectacle gnome-screenshot
    elif pacman -Q gnome-desktop &> /dev/null; then
      echo "GNOME is installed on this Arch-based system."
      sudo pacman -S spectacle gnome-screenshot
    else
      echo "Neither KDE Plasma nor GNOME is installed on this Arch-based system."
    fi
  # Check for Fedora system
  elif which dnf &> /dev/null; then
    sudo dnf -y update && sudo dnf -y install tesseract tesseract-ocr





  else
    echo "This script is not supported on this system."
  fi

else
  echo "Dependencies will not be installed."
fi


