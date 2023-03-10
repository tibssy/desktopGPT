<h1 style="font-size: 48pt; text-align: center;">DesktopGPT</h1>

DesktopGPT is an application that allows you to take a screenshot of an area selected with your mouse, extract text using Tesseract OCR, process it with OpenAI Completions API, and display the response as a system notification. The app can also copy the sent and received text to the clipboard.

<br>
<h2>Installation</h2>
You can install DesktopGPT using the provided installation script. The script installs all the necessary dependencies and creates a binary of the app using pyinstaller.
<br>
<br>
<h3>Using the installation script:</h3>

```Bash
git clone https://github.com/tibssy/desktopGPT.git
cd desktopGPT
./install.sh
```
The script will install all the necessary dependencies, build the binary and prompt you for your OpenAI API key. Once the installation is complete, the binary and the config file will be located in ~/.desktopGPT

Please note that the installation script has been tested on Manjaro, Arch, Ubuntu, Linux Mint, and Fedora. Alternatively, you can manually install the dependencies using the package manager of your Linux distribution.
<br>
<br>
<h3>Manual installation:</h3>
For KDE/Plasma, make sure to add "spectacle" to your dependencies, and for GNOME/Cinnamon/Xfce, add "gnome-screenshot". These package names are the same for all three package managers: pacman, apt, and dnf.
<br>
<br>
For Debian/Ubuntu-based systems:

```bash
sudo apt-get update && sudo apt-get install -y python3-pip python3-virtualenv binutils xclip tesseract-ocr
```
<br>
For Arch-based systems:

```bash
sudo pacman -Sy python-pip python-virtualenv xclip tesseract tesseract-data-eng
```
<br>
For Fedora-based systems:

```bash
sudo dnf install -y python3-pip python3-virtualenv xclip tesseract-langpack-eng
```

Once the dependencies are installed, you can install the app by running the following command in a virtualenv:

```bash
git clone https://github.com/tibssy/desktopGPT.git
cd desktopGPT/src
virtualenv venv
source venv/bin/activate
pip3 install -r requirements.txt
```

You can optionally create a binary of the app using pyinstaller by running the following commands:

```bash
pip3 install pyinstaller
pyinstaller desktopGPT.spec
```

<br>
<h2>Getting your OpenAI API key</h2>

To use desktopGPT, you'll need an API key from OpenAI. If you don't already have one, you can sign up for a free account https://platform.openai.com/account/api-keys. Once you have an account, you can create an API key from your dashboard.

The installation script for desktopGPT will prompt you for your OpenAI API key at the end of the installation process, and will store it in the configuration file located in ~/.desktopGPT/config.ini. 


<br>
<h2>Usage</h2>
To use DesktopGPT, you can trigger the app by using a hot corner of GNOME, Cinnamon, or any other desktop environment that supports hot corners. Alternatively, you can use a KDE/Plasma widget to run the app.

Once you've triggered the app, select an area of your screen with your mouse and wait for the system notification to appear. The notification will contain the response from OpenAI Completions API, which will have processed the text extracted from the screenshot using Tesseract OCR.

The app will also copy the sent and received text to the clipboard, which you can then paste elsewhere.

<br>
<h2>Contributing</h2>

If you find any bugs or would like to contribute to the project, please feel free to submit a pull request or open an issue on GitHub.

<br>
<h2>License</h2>

DesktopGPT is licensed under the MIT License. See the LICENSE file for more information.
