#!/bin/bash
# apt-cyg
wget rawgit.com/transcode-open/apt-cyg/master/apt-cyg
install apt-cyg /bin

# build tools and packages
apt-cyg install git make cmake extra-cmake-modules gcc-core gcc-g++

apt-cyg install               \
	libQt5Core-devel          \
	libQt5Gui-devel 

apt-cyg install               \
    libKF5Archive-devel   	  \
    libKF5Bookmarks-devel 	  \
    libKF5Codecs-devel        \
    libKF5Completion-devel    \
    libKF5CoreAddons-devel    \
    libKF5Config-devel        \
    kf5-kdoctools             \
    libKF5I18n-devel          \
    libKF5IconThemes-devel    \
    libKF5ItemViews-devel     \
    libKF5KIO-devel           \
    libKF5Notifications-devel \
    libKF5Parts-devel         \
    libKF5Solid-devel         \
    libKF5TextWidgets-devel   \
    libKF5Wallet-devel        \
    libKF5WidgetsAddons-devel \
    libKF5WindowSystem-devel  \
    libKF5XmlGui-devel        \
    libKF5GuiAddons-devel
	
apt-cyg install gettext-devel zlib-devel oxygen-icons dbus-x11
apt-cyg install kdiff3 krename zip unzip arj unace rpm p7zip kget kate konsole

# build krusader
git clone https://github.com/KDE/krusader.git
cd krusader/
mkdir build
cd build/

cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_CXX_COMPILER=g++ -DCMAKE_CXX_STANDARD=11 -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF ..
make -j 8
make install

# start krusader using cygwin XServer
# 
#apt-cyg install openssh xinit xorg-server
#startx krusader.exe -- :0 -clipboard -multiwindow
#
# OR start with any other XServer
#
#DISPALY=:0 krusader.exe