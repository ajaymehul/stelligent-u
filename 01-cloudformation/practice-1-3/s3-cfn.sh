#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [--delete] --friendly-name <friendly_name> --regions <regions> --template <cfn_template>

Tool to manage cloudformation stacks of s3 buckets in multiple regions.
This script automatically chooses to create or update the stack based on its existence.

CFN stacks are named <region>-<friendly-name>
S3 buckets are names <region>-<account-id>-<friendly-name>

Available options:

Flags:
-h, --help      Print this help and exit
-d, --delete    Flag set to delete the CFN stack

Parameters:
--friendly-name <value>  Friendly name of the stacks & corresponding s3 buckets
--regions <value>    	JSON file with a list of target regions
--template <value>    File name of CFN template
EOF
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  delete=0

  while :; do
    case "${1-}" in
    -h | --help) 
			usage 
			exit
			;;
		-d | --delete)
			delete=1
			;;
    --friendly-name) 
      friendly_name="${2-}"
      shift
      ;;
		--regions)
			regions="${2-}"
			shift
			;;
		--template)
			cfn_template="${2-}"
			shift
			;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
#  [[ -z "${cfn_template-}" ]] && usage && die "Missing required parameter: template"
	[[ -z "${regions-}" ]] && usage && die "Missing required parameter: regions"
	[[ -z "${friendly_name-}" ]] && usage && die "Missing required parameter: friendly_name"
#  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

parse_params "$@"
setup_colors

# script functions

create_update_stack () {
	local full_stack_name=$1
	local region=$2
	local operation=$3 # create / update
	aws cloudformation $operation-stack \
		--stack-name $full_stack_name \
		--region $region \
		--template-body file://$cfn_template \
		--parameters ParameterKey=BucketNameParam,ParameterValue=$friendly_name
}


delete_stack() {
	local full_stack_name=$1
	local region=$2
	aws cloudformation delete-stack \
		--stack-name $full_stack_name \
		--region $region 
}


# script logic here

#iterate through JSON list of regions using jq and call create stack
regions_list=`jq -r '.regionList[]' $regions`
msg "${GREEN}Regions:${NOFORMAT}"  && echo $regions_list
for reg in $regions_list
do
	full_name="${reg}-${friendly_name}"

	if [ $delete -eq 1 ] ; then 
		msg "${CYAN} Deleteing stack ${full_name}.... ${NOFORMAT}"
		delete_stack $full_name $reg
	else
		# Check if stack already exists by calling describe-stacks silently and update-stack if failed
		if ! aws cloudformation describe-stacks --stack-name $full_name --region $reg  &>/dev/null ; then
			msg "${CYAN}Creating new stack ${full_name}... ${NOFORMAT}"
			# Try creating the stack
			if ! create_update_stack $full_name $reg 'create'; then
				msg "${RED}Stack creation failed for ${full_name} ${NOFORMAT}\n"
			fi

		else
			msg "${CYAN}Stack exists. Updating stack ${full_name}.... ${NOFORMAT}"
			# Try updating the stack
			if ! create_update_stack $full_name $reg 'update'; then
				msg "${RED}Stack update failed for ${full_name} ${NOFORMAT} \n"
			fi

		fi
	fi
done


msg "${YELLOW}Read parameters:${NOFORMAT}"
msg "--friendly-name: ${friendly_name}"
msg "--regions: ${regions}"
msg "--template: ${cfn_template}"
