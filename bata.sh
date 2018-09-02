#!/bin/bash
# version 	v0.1
# date    	2018-09-02
# function:	Installation of an Bata masternode
#
# Instructions:
#         Run this script w/ the desired parameters. Leave blank or use -h for help.
#
#Platforms:
#         - Linux Ubuntu 16.04/18.04 LTS ONLY on a Vultr, Hetzner or DigitalOcean VPS
#         - Generic Ubuntu support will be added at a later point in time
#Discord: 	Jannas#8759
#LinkedIn:	https://www.linkedin.com/in/jan-terblanche-29a01874/
#Credits: This script is a combination of different scripts, credit to these guys...
#Github	https://github.com/marsmensch, https://gist.github.com/lukechilds, https://github.com/sucremoneda, https://github.com/chaoabunga/mnscripts
scriptversion="v0.1.1"
release="v0.16.2.79"
tags="tags/$release"
git="https://github.com/BTA-BATA/Bataoshi.git"
date="$(date +%y-%m-%d-%s)"
script=$( cd $(dirname ${BASH_SOURCE[0]}) > /dev/null; pwd -P )
logfile="/tmp/install_${date}_out.log"
name="bata"
daemon_dir="/usr/local/bin"
daemon="batad"
cli_dir="/usr/local/bin"
cli="bata-cli"
ssh_port=${SSH_CLIENT##* }
port=5784
rpcport=5785
user="$name"
conf_dir="/home/$name/.$name"
data_dir="/var/lib/$name"
#menu="NodeManager"
sent_dir="/var/lib/$name/sentinel"
sent_env="/var/lib/$name/sentinel/venv"
systemd="/etc/systemd/system"
rpcuser=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
rpcpassword=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)

function get_confirmation() {
    # call when confirmation is required
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac

}

function check_distro() {
    # Ubuntu 16.04 & 18.04
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        if [[ "${VERSION_ID}" != "16.04" ]] && [[ "${VERSION_ID}" != "18.04" ]] ; then
            echo "Only Ubuntu 16.04 & 18.04 LTS are supported, exiting."
            exit 1
        fi
    else
        echo "Only Ubuntu 16.04 & 18.04 LTS are supported, exiting."
        exit 1
    fi

}

function install_packages() {
    # build packages
	apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade  &>> ${logfile} &> /dev/null
    echo "* Installing required packages, it may take some time to finish"
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev jp2a imagemagick &>> ${logfile}
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install -y software-properties-common &>> ${logfile}
	echo "* Adding bitcoin PPA repository"
	apt-add-repository -yu ppa:bitcoin/bitcoin &>> ${logfile} 
	apt-get -qq -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true update &>> ${logfile}
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install libdb4.8-dev libdb4.8++-dev -y &>> ${logfile}
    # only for 18.04 // openssl
    if [[ "${VERSION_ID}" == "18.04" ]] ; then
       apt-get -qqy -o=Dpkg::Use-Pty=0 install libssl1.0-dev &>> ${logfile}
    fi 
	
}

function swapcreate() {
echo -e "* Checking if swap space is needed."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
if [ "$PHYMEM" -lt "2" ];
  then
    echo -e "* Server is running with less than 2G of RAM, creating 2G swap file"
    dd if=/dev/zero of=/swapfile bs=1024 count=2M 	&>> ${logfile}
    chmod 600 /swapfile 							&>> ${logfile}
    mkswap /swapfile 								&>> ${logfile}
    swapon -a /swapfile								&>> ${logfile}
    echo '/var/mnode_swap.img none swap sw 0 0' | tee -a /etc/fstab &>> ${logfile}
    echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf               &>> ${logfile}
    echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf		&>> ${logfile}
else
  echo -e "* Server running with at least 2G of RAM, no swap needed"
fi

}

function create_user() {

    # our new mnode unpriv user acc is added
    if id "${user}" >/dev/null 2>&1; then
        echo "* User exists already, do nothing" &>> ${logfile}
    else
        echo "* Adding new system user ${user}"
        adduser --disabled-password --gecos "" ${user} &>> ${logfile}
		echo "bata	ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi

}

function create_dirs() {

    # individual data dirs for now to avoid problems
    echo "* Creating masternode directories"
    mkdir -p ${conf_dir}
        if [ ! -d "${data_dir}/${name}" ]; then
             echo "creating data directory ${data_dir}/${name}" &>> ${logfile}
             mkdir -p ${data_dir}/${name} &>> ${logfile}
        fi

}

