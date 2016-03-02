#!/bin/bash

# Show help function
function show_help {
    cat <<EOF
Usage: check-radauth [-t type] -u testuser -p testpass -r server[:port] -s radius_secret [-n nas_port] -c

    -h - show this help
    -c - CRITICAL instead of WARNING
    type - one of pap/chap/mschap/eap-md5 (mschap by default)
    testuser/testpass - testing credentials
    server[:port] - address and port of radius server
    radius_secret - radius secret
    nas_port - NAS-Port attribute (10 by default)

man radtest gives more detailed description
EOF
}

# Default values
TYPE="mschap"
USER=""
PASSWORD=""
SERVER=""
NAS_PORT="10"
SECRET=""
ERROR_STRING="WARNING"
ERROR_STATUS="1"

# Get options

OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "h?ct:u:p:r:s:n" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    c)  ERROR_STRING="CRITICAL"
        ERROR_STATUS="2"
        ;;
    t)  TYPE=$OPTARG
        ;;
    u)  USER=$OPTARG
        ;;
    p)  PASSWORD=$OPTARG
        ;;
    r)  SERVER=$OPTARG
        ;;
    s)  SECRET=$OPTARG
        ;;
    n)  NAS_PORT==$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

RADTEST=`which radtest`

if [ ! -x $RADTEST ]; then
    echo "UNKNOWN - radtest not found"
    exit 3;
fi;

RESULT=`$RADTEST -t $TYPE $USER $PASSWORD $SERVER $NAS_PORT $SECRET 2>&1 | grep -E -o 'Access-Accept|Access-Reject|radclient:.*'`

case $RESULT in
Access-Accept)
    echo "OK - user $USER successfully authenticated at server $SERVER"
    exit 0
    ;;
Access-Reject)
    echo "$ERROR_STRING - user $USER rejected at server $SERVER"
    exit $ERROR_STATUS
    ;;
*)
    echo "UNKNOWN - $RESULT"
    exit 3
    ;;
esac
