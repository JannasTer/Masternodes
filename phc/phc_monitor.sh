#/bin/bash

RED='\033[1;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
BROWN='\033[0;34m'
NC='\033[0m' # No Color

## Black        0;30     Dark Gray     1;30
## Red          0;31     Light Red     1;31
## Green        0;32     Light Green   1;32
## Brown/Orange 0;33     Yellow        1;33
## Blue         0;34     Light Blue    1;34
## Purple       0;35     Light Purple  1;35
## Cyan         0;36     Light Cyan    1;36
## Light Gray   0;37     White         1;37

echo && echo
echo "${GREEN}***************************************"
echo "******************${YELLOW}PHC${GREEN}******************"
echo "***************${YELLOW}MAIN MENU${GREEN}***************${NC}"
echo ""
echo -e "${RED}1. ${BLUE}list all nodes ${BROWN}-> phc_list.sh"
echo -e "${RED}2. ${BLUE}check nodes sync ${BROWN}-> phc_check_sync.sh"
echo -e "${RED}3. ${BLUE}resync node out of sync ${BROWN}-> phc_check_resync_all.sh"
echo -e "${RED}4. ${BLUE}restart node ${BROWN}-> phc_restart.sh"
echo -e "${RED}5. ${BLUE}stop node ${BROWN}-> phc_stop.sh"
echo -e "${RED}6. ${BLUE}install new nodes ${BROWN}-> phc_setup.sh"
echo -e "${RED}7. ${BLUE}check node status ${BROWN}-> phc_check_status.sh"
echo -e "${RED}8. ${BLUE}check getinfo ${BROWN}-> phc_get_info.sh"
echo -e "${RED}9. exit${NC}"
echo "${GREEN}***************************************${NC}"
echo "choose an option:"
read OPTION
echo ${OPTION}
ALIAS=""

if [[ ${OPTION} == "1" ]] ; then
  wget https://raw.githubusercontent.com/JannasTer/masternodes/master/phc/phc_list.sh -O phc_list.sh > /dev/null 2>&1
  chmod 777 phc_list.sh
  /bin/bash ./phc_list.sh
elif [[ ${OPTION} == "2" ]] ; then
  echo "Which node do you want to check if synced? Enter alias (if empty then will check all)"
  read ALIAS
  wget https://raw.githubusercontent.com/JannasTer/masternodes/master/phc/phc_check_sync.sh -O phc_check_sync.sh > /dev/null 2>&1
  chmod 777 phc_check_sync.sh 
  /bin/bash ./phc_check_sync.sh $ALIAS
elif [[ ${OPTION} == "3" ]] ; then
  echo "Which node do you want to check sync and resync? Enter alias (if empty then will check all)"
  read ALIAS
  wget https://raw.githubusercontent.com/JannasTer/masternodes/master/phc/phc_check_resync_all.sh -O phc_check_resync_all.sh > /dev/null 2>&1
  chmod 777 phc_check_resync_all.sh  
  /bin/bash ./phc_check_resync_all.sh $ALIAS
elif [[ ${OPTION} == "4" ]] ; then
  echo "Which node do you want to restart? Enter alias (if empty then will check all)"
  read ALIAS
  wget https://raw.githubusercontent.com/JannasTer/masternodes/master/phc/phc_restart.sh -O phc_restart.sh > /dev/null 2>&1
  chmod 777 phc_restart.sh  
  /bin/bash ./phc_restart.sh $ALIAS
elif [[ ${OPTION} == "5" ]] ; then
  echo "Which node do you want to stop? Enter alias (if empty then will check all)"
  read ALIAS
  wget https://raw.githubusercontent.com/JannasTer/masternodes/master/phc/phc_stop.sh -O phc_stop.sh > /dev/null 2>&1
  chmod 777 phc_stop.sh  
  /bin/bash ./phc_stop.sh $ALIAS
elif [[ ${OPTION} == "6" ]] ; then
  wget https://raw.githubusercontent.com/JannasTer/masternodes/master/phc/phc_setup.sh -O phc_setup.sh > /dev/null 2>&1
  chmod 777 phc_setup.sh
  /bin/bash ./phc_setup.sh
elif [[ ${OPTION} == "7" ]] ; then
  echo "For which node do you want to check masternode status? Enter alias (if empty then will check all)"
  read ALIAS
  wget https://raw.githubusercontent.com/JannasTer/masternodes/master/phc/phc_check_status.sh -O phc_check_status.sh > /dev/null 2>&1
  chmod 777 phc_check_status.sh  
  /bin/bash ./phc_check_status.sh $ALIAS
elif [[ ${OPTION} == "8" ]] ; then
  echo "For which node do you want to check getinfo? Enter alias (if empty then will check all)"
  read ALIAS
  wget https://raw.githubusercontent.com/JannasTer/masternodes/master/phc/phc_get_info.sh -O phc_get_info.sh > /dev/null 2>&1
  chmod 777 phc_get_info.sh  
  /bin/bash ./phc_get_info.sh $ALIAS
elif [[ ${OPTION} == "9" ]] ; then
  exit 0
fi
/bin/bash ./phc_monitor.sh