function configure_firewall() {
    echo "* Configuring firewall rules"
    # disallow everything except ssh and masternode inbound ports
    ufw default deny            &>> ${logfile}
    ufw logging on              &>> ${logfile}
    ufw allow ${ssh_port}/tcp   &>> ${logfile}
	ufw allow ${port}/tcp     	&>> ${logfile}
	ufw allow ${rpcport}/tcp	&>> ${logfile}
    # This will only allow 6 connections every 30 seconds from the same IP address.
    ufw limit OpenSSH	        &>> ${logfile}
    ufw --force enable          &>> ${logfile}
    echo "* Firewall ufw is active and enabled on system startup"
	
}

function create_config() {

rm -f ${conf_dir}/${name}.conf &>> ${logfile}
echo -e "$name MasterNode will be configured for MAINNET"
cat << EOF >> ${conf_dir}/${name}.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcport=$rpcport
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
EOF
	
echo -e "* Enter your Masternode Private Key"
read -e KEY
if [[ -z "$KEY" ]]; then
 sudo -u ${user} ${daemon_dir}/${daemon} -conf=${conf_dir}/${name}.conf -datadir=${data_dir}/${name}	&>> ${logfile}
 sleep 5
 if [ -z $(pidof ${daemon}) ]; then
   echo -e "* $name server couldn't start. Check /var/log/syslog for errors."
   exit 1
 fi
 KEY=$(sudo -u ${user} -- bash -c "${daemon_dir}/${daemon} -conf=${conf_dir}/${name}.conf -datadir=${data_dir}/${name} masternode genkey")	&>> ${logfile}
 kill $(pidof ${daemon})	&>> ${logfile}
fi
NODEIP=$(curl -s4 icanhazip.com)	&>> ${logfile}
sudo iptables -t nat -I OUTPUT -d ${NODEIP} -p tcp --dport ${port} -j REDIRECT --to-ports ${port}
cat << EOF >> ${conf_dir}/${name}.conf
#externalip=${NODEIP}:${port}
logtimestamps=1
maxconnections=256
masternode=1
staking=0
gen=0
masternodeprivkey=$KEY
masternodeaddr=$NODEIP:$port
EOF
}

function create_systemd() {
rm -f ${systemd}/${name}.service
echo "* Writing systemd config file ${systemd}/${name}.service"  &>> ${logfile}
touch ${systemd}/${name}.service
chmod 664 ${systemd}/${name}.service
cat << EOF >> ${systemd}/${name}.service
[Unit]
Description=${name} Service
After=network.target
[Service]
User=${user}
Group=${user}

Type=forking
PIDFile=${data_dir}/${name}/${name}.pid
ExecStart=${daemon_dir}/${daemon} -daemon -pid=${data_dir}/${name}/${name}.pid -conf=${conf_dir}/${name}.conf -datadir=${data_dir}/${name}
ExecStop=${cli_dir}/${cli} stop -conf=${conf_dir}/${name}.conf -datadir=${data_dir}/${name}

Restart=always
RestartSec=5
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=5s
StartLimitInterval=120s
StartLimitBurst=15

[Install]
WantedBy=multi-user.target
EOF

}

function set_permissions() {

	mkdir -p /var/log/sentinel &>> ${logfile}
	chown -R ${user}:${user} ${conf_dir} ${data_dir} /var/log/sentinel ${sent_dir}/database &>> ${logfile} ${daemon_dir}/${daemon} $
    # make group permissions same as user, so masternode user can be added to masternode group
    chmod -R g=u ${conf_dir} ${data_dir} /var/log/sentinel &>> ${logfile}

}

function clear_all() {

    echo "Deleting all ${name} related data!" &>> ${logfile}
	systemctl stop ${name}.service &>> ${logfile}
	rm -f ${systemd}/${name}.service &>> ${logfile}	
    rm -f ${conf_dir}/${name}.conf &>> ${logfile}
    rm -rf ${data_dir} &>> ${logfile}
	rm -rf ${script}/${name} &>> ${logfile}
    rm -f ${daemon_dir}/${daemon} &>> ${logfile}
	rm -f ${cli_dir}/${cli} &>> ${logfile}
    echo "DONE!"
    exit 0

}

