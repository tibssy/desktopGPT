#!/bin/bash


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


check_packages() {
  not_installed=""
  for pkg in "$@"; do
    if [ "$packagemanager" == "apt" ] && [ $(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
      not_installed+=" $pkg"
    elif [ "$packagemanager" == "pacman" ] &&  ! pacman -Qi "$pkg" >/dev/null 2>&1 ; then
      not_installed+=" $pkg"
    elif [ "$packagemanager" == "dnf" ] && ! dnf list installed "$pkg" >/dev/null 2>&1 ; then
      not_installed+=" $pkg"
    fi
  done
  echo "$not_installed"
}


print_not_installed() {
  echo -e "\n\e[32m${packagemanager^} will install the following package(s) on your $distro_name system:"
  echo  -e "**********************************************************************\e[0m"
  for arg in "$@"; do
      echo -e "\e[33m - $arg\e[0m"
  done
}


builder() {
  cd src/
  echo -e "\n\e[32mCreate virtual environment.\n******************************\e[0m\n"
  virtualenv venv
  source venv/bin/activate
  if [ -n "$VIRTUAL_ENV" ]; then
      echo -e "\n\e[32mVirtual environment is active.\n******************************\e[0m\n"
      echo -e "\e[32mPip Upgrade\n***********\e[0m"
      pip3 install --upgrade pip
      pip3 --version
      echo -e "\n\e[32mInstall Requirements\n********************\e[0m"
      pip3 --version
      pip3 install -r requirements.txt
      pip3 install pyinstaller
      echo -e "\n\e[32mBuild Binary\n************\e[0m"
      pyinstaller desktopGPT.spec
      deactivate
      if [ "$?" -ne 0 ]; then
        echo -e "\e[33mPyInstaller encountered an error.\e[0m"
      else
        echo -e "\n\e[32mPyInstaller finished successfully.\n**********************************\e[0m"
      fi
  else
      echo "Virtual environment is not active."
      exit;
  fi
}


finalize() {
  echo -e "\n\e[32mFinalize DesktopGPT\n*******************\e[0m\n"
  if [ -d "$dst_folder" ]; then
    read -p "Destination directory already exists. Do you want to overwrite it (y/n)? " dst_f
    case "$dst_f" in
      y|Y) rm -rf "$dst_folder"/*;;
      n|N) exit;;
      *) echo "Invalid choice."; exit;;
    esac
  else
    mkdir $dst_folder
  fi

  cp -r "$(pwd)/img" "$(pwd)/dist/desktopGPT" "$(pwd)/config.ini" "$dst_folder"
  chmod +x "$dst_folder/desktopGPT"
  echo -e "\n\e[32mDesktopGPT Successfully Installed to $dst_folder.\n***********************************************\e[0m\n"

  add_key
}


add_key() {
  echo -e "\e[32mAdd API-KEY\n***********\e[0m\n"
  read -p "Would you like to add your OpenAI API-KEY to the config file now (y/n)? " add_api_key
  if [ "$add_api_key" == "y" ] || [ "$add_api_key" == "Y" ]; then
    echo -n "Enter the API key: "
    read api_key
    if [ -n "$api_key" ]; then
      if grep -q "API_KEY" "$dst_folder/config.ini"; then
        sed -i "/API_KEY/c API_KEY = $api_key" "$dst_folder/config.ini"
      else
        if grep -q "\[OPENAI\]" "$dst_folder/config.ini"; then
          sed -i "/\[OPENAI\]/a API_KEY = $api_key" "$dst_folder/config.ini"
        else
          echo -e "\n[OPENAI]\nAPI_KEY = $api_key" >> "$dst_folder/config.ini"
        fi
      fi
      echo -e "\n\e[32mAPI key added/replaced in $dst_folder/config.ini successfully.\e[0m"
    else
      echo -e "\n\e[31mNo API key has been provided. You can add it later in the $dst_folder/config.ini file.\e[0m"
    fi
  else
    echo -e "\n\e[31mNo API key has been provided. You can add it later in the $dst_folder/config.ini file.\e[0m"
  fi
}


main() {
  distro_name=$(grep '^NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
  packagemanager=$(get_package_manager)
  dependencies=${packages[$packagemanager]}

  echo -e "\n\e[32m************************ DesktopGPT Installer ************************\e[0m\n"
  read -p "Would you like to run it on KDE/Plasma (y/n)? " plasma_support
  read -p "Would you like to run it on Gnome, Cinnamon, XFCE  (y/n)? " other_than_plasma

  if [ "$plasma_support" == "y" ] || [ "$plasma_support" == "Y" ]; then
    dependencies+=" spectacle"
  fi

  if [ "$other_than_plasma" == "y" ] || [ "$other_than_plasma" == "Y" ]; then
    dependencies+=" gnome-screenshot"
  fi

  not_installed=($(check_packages $dependencies))
  if [ ${#not_installed[@]} -gt 0 ]; then
    print_not_installed ${not_installed[*]}
    echo -e "\n"
    read -p "Would you like to continue (y/n)? " to_install
    if [ "$to_install" == "y" ] || [ "$to_install" == "Y" ]; then
      eval "${commands[$packagemanager]} ${not_installed[*]}"
      if [[ $? -eq 0 ]]; then
        echo -e "\e[32mPackage(s) installed successfully\e[0m"
      else
        exit 1
      fi
    else
      echo -e "\e[31mYou cannot build DesktopGPT without these dependencies.\e[0m"
      exit;
    fi
  fi

  builder
  finalize
}


dst_folder="$(echo $HOME)/.desktopGPT"

declare -A commands
commands["apt"]="sudo apt-get update && sudo apt-get install -y"
commands["pacman"]="sudo pacman -Sy"
commands["dnf"]="sudo dnf check-update sudo dnf install -y"

declare -A packages
packages["apt"]="python3-pip python3-virtualenv binutils xclip tesseract-ocr"
packages["pacman"]="python-pip python-virtualenv xclip tesseract tesseract-data-eng"
packages["dnf"]="python3-pip python3-virtualenv xclip tesseract-langpack-eng"

main