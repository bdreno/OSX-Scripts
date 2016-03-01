#!/bin/bash

#var for jamf binary
jamfBinary='/usr/sbin/jamf'

#var for jamf helper binary
jamfHelper='/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper'


# Alternative format for DecryptString function
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String"
    local SALT="a88855f7a37792b8"
    local K="f87189a908943aed913f78f8"
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "$SALT" -k "$K"
}

jssURL=$4
encryptedApiUsername=$5
encryptedApiPass=$6

exitStatus=0
resetWindow=1
delay=1
userInput=-1



apiUsername=$(DecryptString "$encryptedApiUsername")
apiPass=$(DecryptString "$encryptedApiPass")





# give users an option of 1, 2, ..., 5 days

while [ $delay -lt '6' ] && [ $userInput -ne '0' ] ; do
	userInput=$("$jamfHelper" -windowType hud -title "Configuration" -heading "Enable LockDown Browser" -description "This program will disable remote support on this machine for the specified number of days, up to five.  This will allow LockDown Browser to run." -icon '/Applications/System Preferences.app/Contents/Resources/PrefApp.icns' -button1 "$delay" -button2 "Longer"  "" -defaultButton 1)
	if [ $userInput -eq '2' ] ; then
		delay=$[ $delay+1 ]
	fi
done

if [ $userInput -eq '0' ] ; then

	#add delay to resetWindow
	resetWindow=$((delay + resetWindow))

	serialNumber=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{ print $4; }')
	
	jssComputerId=$( curl -k -sS -u ${apiUsername}:${apiPass} -H "Accept: application/xml" $jssURL/JSSResource/computers/serialnumber/$serialNumber | xmllint -format --xpath "/computer/general/id/text()" - )
	
	#error check echo $?


	#Build XML for submission
	xmlSubmission="<computer><extension_attributes><extension_attribute><name>LockDown Browser - days until reset</name><value>$resetWindow</value></extension_attribute></extension_attributes></computer>"

	#update JSS via API 
	curl -k -sS -u ${apiUsername}:${apiPass} -X PUT -H "Content-Type: text/xml" ${jssURL}/JSSResource/computers/id/$jssComputerId -d "$xmlSubmission"
	curlStatus=$?

	#confirm result code
	sleeptime=3
	sleep $sleeptime
	#Disable  ssh
	yes yes | /usr/sbin/systemsetup -setremotelogin off
	
	#Disable ARD
	sleep $sleeptime
	sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off

	#Disable Screen Sharing
	sleep $sleeptime
	sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist


	#Open Lockdown Browser
	sleep $sleeptime
	open "/Applications/LockDown Browser.app"

		
fi



exit $exitStatus