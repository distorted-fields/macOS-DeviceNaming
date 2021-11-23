#!/bin/bash
#
#
#     Created by A.Hodgson
#      Date: 05/15/2020
#      Purpose:
#  
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
ldap_server=""
ldap_user=""
ldap_pass=""
computerOU=""

JAMF_BINARY="/usr/local/bin/jamf"

# Get User
user=$(defaults read /Library/Preferences/com.apple.loginwindow lastUserName)
first_name=$(echo $user | cut -d'_' -f 1)
last_name=$(echo $user | cut -d'_' -f 2)
userfullname=$first_name$last_name
site_prefix=$( ldapsearch -H 'ldap://'$ldap_server -x -D $ldap_user -w $ldap_pass -b $computerOU '(sAMAccountName='$user')' division | grep 'division: ' | awk '{print $2}')
if ["$site_prefix" == ""]; then
	site_prefix="unknown"
fi
# Build Device name
device_name="$site_prefix-staff-$userfullname"
# Convert name to all lover case
device_name=$(tr "[:upper:]" "[:lower:]" <<<"$device_name")

echo $device_name

# Set device name in Jamf
"$JAMF_BINARY" setComputerName -name "$device_name"
