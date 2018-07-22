#/bin/bash
release=""
tags="tags/$release"
git="https://github.com/DucatC/Ducat-Coin.git"
current_release
function current_release () {
latest_release="$( bash <<EOF
curl --silent "https://api.github.com/repos/DucatC/Ducat-Coin/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")'
EOF
)"
}

cd ~
echo "****************************************************************************"
echo "* Ubuntu 18.04 is the recommended opearting system for this install.       *"
echo "*                                                                          *"
echo "* This script will install and configure your Ducat Coin masternodes.      *"
echo "****************************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!                                                 !"
echo "! Make sure you double check before hitting enter !"
echo "!                                                 !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo

echo "Do you want to install all needed dependencies (no if you did it before)? [y/n]"
read DOSETUP

if [[ $DOSETUP =~ "y" ]] ; then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get install -y nano htop git
  sudo apt-get install -y software-properties-common
  sudo apt-get install -y build-essential libtool autotools-dev pkg-config libssl-dev
  sudo apt-get install -y libboost-all-dev
  sudo apt-get install -y libevent-dev
  sudo apt-get install -y libminiupnpc-dev
  sudo apt-get install -y autoconf
  sudo apt-get install -y automake unzip libgmp-dev
  sudo add-apt-repository  -y  ppa:bitcoin/bitcoin
  sudo apt-get update
  sudo apt-get install -y libdb4.8-dev libdb4.8++-dev

  mkdir -p ~/bin
  echo 'export PATH=~/bin:$PATH' > ~/.bash_aliases
  source ~/.bashrc
fi

## COMPILE AND INSTALL
git clone ${git} Ducat-Coin
cd Ducat-Coin
git checkout ${release}

chmod u+x share/genbuild.sh
chmod u+x src/leveldb/build_detect_platform
chmod u+x ./autogen.sh && ./autogen.sh
./configure --without-gui
make
cd Ducat-Coin/src
sudo strip ducatd
sudo chmod 755 ducatd
sudo mv ducatd /usr/bin

echo ""
echo "Configure your masternodes now!"
echo "Type the IP of this server, followed by [ENTER]:"
read IP

echo ""
echo "Enter masternode private key for node $ALIAS"
read PRIVKEY

CONF_DIR=~/.Ducat/
mkdir $CONF_DIR
CONF_FILE=Ducat.conf
PORT=10015

echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> $CONF_DIR/$CONF_FILE
echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> $CONF_DIR/$CONF_FILE
echo "rpcallowip=127.0.0.1" >> $CONF_DIR/$CONF_FILE
echo "listen=1" >> $CONF_DIR/$CONF_FILE
echo "server=1" >> $CONF_DIR/$CONF_FILE
echo "daemon=1" >> $CONF_DIR/$CONF_FILE
echo "logtimestamps=1" >> $CONF_DIR/$CONF_FILE
echo "maxconnections=256" >> $CONF_DIR/$CONF_FILE
echo "masternode=1" >> $CONF_DIR/$CONF_FILE
echo "" >> $CONF_DIR/$CONF_FILE

echo "addnode=46.101.61.220:10015" >> $CONF_DIR/$CONF_FILE
echo "addnode=45.77.58.196:10015" >> $CONF_DIR/$CONF_FILE
echo "addnode=209.250.228.241:10015" >> $CONF_DIR/$CONF_FILE
echo "addnode=209.250.226.12:10015" >> $CONF_DIR/$CONF_FILE

echo "" >> $CONF_DIR/$CONF_FILE
echo "port=$PORT" >> $CONF_DIR/$CONF_FILE
echo "masternodeaddr=$IP:$PORT" >> $CONF_DIR/$CONF_FILE
echo "masternodeprivkey=$PRIVKEY" >> $CONF_DIR/$CONF_FILE
sudo ufw allow $PORT/tcp

ducatd -daemon
