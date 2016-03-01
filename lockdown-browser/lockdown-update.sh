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


