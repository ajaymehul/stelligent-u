#!/usr/bin/env python3
"""
Module Docstring
"""

import sys
import boto3
import json

__author__ = "ajaymehul"
__version__ = "0.1.0"
__license__ = "MIT"


def _create_stack(full_stack_name, template_file, client, bucket_name):
	print("Creating stack {}....".format(full_stack_name))
	response = client.create_stack(
		StackName = full_stack_name,
		TemplateBody = _read_template(template_file),
		Parameters = [{
			'ParameterKey': 'BucketNameParam',
			'ParameterValue': bucket_name
		}]
	)
	print(response)

def _update_stack(full_stack_name, template_file, client, bucket_name):
	print("Updating stack {}....".format(full_stack_name))
	response = client.update_stack(
		StackName = full_stack_name,
		TemplateBody = _read_template(template_file),
		Parameters = [{
			'ParameterKey': 'BucketNameParam',
			'ParameterValue': bucket_name
		}]
	)
	print(response)

def _delete_stack(full_stack_name, client):
	print("Deleting stack {}....".format(full_stack_name))
	response = client.delete_stack(
		StackName=full_stack_name
	)
	print(response)

	

def _stack_exists(stack_name, client):
    stacks = client.list_stacks()['StackSummaries']
    for stack in stacks:
        if stack['StackStatus'] == 'DELETE_COMPLETE':
            continue
        if stack_name == stack['StackName']:
            return True
    return False

def _read_template(template):
	with open(template) as fileobj:
		template_body = fileobj.read()
	return template_body

def _read_regions(regions_file):
	f = open(regions_file)
	data = json.load(f)
	regions = data['regionList']
	f.close()
	return regions

def _create_regional_clients(regions_list):
	clients = []
	for region in regions_list:
		client = boto3.client('cloudformation', region_name=region)
		clients.append(client)
	return clients

	

def main():
    #Check for arguments
	if len(sys.argv) < 4:
		print("Missing arguments. \nUsage: ./s3-cfn.py <stack-name> <regions-json> <template-yaml> [delete (optional)]")
		exit()
	stack_name = sys.argv[1]
	regions_file = sys.argv[2]
	template_file = sys.argv[3]

	regions_list = _read_regions(regions_file)

	regional_clients = _create_regional_clients(regions_list)

	for index, client in enumerate(regional_clients):
		full_stack_name = "-".join([regions_list[index], stack_name])

		if _stack_exists(full_stack_name, client):
			if len(sys.argv) > 4 and sys.argv[4] == "delete":
				_delete_stack(full_stack_name, client)		
			else:
				_update_stack(full_stack_name, template_file, client, stack_name)
		else:
			_create_stack(full_stack_name, template_file, client, stack_name)


if __name__ == "__main__":
	""" This is executed when run from the command line """
	main()
