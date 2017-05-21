# EEC2: Enhanced EC2

## Overview
This gem provides a number of command line tools that greatly simplify working with
Amazon EC2 instances. 

Why use eec2, when there is already the AWS CLI? 
The key aim of eec2 is **convenience**, especially for the common set of operations that I found myself doing in my own work.

All eec2 commands operate on **instance names**, rather than IDs.
What's more, you can use wildcards to operate on multiple instances.

#### Example
For instance, logging into instances is as simple as `eec2 ssh my-node-server`.

But where eec2 really shines is when working with multiple instances. Let's say you need to
create 16 load test instances, deploy some files to them, and then launch the tests.
With eec2, this can be done so easily:

```bash
eec2 create [options omitted for brevity] loadtest-{1..16}
eec2 scp somefile anotherfile *.sh *.yml loadtest-\*:
eec2 ssh loadtest-\* -c './start-loadtest.sh'
```

### Commands
Here are brief descriptions of each command. For full details, use `eec2 help COMMAND` to see each command's details.

##### config
Use this command to set up your AWS config files (in ~/.aws).
##### create
Create (AKA 'launch') EC2 instance(s).
##### delete
Delete (terminate) EC2 instance(s).
##### ip-add, ip-ls, ip-rm
Configure private IP addresses.
##### ls
List the specified EC2 instance(s).
##### ren
Renames the specified EC2 instance(s).
##### scp
Copy files to and from the specified EC2 instance(s).
##### ssh
Login to the specified EC2 instance(s) and optionally run a command.
##### start
Start the specified EC2 instance(s).
##### stop
Stop the specified EC2 instance(s).
##### tag
Manipulate instance tags.
