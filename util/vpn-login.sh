#!/usr/bin/env bash

################################################################
# Script to automate login to uni network via VPN              #
# Security through GPG-id and sudo passwords required          #
################################################################

# --- Config
VPN_SERVER="vpn-ac.uni-heidelberg.de/2fa"
VPN_USER="pc339"
VPN_AGENT="AnyConnect"
PASS_ENTRY="unihd/uni-id"
TOTP_ENTRY="unihd/uni-id-totp"
PID_FILE="/run/openconnect_vpn.pid"
VPN_IFACE="tun0"

# --- Logic
vpn_connect() {
	# --- Checks
	# pid file to track/kill background process
	if [ -f "$PID_FILE" ] && sudo kill -0 $(cat "$PID_FILE") 2>/dev/null; then
		echo "VPN appears to be running already (PID: $(cat $PID_FILE))."
		echo "'sudo kill \$(cat $PID_FILE)' to stop it."
		exit 0
	fi
	# fetch passwords
	VPN_PASSWORD=$(pass show "$PASS_ENTRY" | head -n 1)
	VPN_CODE=$(pass otp "$TOTP_ENTRY")

	if [[ -z "$VPN_PASSWORD" ]] || [[ -z "$VPN_CODE" ]]; then
		echo "Error: Password or TOTP not found"
		sleep 10
		exit 1
	fi


	# --- Connect to VPN
	# --no-external-auth flag fixes E401
	{
		echo "$VPN_PASSWORD"
		echo "$VPN_CODE"
	} | sudo openconnect \
		--background \
		--pid-file="$PID_FILE" \
		--user="$VPN_USER" \
		--useragent="$VPN_AGENT" \
		--no-external-auth \
		--passwd-on-stdin \
		"$VPN_SERVER" || {
			# Error Handling: 
			echo "----------------------------------------------------------------"
			echo "Connection lost or not possible"
			echo "10 Second pause to avoid flooding logs"
			echo "----------------------------------------------------------------"
			sleep 10
			exit 1
		}
}

vpn_disconnect() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "Stopping VPN (PID: $PID)"
        
        if sudo kill "$PID"; then
            echo "VPN Connection severed."
            sleep 1
			# openconnect should remove this (until it doesnt)
            [ -f "$PID_FILE" ] && sudo rm -f "$PID_FILE"
        else
            echo "Error: Failed to kill process $PID."
        fi
    else
        echo "Error: No VPN PID found at $PID_FILE."
    fi
}

# TODO: Doesnt really need to exist separately from main network-status script
vpn_status() {
    if [ -f "$PID_FILE" ] && sudo kill -0 $(cat "$PID_FILE") 2>/dev/null; then
		PID=$(cat "$PID_FILE")
        echo "VPN active (PID: $(cat $PID_FILE))"
		DURATION=$(ps -p "$PID" -o etime= | tr -d ' ')
        echo " PID      : $PID"
        echo " Uptime   : $DURATION"
        echo " Interface: $VPN_IFACE"
        
        if ip link show "$VPN_IFACE" > /dev/null 2>&1; then
            IP_ADDR=$(ip -4 -brief addr show "$VPN_IFACE" | awk '{print $3}')
            echo " IP Addr  : $IP_ADDR"
            
            # Data Transfer
            STATS=$(ip -s -h link show "$VPN_IFACE" | grep -A 5 "$VPN_IFACE")
            RX_BYTES=$(echo "$STATS" | grep -A 1 "RX:" | tail -n 1 | awk '{print $1}')
            TX_BYTES=$(echo "$STATS" | grep -A 1 "TX:" | tail -n 1 | awk '{print $1}')
			echo " Traffic  : Down: $RX_BYTES | Up: $TX_BYTES"
		else
            echo " Warning: Process is running, but interface $VPN_IFACE is missing."
		fi
    else
        echo "VPN not active"
    fi
}

case "$1" in
    connect|start)
        vpn_connect
        ;;
    disconnect|stop)
        vpn_disconnect
        ;;
    status)
        vpn_status
        ;;
    restart)
        vpn_disconnect
        sleep 2
        vpn_connect
        ;;
    *)
        echo "Usage: $0 {connect|disconnect|status|restart}"
        exit 1
        ;;
esac
