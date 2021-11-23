#!/usr/bin/python

# Rename computer from remote CSV using Jamf binary
# Pass in the URL to your remote CSV file using script parameter 4
# The remote CSV could live on a web server you control, OR be a Google Sheet specified in the following format:
# https://docs.google.com/spreadsheets/u/0/d/[SHEET ID]/export?format=csv&id=[SHEET ID]&gid=[TAB ID]

import os
import sys
from urllib.request import urlopen
import urllib.error
import subprocess
CSV_PATH = '/var/tmp/computernames.csv'
needs_rebind = ''

def download_csv(url):
    # Downloads a remote CSV file to CSV_PATH
    try:
        # open the url
        csv = urlopen(url).read().decode('utf-8')
        # ensure the local path exists
        directory = os.path.dirname(CSV_PATH)
        if not os.path.exists(directory):
            os.makedirs(directory)
        # write the csv data to the local file
        with open(CSV_PATH, 'w+') as local_file:
            local_file.write(csv)
        # return path to local csv file to pass along
        return CSV_PATH
    except (urllib.error.HTTPError, urllib.error.URLError):
        print('ERROR: Unable to open URL', url)
        return False
    except (IOError, OSError):
        print('ERROR: Unable to write file at', CSV_PATH)
        return False

def rename_computer(path):
    # Renames a computer using the Jamf binary and local CSV at <path>
    cmd = ['/usr/local/bin/jamf', 'setComputerName', '-fromFile', path]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, _ = proc.communicate()
    if proc.returncode == 0:
        # on success the jamf binary reports 'Set Computer Name to XXX'
        # so we split the phrase and return the last element
        return out.split(' ')[-1]
    else:
        return False

def bind_computer(trigger):
    # Call the binding policy via jamf binary
    cmd = ['/usr/local/bin/jamf', 'policy', '-event', trigger]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, _ = proc.communicate()
    if proc.returncode == 0:
        return True
    else:
        return False

def unbind_computer():
    # Call the binding policy via jamf binary
    cmd = ['/usr/sbin/dsconfigad', '-show', '|', 'awk', '/Active Directory Domain/']
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, _ = proc.communicate()
    if out:
        print('Computer is bound')
        global needs_rebind
        needs_rebind = 'TRUE'
        cmd = ['/usr/sbin/dsconfigad', '-force', '-remove', '-u', 'Casper_Bind', '-p', 'cspw4wb!']
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, _ = proc.communicate()
        if proc.returncode == 0:
            return True
        else:
            return False
    else:
        print('Computer is not bound')
        return True


def main():
    try:
      #   csv_url = sys.argv[4]
        csv_url = 'https://docs.google.com/spreadsheets/u/0/d/1CjLv3lfAYtAVmO1yuxVFoL_bFAusntITgjvdzdeEbb4/export?format=csv&id=1CjLv3lfAYtAVmO1yuxVFoL_bFAusntITgjvdzdeEbb4&gid=265393794'
    except ValueError:
        print('ERROR: You must provide the URL of a remote CSV file.')
        sys.exit(1)
    computernames = download_csv(csv_url)
    if computernames:
        unbind_status = unbind_computer()
        if unbind_status:
            print('Computer succesfully unbound')
            rename = rename_computer(computernames)
            if rename:
                print('SUCCESS: Set computer name to', rename)
                if needs_rebind:
                	binding_status = bind_computer('bindme')
	                if binding_status:
	                	print('Successfully rebound computer')
	                else:
	                	print('ERROR rebinding computer')
	                	sys.exit(1)
                else:
                	print('No rebind necessary')
            else:
                print('ERROR: Unable to set computer name. Is this device in the remote CSV file?')
                if needs_rebind:
                	binding_status = bind_computer('bindme')
                	if binding_status:
                		print('Successfully rebound computer')
                	else:
                		print('ERROR rebinding computer')
                	sys.exit(1)
                else:
	                sys.exit(1)
        else:
            print('ERROR unbinding computer')
            sys.exit(1)
    else:
        print('ERROR: Unable to set computer name without local CSV file.')
        sys.exit(1)


if __name__ == '__main__':
    main()