## `s3-cfn.sh`
### Usage
`s3-cfn.sh [-h] [--delete] --stack-name <stack_name> --regions <regions> --template <cfn_template>`
> Executing the script without the optional --delete flag creates or updates the stack depending on its existence. Specifying the --delete flag deletes the stacks named <region>-<friendly-name>

Format for specifying list of regions in json:
```
{
    "regionList": ["us-east-1", "us-east-2"]    
}
```

## `s3-cfn.py`

### Usage
`./s3-cfn.py <stack-name> <regions-json> <template-yaml> [delete (optional)]`
> Order of arguments to the script cannot be changed. Delete still requires a region <regions-json> <template-yaml> to be specified although they won't be used.

Format for specifying list of regions in json:
```
{
    "regionList": ["us-east-1", "us-east-2"]    
}
```













