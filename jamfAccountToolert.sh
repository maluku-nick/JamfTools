#!/bin/bash
# # # # # # # # # # # # # # # # # # #
# 	Script Naam	- jamfAccountToolert.sh
# 	Auteur		  - Nick van Jaarsveld
# 	Organisatie	- Maluku-Nick
# 	Versie		  - 1.1
# 	Beschrijving
#	  Creates or deletes one or more Jamf Pro User Accounts to Jamf Pro using the Classic API
#
# # # # # # # # # # # # # # # # # # #


####################################
## VARIABLES

# configure json file for authentication
JSON=".createaccount"
jamfpro=`cat "$JSON" | python -c "import sys, json; print(json.load(sys.stdin)['user'])"`
jamfPass=`cat "$JSON" | python -c "import sys, json; print(json.load(sys.stdin)['pass'])"`

# get general information
localUser=$(id -un)
xmlLocation="/Users/$localUser/Downloads"

# list of url's to process
sourceURL="https://source.jamfcloud.com"
targetURL="https://test-target.jamfcloud.com"

targetURL=("https://target.jamfcloud.com"
	"https://target.jamfcloud.com")


####################################
# FUNCTIONS

newUser () {
	echo "Enter username to work with"
	read jamfUser

	echo "Downloading user $jamfUser from $sourceURL"
	curl -su $jamfpro:$jamfPass "$sourceURL/JSSResource/accounts/username/$jamfUser" -H -X GET "accept: application/xml" | xmllint --format - > "$xmlLocation/$jamfUser.xml"
	
	
	for u in "${targetURL[@]}"
	do
		echo "Creating user $jamfUser on $u"
		curl -su $jamfpro:$jamfPass "$u/JSSResource/accounts" -H "content-type: application/xml" -X POST -T "$xmlLocation/$jamfUser.xml"
		echo ""
		echo "======================================================================================================="
		echo ""
	done
	
	echo "Removing downloaded xml"
	rm -f "$xmlLocation/$jamfUser.xml"
}


deleteUser () {
	echo "Enter username to work with"
	read jamfUser

	for u in "${targetURL[@]}"
	do
		echo "Downloading user $jamfUser from $u"
		curl -su $jamfpro:$jamfPass -H -X GET "accept: application/xml" "$u/JSSResource/accounts/username/$jamfUser" | xmllint --format - > "$xmlLocation/$jamfUser.xml"
		
		echo "Getting object ID for user $jamfUser"
		id=$(xmllint --xpath '/account/id/text()' $xmlLocation/$jamfUser.xml)
		echo "Object ID is: $id"
		
		echo "Deleting user $jamfUser from $u"
		curl -su $jamfpro:$jamfPass -X DELETE "$u/JSSResource/accounts/userid/$id"
		rm -f "$xmlLocation/$jamfUser.xml"
		echo ""
		echo "======================================================================================================="
		echo ""
	done
}


####################################
# START SCRIPT


while :
do
	clear
	echo "--------------------------------------------------------------------"
	echo "|"
	echo "| MALUKU-NICK" 
	echo "| Jamf Pro Account Toolert"
	echo "|"
	echo "--------------------------------------------------------------------"
	echo "| c | Create a Jamf Pro user account on all Jamf Pro instances"
	echo "| d | Delete a Jamf Pro user account from all Jamf Pro instances"
	echo "| q | Quit"
	echo "--------------------------------------------------------------------"
	read -rp $'\e[1m'"| Pick your favourite option: "$'\e[0m' INVOER
	case $INVOER in
		[cC])      newUser;;
		[dD])      deleteUser;;
		[qQ])     exit 0 ;;
		*)     echo "Computer says no. Please try again" ; sleep 1 ;;
	esac
done
