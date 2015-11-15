#!/bin/bash
#
#
#_________________________________________________________________________
#                                                                         | 
#                                                                         |
#  Author:   Blake Huber                                                  |
#  Purpose:  QuickView of all EC2 snapshots in the AWS acct               |
#            indicated by $AWS_ACCESS_KEY                                 |
#  Name:     ec2-qv-snapshots.sh                                          |
#  Location: $EC2_REPO                                                    |
#  Requires: awscli, awk, sed, writable dir                               |
#  Environment Variables (required, global):                              |
#       EC2_BASE                                                          |
#       EC2_HOME                                                          |
#       AWS_ACCESS_KEY                                                    |
#       AWS_SECRET_KEY                                                    |
#       AWS_DEFAULT_REGION                                                |
#  User:     $USER                                                        |
#  Out:      CLI                                                          |
#  Error:    stderr                                                       |
#  Log:      N/A                                                          |
#                                                                         |
#_________________________________________________________________________|

# < -- Start -->

#
# print header
#

# set vars
BOLD=`tput bold`
UNBOLD=`tput sgr0`

# functions
indent18() { sed 's/^/                  /'; }

# print region identifier
printf "\n\n${BOLD}SNAPSHOTS:${UNBOLD} $AWS_DEFAULT_REGION\n\n" | indent18

# test default shell, format change if debian default (dash)
case "$SHELL" in
  *bash*)
        # shell appears to be bash 
        echo -ne "\nSnapId Vo1. State Prog VolumeId Description\n \
        ------------- ----  --------- ---- ------------ \
        ---------------------------------------------------\n" \
	> .ec2-qv-snapshots.tmp
  ;;

  *)
        # shell other than bash 
        echo "\nDefault shell appears to be non-bash. Please rerun with bash. Exiting. Code $E_BADSHELL\n"
        exit $E_BADSHELL
  ;;
esac

#
# output from aws
#
aws ec2 describe-snapshots \
	--owner self \
	--output text \
	--query "Snapshots[*]. \
		[SnapshotId, \
		VolumeSize, \
		State, \
		Progress,\
		VolumeId,\
		Description]" | \
sort -rk +6n  >> .ec2-qv-snapshots.tmp

# print and format output
#
# Note: Since awk is looking for blank space as delimiter, we allow spaces
#       in the description field by telling awk these are 2 char columns.
#       Description field containing up to 7 strings separated by a single 
#       space will be printed via below awk statement (last 7 columns).
#
awk  '{ printf "%-14s %-5s %-10s %-5s %-13s %-2s %-2s %-2s %-2s \n", \
	$1, $2, $3, $4, $5, $6, $7, $8, $9}' .ec2-qv-snapshots.tmp

# print footer
echo " "

# clean up
rm .ec2-qv-snapshots.tmp

exit 0
