#!/bin/bash

ARN_FILE_PATH=".serial"

#Check for config file
if [ ! -f ~/.aws/config ]; then
	echo "Missing AWS configuration"
	exit 0;
fi

#Check for credentials file
if [ ! -f ~/.aws/credentials ]; then
	echo "Missing AWS Credentials"
	exit 0;
fi


#Get MFA Serial ARN
mfa_device=$(cat ${ARN_FILE_PATH})

#Prompt MFA code from user
read -p "Enter your 6 digit MFA code: " mfa_code

#Use aws cli to get session token
_sts_output=$(aws sts get-session-token \
	--serial-number ${mfa_device} \
	--token-code ${mfa_code})

#extract the credentials using jq
AWS_ACCESS_KEY_ID=$(echo ${_sts_output} | jq -r '.Credentials.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo ${_sts_output} | jq -r '.Credentials.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo ${_sts_output} | jq -r '.Credentials.SessionToken')


#set the credentials in the config file
aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}" --profile temp
aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" --profile temp
aws configure set aws_session_token "${AWS_SESSION_TOKEN}" --profile temp




