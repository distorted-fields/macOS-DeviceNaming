#!/bin/bash
#
#
#     Created by A.Hodgson
#      Date: 06/12/2019
#      Purpose: Prompt user to enter a name.
#			If name is blank, failover to check for an asset tag in Jamf.
#			If asset tag is empty, or device isn't enrolled, then failover to the serial number
#  
#
######################################

#set these variables to check for asset_tag - user must have computer read privileges
apiUser=""
apiPassword=""
jssURL=""

# capture user input name
while true
do
ComputerName=$(osascript -e 'Tell application "System Events" to display dialog "Please enter a name for your computer" default answer ""' -e 'text returned of result' 2>/dev/null)
    if [ $? -ne 0 ]     
    then # user cancel
        break
    elif [ -z "$name" ]
    then # loop until input or cancel
        osascript -e 'Tell application "System Events" to display alert "Please enter a name or select Cancel!" as warning'
    else [ -n "$name" ] # user input
        break
    fi
done

#ComputerName="$ComputerName"

#if no name is entered, fall back to the serial number
if [ -z "$ComputerName" ]
then
	echo "User didn't enter a name, checking API for asset tag"
	if [ -z "$apiUser" ]
	then
		echo "API credentials not supplied, setting device name to serial number."
		# Get the Serial Number of the Machine
		ComputerName=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
	else 
		# get the asset tag
		sn=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
		asset_tag=$(curl -sku "$apiUser":"$apiPassword" -H "Accept: text/xml" "$jssURL"/JSSResource/computers/serialnumber/$sn -X GET | awk -F '<asset_tag>|</asset_tag>' '{print $2}')
		#check if asset_tag is empty and failover to serial number
		if [ -z "$asset_tag" ]
		then
			echo "Asset tag not found, or credentials were incorrect."
			echo "Setting device name to serial number."
			# Get the Serial Number of the Machine
			ComputerName=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
		else
			echo "Asset tag found, setting device name to that."
			#asset tag wasn't empty set as computer name
			ComputerName="$asset_tag"
		fi
	fi
fi

sudo scutil --set HostName "$ComputerName"
sudo scutil --set LocalHostName "$ComputerName"
sudo scutil --set ComputerName "$ComputerName"

echo "Device name set, updating inventory."
jamf recon

exit 0
