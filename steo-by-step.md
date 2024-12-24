# JAMF Migration Process: Step-by-Step Guide

*Last Updated: December 24, 2024*  
*Author: Grant Huiras*  
*Status: Active*

## Overview
This document outlines the step-by-step process for migrating devices to our JAMF environment using the automated migration script. The process combines automated steps with necessary manual verification points to ensure a smooth transition.

## Prerequisites
- Administrative access to the device
- JAMF Pro access
- Azure account credentials
- Migration script (`jamf_migration_prep.sh`)
- Backup of all critical data

## Pre-Migration Checklist
- [ ] Verify user has Azure account access
- [ ] Confirm all critical data is backed up
- [ ] Check available disk space (minimum 10GB recommended)
- [ ] Document current device name and configuration
- [ ] Ensure stable internet connection

## Migration Process

### Phase 1: Initial Setup
1. **Login and Authentication**
   - Log in to the device with administrative credentials
   - Open Terminal
   - Navigate to script location
   - Execute: `sudo ./jamf_migration_prep.sh`

2. **Profile Management**
   - Script automatically removes existing management profiles
   - *Manual Check Point:* Verify profiles are removed in System Settings

### Phase 2: Data Protection
1. **Azure MFA Configuration**
   - Disable MFA or add alternative authentication method
   - *Manual Check Point:* Test Azure login

2. **OneDrive Preparation**
   - Review OneDrive sync status
   - Resolve any pending sync issues
   - *Manual Check Point:* Verify all files are synced

### Phase 3: Application Management
1. **Application Removal**
   The script automatically removes:
   - Microsoft Office Suite
   - GarageBand
   - iMovie
   - Keynote
   - Numbers
   - Pages
   - TeamViewer Host
   - Zoom
   
   *Manual Check Point:* Verify applications are removed

2. **Clean-up**
   - Script empties Trash
   - Removes residual application data

### Phase 4: JAMF Enrollment
1. **Initial Enrollment**
   - Script triggers JAMF enrollment
   - *Manual Check Point:* Confirm enrollment status

2. **Device Configuration**
   - Enter new computer name when prompted
   - Wait for MDM server sync (approximately 2 minutes)
   - *Manual Check Point:* Verify computer name update

### Phase 5: Application Reinstallation
1. **Self Service Applications**
   Manually install from Self Service:
   - Google Chrome
   - TeamViewer
   - Zoom
   - OneDrive

2. **Configuration Profiles**
   - Apply necessary configuration profiles
   - *Manual Check Point:* Verify profile application

### Phase 6: System Updates
1. **Software Update**
   - Script initiates system update
   - *Manual Check Point:* Confirm update completion

## Troubleshooting

### Common Issues
1. **Profile Removal Failure**
   - Solution: Manually remove profiles through System Settings
   - If persists, contact IT support

2. **OneDrive Sync Issues**
   - Clear OneDrive cache
   - Reset OneDrive sync
   - Contact IT if issues persist

3. **JAMF Enrollment Failures**
   - Verify network connection
   - Check enrollment credentials
   - Run `sudo jamf recon` manually

## Post-Migration Checklist
- [ ] Verify all applications are installed correctly
- [ ] Test OneDrive access and sync
- [ ] Confirm JAMF enrollment
- [ ] Test Self Service functionality
- [ ] Verify user permissions
- [ ] Check system update status

## Support Contact Information
- IT Support Portal: [Insert URL]
- Emergency Support: [Insert Phone Number]
- Email: [Insert Email]

## Related Documentation
- JAMF Pro Administrator Guide
- OneDrive Migration Guide
- Azure MFA Configuration Guide

---
*For internal use only. Please report any issues or suggested updates to the IT team.*