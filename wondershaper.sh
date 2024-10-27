#!/bin/sh
IF="wlp2s0"

if [ -z $1 ] 
then
    echo "clear bandwidth limit"
    sudo wondershaper -a ${IF} -c;
else
    echo "set limit to ${1}"
    sudo wondershaper -a ${IF} -c;sudo wondershaper -a ${IF} -u ${1} -d ${1}
fi
