#/bin/bash

PARAM1=$*

if [ -z "$PARAM1" ]; then
  PARAM1="*"  	  
else
  PARAM1=${PARAM1,,} 
fi

for FILE in ~/bin/phcd_$PARAM1.sh; do
  sleep 2
  echo "****************************************************************************"
  echo FILE: " $FILE"

  PHCSTARTPOS=$(echo $FILE | grep -b -o _)
  PHCLENGTH=$(echo $FILE | grep -b -o .sh)
  PHCSTARTPOS_1=$(echo ${PHCSTARTPOS:0:2})
  PHCSTARTPOS_1=$[PHCSTARTPOS_1 + 1]
  PHCNAME=$(echo ${FILE:PHCSTARTPOS_1:${PHCLENGTH:0:2}-PHCSTARTPOS_1})  
  
  PHCPID=`ps -ef | grep -i $PHCNAME | grep -i phcd | grep -v grep | awk '{print $2}'`
  echo "PHCPID="$PHCPID

  if [ -z "$PHCPID" ]; then
    echo "PHC $PHCNAME is STOPPED can't check if synced!"
    break
  fi  
  
  LASTBLOCK=$(~/bin/phcd_$PHCNAME.sh getblockcount)
  GETBLOCKHASH=$(~/bin/phcd_$PHCNAME.sh getblockhash $LASTBLOCK)  
  
  LASTBLOCKCOINEXPLORERPHC=$(curl -s4 http://54.37.233.45/bc_api.php?request=getblockcount)
  BLOCKHASHCOINEXPLORERPHC=', ' read -r -a array <<< $LASTBLOCKCOINEXPLORERPHC
  BLOCKHASHCOINEXPLORERPHC=${array[6]}
  BLOCKHASHCOINEXPLORERPHC=$(echo $BLOCKHASHCOINEXPLORERPHC | tr , " ")
  BLOCKHASHCOINEXPLORERPHC=$(echo $BLOCKHASHCOINEXPLORERPHC | tr '"' " ")
  BLOCKHASHCOINEXPLORERPHC="$(echo -e "${BLOCKHASHCOINEXPLORERPHC}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  echo "LASTBLOCK="$LASTBLOCK
  echo "GETBLOCKHASH="$GETBLOCKHASH
  echo "BLOCKHASHCOINEXPLORERPHC="$BLOCKHASHCOINEXPLORERPHC
  
  if [ "$GETBLOCKHASH" == "$BLOCKHASHCOINEXPLORERPHC" ]; then
    echo "Wallet $FILE is SYNCED!"
  else
	if [ "$BLOCKHASHCOINEXPLORERPHC" == "Too" ]; then
	   echo "COINEXPLORERPHC Too many requests"
    else 
       echo "Wallet $FILE is NOT SYNCED!"
	fi
  fi
done
