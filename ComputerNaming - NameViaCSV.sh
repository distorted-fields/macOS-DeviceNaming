#!/bin/bash
#
#
#     Created by A.Hodgson
#      Date: 2022-09-07
#      Purpose: name computer by CSV, failover to serial if not in CSV
#  
#
############################################################# 
sheetID="" #Spreadsheet ID = https://docs.google.com/spreadsheets/d/THIS_IS_THE_ID/edit needs "Anyone with link access"
omitRows="1" # number of rows at the top of the sheet to omit (IE Headers)
#############################################################
# letter designation of the column in the sheet for the device serial numbers
serialCol="A"
# letter designation of the colum in the sheet for the custom device name
nameCol="B"

# get the device serial number
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
#Look up serial number from Google Sheet using the Google visualization api
name=$(curl -sL "https://docs.google.com/spreadsheets/d/$sheetID/gviz/tq?tqx=out:csv&tq=select%20$nameCol%20WHERE%20$serialCol%3D%27$serialNumber%27" | sed 's/"//g' | tail -n+$((omitRows+1)))
echo "Name: $name"

if [[ "$name" == "" ]]; then
	echo "Failed by CSV, using Serial Number instead"
	jamf setComputerName -name "$serialNumber"
else
	jamf setComputerName -name "$name"
fi
