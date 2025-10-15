#!/usr/bin/env bash

# A script to streamline logging into an OpenConnect VPN
# It retrieves the password from `pass` and pipes it to openconnect.

# The server address for your VPN
VPN_SERVER="vpn-ac.uni-heidelberg.de"

# Your VPN username
VPN_USER="pc339"

PASS_PATH="$HOME/.password-store"
# The path to your password in the `pass` store
PASS_ENTRY="opencon/vpn/unihd.gpg"

# The protocol for your VPN (e.g., anyconnect, gp for GlobalProtect)
# Check your university's documentation if you are unsure.
VPN_PROTOCOL="anyconnect"

VPN_AGENT="AnyConnect Linux_64 4.10.05095"


# --- Script Body ---

# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Check for dependencies
if ! command -v openconnect &> /dev/null; then
    echo "Error: openconnect could not be found. Please install it." >&2
    exit 1
fi

if ! command -v pass &> /dev/null; then
    echo "Error: pass could not be found. Please install it." >&2
    exit 1
fi

# 2. Announce connection attempt
echo "Attempting to connect to $VPN_SERVER as $VPN_USER..."
echo "Password will be retrieved from 'pass' entry: $PASS_ENTRY"
echo "You will be prompted for your TOTP."

# 3. Execute the connection
# - We retrieve the password using `pass show`.
# - The password is then piped (|) to openconnect's standard input.
# - `--passwd-on-stdin` tells openconnect to read the password from the pipe.
# - The `||` block is executed ONLY if openconnect fails (returns a non-zero exit code).
#   This adds the requested pause to prevent log spam from looped scripts.
#
# Note: openconnect often requires root privileges to manage network interfaces.
# Therefore, this script should typically be run with `sudo`.
gpg -q -d "$PASS_PATH/$PASS_ENTRY"| cat - /dev/tty | sudo openconnect \
    --protocol="$VPN_PROTOCOL" \
	--useragent="$VPN_AGENT" \
    --user="$VPN_USER" \
    --passwd-on-stdin \
    "$VPN_SERVER" || {
        echo "Connection failed or was terminated with an error."
        echo "Pausing for 10 seconds as requested by the provider..."
        sleep 10
        exit 1 # Ensure the script exits with a failure status
    }

echo "VPN connection terminated successfully."

