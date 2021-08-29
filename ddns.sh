#!/bin/bash

timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

log() {
    echo -e "$(timestamp)\t$@"
}

# Ensure that a set of mandatory env vars exist, or let the script exit
check_env_vars()
{
    VARS=("$@")
    for VAR in "${VARS[@]}"; do
        [ -z "${!VAR}" ] && echo "${VAR} environment variable is empty or not set." && exit 1
    done
}

# Replaces placeholders such as {IP} with the value of "${IP}". 
# The value will be either a local variable in this script, or an environment variable.
replace_placeholders () {
    local input="$1"
    local sed_args=()
    local varname
    while read varname ; do
        sed_args+=(-e "s|{$varname}|${!varname}|g")
    done < <(echo "$input" | grep -Eo '\{[A-Z_]*\}' | grep -Eo '[A-Z_]*' | sort -u)
    if [[ "${#sed_args[@]}" = 0 ]] ; then
        echo "$input"
    else
        echo "$input" | sed "${sed_args[@]}"
    fi
}


# Check mandatory environment variables
check_env_vars DDNS_URL USERNAME PASSWORD HOSTNAME

# Optional environment variables - fallback on default values
MYIP_URL="${MYIP_URL:-https://ipecho.net/plain}"
INTERVAL=${INTERVAL:-5}
USER_AGENT="curl docker-ddns/1.0 ${EMAIL}"
URL="$DDNS_URL"

# Ensure the provided interval is a valid integer
if [[ $INTERVAL != [0-9]* ]]; then
    echo "Interval is not an integer."
    exit 1
fi


CURRENT_IP=$(dig @8.8.8.8 +short "$HOSTNAME" A | head -n 1)
log "ddns.sh - A request will be done every ${INTERVAL} minute(s) against '${MYIP_URL}' to check if the public IP address has changed"
log "Current IP: ${CURRENT_IP}"

LAST_IP=""
while true; do

    IP=$(curl -s "${MYIP_URL}")

    if [ -z $IP ]; then
        log "Could not detect external IP. Trying again in 1 minute."
		sleep "1m"
		continue
    fi

    # Update the record if the IP has changed. However, always update the first time the script is run.
    if [[ "$IP" != "$LAST_IP" ]]; then

        PARAMS="hostname=${HOSTNAME}&myip=${IP}"
        URL="$(replace_placeholders $URL)"

        log ""
        log "New IP detected, updating record."
        log ""
		
        RESPONSE=$(curl -s -w "\n%{http_code}\nGET %{url_effective}" --insecure --user "$USERNAME:$PASSWORD" --user-agent "$USER_AGENT" -G -d "$PARAMS" "$URL")
        RESP_HTTP_CODE=$(echo "$RESPONSE" | tail -n 2 | head -n 1)
        RESP_URL=$(echo "$RESPONSE" | tail -n 1)
        RESP_CONTENT=$(echo "$RESPONSE" | head -n -2)
		
        log "$RESP_URL ($RESP_HTTP_CODE)"
        log "$RESP_CONTENT"
        log ""
	
    fi

    log "A  ${HOSTNAME}  ${IP}"
    LAST_IP="$IP"

    if [ $INTERVAL -eq 0 ]; then
        break
    else
        sleep "${INTERVAL}m"
    fi

done

exit 0