function cleanup_after() {

    apt-get -qqy -o=Dpkg::Use-Pty=0 --force-yes autoremove &>> ${logfile}
    apt-get -qqy -o=Dpkg::Use-Pty=0 --force-yes autoclean &>> ${logfile}
	rm -rf ${script}/${name} &>> ${logfile}

}

function print_logo() {
    cd ~/
	wget -q https://www.mining-dutch.nl/site_assets/images/bata.png 2>&1
	convert bata.png bata.jpg 2>&1
	rm bata.png
	mv bata.jpg /usr/local/bin/bata.jpg 2>&1
    jp2a -b --colors --width=55 /usr/local/bin/bata.jpg 2>&1

}

function source_config() {

    check_distro

# main block of function logic starts here
    if [[ "$update" -eq 1 ]]; then
        if [[ ! -f "${daemon_dir}/${daemon}" ]]; then
            echo "UPDATE FAILED! Daemon hasn't been found. Please try the normal installation process by omitting the upgrade parameter."
            exit 1
        fi
        if [[ ! -f "${data_dir}/${name}.menu.sh" ]]; then
            echo "UPDATE FAILED! Masternode activation file ${name}.menu.sh hasn't been found. Please try the normal installation process by omitting the upgrade parameter."
            exit 1
		fi
			if [ ! -d ${data_dir} ]; then
			echo "UPDATE FAILED! ${data_dir} hasn't been found. Please try the normal installation process by omitting the upgrade parameter."
			exit 1
		fi
	fi
    echo "************************* Installation Plan *****************************************"
    echo ""
    if [[ "${update}" -eq 1 ]]; then
        echo "Your existing masternode will be updated with... "
        echo "$(tput bold)$(tput setaf 2) => ${name} masternode in version ${release} $(tput sgr0)"
    else
        echo "Your masternode will be installed and configured with... "
        echo "$(tput bold)$(tput setaf 2) => ${name} masternode in version ${release} $(tput sgr0)"
    fi

    # start nodes after setup
    if [[ "$startnode" -eq 1 ]]; then
        echo "The masternode service will be started after the installation."
    fi
    echo ""
    echo "A logfile for this run can be found at the following location:"
    echo "${logfile}"
    echo ""
    echo "*************************************************************************************"
    sleep 5

    # main routine
    if [[ "$update" -eq 0 ]]; then
        swapcreate
    fi
    install_packages
    print_logo
    build_mn
    if [[ "$update" -eq 0 ]]; then
        create_user
        create_dirs
        configure_firewall
        create_config
        create_systemd
		change_password
    fi
    set_permissions
    cleanup_after
    if [[ "$update" -eq 1 ]]; then
        echo  "I need to update the systemctl daemon now, else an error will occur when running 'systemctl enable' on a changed systemd process"
        systemctl daemon-reload
    fi
	final_call
}

function start_daemon() {
	systemctl daemon-reload
	sleep 30
	systemctl enable ${name}.service
	systemctl start ${name}.service
	sudo -u ${user} -- bash -c "${daemon_dir}/${daemon} -conf=${conf_dir}/${name}.conf -datadir=${data_dir}/${name}"
sleep 5
if [[ -z "$(pidof ${daemon})" ]]; then
		echo -e "${name}.service is not running, please investigate. You should start by running the following commands as root:"
		echo "systemctl start ${name}.service"
		echo "systemctl status ${name}.service"
		echo "less /var/log/syslog"
fi
clear
}

function change_password() {
clear
echo "Please enter a password for ${user} user"
passwd bata
clear
}

