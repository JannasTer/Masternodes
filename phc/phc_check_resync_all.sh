#/bin/bash

PARAM1=$*

if [ -z "$PARAM1" ]; then
  PARAM1="*"  	  
else
  PARAM1=${PARAM1,,} 
fi

for FILE in ~/bin/phcd_$PARAM1.sh; do
  echo "****************************************************************************"
  COUNTER=1
  DATE=$(date '+%d.%m.%Y %H:%M:%S');
  echo "DATE="$DATE
  echo FILE: " $FILE"
  #cat $FILE
  PHCSTARTPOS=$(echo $FILE | grep -b -o _)
  PHCLENGTH=$(echo $FILE | grep -b -o .sh)
  # echo ${PHCSTARTPOS:0:2}
  PHCSTARTPOS_1=$(echo ${PHCSTARTPOS:0:2})
  PHCSTARTPOS_1=$[PHCSTARTPOS_1 + 1]
  PHCNAME=$(echo ${FILE:PHCSTARTPOS_1:${PHCLENGTH:0:2}-PHCSTARTPOS_1})
  PHCCONFPATH=$(echo "$HOME/.phc_$PHCNAME")
  # echo $PHCSTARTPOS_1
  # echo ${PHCLENGTH:0:2}
  echo CONF FOLDER: $PHCCONFPATH
  
  for (( ; ; ))
  do
    sleep 2
	
	PHCPID=`ps -ef | grep -i $PHCNAME | grep -i phcd | grep -v grep | awk '{print $2}'`
	echo "PHCPID="$PHCPID
	
	if [ -z "$PHCPID" ]; then
	  echo "PHC $PHCNAME is STOPPED can't check if synced!"
	  break
	fi
  
	LASTBLOCK=$(~/bin/phcd_$PHCNAME.sh getblockcount)
	GETBLOCKHASH=$(~/bin/phcd_$PHCNAME.sh getblockhash $LASTBLOCK)

	echo "LASTBLOCK="$LASTBLOCK
	echo "GETBLOCKHASH="$GETBLOCKHASH
	
	LASTBLOCKCOINEXPLORERPHC=$(curl -s4 http://54.37.233.45/bc_api.php?request=getblockcount)
	# echo $LASTBLOCKCOINEXPLORERPHC
	BLOCKHASHCOINEXPLORERPHC=', ' read -r -a array <<< $LASTBLOCKCOINEXPLORERPHC
	BLOCKCOUNTCOINEXPLORERPHC=${array[8]}
	# echo $BLOCKCOUNTCOINEXPLORERPHC	
	BLOCKCOUNTCOINEXPLORERPHC=$(echo $BLOCKCOUNTCOINEXPLORERPHC | tr , " ")
	# echo $BLOCKCOUNTCOINEXPLORERPHC
	BLOCKCOUNTCOINEXPLORERPHC=$(echo $BLOCKCOUNTCOINEXPLORERPHC | tr '"' " ")
	# echo $BLOCKCOUNTCOINEXPLORERPHC
	# echo -e "BLOCKCOUNTCOINEXPLORERPHC='${BLOCKCOUNTCOINEXPLORERPHC}'"
	BLOCKCOUNTCOINEXPLORERPHC="$(echo -e "${BLOCKCOUNTCOINEXPLORERPHC}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	# echo -e "BLOCKCOUNTCOINEXPLORERPHC='${BLOCKCOUNTCOINEXPLORERPHC}'"	
	
	BLOCKHASHCOINEXPLORERPHC=${array[6]}
	# echo "BLOCKHASHCOINEXPLORERPHC="$BLOCKHASHCOINEXPLORERPHC
	BLOCKHASHCOINEXPLORERPHC=$(echo $BLOCKHASHCOINEXPLORERPHC | tr , " ")
	# echo $BLOCKHASHCOINEXPLORERPHC
	BLOCKHASHCOINEXPLORERPHC=$(echo $BLOCKHASHCOINEXPLORERPHC | tr '"' " ")
	# echo $BLOCKHASHCOINEXPLORERPHC
	# echo -e "BLOCKHASHCOINEXPLORERPHC='${BLOCKHASHCOINEXPLORERPHC}'"
	BLOCKHASHCOINEXPLORERPHC="$(echo -e "${BLOCKHASHCOINEXPLORERPHC}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	# echo -e "BLOCKHASHCOINEXPLORERPHC='${BLOCKHASHCOINEXPLORERPHC}'"		

	echo "LASTBLOCK="$LASTBLOCK
	echo "GETBLOCKHASH="$GETBLOCKHASH
	echo "BLOCKHASHCOINEXPLORERPHC="$BLOCKHASHCOINEXPLORERPHC


	echo "GETBLOCKHASH="$GETBLOCKHASH
	echo "BLOCKHASHCOINEXPLORERPHC="$BLOCKHASHCOINEXPLORERPHC
	if [ "$GETBLOCKHASH" == "$BLOCKHASHCOINEXPLORERPHC" ]; then
		echo $DATE" Wallet $PHCNAME is SYNCED!"
		break
	else  
	    if [ "$BLOCKHASHCOINEXPLORERPHC" == "Too" ]; then
		   echo "COINEXPLORERPHC Too many requests"
		   break  
		fi
		
		# Wallet is not synced
		echo $DATE" Wallet $PHCNAME is NOT SYNCED!"
		#
		# echo $LASTBLOCKCOINEXPLORERPHC
		#break
		#STOP 
		~/bin/phcd_$PHCNAME.sh stop
		sleep 3 # wait 3 seconds 
		PHCPID=`ps -ef | grep -i $PHCNAME | grep -i phcd | grep -v grep | awk '{print $2}'`
		echo "PHCPID="$PHCPID
		
		if [ -z "$PHCPID" ]; then
		  echo "PHC $PHCNAME is STOPPED"
		  
		  cd $PHCCONFPATH
		  echo CURRENT CONF FOLDER: $PWD
		  echo "Copy BLOCKCHAIN without conf files"
		  wget http://blockchain.phc.vision/ -O bootstrap.zip
		  # rm -R peers.dat 
		  rm -R ./database
		  rm -R ./blocks	
		  rm -R ./sporks
		  rm -R ./chainstate		  
		  unzip  bootstrap.zip
		  $FILE
		  sleep 5 # wait 5 seconds 
		  
		  PHCPID=`ps -ef | grep -i $PHCNAME | grep -i phcd | grep -v grep | awk '{print $2}'`
		  echo "PHCPID="$PHCPID
		  
		  if [ -z "$PHCPID" ]; then
			echo "PHC $PHCNAME still not running!"
		  fi
		  
		  break
		else
		  echo "PHC $PHCNAME still running!"
		fi
	fi
	
	COUNTER=$[COUNTER + 1]
	echo COUNTER: $COUNTER
	if [[ "$COUNTER" -gt 9 ]]; then
	  break
	fi		
  done		
done
