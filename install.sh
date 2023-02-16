#!/bin/bash


#echo -e "\n\e[33m***** DesktopGPT Installer *****\e[0m\n\nThe installer will install the following dependencies:\n\n[TO BUILD DESKTOPGPT BINARY]\n\e[32m - python-pip\n - virtualenv\e[0m\n\n[TO RUN DESKTOPGPT BINARY]\n\e[32m - xclip\n - tesseract-ocr\n - gnome-screenshot/spectacle\e[0m\n"


get_package_manager() {
  if which apt-get &> /dev/null; then
    echo "apt"
  elif which dnf &> /dev/null; then
    echo "dnf"
  elif which pacman &> /dev/null; then
    echo "pacman"
  else
    echo "Unknown"
  fi
}

print_not_installed() {
    for arg in "$@"; do
        echo -e "\e[31m - $arg\e[0m"
    done
}

check_packages() {
  not_installed=""
  for package in "$@"; do
    if [ "$package_manager_name" == "apt" ] && [ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
      not_installed+=" $package"
    elif [ "$package_manager_name" == "pacman" ] &&  ! pacman -Qi "$package" >/dev/null 2>&1 ; then
      not_installed+=" $package"
    elif [ "$package_manager_name" == "dnf" ] && ! dnf list installed "$package" >/dev/null 2>&1 ; then
      not_installed+=" $package"
    fi
  done
  echo "$not_installed"
}

builder() {
  cd src/
  pip3 install --upgrade pip
  pip3 install virtualenv
  virtualenv venv
  source venv/bin/activate
  if [ -n "$VIRTUAL_ENV" ]; then
      echo -e "\e[32mVirtual environment is active.\e[0m"
      pip3 install -r requirements.txt
      pip3 install pyinstaller
      pip3 freeze
      pyinstaller desktopGPT.spec
      deactivate
      if [ "$?" -ne 0 ]; then
        echo -e "\e[33mPyInstaller encountered an error.\e[0m"
      else
        echo -e "\e[32mPyInstaller finished successfully.\e[0m"
      fi
  else
      echo "Virtual environment is not active."
      exit;
  fi
}

package_installer() {
  if [ "$package_manager_name" == "apt" ]; then
    sudo apt-get update && sudo apt-get install -y ${not_installed[*]}
  elif [ "$package_manager_name" == "pacman" ]; then
    sudo pacman -Sy && sudo pacman -Sy ${not_installed[*]}
  elif [ "$package_manager_name" == "dnf" ]; then
    sudo dnf check-update && sudo dnf install -y ${not_installed[*]}
  fi
}



src_folder="./src"
dst_folder="$(echo $HOME)/.desktopGPT"
dependencies=""
dependencies_for_apt="python3-pip python3-virtualenv binutils xclip tesseract-ocr"
dependencies_for_pacman="python-pip python-virtualenv xclip tesseract tesseract-data-eng"
dependencies_for_dnf="python3-pip python3-virtualenv xclip tesseract-langpack-eng"
package_manager_name=$(get_package_manager)

echo -e "\n\e[33m***** DesktopGPT Installer *****\e[0m\n"
echo -e "\nWhat desktop environment would you like to use for running DesktopGPT?"
read -p "Do you want to be abel to run it on KDE/Plasma (y/n)? " plasma_support
read -p "Do you want to be abel to run it on Gnome, Cinnamon, XFCE (y/n)? " other_than_plasma
echo -e "Package manager: \e[32m$package_manager_name\e[0m"

# for apt
if [ "$package_manager_name" == "apt" ]; then
  dependencies=$dependencies_for_apt


# For pacman
elif [ "$package_manager_name" == "pacman" ]; then
  dependencies=$dependencies_for_pacman

# For dnf
elif [ "$package_manager_name" == "dnf" ]; then
  dependencies=$dependencies_for_pacman
fi

if [ "$plasma_support" == "y" ] || [ "$plasma_support" == "Y" ]; then
  dependencies+=" spectacle"
fi

if [ "$other_than_plasma" == "y" ] || [ "$other_than_plasma" == "Y" ]; then
  dependencies+=" gnome-screenshot"
fi

#
not_installed=($(check_packages $dependencies))
if [ ${#not_installed[@]} -gt 0 ]; then
  print_not_installed ${not_installed[*]}
  echo -e "\n"
  read -p "Do you want to install this dependencies (y/n)? " py_dep
  if [ "$py_dep" == "y" ] || [ "$py_dep" == "Y" ]; then
    package_installer
    builder
  else
    echo -e "\e[33mWithout install this dependencies you cannot buld DesktopGPT\e[0m"
    exit;
  fi
else
  builder
fi

#if [ -d "$dst_folder" ]; then
#  read -p "Destination directory already exists. Do you want to continue? (y/n) " destenation









#src_folder="./src"
#dst_folder="$(echo $HOME)/.example"
#if [ -d "$dst_folder" ]; then
#  read -p "Destination directory already exists. Do you want to continue? (y/n) " choice
#  case "$choice" in
#    y|Y) cp -r $src_folder/* $dst_folder;;
#    n|N) exit;;
#    *) echo "Invalid choice."; exit;;
#  esac
#else
#  mkdir $dst_folder
#  cp -r $src_folder/* $dst_folder
#fi
#echo "Directory copied from $src_folder to $dst_folder"
#
#
#echo -n "Enter the API key: "
#read api_key
#if [ -z "$api_key" ]; then
#  echo "No API key has been provided. You can add it later in the config.ini file."
#fi
#
#
## Replace the API key in the ini file
#if grep -q "API_KEY" "$dst_folder/config.ini"; then
#  sed -i "/API_KEY/c API_KEY = $api_key" "$dst_folder/config.ini"
#else
#  if grep -q "\[OPENAI\]" "$dst_folder/config.ini"; then
#    sed -i "/\[OPENAI\]/a API_KEY = $api_key" "$dst_folder/config.ini"
#  else
#    echo -e "\n[OPENAI]\nAPI_KEY = $api_key" >> "$dst_folder/config.ini"
#  fi
#fi
#echo "API key added/replaced in config.ini successfully."
#
#
#read -p "Do you want to install dependencies (y/n)? " choice
#if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
#  # Check for Debian-based systems
#  if which apt-get &> /dev/null; then
#    sudo apt-get update && sudo apt-get install -y xclip tesseract-ocr
#    if dpkg-query -W -f='${Status}' "plasma-desktop" | grep -q "ok installed" &&
#      dpkg-query -W -f='${Status}' "gnome-desktop-environment" | grep -q "ok installed"; then
#      echo "KDE Plasma and GNOME are installed on this Debian-based system."
#      sudo apt-get install -y spectacle gnome-screenshot
#    elif dpkg-query -W -f='${Status}' "plasma-desktop" | grep -q "ok installed"; then
#      echo "KDE Plasma is installed on this Debian-based system."
#      sudo apt-get install -y spectacle
#    elif dpkg-query -W -f='${Status}' "gnome-desktop-environment" | grep -q "ok installed"; then
#      echo "GNOME is installed on this Debian-based system."
#      sudo apt-get install -y gnome-screenshot
#    else
#      echo "Neither KDE Plasma nor GNOME is installed on this Debian-based system."
#    fi
#  # Check for Arch-based systems
#  elif which pacman &> /dev/null; then
#    sudo pacman -Sy && sudo pacman -S xclip tesseract tesseract-data-eng
#    if pacman -Q plasma-desktop &> /dev/null &&
#      pacman -Q gnome-desktop &> /dev/null; then
#      echo "KDE Plasma and GNOME are installed on this Arch-based system."
#      sudo pacman -S spectacle gnome-screenshot
#    elif pacman -Q plasma-desktop &> /dev/null; then
#      echo "KDE Plasma is installed on this Arch-based system."
#      sudo pacman -S spectacle
#    elif pacman -Q gnome-desktop &> /dev/null; then
#      echo "GNOME is installed on this Arch-based system."
#      sudo pacman -S gnome-screenshot
#    else
#      echo "Neither KDE Plasma nor GNOME is installed on this Arch-based system."
#    fi
#  # Check for Fedora system
#  elif which dnf &> /dev/null; then
#    sudo dnf -y update && sudo dnf -y install tesseract tesseract-ocr
#
#
#
#
#
#  else
#    echo "This script is not supported on this system."
#  fi
#
#else
#  echo "Dependencies will not be installed."
#fi
#

