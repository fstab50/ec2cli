#!/bin/bash
#
#  Author: Blake Huber
#  Purpose: QuickView of ec2 instance data in table form
#  User: $USER
#  Requires:  awscli 
#  Log:  N/A
#
# < -- Start -->

# print header
echo " "

# output from aws
aws ec2 describe-tags --output table

# print footer
echo " "