function build_mn() {
    # daemon not found compile it
    if [[ ! -f ${daemon_dir}/${daemon} ]] || [[ "$update" -eq 1 ]]; then
        # if coin directory (name) exists, we remove it, to make a clean git clone
        if [[ -d ${script}/${name} ]]; then
			echo "Deleting ${script}/${name} for clean cloning" &>> ${logfile}
            rm -rf ${script}/${name}    &>> ${logfile}
			echo "Stopping $(tput setaf 1)${daemon}$(tput setaf 7) daemon" &>> ${logfile}
				systemctl stop ${name}.service &>> ${logfile}
				sudo -u bata -- bash -c "/usr/local/bin/bata-cli stop -conf=/home/bata/.bata/bata.conf -datadir=/var/lib/bata"
        fi
        cd ${script}                       &>> ${logfile}
        git clone ${git} ${name}                    &>> ${logfile}
		echo " * Entering ${script}/${name} directory."
        cd ${script}/${name}            &>> ${logfile}
        echo "* Checking out desired GIT tag: ${release}"
        git checkout ${release}                             &>> ${logfile}
		if [[ "$update" -eq 1 ]]; then
            echo "Updated source files, deleting the old daemon NOW!" &>> ${logfile}
            rm -f ${daemon_dir}/${daemon}
            # old daemon must be removed before compilation. Would be better to remove it afterwards, however not possible with current structure
            if [ -f ${daemon_dir}/${daemon} ]; then
                echo "UPDATE FAILED! Daemon ${daemon_dir}/${daemon} couldn't be removed. Please engage with us in Discord https://discord.gg/j9GJjdZ Thank you!"
                exit 1
            fi
        fi

    # compilation starts here
		chmod u+x share/genbuild.sh
		chmod u+x src/leveldb/build_detect_platform
		chmod u+x ./autogen.sh && ./autogen.sh
		./configure --without-gui
		make
		cd ${script}/${name}/src
		strip batad
		strip bata-cli
		chmod 755 batad bata-cli
		mv batad ${daemon_dir}/${daemon}
		mv bata-cli ${cli_dir}/${cli}
    else
        echo "* Daemon already in place at ${daemon_dir}/${daemon}, not compiling"
    fi

        # if it's not available after compilation, theres something wrong
        if [[ ! -f ${daemon_dir}/${daemon} ]]; then
                echo "COMPILATION FAILED! Please engage with us in Discord. Thank you!"
                exit 1
        fi
}
#WIP
function create_script() {					&> /dev/null
(cat > ${data_dir}/${name}.menu.sh) << "EOF" 	&> /dev/null
#!/bin/bash
pause(){ 
  read -p "Press [Enter] key to continue..." fackEnterKey 
	} 
	one(){
	echo "Start Masternode"
		sudo -u bata -- bash -c "/usr/local/bin/batad -conf=/home/bata/.bata/bata.conf -datadir=/var/lib/bata"
        pause
	}
	two(){
	echo "Check systemd status"
		systemctl status bata.service
		pause
	}
	three(){
	echo "Run Masternode GetInfo"
		sudo -u bata -- bash -c "/usr/local/bin/bata-cli -getinfo -conf=/home/bata/.bata/bata.conf -datadir=/var/lib/bata"
        pause
	}
	four(){
	echo  "Edit Masternode config file"
		nano /home/bata/.bata/bata.conf
        pause
	}
	five(){
	echo  "Check Masternode Status"
		sudo -u bata -- bash -c "/usr/local/bin/bata-cli -conf=/home/bata/.bata/bata.conf -datadir=/var/lib/bata masternode status"
       pause
	}
	six(){
	echo  "Check Masternode Sync Status"
		sudo -u bata -- bash -c "/usr/local/bin/bata-cli -conf=/home/bata/.bata/bata.conf -datadir=/var/lib/bata mnsync status"
       pause
	}
#	seven(){
#	echo  "Check Masternode Debug"
#		sudo -u bata -- bash -c "/usr/local/bin/bata-cli -conf=/home/bata/.bata/bata.conf -datadir=/var/lib/bata masternode debug"
#      pause
#	}
	show_menus() {
	clear
	jp2a -b --colors --width=55 /usr/local/bin/bata.jpg
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "  M A I N - M E N U"
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Start Masternode"
	echo "2. Check systemd status"
	echo "3. Run Masternode GetInfo"
	echo "4. Edit Masternode config file"
	echo "5. Check Masternode Status"
	echo "6. Check Masternode Sync Status"
	echo "7. $(tput setaf 1)Exit$(tput setaf 7)"
	}
	read_options(){
	local choice
	read -p "Enter choice [ 1 - 7 ] " choice
	case ${choice} in
		1) one ;;
		2) two ;;
		3) three ;;
		4) four ;;
		5) five ;;
		6) six ;;
		7) exit 0;;
		*) echo -e "  $(tput setaf 1)Error...$(tput setaf 7)" && sleep 2
	esac
	}
trap '' SIGINT SIGQUIT SIGTSTP
while true
do
	show_menus
	read_options
done
EOF
}

