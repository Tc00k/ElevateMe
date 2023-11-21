#!/bin/bash

## This script requires SwiftDialog to be installed on the receiving machine and is intended to be deployed via Jamf Pro
## Created by: Trenton Cook
## https://www.github.com/Tc00k

#############################################
##                VARIABLES                ##
#############################################

DEBUG="${5:-"true"}" ## Sets the script to debug for testing purposes [Default True]
scriptLog="/var/tmp/ElevateMeDialog.log" ## Local log location
formJSONFile=$( mktemp -u /var/tmp/formJSONFile.XXX ) ## Temp file for JSON data that stores the request form
demotion_script="/private/var/demotion_script" ## Demotion script location
demotion_plist="/Library/LaunchDaemons/demotion.plist" ## Demotion Plist location
timeToDemotion="${4:-"300"}" ## Set demotion time limit with the fourth script parameter in JAMF [ Default: 300 ]

doWebhook="${6:-"true"}" ## Sets the script to report to a slack channel via webhook [Default True]
webhookURL=""  ## Your Slack Webhook URL

#############################################
##                 LOGGING                 ##
#############################################

## Function for updating the script log
function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

## Create log file if not found

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
else
    ## Create adequate spacer in log for readabilities sake
	updateScriptLog ""
    updateScriptLog "---==========================================---"
    updateScriptLog ""
fi

#############################################
##              PRE-REQUISITES             ##
#############################################

## Determine debug status and report
if [ $DEBUG != "false" ]; then
    updateScriptLog "-- Debug Mode: True --"
else
    updateScriptLog "-- Debug Mode: False --"
fi

## Gather logged in user
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
updateScriptLog "-- User requesting Admin: $loggedInUser"

updateScriptLog "-- Generating Demotion Plist content..."
    demotion_plist_content="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
    <plist version=\"1.0\">
    <dict>
	    <key>EnvironmentVariables</key>
	    <dict>
		    <key>PATH</key>
		    <string>/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/usr/local/sbin:/opt/local/bin</string>
	    </dict>
	    <key>Label</key>
	    <string>demotion</string>
	    <key>LaunchOnlyOnce</key>
	    <true/>
	    <key>ProgramArguments</key>
	    <array>
		    <string>/bin/sh</string>
		    <string>/private/var/demotion_script</string>
	    </array>
	    <key>RunAtLoad</key>
	    <false/>
	    <key>StartInterval</key>
	    <integer>$timeToDemotion</integer>
    </dict>
    </plist>
    "

#############################################
##            ELEVATION FUNCTION           ##
#############################################

Elevate(){
    if [ $DEBUG == "false" ]; then
        ## Create Demotion plist to run demotion script after five minutes
        echo "$demotion_plist_content" > $demotion_plist
        chmod 644 $demotion_plist
        chown root:wheel $demotion_plist
        launchctl load $demotion_plist
        ## Elevation command here
        /usr/sbin/dseditgroup -o edit -a $loggedInUser -t user admin
    fi
        ############
        ##  Demotion Script
        ############

        updateScriptLog "-- Creating demotion script for Plist..."
    if [ $DEBUG == "false" ]; then
        cat << '        ==endOfScript==' > $demotion_script
        #!/bin/bash

        ## Variables
        demotion_script="/private/var/demotion_script"
        demotion_plist="/Library/LaunchDaemons/demotion.plist"
        loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
        elevationDurationMinutes="5"

        ## Demotion
        /usr/sbin/dseditgroup -o edit -d $loggedInUser -t user admin

        ## Collect logs
        timestamp=$(date +%s)
        /usr/bin/log collect --output /private/var/log/elevateLog-$timestamp.logarchive --last "${elevationDurationMinutes}"m
        sleep 5
        ## Cleanup
        rm -rf $demotion_plist
        rm -rf $demotion_script

        ==endOfScript==

        ## Edit script permissions
        /usr/sbin/chown root:wheel $demotion_script && /bin/chmod +x $demotion_script
    fi
}

#############################################
##             WEBHOOK REPORTING           ##
#############################################
Webhook(){
webHookdata=$(cat <<EOF
{
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "Admin Request:",
                "emoji": true
            }
        },
        {
            "type": "section",
            "fields": [
                {
                    "type": "mrkdwn",
                    "text": "*Computer Name:*\n$( scutil --get ComputerName )"
                },
                {
                    "type": "mrkdwn",
                    "text": "*User:*\n${loggedInUser}"
                },
                {
                    "type": "mrkdwn",
                    "text": "*Duration:*\n${timeToDemotion} seconds"
                },
                {
                    "type": "mrkdwn",
                    "text": "*Details:*\n${formResults}"
                }
            ]
        }
    ]
}
EOF
)

/usr/bin/curl -sSX POST -H 'Content-type: application/json' --data "${webHookdata}" $webhookURL 2>&1
}

#############################################
##             REQUEST FORM SETUP          ##
#############################################

updateScriptLog "-- Grabbing Dialog binary..."
dialogBinary="/usr/local/bin/dialog"

## Page 1 Variables

updateScriptLog "-- Setting Page 1 variables..."
page1button1text="Submit"
page1button2text="Cancel"
page1title="ElevateMe"
page1Icon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )
page1message="Please fill out this form to request five minutes of temporary admin access. Be aware that all actions performed within the alotted time limit will be recorded and sent to security pending review if the need arises."
usernameJSON='{ "title" : "Full Name","required" : true,"prompt" : "First Last" },'
reasonJSON='{ "title" : "Reason","required" : true,"prompt" : "Installing Adobe Creative Cloud , etc" },'
textFieldJSON="${usernameJSON}${reasonJSON}"

## Page 1 Configuration

updateScriptLog "-- Writing Alert Data..."

page1Config='
{
    "title" : "'"$page1title"'",
    "message" : "'"$page1message"'",
    "button1text" : "'"$page1button1text"'",
    "button2text" : "'"$page1button2text"'",
    "messagefont" : "size=18",
    "titlefont" : "size-38",
    "textfield" : [
        '${textFieldJSON}'
    ],
    "icon" : "'"$page1Icon"'",
    "height" : "325",
    "position" : "center",
    "ontop" : "true"
}
'

updateScriptLog "-- Writing JSON data to temp file..."
echo "$page1Config" > "$formJSONFile"


## Launches page 1 dialog
formResults=$( eval "${dialogBinary} --jsonfile ${formJSONFile} --json" | awk '{ gsub(/[{}]/, ""); print }' | awk '{ gsub(",", ""); print }' | awk '{ gsub("\"", ""); print }')
updateScriptLog " USER RESPONSES: $formResults"

if [[ -z "${formResults}" ]]; then
    formReturnCode="2"
else
    formReturnCode="0"
fi

## Run commands based off button returns (Alert)
case $formReturnCode in 
    ## Button 1 Return
    0)
    updateScriptLog "-- User pressed $page1button1text --"
    updateScriptLog "-- Elevating..."
    if [ $doWebhook == "true" ]; then
    Webhook
    fi
    if [ $DEBUG == "false" ]; then
    Elevate
    fi
    $dialogBinary --timer 300 --position bottomright --moveable --message "" --title "Admin time remaining:" --height 100  --icon none --width 200 --titlefont 'size=14'
    rm -rf $formJSONFile
    ;;
    ## Button 2 Return
    2)
    updateScriptLog "-- User pressed $page1button2text --"
    rm -rf $formJSONFile
    exit 0
    ;;
esac
