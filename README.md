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
- 🔧 Customizable
- 💻 Made specifically for a Jamf Pro environment
- ✔️ Easy to setup

## Getting Started

Follow the below steps to get ElevateMe setup and running

### Prerequisites

Make sure you have the following:

- Jamf Instance with the target computer(s) added
- SwiftDialog installed on the target computer(s) (https://github.com/swiftDialog/swiftDialog)
- Target computers user accounts are set to standard and not admin

### Installation

1. Create a new script named "ElevateMe" in your Jamf pro instance
2. Copy the contents from ElevateMe.bash to this new script and press save
3. Navigate to your computer policies and select "New"
4. Give it a name, I chose "ElevateMe - Self Service"
5. Select a Category if you want
6. Under General, set the Execution Frequency to "Ongoing"
7. Under Scripts, Select "Configure" and add our "ElevateMe" script
8. Set a scope for the ElevateMe policy under the "Scope" tab, if you need it set to a specific subset of computers be sure to only select those computers
9. Switch to the "Self Service" tab and check the box to enable this policy within Self Service
10. Give it a display name, I chose "ElevateMe" again here
11. Change both the Before and After Initiation button labels to "Elevate"
12. Give it a description if you want/need
13. Upload a preferred Icon
14. Select a category to display the policy within Self Service, I chose my utilities category
15. Double check all settings and press "Save" in the bottom right

### Usage

Computers in the ElevateMe policy scope will now have a Self Service entry they can activate to gain Admin level access for the time limit that you have chosen
