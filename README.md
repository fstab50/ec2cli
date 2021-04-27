<a name="top"></a>
* * *
# EC2cli - Amazon EC2 Utilities
* * *

## Contents

* [**About**](#about-this-repository)

* [**Summary**](#summary)

* [**Dependencies**](#dependencies)

* [**Program Options**](#program-options)

* [**Installation**](#installation)
  * [Ubuntu, Linux Mint, Debian-based Distributions](#debian-distro-install)
  * [Redhat, CentOS, Fedora](#redhat-distro-install)
  * [Amazon Linux 2](#amzn2-distro-install)

* [**Configuration**](#configuration)

* [**Verify Your Configuration**](#verify-your-configuration)

* [**Identity and Access Management (IAM) Permissions**](#iam-permissions)

* [**Build Options**](#build-options)

* [**Screenshots**](#screenshots)
  * [`list` Command](#screenshots0)
  * [`run` Command](#screenshots1)
  * [ `--tags` Resource Option](#screenshots2)
  * [EC2 Spot Price Utility](#screenshots3)

* [**Author & Copyright**](#author--copyright)

* [**License**](#license)

* [**Disclaimer**](#disclaimer)

--

[back to the top](#top)

* * *

## About this repository

* Purpose: 		CLI utilities for use with Amazon Web Services (AWS)
* Version:	2.4.11
* Repo: 		https://github.com/fstab50/ec2cli

--

[back to the top](#top)

* * *
## Summary

EC2cli was developed to make life easier when working with AWS services in a cli environment.  EC2cli utilizes AWS' cli tools to enable you to send signed requests to Amazon's API to perform uses cases typically  accomplished using the console interface.  EC2cli will save time and effort to perform operations such as taking a snapshot or listing which EC2 instances are running.

While it is clear that accomplishing the ec1cli's functionality with the AWS ruby or python SDK's may be cleaner, ec2cli was developed in bash to make it easy for system administrators and solution architects to modify ec2cli for each's respective use cases.

_Dependency Note_:  ec2cli was developed and tested under bash. Some functionality may work with other shells; however, your mileage may vary.

[![instances](./assets/ec2cli-list-instances.png)](https://images.awspros.world/ec2cli/ec2cli-list-instances.png)

(See [Screenshots](#screenshots) section below)

--

[back to the top](#top)

* * *

## Dependencies

[ec2cli](https://github.com/fstab50/ec2cli) requires the following to function correctly:

- A modern Linux distribution with bash (4.x+)
- [Python version 3.6+](https://docs.python.org/3/)
- Appropriate [Identity and Access Management (IAM) Permissions](#iam-permissions) to access your Amazon Web Services account.
- Configuration of [Amazon Web Services CLI tools](https://github.com/aws/aws-cli) (awscli).  After installation, follow this [configuration guide](#configuration) to set up the awscli for Bash.
- [jq](https://stedolan.github.io/jq), a json parser generally available from your distribution repo
- Standard linux utilities:
    * grep
    * awk
    * sed
    * cat
    * hostname

--

[back to the top](#top)

* * *

## Program Options ##

```bash
	$ ec2cli --help
```

[![help](./assets/ec2cli-help.png)](https://images.awspros.world/ec2cli/ec2cli-help.png)


### Notes: ###

* **RESOURCE** is required. Represents a disparate AWS resource. Only 1 resource at a time is supported.

* **COMMAND** is optional. If omitted, ec2cli defaults to the `list` command and lists details of the EC2 resource specified by the OPTION parameter.

* **REGIONCODE** is optional. If omitted, ec2cli defaults to the AWS default region defined in the `AWS_DEFAULT_REGION` environment variable (if present); or alternately, the awscli config file.

* `create` and `run` commands currently have support for limited resource types. Update your local repo frequently to enable additional resource types as additional types are added.

[back to the top](#top)

* * *
## Installation ##
* * *

<a name="debian-distro-install"></a>
### Ubuntu, Linux Mint, Debian variants  (Python 3.6+)

The easiest way to install **ec2cli** on debian-based Linux distributions is via the debian-tools package repository:


1. Open a command line terminal.

    [![deb-install0](./assets/deb-install-0.png)](http://images.awspros.world/ec2cli/deb-install-0.png)

2. Download and install the repository definition file

    ```
    $ sudo apt install wget
    ```

    ```
    $ wget http://awscloud.center/deb/debian-tools.list
    ```

    [![deb-install1](./assets/deb-install-1.png)](http://images.awspros.world/ec2cli/deb-install-1.png)

    ```
    $ sudo chown 0:0 debian-tools.list && sudo mv debian-tools.list /etc/apt/sources.list.d/
    ```

3. Install the package repository public key on your local machine

    ```
    $ wget -qO - http://awscloud.center/keys/public.key | sudo apt-key add -
    ```

    [![deb-install2](./assets/deb-install-2.png)](http://images.awspros.world/ec2cli/deb-install-2.png)

4. Update the local package repository cache

    ```
    $ sudo apt update
    ```

5. Install **ec2cli** os package

    ```
    $ sudo apt install ec2cli
    ```

    [![deb-install3a](./assets/deb-install-3a.png)](http://images.awspros.world/ec2cli/deb-install-3a.png)

    Answer "y":

    [![deb-install3b](./assets/deb-install-3b.png)](http://images.awspros.world/ec2cli/deb-install-3b.png)


6. Verify Installation

    ```
    $ apt show ec2cli
    ```

    [![apt-show](./assets/deb-install-4.png)](http://images.awspros.world/ec2cli/deb-install-4.png)


[back to the top](#top)

* * *

<a name="redhat-distro-install"></a>
### Redhat, CentOS  (Python 3.6+), Fedora (Python 3.7+)

The easiest way to install **ec2cli** on redhat-based Linux distributions is via the developer-tools package repository:

1. Open a command line terminal.

    [![rpm-install0](./assets/rpm-install-0.png)](http://images.awspros.world/ec2cli/rpm-install-0.png)

2. Install the official epel package repository

    ```
    $ sudo yum install epel-release
    ```

2. Download and install the repo definition file

    ```
    $ sudo yum install wget
    ```

    [![rpm-install1](./assets/rpm-install-1.png)](http://images.awspros.world/ec2cli/rpm-install-1.png)

    ```
    $ wget http://awscloud.center/rpm/developer-tools.repo
    ```

    [![rpm-install2](./assets/rpm-install-2.png)](http://images.awspros.world/ec2cli/rpm-install-2.png)

    ```
    $ sudo chown 0:0 developer-tools.repo && sudo mv developer-tools.repo /etc/yum.repos.d/
    ```

    [![rpm-install2b](./assets/rpm-install-2b.png)](http://images.awspros.world/ec2cli/rpm-install-2b.png)


3. Delete the local repository cache, then Update the cache with new package references

    ```
    $ sudo rm -fr /var/cache/yum
    $ sudo yum update -y
    ```

4. Install the **ec2cli** os package

    ```
    $ sudo yum install ec2cli
    ```

    [![rpm-install3](./assets/rpm-install-3.png)](http://images.awspros.world/ec2cli/rpm-install-3.png)


    Answer "y":

    [![rpm-install4](./assets/rpm-install-4.png)](http://images.awspros.world/ec2cli/rpm-install-4.png)


5. Verify Installation

    ```
    $ yum info ec2cli
    ```

    [![rpm-install5](./assets/rpm-install-5.png)](http://images.awspros.world/ec2cli/rpm-install-5.png)


[back to the top](#top)

* * *
<a name="amzn2-distro-install"></a>
### Amazon Linux 2

Redhat Package Manager (RPM) format used by Amazon Linux under development.  Check [amzn2.awscloud.center](http://s3.us-east-2.amazonaws.com/amzn2.awscloud.center/index.html) page for updates.

--

[back to the top](#top)


* * *

## Configuration ##

1. You will have to configure the Amazon Web Servies comand line interface before attempting to use **ec2cli**:

a. Run the _aws configure_ command:

```bash
$ aws configure
   AWS Access Key ID: foo
   AWS Secret Access Key: bar
   Default region name [us-west-2]: us-west-2
   Default output format [None]: json
```

b. Optionally, define a profile for a specific user:

```bash
  $ aws configure --profile testuser
    AWS Access Key ID: footestuser
    AWS Secret Access Key: bartestuser
    Default region name [us-west-2]: us-west-2
    Default output format [None]: json
```

c. Configure bash command completion:  	You'll want to enable command completion to make awscli
	commands easy to type and recall.  After installing awscli,
	add the following to your .bashrc or .bash_profile:

```bash
  # .bashrc
	complete -C aws_completer aws
```

2. Next, configure [IAM policy permissions](#iam-permissions) for the user profile which will generally be used with **ec2cli**.

--

[back to the top](#top)

* * *

### Verify Your Configuration

After completing the above Installation and Configuration sections, verify your configuration:

```bash
$ aws --version
```

Output:

```
$  aws-cli/1.19.44 Python/3.8.5 Linux/5.6.0-1052-oem botocore/1.20.44
```

**Note**: Python and Kernel versions will depend upon your system parameters

[back to the top](#top)

* * *

## IAM Permissions ##

#### ec2cli Required Permissions ####
You'll need appropriate IAM permissions to execute ec2cli.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:CreateKeyPair",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot",
                "ec2:DetachVolume",
                "ec2:RunInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": [
                "*"
        ]
        }
    ]
}

```

You can grab a read-only version of the policy [here](./policies/iampolicy-EC2-quickview.json) or the full IAM policy which allows changes to resources [here](./policies/iampolicy-EC2-full.json).

[back to the top](#top)

* * *

## Build options

**[GNU Make](https://www.gnu.org/software/make) Targets**.  If you wish to use this project to compile your own Linux installation pa kages, type the following to display the available make targets from the root of the project:

```bash
    $  make help
```

<p align="center">
    <a href="http://images.awspros.world/ec2cli/make-help.png" target="_blank"><img src="./assets/make-help.png">
</p>

--

[back to the top](#top)

* * *
## Screenshots ##
* * *
<a name="screenshots0"></a>
#### [Screenshots](#screenshots) / ec2cli `list` command

List command displays AWS resource details for your AWS default region if no region specified. If an alternate region given as a parameter, displays resource details for the specified region.


```bash
$ ec2cli --instances    # list ec2 instances, AWS default region (us-west-2)
```
[![instances](./assets/ec2cli-list-instances.png)](https://images.awspros.world/ec2cli/ec2cli-list-instances.png)

```bash
$ ec2cli --volumes    # list ebs volume details, AWS default region (us-west-2)
```

[![volumes](./assets/ec2cli-list-volumes.png)](https://images.awspros.world/ec2cli/ec2cli-list-volumes.png)


```bash
$ ec2cli --snapshots    # list snapshots, AWS default region (us-west-2)
```
[![snapshots](./assets/ec2cli-list-snapshots.png)](https://images.awspros.world/ec2cli/ec2cli-list-snapshots.png)

```bash
$ ec2cli --secgroups    # list security group details, AWS default region (us-west-2)
```
[![securitygroups](./assets/ec2cli-list-securitygroups.png)](https://images.awspros.world/ec2cli/ec2cli-list-securitygroups.png)

[back to the top](#top)

* * *

<a name="screenshots1"></a>
#### [Screenshots](#screenshots) / ec2cli `run` command

*Note: this utility may also be used to automate login to a running EC2 instance*
*as well as starting a stopped instance. See step 2. (below)*

```bash
$ ec2cli --instances run    # run/ log on to EC2 instances in default region
```
1.Select from list of instance choices:

[![instances](./assets/start-instance_01.png)](https://images.awspros.world/ec2cli/start-instance_01.png)

2.After instance is chosen, ec2cli performs a network access check:

  * Access check sources the security group and validates IPs listed in the group against your local IP.
  * _Note_: if the instance you chose is already running, the ec2cli moves immediately to authentication (Step 4).

[![instances](./assets/start-instance_2.png)](https://images.awspros.world/ec2cli/start-instance_2.png)


3.If network access check succeeds, the ec2 wait function is called to prevent login until the instance starts.

[![instances](./assets/start-instance_03.png)](https://images.awspros.world/ec2cli/start-instance_03.png)

4.Authentication start:

  * Public IP and ssh key name are sourced from instance json data via api call.
  * The ssh key is then located on your local machine in the dir specified by the ``$SSH_KEYS`` env variable.

[![instances](./assets/start-instance_04.png)](https://images.awspros.world/ec2cli/start-instance_04.png)

5.Login established (entire start sequence shown)

[![instances](./assets/start-instance_05.png)](https://images.awspros.world/ec2cli/start-instance_05.png)

--

[back to the top](#top)

* * *

<a name="screenshots2"></a>
#### [Screenshots](#screenshots) / ec2cli --tags <resourceId>

Display all tags attached to an EC2 resource by following the steps below:

1. Enter the ```--tags``` parameter after the main executable:

```
$  ec2cli --tags
```

2.  Hit the <tab> key twice to display a list of available EC2 resource Ids:

```
$ ec2cli --tags <tab><tab>
```
[![tags1](./assets/tags-completion.png)](https://images.awspros.world/ec2cli/tags-completion.png)

3. Choose a resource id by typing the first few characters.  Then hit the <tab> key.

* Example 1:  Tags associated with a specific EC2 machine instance:

[![tags2](./assets/tags-instance.png)](https://images.awspros.world/ec2cli/tags-instance.png)

* Example 2:  Tags associated with an EC2 snapshot:

[![tags3](./assets/tags-snapshot.png)](https://images.awspros.world/ec2cli/tags-snapshot.png)

--

[back to the top](#top)

* * *

<a name="screenshots3"></a>
#### [Screenshots](#screenshots) / Spot Price Utility


[Screenshots (continued)](./README_spot.md)

[back to the top](#top)

* * *

## Author & Copyright

All works contained herein copyrighted via below author unless work is explicitly noted by an alternate author.

* Copyright Blake Huber, All Rights Reserved.

[back to the top](#top)

* * *

## License

* Software contained in this repo is licensed under the [license agreement](./LICENSE.md).  You may display the license and copyright information by issuing the following command:

```
$ ec2cli --version
```

[![version](./assets/version-copyright.png)](https://images.awspros.world/ec2cli/version-copyright.png)


[back to the top](#top)

* * *

## Disclaimer

*Code is provided "as is". No liability is assumed by either the code's originating author nor this repo's owner for their use at AWS or any other facility. Furthermore, running function code at AWS may incur monetary charges; in some cases, charges may be substantial. Charges are the sole responsibility of the account holder executing code obtained from this library.*

Additional terms may be found in the complete [license agreement](./LICENSE.md).

[back to the top](#top)

* * *
