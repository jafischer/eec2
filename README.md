# EEC2: Enhanced EC2

## Overview
Eec2 provides a number of commands that greatly simplify working with
Amazon EC2 instances. 

Why use eec2, when there's already an AWS CLI? 

Eec2 doesn't aim to replace the AWS CLI. It only covers a fraction of the commands that are available via the AWS CLI. 
The key goal is **convenience** for a small set of very common operations.

Have you ever struggled to manually perform some operation
on a dozen or more EC2 instances by copying their IP addresses and running ssh or scp commands one 
by one? Then eec2 is for you.

All eec2 commands operate on **instance names**, rather than IDs.
What's more, you can use **wildcards** to operate on multiple instances.

## Example
For instance, logging into instances is as simple as `eec2 ssh my-node-server`.

But to illustrate how eec2 really shines when working with multiple instances, let's say you 
need to create 16 load test instances, deploy some files to them, and then launch the tests.
With eec2, this can be done easily:

```
eec2 create [options omitted for brevity] loadtest-{1..16}
eec2 scp somefile anotherfile *.sh *.yml loadtest-\*:
eec2 ssh loadtest-\* -c './start-loadtest.sh'
```

Eec2 has a convenient 'ls' command, that, in its "long form", will show you the estimated 
monthly cost: `eec2 ls -l`

![Sample output](https://raw.githubusercontent.com/jafischer/eec2/master/eec2-screen1.png)

And with even more detail (note the capital `-L` vs `-l`): `eec2 ls -L`

![Sample output](https://raw.githubusercontent.com/jafischer/eec2/master/eec2-screen2.png)

## Commands
Here are brief descriptions of each command. For full details, use `eec2 help COMMAND` to see each command's help text.

#### config
If you haven't used the AWS CLI before, then you'll need to use this command (just once) to  
configure your AWS credentials and AWS region.
#### create
Create (AKA 'launch') instance(s). Create 100 instances and contribute to the Seattle economy.
#### delete
Delete (terminate) instance(s). Delete all of the things! Very wildcard. So danger!
#### ip-add, ip-ls, ip-rm
Configure private IP addresses.
#### ls
List instances and see how much Kenny, who never remembers to shut down his instances, 
is costing you every month.
#### ren
Renames the specified instance(s). Including bulk rename with wildcards! Rename `old*` to `new*` 
just because you can.
#### scp
Copy files to and from the specified instance(s). The command syntax is essentially the same as the scp command, 
but with instance names in place of IP addresses. And with wildcards! Did I mention that?
#### ssh
Login to the specified instance(s) or run a command. Now you can `sudo yum update` all of your instances at once 
because _security_.
#### start
Yin.
#### stop
Yang.
#### tag
Add, modify or remove instance tags.

## Aliases
Speaking of convenience, why even type `eec2 ssh` when a simple `es` will do? Just run the
following commands, and I guarantee you will grow a genuine Unix neckbeard:
```bash
cat >> ~/.bashrc <<EOS
alias es='eec2 ssh'
alias ec='eec2 scp'
alias el='eec2 ls -L'
alias elr='eec2 ls -L --state running'
EOS
```

Windows users can grow neckbeards too. As long as they use PowerShell:
```
# Add these functions to your $profile file:
function es { eec2 ssh $args }
function ec { eec2 scp $args }
function el { eec2 ls -l $args }
function elr { eec2 ls -l --state running $args }
```