function get_help(){
    clear
	echo "##############---Bata Masternode Install Script Help---#########################"
    echo "masternode.sh, version ${scriptversion}";
    echo "Usage example:";
    echo "./masternode.sh (-r|--release) string [(-h|--help)] [(-c|--clear)] [(-n|--startnode)] [(-u|--update)]";
	echo "$(tput setaf 3)./masternode.sh -r ${release} -n$(tput setaf 7) will install the masternode in the ${release} release and start the node for block syncing";
    echo "Options:";
	echo "-r or --release string: Release to be installed. REQUIRED.";
    echo "-h or --help: Displays this information.";
    echo "-c or --clear: Clear ALL ${name} masternode data";
    echo "-n or --startnode: Start masternode after installation to sync with blockchain";
    echo "-u or --update: Updates the ${name} masternode deamon and cli";
    exit 1;
}

function final_call() {

clear
	echo "**************************! ALMOST DONE !******************************"
    if [[ "$update" -eq 0 ]]; then
		echo "Your $(tput setaf 1)${name}$(tput setaf 7) masternode installation and configuration is almost complete"
    else
        echo "Your $(tput setaf 1)${name}$(tput setaf 7) masternode daemon has been updated!"
    fi
    # config script - wip
	if [[ "$update" -eq 0 ]]; then
		create_script	
	fi
	chmod u+x ${data_dir}/${name}.menu.sh
    if [[ "$startnode" -eq 1 ]]; then
        echo ""
        echo "** Your node is starting up"
		start_daemon
    fi

print_logo
echo "==================================================================================="
echo "$(tput setaf 1)${name}$(tput setaf 7) masternode service is up and running as user $(tput setaf 2)$user$(tput setaf 7)"
echo "and it is listening on RPC port $(tput setaf 3) $rpcport$(tput setaf 7) on ${mainnet}"
echo "Configuration file is: $(tput setaf 3) $conf_dir/${name}.conf$(tput setaf 7)"
echo "VPS_IP:PORT $(tput setaf 3)$NODEIP:$port$(tput setaf 7)"
echo "Masternode PRIVATEKEY is: $(tput setaf 3)${KEY}$(tput setaf 7)"
echo "Your RPC user is: $(tput setaf 3)$rpcuser$(tput setaf 7)"
echo "Your RPC password is: $(tput setaf 3)$rpcpassword$(tput setaf 7)"
echo "A logfile for this run can be found at the following location:" 
echo "$(tput setaf 3)$logfile$(tput setaf 7)"
echo "$(tput setaf 1)Please run this script to check the health of your masternode$(tput setaf 7)"
echo "$(tput setaf 3) => $(tput setaf 7)bash $(tput setaf 3)${data_dir}/${name}.menu.sh$(tput setaf 7)"
echo "==================================================================================="
su bata
cd ~/
cd ~/
}

##################------------Menu()---------#####################################

# Declare vars. Flags initalizing to 0.
clear=0;
update=0;
debug=0;
startnode=0;

# Execute getopt
ARGS=$(getopt -o "hr:csudnt" -l "help,release,clear,sentinel,update,debug,startnode,testnet" -n "masternode.sh" -- "$@");

#Bad arguments
if [ $? -ne 0 ];
then
    get_help;
fi

eval set -- "$ARGS";

while true; do
    case "$1" in
        -h|--help)
            shift;
            get_help;
            ;;
        -r|--release)
            shift;
                    if [ -n "$1" ];
                    then
                        release="$1";
                        tags="$1"
                        shift;
                    fi
            ;;
        -c|--clear)
            shift;
                    clear="1";
            ;;
        -u|--update)
            shift;
                    update="1";
            ;;
        -d|--debug)
            shift;
                    debug="1";
            ;;
        -n|--startnodes)
            shift;
                    startnode="1";
            ;;
        --)
            shift;
            break;
            ;;
    esac
done
# Check required arguments
if [ -z "$release" ] 
then
    get_help;
fi
# Check required arguments
if [[ "$clear" -eq 1 ]]; then
    get_confirmation "Would you really like to WIPE ALL DATA!? YES/NO y/n" && clear_all
    exit 0
fi

main() {

    echo "starting" &> ${logfile}

    # debug
    if [ "$debug" -eq 1 ]; then
        echo "********************** VALUES AFTER CONFIG SOURCING: ************************"
    fi

    # configuration
    source_config

    # debug
    if [ "$debug" -eq 1 ]; then

        echo "********************** VALUES AFTER CONFIG SOURCING: ************************"
    fi
}

main "$@"
