#!/bin/bash
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  return location of AZ of EC2 instance                        |
#  Name:     ec2-az-zone-location.sh                                      |
#  Location: $EC2_BASE                                                    |
#  Requires: EC2 api-tools, curl, motd-ec2.sh (parent),                   |
#            for instance located at AWS datacenter only                  |
#  Environment Variables (required, global):                              |
#       EC2_BASE                                                          |
#       EC2_HOME                                                          |
#       AWS_DEFAULT_REGION                                                |
#  User:     init process (root)                                          |
#  StdOut:   log                                                          |
#  Error:    stderr                                                       |
#  Log:      /var/log/messages                                            |
#                                                                         |
#_________________________________________________________________________|

# < -- Start -->

#----   collect location of avail zone  -----------------------------------

# grab region from metadata service
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

	# ID region location 
	case "$REGION" in
		eu-west-1*)
		  LOCATION="Europe (Ireland)"
		  ;;
		eu-central-1*)
		  LOCATION="Europe (Frankfurt, Germany)"
		  ;;
		sa-east-1*)
		  LOCATION="South America (Sao Paulo)"
		  ;;
		us-east-1*)
		  LOCATION="United States (N. Virgina)"
		  ;;
		us-west-1*)
		  LOCATION="United States (N. California)"
		  ;;
		us-west-2*)
   		  LOCATION="United States (Oregon)"
		  ;;
		ap-northeast-1*)
		  LOCATION="Asia Pacific (Tokyo)"
		  ;;
		ap-southeast-1*)
		  LOCATION="Asia Pacific (Singapore)"
		  ;;
		ap-southeast-2*)
		  LOCATION="Asia Pacific (Sydney)"
		  ;;
		*)
		  LOCATION="New Region"
		  ;;
	esac

echo $LOCATION

exit 0

#<----- end --------------->
