#!/usr/bin/env bash

# This is an installer script for SmartMirror. It works well enough
# that it can detect if you have Node installed, run a binary script
# and then download and run SmartMirror.
echo -e "\e[0m"
echo ' $$$$$$\  $$\      $$\  $$$$$$\  $$$$$$$\ $$$$$$$$\       $$\      $$\ $$$$$$\ $$$$$$$\  $$$$$$$\   $$$$$$\  $$$$$$$\  '
echo '$$  __$$\ $$$\    $$$ |$$  __$$\ $$  __$$\\__$$  __|      $$$\    $$$ |\_$$  _|$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ '
echo '$$ /  \__|$$$$\  $$$$ |$$ /  $$ |$$ |  $$ |  $$ |         $$$$\  $$$$ |  $$ |  $$ |  $$ |$$ |  $$ |$$ /  $$ |$$ |  $$ |'
echo '\$$$$$$\  $$\$$\$$ $$ |$$$$$$$$ |$$$$$$$  |  $$ |         $$\$$\$$ $$ |  $$ |  $$$$$$$  |$$$$$$$  |$$ |  $$ |$$$$$$$  |'
echo ' \____$$\ $$ \$$$  $$ |$$  __$$ |$$  __$$<   $$ |         $$ \$$$  $$ |  $$ |  $$  __$$< $$  __$$< $$ |  $$ |$$  __$$< '
echo '$$\   $$ |$$ |\$  /$$ |$$ |  $$ |$$ |  $$ |  $$ |         $$ |\$  /$$ |  $$ |  $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |'
echo '\$$$$$$  |$$ | \_/ $$ |$$ |  $$ |$$ |  $$ |  $$ |         $$ | \_/ $$ |$$$$$$\ $$ |  $$ |$$ |  $$ | $$$$$$  |$$ |  $$ |'
echo ' \______/ \__|     \__|\__|  \__|\__|  \__|  \__|         \__|     \__|\______|\__|  \__|\__|  \__| \______/ \__|  \__|'                                                                                                      
echo -e "\e[0m"

# Define the tested version of node. 
NODE_TESTED="v5.1.0"

#Determine which Pi is running.
ARM=$(uname -m) 

#Check the Raspberry Pi version.
if [ "$ARM" != "armv7l" ]; then
	echo -e "\e[91mSorry, your Raspberry Pi is not supported."
	echo -e "\e[91mPlease run SmartMirror on a Raspberry Pi 2 or 3."
	exit;
fi

#define helper methods.
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function command_exists () { type "$1" &> /dev/null ;}

# Installing helper tools
echo -e "\e[96mInstalling helper tools ...\e[90m"
sudo apt-get install curl wget git build-essential unzip || exit

# Check if we need to install or upgrade node.
echo -e "\e[96mCheck current Node installation ...\e[0m"
NODE_INSTALL=false
if command_exists node; then
	echo -e "\e[0mNode currently installed. Checking version number.";
	NODE_CURRENT=$(node -v)
	echo -e "\e[0mMinimum Node version: \e[1m$NODE_TESTED\e[0m"
	echo -e "\e[0mInstalled Node version: \e[1m$NODE_CURRENT\e[0m"
	if version_gt $NODE_TESTED $NODE_CURRENT; then
    	echo -e "\e[96mNode should be upgraded.\e[0m"
    	NODE_INSTALL=true

    	#Check if a node process is currenlty running.
    	#If so abort installation.
    	if pgrep "node" > /dev/null; then
		    echo -e "\e[91mA Node process is currently running. Can't upgrade."
		    echo "Please quit all Node processes and restart the installer."
		    exit;
		fi

    else
    	echo -e "\e[92mNo Node upgrade nessecery.\e[0m"
	fi

else
	echo -e "\e[93mNode is not installed.\e[0m";
	NODE_INSTALL=true
fi

# Install or upgare node if nessecery.
if $NODE_INSTALL; then

	echo -e "\e[96mStart Node download ...\e[0m"

	#Fetch the latest version of Node.js.
	#TODO: Is there a native way to fetch the latest node version?
	echo -e "\e[39mRetrieving latest node version."
	NODE_LATEST=$(curl -l http://api.jordidepoortere.com/nodejs-latest/ 2> /dev/null) 

	if [ "$NODE_LATEST" == "" ]; then
		echo -e "\e[91mCould not retreive latest node version."
		echo -e "\e[91mPlease try again or open an issue on GitHub."
		exit
	fi

	echo -e "Latest node version: \e[1m$NODE_LATEST\e[0m"

	#Construct the download URL.
	DOWNLOAD_URL="https://nodejs.org/dist/latest/node-$NODE_LATEST-linux-$ARM.tar.gz" 

	#Create Download Directory
	rm -Rf ~/.SmartMirrorNodeInstaller || exit
	mkdir ~/.SmartMirrorNodeInstaller || exit
	cd  ~/.SmartMirrorNodeInstaller || exit

	#Download Installer
	echo -e "\e[39mDownloading node ... \e[90m"
	if wget $DOWNLOAD_URL --no-verbose --show-progress; then
		echo -e "\e[39mDownload complete."
	else
		echo -e "\e[91mCould not download node."
		exit;
	fi

	#Unpack and copy.
	echo -e "\e[96mStart Node installation ...\e[90m"
	tar xvf node-$NODE_LATEST-linux-$ARM.tar.gz || exit
	cd node* || exit
	sudo cp -R * /usr/local || exit

	#Cleanup
	rm -Rf ~/.SmartMirrorNodeInstaller || exit
fi

#Install magic mirror
cd ~
if [ -d "$HOME/SmartMirror" ] ; then
	echo -e "\e[93mIt seems like SmartMirror is allready installed."
	echo -e "To prevent overwriting, the installer will be aborted."
	echo -e "Please rename the \e[1m~/SmartMirror\e[0m\e[93m folder and try again.\e[0m"
	echo ""
	echo -e "If you want to upgrade your installation run \e[1m\e[97mgit pull\e[0m from the ~/SmartMirror directory."
	echo ""
	exit;
fi

echo -e "\e[96mCloning SmartMirror ...\e[90m"
if git clone https://github.com/crazywolf132/SmartMirror.git; then 
	echo -e "\e[92mCloning SmartMirror Done!\e[0m"
else
	echo -e "\e[91mUnable to clone SmartMirror."
	exit;
fi

cd ~/SmartMirror  || exit
echo -e "\e[96mInstalling dependencies ...\e[90m"
if npm install; then 
	echo -e "\e[92mDependencies installation Done!\e[0m"
else
	echo -e "\e[91mUnable to install dependencies!"
	exit;
fi

echo " "
echo -e "\e[92mWe're ready! Run \e[1m\e[97mDISPLAY=:0 npm start\e[0m\e[92m from the ~/SmartMirror directory to start your SmartMirror."
echo " "
echo " "
