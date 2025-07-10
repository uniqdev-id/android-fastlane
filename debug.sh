#!/bin/bash
#run: ./install --live --force --variant development|staging|production

RED='\033[0;31m'
GREEEN='\033[0;32m' 
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

export PATH="$PATH:/home/gitpod/android-sdk/platform-tools/:/home/gitpod/android-sdk/tools/bin/"
export JAVA_HOME=/home/gitpod/.sdkman/candidates/java/17.0.5.fx-zulu

android_dir="$HOME/.android"
workspace_keystore="/workspace/debug.keystore"
android_keystore="$android_dir/debug.keystore"

# Default variant
variant="development"
force=false
live=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            force=true
            shift
            ;;
        --live)
            live=true
            shift
            ;;
        --variant)
            variant="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate variant
if [[ ! "$variant" =~ ^(development|staging|production)$ ]]; then
    echo -e "${RED}Invalid variant. Must be development, staging, or production${NC}"
    exit 1
fi

# Configure app variables based on variant
case $variant in
    development)
        app_id="id.uniq.uniqpos.development"
        build_task="assembleDevelopmentDebug"
        install_task="installDevelopmentDebug"
        ;;
    staging)
        app_id="id.uniq.uniqpos.beta"
        build_task="assembleAliveDebug"
        install_task="installAliveDebug"
        ;;
    production)
        app_id="id.uniq.uniqpos"
        build_task="assembleProductionRelease"
        install_task="installProductionRelease"
        ;;
esac

# Create Android directory if it doesn't exist
if [ ! -d "$android_dir" ]; then
    echo "Creating Android directory..."
    mkdir -p "$android_dir"
fi

if [ ! -f "$android_keystore" ]; then
    echo "Copying debug.keystore..."
    cp "$workspace_keystore" "$android_keystore"
    chmod 600 "$android_keystore"
fi

# Check if any devices are connected
devices_output=$(adb devices)
ip="100.117.226.78"

# check if your device (by ip) is connected
if [[ $devices_output == *"${ip}"* ]]; then
    echo -e "${GREEEN}#Devices are connected${NC}"
else
    echo -e "${YELLOW}--- Pairing Device With Code ---"
    echo -e "${YELLOW}--- IP: ${ip} ---"

    # Prompt user for IP, port, and code
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
        echo "Device is Connected with ip ${ip}!"
    else
        echo -e "${RED}Device connection failed!${NC}"
    fi

    force=true
fi

# Function to build, install, and open app
build_install_open() {
    # Fetch updates
    git fetch origin

    # Check if update found
    local update_found=$(git status -uno | grep "Your branch is behind")
    echo "$update_found"

    if [[ -n "$update_found" || $force == true ]]; then
        echo "Update found. Building, installing, and opening the app..."
        echo -e "${PURPLE}Building for variant: $variant${NC}"

        # Pull latest changes
        git pull origin "$(git branch --show-current)"
        
        # Build APK
        ./gradlew $build_task

        # Install APK
        ./gradlew $install_task

        # Open app
        adb shell am start -n "$app_id/com.uniq.uniqpos.view.splashscreen.SplashScreen"

        #copy keystore
        if [ ! -f "$workspace_keystore" ]; then
            echo "Copying debug.keystore..."
            cp "$android_keystore" "$workspace_keystore"
            chmod 600 "$workspace_keystore"
        fi

        force=false
    else
        echo -n "."
    fi
}

# Run based on live mode
if [ "$live" = true ]; then
    echo "Running in live mode for variant: $variant"
    while true; do
        build_install_open
        sleep 5
    done
else
    build_install_open
fi