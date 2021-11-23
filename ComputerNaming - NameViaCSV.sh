#!/bin/bash
#
#
#     Created by A.Hodgson
#      Date: 03/03/2021
#      Purpose: Unbind, rename, bind
#  
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
spreadsheet_id="1CjLv3lfAYtAVmO1yuxVFoL_bFAusntITgjvdzdeEbb4" #Spreadsheet needs "Anyone with link access"
csv_location="/var/tmp/computernames.csv"
bind_trigger="bindme" # Jamf Pro policy that will bind computer again. 

# Check the domain returned with dsconfigad
domain=$( dsconfigad -show | awk '/Active Directory Domain/{print $NF}' )
# Unbind if bound
if [ -z "$domain" ]; then
	echo "Mac is not bound..."
else
	echo "Mac is bound, unbinding..."
	dsconfigad -force -remove -u "Casper_Bind" -p "cspw4wb!"
fi

# Check for an existing file
if [ -e "$csv_location" ]; then
	rm -f $csv_location
fi

# download the list
curl -s -o $csv_location https://docs.google.com/spreadsheets/d/$spreadsheet_id/gviz/tq?tqx=out:csv
chmod 777 $csv_location
awk '{gsub(/\"/,"")};1' $csv_location  > /var/tmp/converted.csv

# name the computer
jamf setComputerName -fromFile /var/tmp/converted.csv 


# remove CSV files
rm -rf $csv_location
rm -rf /var/tmp/converted.csv

# rebind computer if bound before
if [ -z "$domain" ]; then
	echo "Mac was not bound, skipping rebind..."
else
	echo "Mac was bound, rebinding..."
	jamf policy -event $bind_trigger
fi

#exit script gracefully
exit $status 
