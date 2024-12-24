# JAMF Migration Optimization Prep

A comprehensive shell script for automating the migration and optimization of JAMF deployments on macOS systems.

## Features

- Automated removal of management profiles
- Azure MFA verification
- OneDrive sync and migration handling
- Bulk application removal
- JAMF enrollment automation
- System settings configuration
- Self Service app installation

## Prerequisites

- Root access
- macOS operating system
- JAMF Pro environment
- Azure account access
- Administrative privileges

## Installation

1. Download the script to your local machine
2. Make the script executable:
```bash
chmod +x /path/to/jamf_migration_prep.sh
```

## Usage

Run the script with sudo privileges:

```bash
sudo ./jamf_migration_prep.sh
```

## Script Flow

1. **Initialization**
   - Validates root access
   - Sets up logging
   - Identifies logged-in user

2. **Profile Management**
   - Removes existing management profiles
   - Verifies Azure MFA status

3. **Data Migration**
   - Handles OneDrive sync issues
   - Ensures file migration to OneDrive
   - Removes OneDrive application

4. **Application Management**
   - Removes specified applications
   - Handles special cases (TeamViewer, Zoom)
   - Empties trash

5. **JAMF Enrollment**
   - Processes enrollment
   - Updates computer name
   - Configures Self Service options

6. **System Updates**
   - Installs required applications
   - Updates macOS to latest version

## Logging

The script maintains detailed logs at:
```
/var/log/jamf_migration_prep.log
```

## Error Handling

- Implements error catching and reporting
- Uses `set -e` for immediate exit on errors
- Includes custom error handling function

## Version History

- v1.7 (09/26/2024) - Latest version

## Author

Grant Huiras (io-grant)

## Notes

- Ensure all data is backed up before running
- Verify Azure account settings before migration
- Monitor Self Service installations
- Allow sufficient time for MDM server synchronization