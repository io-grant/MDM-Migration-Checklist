#!/bin/zsh
# shellcheck shell=bash
# shellcheck disable=SC2034

# Author: Grant Huiras (io-grant)
# Contributors: gil@macadmins
# Last Update: 09/26/2024
# Version: 1.7
# Description: JAMF Migration Optimization Prep

set -e # Exit immediately if a command exits with a non-zero status

# Path to the swiftDialog binary and command file
scriptLog="/var/log/jamf_migration_prep.log"
scriptVersion="v1.7"
 
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

# Disable MFA on Azure account
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
while ! confirm_action "Please ensure all needed files are moved into the OneDrive Folder and have synced before moving on. Have you completed this step?" "Please complete the step before proceeding."; do
    echo "Please take the time to move and sync all necessary files."
done
updateScriptLog "Confirmed all needed files are moved into the OneDrive Folder and have synced."

# Remove OneDrive
echo "Uninstalling OneDrive..."
rm -rf /Applications/OneDrive.app || handle_error "Failed to remove OneDrive manually"
updateScriptLog "OneDrive manually removed."

# Move specified applications to Trash
echo "Moving specified applications to Trash..."
apps=(
    "GarageBand" "Google Chrome" "iMovie" "Keynote" 
    "Microsoft Excel" "Microsoft OneNote" "Microsoft Outlook" 
    "Microsoft PowerPoint" "Microsoft Teams" "Microsoft Teams Classic" "Microsoft Word" 
    "Numbers" "Pages" "TeamViewer Host" "Zoom"
)

for app in "${apps[@]}"; do
    app_path=$(sudo find /Applications -maxdepth 2 -iname "${app}.app" -type d -print -quit)

    if [ -n "$app_path" ]; then
        if sudo rm -rf "$app_path"; then
            echo "$app moved to Trash."
            updateScriptLog "$app moved to Trash."
        else
            handle_error "Failed to move $app to Trash"
        fi
    else
        echo "$app is not installed."
        updateScriptLog "$app was not installed, skipped removal."
    fi
done

# Special handling for TeamViewer
echo "Removing TeamViewer components..."
sudo rm -rf /Applications/TeamViewerHost.app
sudo rm -rf /Library/Application\ Support/TeamViewerHost
sudo rm -rf /Library/Preferences/com.teamviewerhost*
sleep 10

# Special handling for Zoom 
echo "Removing Zoom components..."
sudo rm -rf /Applications/zoom.us.app
sudo rm -rf ~/Library/Application\ Support/zoom.us
sudo rm -rf ~/Library/Internet\ Plug-Ins/ZoomUsPlugIn.plugin
sudo rm -rf ~/Library/Preferences/us.zoom.xos.plist
sleep 5

# Empty the Trash
echo "Emptying Trash..."
rm -rf ~/.Trash/* || handle_error "Failed to empty Trash"
updateScriptLog "Trash emptied."
sleep 5

# Enroll in JAMF Instance
echo "Enrolling in JAMF..."
sudo profiles renew -type enrollment || handle_error "Failed to enroll in JAMF"
updateScriptLog "Enrolled in JAMF."

# Confirm JAMF Enrollment
echo "Please confirm JAMF enrollment before proceeding."
updateScriptLog "User prompted to confirm JAMF enrollment."
while ! confirm_action "Please confirm JAMF enrollment before moving on. Have you completed this step?" "Please complete the step before proceeding."; do
    echo "Please take the time to confirm JAMF enrollment."
    updateScriptLog "User did not confirm JAMF enrollment."
    exit 1

# Give time for MDM server to realize what has just happened
sleep 120
echo "Waiting for MDM server to realize what has just happened..."
updateScriptLog "Waiting for MDM server to realize what has just happened..."

# Run Jamf recon with the asset tag
read -r -p "Enter the computer name/asset tag: " computer_name
sudo jamf recon -assetTag "$computer_name" || handle_error "Failed to run Jamf recon"
updateScriptLog "Jamf recon run with asset tag: $computer_name."
sudo jamf recon || handle_error "Failed to run Jamf recon"
updateScriptLog "Jamf recon run."
sleep 10

# Prompt for new computer name
read -p "Enter new computer name: " NEW_NAME

# Update system settings and Jamf Pro
sudo scutil --set ComputerName "$NEW_NAME"
sudo jamf setComputerName -name "$NEW_NAME"
sudo jamf recon
updateScriptLog "Computer name updated to $NEW_NAME."

# Self Service configurations
echo "Configuring Self Service options..."
sudo jamf policy -event removeSophos -verbose || handle_error "Failed to trigger remove Sophos"
updateScriptLog "Sophos removal policy triggered."
sudo jamf policy -event makeUserPrinterAdmin -verbose || handle_error "Failed to trigger make user printer policy"
updateScriptLog "User printer admin policy triggered."
sudo jamf policy -event enableLocalLogin -verbose || handle_error "Failed to trigger enable local login policy"
updateScriptLog "Local login enabled policy triggered."

# Install apps via Self Service (some will not install due to being in mac app catalog via Jamf)
# echo "Installing required apps via Self Service..."
# sudo jamf policy -id installChrome -verbose || handle_error "Failed to trigger Chrome installation"
# updateScriptLog "Chrome installation policy triggered."
# sudo jamf policy -id installZoom -verbose || handle_error "Failed to trigger Zoom installation"
# updateScriptLog "Zoom installation policy triggered."
# sudo jamf policy -event installTeamviewer || handle_error "Failed to trigger TeamViewer installation"
# updateScriptLog "TeamViewer installation policy triggered."

# Manually install apps from Self Service
echo "Please manually install the following apps via Self Service: Google Chrome, TeamViewer, Zoom, OneDrive"
while ! confirm_action "PLease install the gfollowing apps from Self Service: Google Chrome, TeamViewer, Zoom, OneDrive. Have you completed this step?" "Please complete the step before proceeding."; do
    echo "Please take the time to install OneDrive and scope all necessary config profiles."
done
updateScriptLog "Confirmed apps installed via Self Service."

# Install and Apply OneDrive Preferences/Script in Jamf Pro
while ! confirm_action "Please ensure OneDrive is installed and all config profiles have been scoped to the machine in JAMF Pro. Have you completed this step?" "Please complete the step before proceeding."; do
    echo "Please take the time to install OneDrive and scope all necessary config profiles."
done
updateScriptLog "Confirmed OneDrive is installed and configured."

# App installation verification
echo "Verifying app installation..."
updateScriptLog "Initiating app installation verification..."
apps_to_verify=("Google Chrome" "Zoom" "TeamViewer" "OneDrive")
for app in "${apps_to_verify[@]}"; do
    if [ -d "/Applications/$app.app" ]; then
        updateScriptLog "$app successfully installed."
    else
        updateScriptLog "WARNING: $app not found. Please verify installation manually."
    fi
done
echo "Software uopdate will run after this, if you do not want to proceed please exit."
sleep 15

# Update/Upgrade to the most recent macOS version
echo "Updating to the latest macOS version..."
sudo softwareupdate --install --all --restart || handle_error "Failed to update macOS"
updateScriptLog "Updating to the latest macOS version."

echo "Script completed. Please follow any manual steps indicated."
updateScriptLog "Script completed."