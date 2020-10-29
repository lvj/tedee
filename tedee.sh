#!/bin/bash
# Author: Lukasz Jaroszewski
# e-mail: lukasz@ieee.org
# Copyright 2020 Lukasz Jaroszewski
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
# in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
echoerr() { echo "$@" 1>&2; }

#username=""
#password=""
 

TIME_FILE=/tmp/jwt.expires

if test -f "$TIME_FILE"; then
    EXPIRES_IN=$(</tmp/jwt.expires)
else
date -d "-20000 seconds" +%s > /tmp/jwt.expires
EXPIRES_IN=$(</tmp/jwt.expires)
fi

EXPIRES_IN=$(</tmp/jwt.expires)
now=$(date -d "-60 seconds" +%s)


if [ $now -ge $EXPIRES_IN ]; 
then
echo "Getting new token..."
AUTH_JSON_RESPONSE=$(curl -d "grant_type=password&username=${username}&password=${password}&scope=openid 02106b82-0524-4fd3-ac57-af774f340979&client_id=02106b82-0524-4fd3-ac57-af774f340979&response_type=token id_token" -H "Content-Type: application/x-www-form-urlencoded" -X POST https://tedee.b2clogin.com/tedee.onmicrosoft.com/oauth2/v2.0/token?p=B2C_1_SignIn_Ropc)
JWT=$(echo $AUTH_JSON_RESPONSE|jq -r '.access_token')
echo $JWT > /tmp/jwt.token
NEW_EXPIRES_IN=$(echo $AUTH_JSON_RESPONSE|jq -r '.expires_in')
date -d "$NEW_EXPIRES_IN seconds" +%s > /tmp/jwt.expires
else
JWT=$(</tmp/jwt.token)
echoerr "Using old token..."
fi

#echo $JWT

case $1 in
   "status") 
	
	STATUS=$(curl -s -X GET "https://api.tedee.com/api/v1.9/my/device/details" -H "accept: application/json" -H "Authorization: Bearer ${JWT}" -H "Content-Type: application/json-patch+json")
	STATUS_isConnected=$(echo $STATUS|jq '.result.bridges[0].isConnected')
	STATUS_state=$(echo  $STATUS|jq -r '.result.locks[0].lockProperties.state')
	STATUS_batteryLevel=$(echo $STATUS|jq -r '.result.locks[0].lockProperties.batteryLevel')
	STATUS_lock_isConnected=$(echo $STATUS|jq -r '.result.locks[0].isConnected')
	STATUS_isCharging=$(echo $STATUS|jq -r '.result.locks[0].lockProperties.isCharging')
	
	if [ -z "$2" ]
	then
      		STATUS_ARG="E_ARG"
	else
		STATUS_ARG=$2
	fi

	if [ $STATUS_ARG == "isConnected" ];
	then
	echo $STATUS_isConnected
	elif [  $STATUS_ARG == "state" ];
	then
	echo $STATUS_state
	elif [  $STATUS_ARG == "isCharging" ];
        then
	echo $STATUS_isCharging
	elif [ $STATUS_ARG == "batteryLevel" ];
        then
         echo $STATUS_batteryLevel
	elif [  $STATUS_ARG == "lock_isConnected" ];
        then
         echo $STATUS_lock_isConnected
	elif [ $STATUS_ARG == "json" ];
	then
	echo "{\"status\":{\"isConnected\":${STATUS_isConnected},\"state\":${STATUS_state},\"isCharging\":${STATUS_isCharging},\"batteryLevel\": ${STATUS_batteryLevel},\"lock_isConnected\":${STATUS_lock_isConnected}}}"
	elif [ $STATUS_ARG == "jsonfull" ];
	then
	echo $STATUS
	else
	echoerr "Valid options are: status isConnected | isCharging | batteryLevel | lock_isConnected | json | jsnofull, lock,  unlock,  open"
	fi
		
	;;
   "lock") 
	LOCK_STATUS=$(curl -s -X POST "https://api.tedee.com/api/v1.9/my/lock/close" -H "accept: application/json" -H "Authorization: Bearer ${JWT}" -H "Content-Type: application/json-patch+json" -d "{\"deviceId\":2339}")
	echo $LOCK_STATUS|jq
	 ;;
   "unlock") 
	UNLOCK_STATUS=$(curl -s -X POST "https://api.tedee.com/api/v1.9/my/lock/open" -H "accept: application/json" -H "Authorization: Bearer ${JWT}" -H "Content-Type: application/json-patch+json" -d "{\"deviceId\":2339,\"openParameter\":0}")
	echo $UNLOCK_STATUS|jq
	 ;;
   "open") 
	OPEN_STATUS=$(curl -s -X POST "https://api.tedee.com/api/v1.9/my/lock/pull-spring" -H "accept: application/json" -H "Authorization: Bearer ${JWT}" -H "Content-Type: application/json-patch+json" -d "{\"deviceId\":2339}")
	echo $OPEN_STATUS|jq
	 ;;
   "bar") 
	echoerr "BAR";;
   "buzz") 
	echoerr "BUZZ";;
   *) 	echoerr "Valid options are: status isConnected | isCharging | batteryLevel | lock_isConnected | json | jsnofull, lock,  unlock,  open";;
esac



