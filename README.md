# ElevateMe

Created by: Trenton Cook

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)

## Introduction

ElevateMe is a Self Service Jamf script that utilizes SwiftDialog to automate the elevation of standard user accounts to admin level accounts for a set time, after which it will demote them back to standard accounts automatically through the use of a LaunchDaemon.


## Features

- 🗃️ Housed completely within one script
- 📋 Local logging & JAMF logging
- 😄 User friendly GUI
- 🔧 Debug mode for testing
- 💻 Made specifically for a Jamf Pro environment
- ✔️ Easy to setup
- 🗞️ Slack reporting via Webhooks

## Getting Started

Follow the below steps to get ElevateMe setup and running

### Prerequisites

Make sure you have the following:

- Jamf Instance with the target computer(s) added
- SwiftDialog installed on the target computer(s) (https://github.com/swiftDialog/swiftDialog)
- Target computers user accounts are set to standard and not admin

### Installation

1. Create a new script named "ElevateMe" in your Jamf pro instance
2. Copy the contents from ElevateMe.bash to this new script
4. Under "Options" set the fourth parameter label to "Time Limit", fifth parameter label to "Debug", sixth parameter label to "Enable Webhook", and seventh parameter label to "Webhook URL"
5. Navigate to your computer policies and select "New"
6. Give it a name, I chose "ElevateMe - Self Service"
7. Select a Category if you want
8. Under General, set the Execution Frequency to "Ongoing"
9. Under Scripts, Select "Configure" and add our "ElevateMe" script
10. Enter a time limit in seconds or leave it blank to default to five minutes/three hundred seconds
11. Enter "false" in the debug parameter slot to ensure the script actually elevates on launch, if you ever need to test this script you can set it to true and perform your tests
12. Enter "true/false" in the Enable Webook parameter slot (True will send webhooks)
13. If you are using the Slack Webhook function please check the [Webhook Setup](#webhook-setup) section of this readme now
14. Set a scope for the ElevateMe policy under the "Scope" tab, if you need it set to a specific subset of computers be sure to only select those computers
15. Switch to the "Self Service" tab and check the box to enable this policy within Self Service
16. Give it a display name, I chose "ElevateMe" again here
17. Change both the Before and After Initiation button labels to "Elevate"
18. Give it a description if you want/need
19. Upload a preferred Icon
29. Select a category to display the policy within Self Service, I chose my utilities category
20. Double check all settings and press "Save" in the bottom right

### Usage

Computers in the ElevateMe policy scope will now have a Self Service entry they can activate to gain Admin level access for the time limit that you have chosen

When a user runs this script from within self service they will first be greeted by this window which requests their name and the reason they want admin privileges (If you don't like this display message you can change it on line 142 under the variable "page1message")

<img width="815" alt="Screenshot 2023-11-10 at 9 53 52 AM" src="https://github.com/Tc00k/ElevateMe/assets/150291395/e0fd68a1-acb1-4052-a93e-843952bf1328">

The user can either press "Cancel" or "Submit" at this point, both fields are required to Submit

  Cancel: Closes the prompt and makes no changes to the users machine

  OR

  Submit: Submits users answers to the Jamf policy log and the local log which is located on line 12 under the variable "scriptLog", then runs the elevation function and starts the admin timer (pictured below)

<img width="199" alt="Screenshot 2023-11-10 at 9 58 31 AM" src="https://github.com/Tc00k/ElevateMe/assets/150291395/3de11d25-d925-4155-9bed-989806335449">

After the timer has expired the launchDaemon created by the Elevate function will trigger and run the demotion script at root level. Which will remove the user account from the admin list, cleanup by removing the Plist and Demotion script, then create a log archive for the past however long your admin session is set to run under the fourth script parameter. The default location for this log is listed on line 115 (/private/var/elevateLog.logarchive)

![Screenshot 2023-11-21 at 4 28 40 PM](https://github.com/Tc00k/ElevateMe/assets/150291395/c2f60b9a-ce85-469b-8bc7-7e7816968bfb)

This is what the Slack webhook reporting looks like by default

### Webhook Setup

1. Ensure that line 20 "doWebhook" is set to "true"
2. Ensure that you have entered your Webhook URL in line 21 "webhookURL" (Check [Slack](https://api.slack.com/messaging/webhooks) for more information on setting up webhooks)
3. Adjust line 18 "jamfproComputerURL" to reflect your Jamf instance "examplecompany.jamfcloud.com"
4. Open your Jamf Pro instance and create a new Configuration Profile
5. Under the "General" tab give your configuration profile a name and description then, set a category, set "Level" to "Computer Level", and finally set "Distribution Method" to "Install Automatically"
6. Under the "Applications & Custom Settings --> External Applications" tab Select "Add"
7. Set "Source" to "Custom Schema" and "Preference Domain" to "com.elevateme"
8. Select "Add Schema" and paste the contents of "ElevateMe_CustomSchema.json" into the available field and press "Save"
9. Enter "$JSSID" into the "Computer ID" field
10. Scope this configuration profile to the same machines as your ElevateMe policy and press "Save"
11. You can now return to step 14 of the [Installation](#installation) category
    
