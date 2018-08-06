#/bin/bash

PARAM1=$*

if [ -z "$PARAM1" ]; then
  PARAM1="*"  	  
else
  PARAM1=${PARAM1,,} 
fi

for FILE in ~/bin/phcd_$PARAM1.sh; do
  echo "*******************************************"
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
  echo "NODE ALIAS: "$PHCCONFPATH
  echo "CONF FOLDER: "$PHCCONFPATH
done
