<a name="top"></a>
* * *
# EC2cli - Amazon EC2 Utilities
* * *

## Summary

EC2cli was developed to make life easier when working with AWS services in a cli environment.  EC2cli utilizes AWS' cli tools to enable you to send signed requests to Amazon's API to perform uses cases typically  accomplished using the console interface.  EC2cli will save time and effort to perform operations such as taking a snapshot or listing which EC2 instances are running.

That being said, ec2cli was designed for use with relatively low AWS resource counts.  If you are operating at scale, these will prove cumbersome since are no embedded filtering capabilities (if you would like to contribute, please see "Contributing" below).  The assumption is that if you are operating at scale, you have already developed your own tools for managing and operating AWS resources in a commercial environment.

While I realize that accomplishing the same functionality is easier with the AWS ruby or python SDK's, I developed these in bash to make them easy for system administrators and solution architects to modify for their particular use cases.

_Dependency Note_:  ec2cli was developed and tested under bash. Some functionality may work with other shells; however, your mileage may vary.

[![instances](./assets/ec2cli-list-instances.png)](https://images.awspros.world/ec2cli/ec2cli-list-instances.png)

(See [Screenshots](#screenshots) section below)

**Version**:	2.4.10

--

[back to the top](#top)

* * *

## Contents

* [Configuration](#configuration)
* [Permissions](#iam-permissions)
* [Usage](#usage)
* [Screenshots](#screenshots)
* [Contribution Guidelines](#contribution-guidelines)
* [Contact](#contact)

* [**About**](#about-this-repository)

* [**License**](#license)

* [**Dependencies**](#dependencies)

* [**Program Options**](#program-options)

* [**Build Options**](#build-options)

* [**Configuration**](#configuration)

* [**Installation**](#installation)
    * [Ubuntu, Linux Mint, Debian-based Distributions](#debian-distro-install)
    * [Redhat, CentOS](#redhat-distro-install)
    * [Amazon Linux 2, Fedora](#amzn2-distro-install)

* [**Usage**](#usage)

* [**Screenshots**](#screenshots)

* [**Author & Copyright**](#author--copyright)

* [**License**](#license)

* [**Disclaimer**](#disclaimer)

--

[back to the top](#top)

* * *

## About this repository

* Purpose: 		CLI utilities for use with Amazon Web Services (AWS)
* Version:	2.4.10
* Repo: 		https://github.com/fstab50/ec2cli
* Mirror:		https://blakeca00@bitbucket.org/blakeca00/ec2cli.git

* * *

## License

* All utilities contained herein are copyrighted and made available under GPLv2
* See [LICENSE](./LICENSE.txt)

[back to the top](#top)

* * *

## Usage ##

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
### Redhat, CentOS  (Python 3.6+)

Redhat Package Manager (RPM) format used by Redhat-based distros is under development.  Check [rpm.awscloud.center](http://s3.us-east-2.amazonaws.com/rpm.awscloud.center/index.html) page for updates.


[back to the top](#top)

* * *
<a name="amzn2-distro-install"></a>
### Amazon Linux 2 / Fedora (Python 3.7+)

Redhat Package Manager (RPM) format used by Amazon Linux under development.  Check [amzn2.awscloud.center](http://s3.us-east-2.amazonaws.com/amzn2.awscloud.center/index.html) page for updates.

--

[back to the top](#top)


* * *
## Build options

**[GNU Make](https://www.gnu.org/software/make) Targets**.  Type the following to display the available make targets from the root of the project:

```bash
    $  make help
```

<p align="center">
    <a href="http://images.awspros.world/ec2cli/make-help.png" target="_blank"><img src="./assets/make-help.png">
</p>

--

[back to the top](#top)

## Configuration ##

* Configure awscli running the aws configure command:

    ```bash
   $ aws configure

	AWS Access Key ID: foo
	AWS Secret Access Key: bar
	Default region name [us-west-2]: us-west-2
	Default output format [None]: json
    ```

* Optionally, define a profile for a specific user:

    ```bash
   $ aws configure --profile testuser

    AWS Access Key ID: footestuser
    AWS Secret Access Key: bartestuser
    Default region name [us-west-2]: us-west-2
    Default output format [None]: json
    ```

* Command Completion

	You'll want to enable command completion to make awscli
	commands easy to type and recall.  After installing awscli,
	add the following to your .bashrc or .bash_profile:

    ```bash
	# .bashrc
	complete -C aws_completer aws
    ```

[back to the top](#top)

* * *

### Verify Your Configuration

After completing the above Installation and Configuration sections, verify your configuration:

```bash
	$ ec2cli --version
```

[![version](./assets/ec2cli-version.png)]((https://images.awspros.world/ec2cli/ec2cli-version.png))

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

## Screenshots ##

#### ec2cli `list` command ####

List command displays AWS resource details for your AWS default region if no region specified. If an alternate region given as a parameter, displays resource details for the specified region.


```bash
$ ec2cli -i    # list ec2 instances, AWS default region (us-west-2)
```
[![instances](./assets/ec2cli-list-instances.png)](https://images.awspros.world/ec2cli/ec2cli-list-instances.png)

```bash
$ ec2cli -v    # list ebs volume details, AWS default region (us-west-2)
```

[![volumes](./assets/ec2cli-list-volumes.png)](https://images.awspros.world/ec2cli/ec2cli-list-volumes.png)


```bash
$ ec2cli -s    # list snapshots, AWS default region (us-west-2)
```
[![snapshots](./assets/ec2cli-list-snapshots.png)](https://images.awspros.world/ec2cli/ec2cli-list-snapshots.png)

```bash
$ ec2cli -g    # list security group details, AWS default region (us-west-2)
```
[![securitygroups](./assets/ec2cli-list-securitygroups.png)](https://images.awspros.world/ec2cli/ec2cli-list-securitygroups.png)

[back to the top](#top)

* * *

## Screenshots ##

#### ec2cli `run` command ###

*Note: this utility may also be used to automate login to a running EC2 instance*
*as well as starting a stopped instance. See step 2. (below)*

```bash
$ ec2cli -i run    # run/ log on to EC2 instances in default region
```
1.Select from list of instance choices:

![](./assets/start-instance_01.png)

2.After instance is chosen, ec2cli performs a network access check:

  * Access check sources the security group and validates IPs listed in the group against your local IP.
  * _Note_: if the instance you chose is already running, the ec2cli moves immediately to authentication (Step 4).

![](./assets/start-instance_02.png)

3.If network access check succeeds, the ec2 wait function is called to prevent login until the instance starts.

![](./assets/start-instance_03.png)

4.Authentication start:

  * Public IP and ssh key name are sourced from instance json data via api call.
  * The ssh key is then located on your local machine in the dir specified by the ``$SSH_KEYS`` env variable.

![](./assets/start-instance_04.png)

5.Login established (entire start sequence shown)

![](./assets/start-instance_05.png)

[back to the top](#top)

* * *

## Screenshots ##

### Spot Price Utility ###

[Screenshots (continued)](./README_spot.md)

[back to the top](#top)

* * *

## Contribution Guidelines ##

   If you'd like to contribute, please fork and then send me
   a pull request.

[back to the top](#top)

* * *

## Contact ##

* Repo owner:  Blake Huber // @B1akeHuber

[back to the top](#top)
