#!/bin/bash

RED='\033[0;31m'
GREEEN='\033[0;32m' 
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
export PATH="$PATH:/home/gitpod/sdk/platform-tools/"

android_dir="/home/gitpod/.android"
workspace_keystore="/workspace/debug.keystore"
android_keystore="$android_dir/debug.keystore"

if [ ! -d "$android_dir" ]; then
    echo "Creating Android directory..."
    mkdir -p "$android_dir"
fi

if [ ! -f "$android_keystore" ]; then
    echo "Copying debug.keystore..."
    cp "$workspace_keystore" "$android_keystore"
    chmod 600 "$android_keystore"
fi

# Default IP address
ip="100.71.196.118"

# Check if IP is provided as an argument
while getopts ":ip:" opt; do
  case $opt in
    ip)
      ip="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Check if any devices are connected
devices_output=$(adb devices)

# check if your device (by ip) is connected
if [[ $devices_output == *"$ip"* ]]; then
    echo -e "${GREEEN}#Devices are connected${NC}"
else
    echo -e "${YELLOW}--- Pairing Device With Code ---"

    # Prompt user for port and code
    read -p "Pairing port: " port
    read -p "Pairing code: " code

    # Connect using adb pair
    adb pair "$ip:$port" "$code"

    # Prompt user for the second port
    read -p "Enter second port: " port2

    # Connect using adb connect
    adb connect "$ip:$port2"

    echo -e "${NC}"

    # Check if device is connected
    if adb devices | grep -q "$ip"; then
        echo "Device is Connected!"
    else
        echo -e "${RED}Device connection failed!${NC}"
    fi

    #for the first time connect, force install
    force=true
fi