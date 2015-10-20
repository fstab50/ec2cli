# EC2 CLI Utilities  

* [About](#About)
* [License](#License)
* [Introduction](#Introduction)
* [Conventions](#conventions)
* [Contents](#contents)
* [Installation](#installation)
* [Configuration](#configuration)
* [Contribution Guidelines](#contribution)
* [Contact](#contact)

## About this repository 

* Purpose:  	CLI utilities for use with Amazon Web Services (AWS)
* Version:	08/2015
* Repo: 	[ec2] https://github.com/t-stark/ec2.git


## License 

* All utilities contained herein are copyrighted and made available under GPLv2
* See [LICENSE](https://www.gnu.org/licenses/gpl-2.0.html)


## Introduction 

These scripts were developed to make life easier when working with AWS services
in a cli environment.  These utilize AWS' cli tools to enable you to send signed 
requests to Amazon's API to perform uses cases previously performed using the 
console interface.  Using these will save time and effort to perform operations
such as taking a snapshot or listing which EC2 instances are running.

That being said, the scripts in this repo are designed for use with relatively
low AWS resource counts.  In other words, if you are operating at scale and have
1000 EBS volumes, these will prove cumbersome since I haven't added embedded
search capabilities (if you would like to contribute, please see "Contributing" below).  
The assumption is that if you are operating at scale, you have already developed
your own tools for managing and operating AWS resources in that type of
commercial environment.

Dependency Note:  Many of the utilities were developed and tested under bash.
Some may work with other shells; however, your mileage may vary.


## Conventions ##

* "qv" in the filename means "Quick view", a read only (ro) report


* "X" in the filename indicates "Executable".  These make permanent changes to your 
      account resources such as creating a snapshot or mounting a new partition.  Use 
      with caution.  Your IAM user must have rw permissions on the respective
      resources you wish to add or modify using X scripts.


## Contents ##
````
* ec2-qv-AMIs.sh                # Quick view list of all AMI's associated with default region
* ec2-qv-instances.sh           # Quick view list of all EC2 instances in the default region 
* ec2-qv-securitygroups.sh      # Quick view list of all security groups associated
* ec2-qv-snapshots.sh           # Quick view list of all snapshots in default region
* ec2-qv-spot-prices.sh         # Quick view of spot prices in a region you specify
* ec2-qv-subnets.sh             # Quick view of subnets in the default region
* ec2-qv-tags.sh                # Quick view of EC2 tags
* ec2-qv-volumes.sh             # Quick view list of all volumes in the default region
* ec2-qv-vpc.sh                 # Quick view list of all default region vpc's
* ec2-X-attach-volume.sh        # Utility for attaching a volume to an instance
* ec2-X-rdp-desktop.sh          # Client utility for starting a windows RDP instance
* ec2-X-start-instance.sh       # Utility for starting an EC2 instance from a list
* ec2-X-take-snapshot.sh        # Utility for taking snapshots

# init/ 

* motd-ec2.sh                   # dynamic message of the day for EC2 instances. Dep on ec2-az-location.sh
* ec2-hostname.sh               # resets EC2 hostname upon (re)start, part of init process
* ec2-az-location.sh            # grabs region from metadata service. Called by motd-ec2.sh
* ec2.bash_profile              # sample from my EC2 bash_profile
````

## Installation ##

* Dependencies 
	- writable directory where utilities are located
	- installation Amazon CLI tools (awscli)
	- installation of jq, a JSON parser.  See your local distribution repo
	- one of the following python versions: 2.6.5, 2.7.X+, 3.3.X+, 3.4.X+
	- awk, sed


* Environment variables: 
	Setup the following global environment variable3s by adding each to your
	.bashrc or .bash_profile
````                              
# .bashrc 

export EC2_REPO=~/git/ec2              # location of this README and utilities (writable)
export EC2_BASE=/usr/local/ec2         # location of host-based init scripts
export AWS_ACCESS_KEY=XXXXXXXXXXXXX    # Your IAM Access Key
export AWS_SECRET_KEY=XXXXXXXXXXXXX    # Your Secret Key
export AWS_DEFAULT_REGION=us-west-2    # AWS region where majority of your stuff 
````


* Install [awscli](https://github.com/aws/aws-cli/)
	
	Detailed instructions can be found in the README located at:
	https://github.com/aws/aws-cli/

	The easiest method, provided your platform supports it, is via [pip](http://www.pip-installer.org/en/latest).

````
    $ pip install awscli
````
   or, if you are not installing in a virtualenv:
````
    $ sudo pip install awscli
````
   If you have the aws-cli installed and want to upgrade to the latest version you can run:
````
    $ pip install --upgrade awscli
````

## Configuration ##

* Configure awscli 

   Run the aws configure command:

````
   $ aws configure
	
	AWS Access Key ID: foo
	AWS Secret Access Key: bar
	Default region name [us-west-2]: us-west-2
	Default output format [None]: json
````

   To use environment variables, do the following:
````
	$ export AWS_ACCESS_KEY_ID=<access_key>
	$ export AWS_SECRET_ACCESS_KEY=<secret_key>
````
   To use a config file, create a configuration file like this:
````
	[default]
	aws_access_key_id=<default access key>
	aws_secret_access_key=<default secret key>
````
* Config File 
   
    Optional, define a default region for a specific profile by
    placing the following in ~/.aws/config:
````
	[profile testing]
	aws_access_key_id=<testing access key>
	aws_secret_access_key=<testing secret key>
	region=us-west-2
````

* Command Completion 
   	
	You'll want to enable command completion to make awscli
	commands easy to type and recall.  After installing awscli,
	add the following to your .bashrc or .bash_profile:
````
	# .bashrc
	complete -C aws_completer aws
````
   
## Contribution guidelines ##

   In header of most utilities, there is a FUTURE section
   containing feature enhancements so these utilities can stand
   alone.

   If you'd like to contribute, please fork and then send me 
   a pull request.


## Contact ##

* Repo owner:  Blake Huber // @B1akeHuber
