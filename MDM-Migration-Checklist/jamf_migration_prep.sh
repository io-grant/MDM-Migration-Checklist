#!/bin/zsh --no-rcs
# shellcheck shell=bash
# shellcheck disable=SC2034

# Author: Grant Huiras (io-grant)
# Contributors: gil@macadmins
# Last Update: 08/27/2024
# Version: 1.2
# Description: JAMF Migration Optimization Prep

set -e # Exit immediately if a command exits with a non-zero status

# Path to the swiftDialog binary and command file
scriptLog="/var/log/jamf_migration_prep.log"
scriptVersion="v1.2"

# Identify logged-in user
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && !/loginwindow/ { print $3 }')
USER_HOME="/Users/$loggedInUser"

# Optimize logging
function updateScriptLog() {
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - ${1}" | tee -a "${scriptLog}"
}

# Check if script is running as root
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root; exiting."
    exit 3
fi

# Initialize log file
if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file via script ***"
fi

updateScriptLog "\n\n###\n# Jamf Migration Prep (${scriptVersion})\n###\n"
updateScriptLog "\n\n###\n# Beginning Optimization\n###\n"
updateScriptLog "Logged-in user: $loggedInUser"

# Function to handle errors
handle_error() {
    updateScriptLog "ERROR: $1"
    echo "ERROR: $1" >&2
    exit 1
}

# Remove management profiles
updateScriptLog "Removing all management profiles..."
sudo profiles remove -forced -all
updateScriptLog "Management profiles removed."

# Step 2: Disable MFA on Azure account
confirm_action() {
    while true; do
        read -r -p "$1 (y/n): " yn
        case $yn in
            [Yy] ) break;;
            [Nn] ) echo "$2";;
            * ) echo "Please answer y or n.";;
        esac
    done
}

confirm_action "Please ensure that MFA is disabled on the user's Azure account or another authentication method is added. Have you completed this step?" "Please complete the step before proceeding."
updateScriptLog "Confirmed MFA is disabled or alternative authentication method is added."

# Resolve any OneDrive Sync Issues
echo "Please manually resolve any OneDrive Sync issues if present."
updateScriptLog "User notified to resolve any OneDrive Sync issues."

# Move files into OneDrive
confirm_action "Please ensure all needed files are moved into the OneDrive Folder and have synced before moving on. Have you completed this step?" "Please complete the step before proceeding."
updateScriptLog "Confirmed all needed files are moved into the OneDrive Folder and have synced."

# Update/Upgrade to the most recent macOS version
echo "Updating to the latest macOS version..."
sudo softwareupdate --install --all --restart || handle_error "Failed to update macOS"
updateScriptLog "Updating to the latest macOS version."

# Remove OneDrive
echo "Uninstalling OneDrive..."
if [ -x /Applications/AppCleaner.app/Contents/MacOS/AppCleaner ]; then
    /Applications/AppCleaner.app/Contents/MacOS/AppCleaner --remove OneDrive || handle_error "Failed to remove OneDrive using AppCleaner"
    updateScriptLog "OneDrive removed using AppCleaner."
else
    rm -rf /Applications/OneDrive.app || handle_error "Failed to remove OneDrive manually"
    updateScriptLog "OneDrive manually removed."
fi

# Move specified applications to Trash
echo "Moving specified applications to Trash..."
apps=(
    "GarageBand" "Google Chrome" "iMovie" "Keynote" 
    "Microsoft Excel" "Microsoft OneNote" "Microsoft Outlook" 
    "Microsoft PowerPoint" "Microsoft Teams" "Microsoft Word" 
    "Numbers" "Pages" "Zoom"
)

for app in "${apps[@]}"; do
    if [ -d "/Applications/$app.app" ]; then
        sudo rm -rf "/Applications/$app.app" || handle_error "Failed to remove $app"
        updateScriptLog "$app moved to Trash."
    else
        echo "$app is not installed."
        updateScriptLog "$app was not installed, skipped removal."
    fi
done

# Empty the Trash
echo "Emptying Trash..."
rm -rf ~/.Trash/* || handle_error "Failed to empty Trash"
updateScriptLog "Trash emptied."

# Enroll in JAMF
echo "Enrolling in JAMF..."
sudo profiles renew -type enrollment || handle_error "Failed to enroll in JAMF"
updateScriptLog "Enrolled in JAMF."

# Run Jamf recon with the asset tag
read -r -p "Enter the computer name/asset tag: " computer_name
sudo jamf recon -assetTag "$computer_name" || handle_error "Failed to run Jamf recon"
updateScriptLog "Jamf recon run with asset tag: $computer_name."

# Self Service configurations
echo "Configuring Self Service options..."
sudo jamf policy -event removeSophos -verbose || handle_error "Failed to trigger remove Sophos"
updateScriptLog "Sophos removal policy triggered."
sudo jamf policy -event makeUserPrinterAdmin -verbose || handle_error "Failed to trigger make user printer policy"
updateScriptLog "User printer admin policy triggered."
sudo jamf policy -event enableLocalLogin -verbose || handle_error "Failed to trigger enable local login policy"
updateScriptLog "Local login enabled policy triggered."

# Install apps via Self Service
echo "Installing required apps via Self Service..."
sudo jamf policy -event installChrome -verbose || handle_error "Failed to trigger Chrome installation"
updateScriptLog "Chrome installation policy triggered."
sudo jamf policy -event installZoom -verbose || handle_error "Failed to trigger Zoom installation"
updateScriptLog "Zoom installation policy triggered."
sudo jamf policy -event installTeamViewer -verbose || handle_error "Failed to trigger TeamViewer installation"
updateScriptLog "TeamViewer installation policy triggered."

# Install and Apply OneDrive Preferences/Script in Jamf Pro
echo "Applying OneDrive Preferences and Script in Jamf Pro..."
confirm_action "Please ensure OneDrive is installed and all config profiles have been scoped to the machine in JAMF Pro before moving on. Have you completed this step?" "Please complete the step before proceeding."
updateScriptLog "Confirmed OneDrive is installed and configured."

# App installation verification
echo "Verifying app installation..."
updateScriptLog "Initiating app installation verification..."
apps_to_verify=("Google Chrome" "Zoom" "TeamViewer")
for app in "${apps_to_verify[@]}"; do
    if [ -d "/Applications/$app.app" ]; then
        updateScriptLog "$app successfully installed."
    else
        updateScriptLog "WARNING: $app not found. Please verify installation manually."
    fi
done

echo "Script completed. Please follow any manual steps indicated."
updateScriptLog "Script completed."