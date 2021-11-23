# macOSDeviceNaming Script

These scripts are for naming macOS devices. Designed as a supplement for DEP enrollments, but can really be used anytime you wish to update a computer name. 

### ComputerNaming - AutoNameLDAP.sh
Names computer based on the logged in user, requires a connection to an LDAP server. Tested with an on-prem server, modifications for cloud are likely necessary.

### ComputerNaming - NameViaCSV.py
Keep a list of computer names and serials in Google Sheets - give it "anyone with the link can view" access. Col 1 should be the serial, Col 2 the computer name.

### omputerNaming - NameViaCSV.sh 
Same as above but includes unbinding prior, if detected. Names computer. Rebinds if unbind was run. Requires an LDAP server connection, modifications for cloud are likely necessary. 

### ComputerNaming - JPS-AssetTag.sh
Script will prompt the user for a name for the computer. If the user hits cancel at the prompt, and API credentials are supplied at the top of the script, then the script will try to reach the API to check for an asset tag to use. This is useful for re-enrolling computer only. If the asset tag attempt fails for any reason (no creds, or no asset tag), then the script will finally failover to use the serial number for the computer name. 

This script is designed to be run as a policy in Jamf Pro. I did not test against the login/out triggers, nor do I have any idea what's going to happen if the device is at the login screen when it runs. 

Lastly - if you're running macOS 10.14+, it's assumed you have the Jamf PPPC profile deployed to your computers by default from Jamf, or you've grabbed the profile here and have deployed it before running this script - https://github.com/jamf/JamfPrivacyPreferencePolicyControlProfiles
